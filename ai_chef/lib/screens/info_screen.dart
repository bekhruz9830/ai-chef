import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_chef/constants/theme.dart';
import 'package:ai_chef/services/localization_service.dart';

enum InfoType { about, privacy, terms }

class InfoScreen extends StatelessWidget {
  final InfoType type;

  const InfoScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context, listen: true);
    final title = type == InfoType.about
        ? loc.t('about_app')
        : type == InfoType.privacy
            ? loc.t('privacy')
            : loc.t('terms');
    final content = type == InfoType.about
        ? loc.t('about_description')
        : type == InfoType.privacy
            ? loc.t('privacy_content')
            : loc.t('terms_content');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (type == InfoType.about) ...[
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text('👨‍🍳', style: TextStyle(fontSize: 44)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  loc.t('about_title'),
                  style: AppTextStyles.title.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              content,
              style: AppTextStyles.body.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
