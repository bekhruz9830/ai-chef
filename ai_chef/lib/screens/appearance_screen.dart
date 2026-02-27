import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_chef/constants/theme.dart';
import 'package:ai_chef/services/theme_service.dart';
import 'package:ai_chef/services/localization_service.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context, listen: true);
    final theme = Provider.of<ThemeService>(context, listen: true);
    final isDark = theme.isDark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(loc.t('appearance')),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: _ThemeCard(
                isSelected: !isDark,
                isDark: false,
                icon: '☀️',
                label: loc.t('light_mode'),
                onTap: () => theme.setDark(false),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ThemeCard(
                isSelected: isDark,
                isDark: true,
                icon: '🌙',
                label: loc.t('dark_mode'),
                onTap: () => theme.setDark(true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final bool isSelected;
  final bool isDark;
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.isSelected,
    required this.isDark,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final barColor = const Color(0xFFFF6B35);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: barColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Container(
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 28),
          ],
        ),
      ),
    );
  }
}
