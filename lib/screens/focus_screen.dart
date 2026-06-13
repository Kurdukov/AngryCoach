import 'package:flutter/material.dart';

import '../models/daily_result.dart';
import '../models/habit.dart';
import '../models/stats.dart';
import '../theme/app_colors.dart';
import '../widgets/angry_avatar.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({
    super.key,
    required this.habit,
    required this.stats,
    required this.dailyResult,
    required this.onComplete,
    required this.onFail,
  });

  final Habit habit;
  final Stats stats;
  final DailyResult dailyResult;
  final Future<void> Function() onComplete;
  final Future<void> Function() onFail;

  @override
  Widget build(BuildContext context) {
    final locked = dailyResult.isDoneToday;

    return Scaffold(
      backgroundColor: AppColors.lime,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 760;
            final avatarSize = compact ? 190.0 : 250.0;
            final sectionGap = compact ? 18.0 : 30.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 42,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          color: AppColors.ink,
                        ),
                        Expanded(
                          child: Text(
                            habit.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    SizedBox(height: sectionGap),
                    AngryAvatar(size: avatarSize),
                    SizedBox(height: compact ? 16 : 22),
                    Text(
                      '${stats.currentStreak} дн.',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'текущая серия, не испорти',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: sectionGap),
                    _Tip(
                      icon: Icons.schedule_rounded,
                      text: 'Напоминание в ${habit.notificationTime}',
                      compact: compact,
                    ),
                    const SizedBox(height: 10),
                    _Tip(
                      icon: Icons.emoji_events_rounded,
                      text: 'Лучшая серия: ${stats.bestStreak}',
                      compact: compact,
                    ),
                    const SizedBox(height: 10),
                    _Tip(
                      icon: Icons.mood_bad_rounded,
                      text: 'Доверие тренера: ${stats.trustLevel}%',
                      compact: compact,
                    ),
                    const SizedBox(height: 10),
                    _Tip(
                      icon: _statusIcon(),
                      text: _statusText(),
                      compact: compact,
                    ),
                    SizedBox(height: compact ? 18 : 22),
                    FilledButton(
                      onPressed: locked
                          ? null
                          : () async {
                              await onComplete();
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.ink,
                      ),
                      child: const Text('Готово'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: locked
                          ? null
                          : () async {
                              await onFail();
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                      child: const Text(
                        'Я провалился, тренер',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _statusIcon() {
    return switch (dailyResult.status) {
      DailyStatus.success => Icons.check_circle_rounded,
      DailyStatus.fail => Icons.cancel_rounded,
      DailyStatus.pending => Icons.radio_button_unchecked_rounded,
    };
  }

  String _statusText() {
    return switch (dailyResult.status) {
      DailyStatus.success => 'Сегодня выполнено. Да, тренер тоже удивлен.',
      DailyStatus.fail => 'Сегодня провалено. Завтра будет новый раунд.',
      DailyStatus.pending => 'Сегодня еще ждем результата.',
    };
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.icon, required this.text, required this.compact});

  final IconData icon;
  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 18,
        vertical: compact ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.ink),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
