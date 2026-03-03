import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:ai_chef/constants/theme.dart';
import 'package:ai_chef/services/localization_service.dart';

/// Telegram bot Ai Chef. Chat ID: напишите боту @AiChef в Telegram, затем откройте в браузере:
/// https://api.telegram.org/bot8153689622:AAEA_xcthWDCheuwOJurQZerwVLVUzReQwY/getUpdates
/// В ответе найдите "chat":{"id": 123456789} — подставьте это число ниже вместо ''.
const String _telegramBotToken = String.fromEnvironment('TELEGRAM_BOT_TOKEN', defaultValue: '8153689622:AAEA_xcthWDCheuwOJurQZerwVLVUzReQwY');
const String _telegramChatId = String.fromEnvironment('TELEGRAM_CHAT_ID', defaultValue: '1780136956');

const List<String> _ratingLabels = [
  'Poor',
  'Fair',
  'Good',
  'Very Good',
  'Excellent!',
];

const int _maxReviewLength = 500;

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _sending = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendFeedback(LocalizationService loc) async {
    if (_rating == 0) {
      setState(() {
        _message = loc.t('select_rating');
        _isSuccess = false;
      });
      return;
    }
    setState(() {
      _sending = true;
      _message = null;
    });
    final comment = _commentController.text.trim();
    final label = _ratingLabels[_rating - 1];
    final text = '⭐ AI Chef Review\nRating: $_rating — $label\n${comment.isNotEmpty ? 'Comment: $comment' : ''}';

    if (_telegramBotToken.isNotEmpty && _telegramChatId.isNotEmpty) {
      try {
        final uri = Uri.parse(
          'https://api.telegram.org/bot$_telegramBotToken/sendMessage',
        );
        await http.post(
          uri,
          body: {'chat_id': _telegramChatId, 'text': text},
        );
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _sending = false;
        _message = loc.t('feedback_saved_thanks');
        _isSuccess = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = Provider.of<LocalizationService>(context, listen: true);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? theme.cardColor : theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? AppColors.textPrimary;
    final subtitleColor = theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary;

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: Text(loc.t('review_title')),
        backgroundColor: theme.appBarTheme.backgroundColor ?? surfaceColor,
        foregroundColor: theme.appBarTheme.iconTheme?.color ?? textColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.restaurant, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              loc.t('review_question'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
              ) ?? AppTextStyles.subtitle.copyWith(color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              loc.t('review_subtitle'),
              style: theme.textTheme.bodyMedium?.copyWith(color: subtitleColor)
                  ?? AppTextStyles.caption.copyWith(color: subtitleColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Text(
              loc.t('your_rating'),
              style: theme.textTheme.labelMedium?.copyWith(
                color: subtitleColor,
                letterSpacing: 0.5,
              ) ?? AppTextStyles.caption.copyWith(color: subtitleColor),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                final selected = _rating >= star;
                return GestureDetector(
                  onTap: () => setState(() => _rating = star),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      selected ? Icons.star : Icons.star_border,
                      size: 44,
                      color: selected ? const Color(0xFFFFC107) : subtitleColor,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            if (_rating >= 1 && _rating <= 5)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_ratingLabels[_rating - 1]} 😊',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            const SizedBox(height: 28),
            Text(
              loc.t('your_review'),
              style: theme.textTheme.labelMedium?.copyWith(
                color: subtitleColor,
                letterSpacing: 0.5,
              ) ?? AppTextStyles.caption.copyWith(color: subtitleColor),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _commentController,
              maxLines: 5,
              maxLength: _maxReviewLength,
              decoration: InputDecoration(
                hintText: loc.t('review_placeholder'),
                alignLabelWithHint: true,
                filled: true,
                fillColor: isDark ? theme.dividerColor.withOpacity(0.3) : theme.inputDecorationTheme.fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                counterText: '',
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_commentController.text.length} / $_maxReviewLength',
                style: AppTextStyles.caption.copyWith(color: subtitleColor),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(
                _message!,
                style: AppTextStyles.body.copyWith(
                  color: _isSuccess ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sending ? null : () => _sendFeedback(loc),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _sending
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(loc.t('submit_review')),
                          const SizedBox(width: 8),
                          const Icon(Icons.star_outline, size: 20, color: Colors.white),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
