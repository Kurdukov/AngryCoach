import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../models/stats.dart';
import '../theme/app_colors.dart';
import '../widgets/angry_avatar.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({
    super.key,
    required this.habit,
    required this.stats,
    required this.onComplete,
    required this.onFail,
  });

  final Habit habit;
  final Stats stats;
  final Future<void> Function() onComplete;
  final Future<void> Function() onFail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lime,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const Spacer(),
              const AngryAvatar(size: 260),
              const SizedBox(height: 24),
              Text(
                '${stats.currentStreak} дн.',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
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
              const Spacer(),
              _Tip(
                icon: Icons.schedule_rounded,
                text: 'Напоминание в ${habit.notificationTime}',
              ),
              const SizedBox(height: 12),
              _Tip(
                icon: Icons.emoji_events_rounded,
                text: 'Лучшая серия: ${stats.bestStreak}',
              ),
              const SizedBox(height: 12),
              _Tip(
                icon: Icons.mood_bad_rounded,
                text: 'Доверие тренера: ${stats.trustLevel}%',
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () async {
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
                onPressed: () async {
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
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(24),
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
