# RevenueCat Subscriptions (AI Chef)

## API key

- **Where:** `lib/config/keys.dart` → `revenueCatApiKey`, or pass at build time:
  ```bash
  flutter run --dart-define=REVENUECAT_API_KEY=appl_xxx  # iOS
  flutter run --dart-define=REVENUECAT_API_KEY=goog_xxx  # Android
  ```
- **Get keys:** [RevenueCat Dashboard](https://app.revenuecat.com) → Project → API Keys.
- **Production:** Use the **Production** (live) public key for release builds. Do not commit it to public repos; use CI secrets or `--dart-define`.
- **Testing:** Use the **Sandbox** (test) public key for development.

## Testing sandbox subscriptions

- **iOS:** Sign out of App Store in Settings, then run the app; when you purchase, sign in with a **Sandbox Apple ID** (created in App Store Connect → Users and Access → Sandbox).
- **Android:** Add test license accounts in Google Play Console → Setup → License testing; use that account on device/emulator for test purchases.

## Firestore integration

- **Write:** `SubscriptionService` writes `premium`, `premiumExpiration`, and `premiumUpdatedAt` to `users/{userId}` after purchase, restore, and when entitlement changes.
- **Read:** Use `FirebaseService.getUserProfile()` and check `data['premium']`, or listen to `users/{userId}`. For access control, **always** rely on RevenueCat (e.g. `SubscriptionService.instance.isPremium`) as source of truth; Firestore is for display and server-side convenience.
- **Server-side verification:** Use [RevenueCat REST API – Subscriber](https://docs.revenuecat.com/reference/subscribers) with your **secret** API key to verify entitlement before granting premium content on your backend.

## App wiring

1. **Startup:** After Firebase init, call `SubscriptionService.instance.init()` (e.g. in `main()` or after `runApp`).
2. **After login:** Call `SubscriptionService.instance.logIn(FirebaseAuth.instance.currentUser!.uid)`.
3. **On logout:** Call `SubscriptionService.instance.logOut()`.
4. **Paywall:** Navigate to `PaywallScreen()` (e.g. from profile or when a premium feature is tapped).

## Entitlement and offering

- **Entitlement ID:** `premium` (must match RevenueCat dashboard).
- **Offering ID:** `default` (must match RevenueCat dashboard).
- **Products:** Configure Monthly, Yearly, and Lifetime in App Store Connect / Google Play Console and map them in RevenueCat to the `default` offering.
