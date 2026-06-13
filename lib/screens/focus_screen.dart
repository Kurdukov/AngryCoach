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
    final statusColor = switch (dailyResult.status) {
      DailyStatus.success => AppColors.lime,
      DailyStatus.fail => AppColors.pink,
      DailyStatus.pending => AppColors.yellow,
    };

    return Scaffold(
      backgroundColor: statusColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 760;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 42,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          color: AppColors.ink,
                        ),
                        const Spacer(),
                        _StatusBadge(status: dailyResult.status),
                      ],
                    ),
                    SizedBox(height: compact ? 18 : 28),
                    Text(
                      locked ? _lockedTitle() : 'Ежедневный отчёт',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _CoachPanel(
                      habitName: habit.name,
                      message: _coachText(),
                      compact: compact,
                    ),
                    const SizedBox(height: 14),
                    _ContextGrid(
                      reminderTime: habit.notificationTime,
                      currentStreak: stats.currentStreak,
                      trustLevel: stats.trustLevel,
                      bestStreak: stats.bestStreak,
                    ),
                    SizedBox(height: compact ? 18 : 26),
                    if (locked)
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Понятно'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          foregroundColor: Colors.white,
                        ),
                      )
                    else ...[
                      FilledButton.icon(
                        onPressed: () async {
                          await onComplete();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Выполнил'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await onFail();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        icon: const Icon(Icons.cancel_rounded),
                        label: const Text('Провалил'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: const BorderSide(
                            color: AppColors.ink,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _lockedTitle() {
    return switch (dailyResult.status) {
      DailyStatus.success => 'Зачёт принят',
      DailyStatus.fail => 'Провал записан',
      DailyStatus.pending => 'Ежедневный отчёт',
    };
  }

  String _coachText() {
    return switch (dailyResult.status) {
      DailyStatus.success =>
        'Сегодня выполнено. Тренер морщится, но факт есть.',
      DailyStatus.fail => 'Сегодня провалено. Завтра будет новый раунд.',
      DailyStatus.pending =>
        'Докладывай честно. Тренер всё равно почувствует слабину.',
    };
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final DailyStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(), color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(
            _statusText(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon() {
    return switch (status) {
      DailyStatus.success => Icons.check_rounded,
      DailyStatus.fail => Icons.close_rounded,
      DailyStatus.pending => Icons.radio_button_unchecked_rounded,
    };
  }

  String _statusText() {
    return switch (status) {
      DailyStatus.success => 'готово',
      DailyStatus.fail => 'провал',
      DailyStatus.pending => 'отчёт',
    };
  }
}

class _CoachPanel extends StatelessWidget {
  const _CoachPanel({
    required this.habitName,
    required this.message,
    required this.compact,
  });

  final String habitName;
  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AngryAvatar(size: compact ? 86 : 104),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habitName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.ink.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w800,
                    height: 1.16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextGrid extends StatelessWidget {
  const _ContextGrid({
    required this.reminderTime,
    required this.currentStreak,
    required this.trustLevel,
    required this.bestStreak,
  });

  final String reminderTime;
  final int currentStreak;
  final int trustLevel;
  final int bestStreak;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.75,
      children: [
        _ContextTile(
          icon: Icons.local_fire_department_rounded,
          label: 'Серия',
          value: '$currentStreak дн.',
        ),
        _ContextTile(
          icon: Icons.visibility_rounded,
          label: 'Доверие',
          value: '$trustLevel%',
        ),
        _ContextTile(
          icon: Icons.emoji_events_rounded,
          label: 'Рекорд',
          value: '$bestStreak дн.',
        ),
        _ContextTile(
          icon: Icons.schedule_rounded,
          label: 'Напоминание',
          value: reminderTime,
        ),
      ],
    );
  }
}

class _ContextTile extends StatelessWidget {
  const _ContextTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.ink, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.ink.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
