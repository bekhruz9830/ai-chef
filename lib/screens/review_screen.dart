import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/theme.dart';

/// Telegram bot Ai Chef. Chat ID: напишите боту в Telegram, откройте getUpdates (см. ссылку в ai_chef review_screen.dart), подставьте id сюда.
const String _telegramBotToken = String.fromEnvironment('TELEGRAM_BOT_TOKEN', defaultValue: '8153689622:AAEA_xcthWDCheuwOJurQZerwVLVUzReQwY');
const String _telegramChatId = String.fromEnvironment('TELEGRAM_CHAT_ID', defaultValue: '1780136956');

const List<String> _ratingLabels = [
  'Poor',
  'Fair',
  'Good',
  'Very Good',
  'Excellent!',
];

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

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendFeedback() async {
    if (_rating == 0) {
      setState(() => _message = 'Please select a rating.');
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
        _message = 'Saved, thank you for your feedback!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rate the app'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            const Text(
              'How would you rate your experience?',
              style: AppTextStyles.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
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
                      size: 48,
                      color: selected ? AppColors.primary : AppColors.textLight,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Text(
              _rating >= 1 && _rating <= 5 ? _ratingLabels[_rating - 1] : '',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Optional comment',
                alignLabelWithHint: true,
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(
                _message!,
                style: AppTextStyles.caption.copyWith(
                  color: _message!.startsWith('Thank') ? AppColors.success : AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sending ? null : _sendFeedback,
                child: _sending
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Send feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
