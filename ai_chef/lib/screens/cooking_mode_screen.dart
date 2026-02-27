import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_chef/services/localization_service.dart';
import 'package:flutter/services.dart';
import 'package:ai_chef/constants/theme.dart';
import 'package:ai_chef/models/recipe.dart';
import 'package:ai_chef/screens/completion_screen.dart';

class CookingModeScreen extends StatefulWidget {
  final Recipe recipe;

  const CookingModeScreen({super.key, required this.recipe});

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen> {
  late Recipe _recipe;
  int _currentStepIndex = 0;
  Timer? _timer;
  int _timerTotalSeconds = 0;
  int _timerRemainingSeconds = 0;
  bool _timerPaused = false;

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  RecipeStep get _currentStep => _recipe.steps[_currentStepIndex];
  bool get _isLastStep => _currentStepIndex == _recipe.steps.length - 1;

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() {
      _timerTotalSeconds = seconds;
      _timerRemainingSeconds = seconds;
      _timerPaused = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timerPaused) return;
      if (_timerRemainingSeconds <= 0) {
        _timer?.cancel();
        HapticFeedback.heavyImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⏰ ${Provider.of<LocalizationService>(context).t('timer_done')}'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          setState(() {});
        }
        return;
      }
      setState(() => _timerRemainingSeconds--);
    });
  }

  void _toggleTimerPause() {
    setState(() => _timerPaused = !_timerPaused);
  }

  void _cancelTimer() {
    _timer?.cancel();
    setState(() {
      _timerTotalSeconds = 0;
      _timerRemainingSeconds = 0;
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _getStepEmoji(int index) {
    const emojis = ['🥘', '🍳', '🥗', '🍲', '👨‍🍳', '🍽️', '🔥', '🥄'];
    return emojis[index % emojis.length];
  }

  void _nextStep() {
    _timer?.cancel();
    setState(() {
      _timerTotalSeconds = 0;
      _timerRemainingSeconds = 0;
    });
    if (_isLastStep) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CompletionScreen(recipe: _recipe),
        ),
      );
    } else {
      setState(() => _currentStepIndex++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _recipe.steps.isEmpty
        ? 0.0
        : (_currentStepIndex + 1) / _recipe.steps.length;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${Provider.of<LocalizationService>(context).t('step')} ${_currentStepIndex + 1} ${Provider.of<LocalizationService>(context).t('of')} ${_recipe.steps.length}',
                          style: AppTextStyles.caption.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Theme.of(context).dividerColor,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        _getStepEmoji(_currentStepIndex),
                        style: const TextStyle(fontSize: 120),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).dividerColor,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        _currentStep.instruction,
                        style: AppTextStyles.title.copyWith(
                          fontSize: 20,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        maxLines: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_recipe.ingredients.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        Provider.of<LocalizationService>(context).t('ingredients_for_recipe'),
                        style: AppTextStyles.subtitle.copyWith(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _recipe.ingredients.take(8).map((ing) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).chipTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            child: Text(
                              ing,
                              style: (Theme.of(context).chipTheme.labelStyle ?? AppTextStyles.caption).copyWith(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    if (_currentStep.timerSeconds != null &&
                        _currentStep.timerSeconds! > 0) ...[
                      const SizedBox(height: 24),
                      _buildTimerSection(),
                    ],
                    if (_currentStep.tip != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).chipTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💡', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _currentStep.tip!,
                                style: AppTextStyles.body.copyWith(
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _isLastStep ? '${Provider.of<LocalizationService>(context).t('finish_cooking')} 👨‍🍳' : Provider.of<LocalizationService>(context).t('next_step'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerSection() {
    final hasActiveTimer =
        _timerTotalSeconds > 0 && _timerRemainingSeconds >= 0;
    final stepSeconds = _currentStep.timerSeconds ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.gradient2.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          if (hasActiveTimer) ...[
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: _timerTotalSeconds > 0
                          ? _timerRemainingSeconds / _timerTotalSeconds
                          : 0,
                      strokeWidth: 8,
                      backgroundColor: Theme.of(context).dividerColor,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  Text(
                    _formatTime(_timerRemainingSeconds),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _toggleTimerPause,
                  icon: Icon(_timerPaused ? Icons.play_arrow : Icons.pause),
                  label: Text(_timerPaused ? 'Resume' : 'Pause'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _cancelTimer,
                  icon: const Icon(Icons.stop),
                  label: const Text('Cancel'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ] else ...[
            const Text('⏱', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              '${_formatTime(stepSeconds)} timer',
              style: AppTextStyles.subtitle.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _startTimer(stepSeconds),
              icon: const Icon(Icons.timer),
              label: Text(Provider.of<LocalizationService>(context).t('start_timer')),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
