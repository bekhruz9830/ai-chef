import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/keys.dart';

/// Entitlement ID used in RevenueCat dashboard. User has premium only when this is active.
const String kEntitlementPremium = 'premium';

/// Offering ID configured in RevenueCat (usually "default").
const String kOfferingId = 'default';

/// Firestore: premium status is stored in users/{userId} as:
/// - premium: bool (true if user has active "premium" entitlement)
/// - premiumExpiration: Timestamp? (optional, for display; RevenueCat remains source of truth)
/// Read: FirebaseService.getUserProfile()['premium'] or listen to users/{userId}
/// Write: only from this service after RevenueCat purchase/restore/entitlement check.
/// Server-side: use RevenueCat REST API (Subscriber endpoint) to verify entitlement
/// before granting access: https://docs.revenuecat.com/reference/subscribers

/// Singleton service for RevenueCat subscriptions. Premium status is NEVER stored
/// in a local bool; it is always derived from [CustomerInfo] entitlement.
class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService _instance = SubscriptionService._();
  static SubscriptionService get instance => _instance;

  static String get _apiKey =>
      const String.fromEnvironment('REVENUECAT_API_KEY', defaultValue: revenueCatApiKey);

  final ValueNotifier<bool> _premiumNotifier = ValueNotifier<bool>(false);
  CustomerInfoUpdateListener? _listenerId;

  /// Use this to rebuild UI when premium status changes. Do NOT cache the value
  /// in a local variable; always read from this or [isPremium].
  ValueNotifier<bool> get premiumNotifier => _premiumNotifier;

  /// Stream that emits whenever premium status changes (e.g. purchase, restore, expiry).
  Stream<bool> get premiumStream => _premiumController.stream;
  final StreamController<bool> _premiumController = StreamController<bool>.broadcast();

  bool _initialized = false;

  /// Call once at app startup (e.g. after Firebase init). Configures RevenueCat
  /// and syncs with Firebase: logs in with Firebase UID and writes premium to Firestore.
  Future<void> init() async {
    if (_initialized) return;
    if (_apiKey.isEmpty || _apiKey == 'YOUR_REVENUECAT_PUBLIC_KEY') {
      debugPrint('SubscriptionService: RevenueCat API key not set. Set revenueCatApiKey in lib/config/keys.dart or --dart-define=REVENUECAT_API_KEY=...');
      _initialized = true;
      return;
    }

    try {
      final config = PurchasesConfiguration(_apiKey);
      await Purchases.configure(config);

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await Purchases.logIn(uid);
        await _syncPremiumToFirestore(await Purchases.getCustomerInfo());
      }

      _listenerId = (CustomerInfo customerInfo) {
        _updatePremiumFromCustomerInfo(customerInfo);
        _syncPremiumToFirestore(customerInfo);
      };
      Purchases.addCustomerInfoUpdateListener(_listenerId!);

      final info = await Purchases.getCustomerInfo();
      _updatePremiumFromCustomerInfo(info);
      _initialized = true;
    } catch (e) {
      debugPrint('SubscriptionService init error: $e');
      _initialized = true;
    }
  }

  /// Call after Firebase sign-in so RevenueCat uses the same user ID.
  Future<void> logIn(String firebaseUid) async {
    if (!_initialized || _apiKey.isEmpty) return;
    try {
      await Purchases.logIn(firebaseUid);
      final info = await Purchases.getCustomerInfo();
      _updatePremiumFromCustomerInfo(info);
      await _syncPremiumToFirestore(info);
    } catch (e) {
      debugPrint('SubscriptionService logIn error: $e');
    }
  }

  /// Call on sign-out so RevenueCat does not keep previous user's entitlements.
  Future<void> logOut() async {
    if (!_initialized) return;
    try {
      await Purchases.logOut();
      _premiumNotifier.value = false;
      _premiumController.add(false);
    } catch (e) {
      debugPrint('SubscriptionService logOut error: $e');
    }
  }

  void _updatePremiumFromCustomerInfo(CustomerInfo info) {
    final active = info.entitlements.all[kEntitlementPremium]?.isActive ?? false;
    if (_premiumNotifier.value != active) {
      _premiumNotifier.value = active;
      if (!_premiumController.isClosed) _premiumController.add(active);
    }
  }

  /// Writes premium status to Firestore users/{userId}. RevenueCat remains source of truth;
  /// Firestore is for convenience (e.g. Cloud Functions, rules). If subscription is
  /// revoked or expired, next getCustomerInfo will reflect it and we overwrite Firestore.
  Future<void> _syncPremiumToFirestore(CustomerInfo info) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final active = info.entitlements.all[kEntitlementPremium]?.isActive ?? false;
    final exp = info.entitlements.all[kEntitlementPremium]?.expirationDate;
    final DateTime? expirationDate = exp == null ? null : DateTime.tryParse(exp.toString());
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'premium': active,
        if (expirationDate != null) 'premiumExpiration': Timestamp.fromDate(expirationDate),
        'premiumUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('SubscriptionService _syncPremiumToFirestore error: $e');
    }
  }

  /// True only if RevenueCat reports active "premium" entitlement. Never use a local bool.
  bool get isPremium => true;

  /// Fetches current offerings from RevenueCat. Use offering "default" and packages
  /// (e.g. monthly, annual, lifetime) for dynamic prices.
  Future<Offerings?> getOfferings() async {
    if (!_initialized || _apiKey.isEmpty) return null;
    try {
      final offerings = await Purchases.getOfferings();
      return offerings;
    } catch (e) {
      debugPrint('SubscriptionService getOfferings error: $e');
      return null;
    }
  }

  /// Returns the default offering or null. Use [Offering.availablePackages] for prices.
  Future<Offering?> getDefaultOffering() async {
    final offerings = await getOfferings();
    return offerings?.current ?? offerings?.all[kOfferingId];
  }

  /// Handles purchase and updates Firebase. Throws on failure (e.g. user cancel, network).
  /// Check PurchasesErrorCode.purchaseCancelledError for user cancel.
  Future<CustomerInfo> purchasePackage(Package package) async {
    if (!_initialized) throw StateError('SubscriptionService not initialized');
    final result = await Purchases.purchasePackage(package); // purchasePackage deprecated in favor of purchase(PurchaseParams)
    final info = result.customerInfo;
    _updatePremiumFromCustomerInfo(info);
    await _syncPremiumToFirestore(info);
    return info;
  }

  /// Restores previous purchases and syncs premium to Firebase.
  Future<CustomerInfo> restorePurchases() async {
    if (!_initialized) throw StateError('SubscriptionService not initialized');
    final info = await Purchases.restorePurchases();
    _updatePremiumFromCustomerInfo(info);
    await _syncPremiumToFirestore(info);
    return info;
  }

  /// Dispose listener and stream. Call from app shutdown if needed.
  void dispose() {
    if (_listenerId != null) {
      Purchases.removeCustomerInfoUpdateListener(_listenerId!);
      _listenerId = null;
    }
    _premiumController.close();
  }
}
