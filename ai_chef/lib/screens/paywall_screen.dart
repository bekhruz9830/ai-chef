import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:ai_chef/constants/theme.dart';
import 'package:ai_chef/services/subscription_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offering? _offering;
  Package? _selectedPackage;
  bool _loading = true;
  bool _purchasing = false;
  bool _restoring = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    setState(() { _loading = true; _error = null; });
    final offering = await SubscriptionService.instance.getDefaultOffering();
    if (!mounted) return;
    if (offering == null || offering.availablePackages.isEmpty) {
      setState(() { _loading = false; _error = 'No offerings available.\nCheck RevenueCat dashboard.'; });
      return;
    }
    Package? defaultPkg;
    for (final p in offering.availablePackages) {
      if (p.packageType == PackageType.annual) { defaultPkg = p; break; }
    }
    setState(() {
      _offering = offering;
      _selectedPackage = defaultPkg ?? offering.availablePackages.first;
      _loading = false;
    });
  }

  Future<void> _purchase(Package package) async {
    setState(() => _purchasing = true);
    try {
      final info = await SubscriptionService.instance.purchasePackage(package);
      if (!mounted) return;
      if (info.entitlements.all['premium']?.isActive ?? false) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Welcome to Premium!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Purchase failed: $e')));
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    try {
      final info = await SubscriptionService.instance.restorePurchases();
      if (!mounted) return;
      if (info.entitlements.all['premium']?.isActive ?? false) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Premium restored!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active subscription found.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null ? _buildError() : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😕', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.body),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadOfferings,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final packages = _offering?.availablePackages ?? [];
    final busy = _purchasing || _restoring;

    return Stack(
      children: [
        Container(
          height: 300,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.gradient1, AppColors.gradient2],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const Text('👨‍🍳', style: TextStyle(fontSize: 60)),
                      const SizedBox(height: 12),
                      const Text(
                        'AI Chef Premium',
                        style: TextStyle(
                          color: Colors.white, fontSize: 28,
                          fontWeight: FontWeight.w800, letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Unlock all features and cook like a pro',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                      const SizedBox(height: 32),
                      _buildFeatures(),
                      const SizedBox(height: 20),
                      ...packages.map((p) => _buildPackageTile(p, busy)),
                      const SizedBox(height: 24),
                      _buildPurchaseButton(busy),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: busy ? null : _restore,
                        child: _restoring
                            ? const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                            : const Text('Restore purchases',
                                style: TextStyle(color: AppColors.textLight)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Cancel anytime. Subscription renews automatically.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textLight, fontSize: 11),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatures() {
    const features = [
      ('🍳', 'Unlimited AI recipes', 'Generate as many as you want'),
      ('📸', 'Photo recognition', 'Identify ingredients from photos'),
      ('📅', 'Weekly meal plans', 'Personalized plans just for you'),
      ('🚫', 'No ads', 'Clean cooking experience'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
      ),
      child: Column(
        children: features.map((f) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(f.$1, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.$2, style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                    Text(f.$3, style: AppTextStyles.caption),
                  ],
                ),
              ),
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildPackageTile(Package package, bool busy) {
    final isSelected = _selectedPackage?.identifier == package.identifier;
    final isPopular = package.packageType == PackageType.annual;

    String title;
    switch (package.packageType) {
      case PackageType.monthly: title = 'Monthly'; break;
      case PackageType.annual: title = 'Yearly'; break;
      default: title = package.identifier;
    }

    return GestureDetector(
      onTap: busy ? null : () => setState(() => _selectedPackage = package),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(
            color: AppColors.primary.withOpacity(0.15), blurRadius: 8,
            offset: const Offset(0, 2),
          )] : [],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border, width: 2),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  if (isPopular) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('BEST VALUE',
                        style: TextStyle(color: Colors.white, fontSize: 10,
                          fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              package.storeProduct.priceString,
              style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 16,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(bool busy) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (busy || _selectedPackage == null) ? null : () => _purchase(_selectedPackage!),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _purchasing
            ? const SizedBox(width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Text(
                _selectedPackage != null
                    ? 'Continue · ${_selectedPackage!.storeProduct.priceString}'
                    : 'Continue',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
