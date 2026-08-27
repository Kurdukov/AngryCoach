import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/coach_intensity.dart';
import '../models/coach_reaction.dart';
import '../models/daily_result.dart';
import '../models/failure_reason.dart';
import '../models/stats.dart';
import '../state/habit_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../widgets/angry_avatar.dart';
import '../widgets/inline_stat_row.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key, this.startInFailureFlow = false});

  // UX fix: the home screen has a quick "✕" action next to the main
  // report button. It used to just open this screen exactly like the
  // primary button, which was misleading — the icon implies "mark as
  // failed" but nothing was recorded until the user tapped again. Now it
  // opens straight into the failure-reason picker instead.
  final bool startInFailureFlow;

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  late Stats _statsBeforeThisVisit;
  bool _submittedThisVisit = false;
  FailureReason? _freshFailureReason;
  bool _choosingFailureReason = false;
  bool _submitting = false;
  bool _updatingReminder = false;

  @override
  void initState() {
    super.initState();
    final controller = context.read<HabitController>();
    _statsBeforeThisVisit = controller.stats;
    if (widget.startInFailureFlow &&
        controller.dailyResult.status == DailyStatus.pending) {
      _choosingFailureReason = true;
    }
  }

  Future<void> _submitSuccess() async {
    setState(() => _submitting = true);
    await context.read<HabitController>().completeToday();
    if (!mounted) {
      return;
    }
    setState(() {
      _submittedThisVisit = true;
      _submitting = false;
    });
  }

  Future<void> _submitFailure(FailureReason reason) async {
    setState(() => _submitting = true);
    await context.read<HabitController>().failToday(reason);
    if (!mounted) {
      return;
    }
    setState(() {
      _submittedThisVisit = true;
      _freshFailureReason = reason;
      _submitting = false;
    });
  }

  Future<void> _pickTomorrowTime(String currentTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(currentTime),
      helpText: 'Во сколько завтра добьём?',
      cancelText: 'Отмена',
      confirmText: 'Поставить',
    );
    if (picked == null || !mounted) {
      return;
    }

    final nextTime = _formatTime(picked);
    final controller = context.read<HabitController>();
    setState(() => _updatingReminder = true);
    await controller.updateReminderTime(nextTime);
    if (!mounted) {
      return;
    }
    setState(() => _updatingReminder = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Завтра тренер придёт в $nextTime. Готовься.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HabitController>();
    final habit = controller.habit;
    if (habit == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final status = controller.dailyResult.status;
    final locked = status != DailyStatus.pending;
    final stats = controller.stats;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;
    final statusColor = switch (status) {
      DailyStatus.success => AppColors.success,
      DailyStatus.fail => AppColors.danger,
      DailyStatus.pending => AppColors.accent,
    };

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 760;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                        const Spacer(),
                        _StatusBadge(status: status, color: statusColor),
                      ],
                    ),
                    SizedBox(height: compact ? 12 : 20),
                    Text(
                      locked ? _lockedTitle(status) : 'Ежедневный отчёт',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w900,
                        height: 0.95,
                      ),
                    ),
                    SizedBox(height: compact ? 14 : 20),
                    _CoachPanel(
                      habitName: habit.name,
                      message: _coachText(status),
                      intensity: controller.intensity,
                      reaction: _coachReaction(status, stats),
                    ),
                    SizedBox(height: compact ? 16 : 22),
                    InlineStatRow(
                      items: [
                        InlineStat(
                          icon: Icons.local_fire_department_rounded,
                          value: '${stats.currentStreak}',
                          label: 'серия',
                        ),
                        InlineStat(
                          icon: Icons.shield_rounded,
                          value: '${stats.trustLevel}%',
                          label: 'доверие',
                        ),
                        InlineStat(
                          icon: Icons.emoji_events_rounded,
                          value: '${stats.bestStreak}',
                          label: 'рекорд',
                        ),
                        InlineStat(
                          icon: Icons.schedule_rounded,
                          value: habit.notificationTime,
                          label: 'напоминание',
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 20 : 28),
                    if (locked) ...[
                      _ResultPanel(
                        status: status,
                        failureReason:
                            _freshFailureReason ?? controller.dailyResult.failureReason,
                        beforeStats: _submittedThisVisit ? _statsBeforeThisVisit : stats,
                        afterStats: stats,
                        freshResult: _submittedThisVisit,
                      ),
                      const SizedBox(height: 14),
                      _TomorrowPlanPanel(
                        reminderTime: habit.notificationTime,
                        updating: _updatingReminder,
                        onPickTime: () => _pickTomorrowTime(habit.notificationTime),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Вернуться'),
                      ),
                    ] else ...[
                      if (_choosingFailureReason) ...[
                        _FailureReasonPanel(
                          submitting: _submitting,
                          onSelect: _submitFailure,
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _submitting
                              ? null
                              : () => setState(() => _choosingFailureReason = false),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Назад'),
                        ),
                      ] else ...[
                        FilledButton.icon(
                          onPressed: _submitting ? null : _submitSuccess,
                          icon: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_circle_rounded),
                          label: Text(_submitting ? 'Сохраняю...' : 'Выполнил'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _submitting
                              ? null
                              : () => setState(() => _choosingFailureReason = true),
                          icon: const Icon(Icons.cancel_rounded),
                          label: const Text('Провалил'),
                        ),
                      ],
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

  String _lockedTitle(DailyStatus status) {
    return switch (status) {
      DailyStatus.success => 'Зачёт принят',
      DailyStatus.fail => 'Провал записан',
      DailyStatus.pending => 'Ежедневный отчёт',
    };
  }

  String _coachText(DailyStatus status) {
    return switch (status) {
      DailyStatus.success => 'Сегодня выполнено. Тренер морщится, но факт есть.',
      DailyStatus.fail => 'Сегодня провалено. Завтра будет новый раунд.',
      DailyStatus.pending => 'Докладывай честно. Тренер всё равно почувствует слабину.',
    };
  }

  CoachReaction _coachReaction(DailyStatus status, Stats stats) {
    return switch (status) {
      DailyStatus.success =>
        stats.currentStreak >= 3 ? CoachReaction.streak : CoachReaction.success,
      DailyStatus.fail => CoachReaction.fail,
      DailyStatus.pending => CoachReaction.idle,
    };
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 9,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.status,
    required this.failureReason,
    required this.beforeStats,
    required this.afterStats,
    required this.freshResult,
  });

  final DailyStatus status;
  final FailureReason? failureReason;
  final Stats beforeStats;
  final Stats afterStats;
  final bool freshResult;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;
    final muted = dark ? Colors.white70 : AppColors.muted;
    final success = status == DailyStatus.success;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                success ? Icons.trending_up_rounded : Icons.warning_rounded,
                color: success ? AppColors.success : AppColors.danger,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Разбор дня',
                      style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _coachVerdict(),
                      style: TextStyle(color: muted, fontWeight: FontWeight.w700, height: 1.16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _RecapMetric(
                  label: 'Серия',
                  value: freshResult
                      ? _changeValue(beforeStats.currentStreak, afterStats.currentStreak)
                      : '${afterStats.currentStreak} дн.',
                ),
              ),
              Expanded(
                child: _RecapMetric(
                  label: 'Доверие',
                  value: freshResult
                      ? _changeValue(beforeStats.trustLevel, afterStats.trustLevel, suffix: '%')
                      : '${afterStats.trustLevel}%',
                ),
              ),
              Expanded(
                child: _RecapMetric(
                  label: 'Провалы',
                  value: freshResult
                      ? _changeValue(beforeStats.missedDays, afterStats.missedDays)
                      : '${afterStats.missedDays}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _coachVerdict() {
    if (status == DailyStatus.success) {
      return 'Выполнено. Серия растёт, доверие тоже. Тренер недоволен только тем, что придраться почти не к чему.';
    }
    final reason = failureReason;
    if (reason == null) {
      return 'Провал принят. Доверие просело, серия сгорела. Завтра придётся возвращать уважение.';
    }
    return '${reason.coachLine} Доверие просело, серия сгорела. Завтра без театра.';
  }

  String _changeValue(int before, int after, {String suffix = ''}) {
    if (before == after) {
      return '$after$suffix';
    }
    return '$before$suffix → $after$suffix';
  }
}

class _RecapMetric extends StatelessWidget {
  const _RecapMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;
    final muted = dark ? Colors.white60 : AppColors.muted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _TomorrowPlanPanel extends StatelessWidget {
  const _TomorrowPlanPanel({
    required this.reminderTime,
    required this.updating,
    required this.onPickTime,
  });

  final String reminderTime;
  final bool updating;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;
    final muted = dark ? Colors.white70 : AppColors.muted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Icon(Icons.alarm_rounded, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('План завтра', style: TextStyle(color: ink, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  'Во сколько завтра добьём?',
                  style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.tonalIcon(
            onPressed: updating ? null : onPickTime,
            icon: updating
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.edit_calendar_rounded),
            label: Text(reminderTime),
            style: FilledButton.styleFrom(minimumSize: const Size(98, 46)),
          ),
        ],
      ),
    );
  }
}

class _FailureReasonPanel extends StatelessWidget {
  const _FailureReasonPanel({required this.submitting, required this.onSelect});

  final bool submitting;
  final ValueChanged<FailureReason> onSelect;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;
    final muted = dark ? Colors.white70 : AppColors.muted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Почему провал?',
          style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          'Выбери честно. Тренер всё равно не поверит, но запишет.',
          style: TextStyle(color: muted, fontWeight: FontWeight.w700, height: 1.16),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FailureReason.values.map((reason) {
            return ActionChip(
              onPressed: submitting ? null : () => onSelect(reason),
              avatar: Icon(_reasonIcon(reason), size: 18),
              label: Text(reason.label),
              labelStyle: const TextStyle(fontWeight: FontWeight.w800),
              backgroundColor: dark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _reasonIcon(FailureReason reason) {
    return switch (reason) {
      FailureReason.lazy => Icons.weekend_rounded,
      FailureReason.forgot => Icons.notifications_off_rounded,
      FailureReason.noTime => Icons.schedule_rounded,
      FailureReason.slipped => Icons.warning_rounded,
      FailureReason.other => Icons.more_horiz_rounded,
    };
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});

  final DailyStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(), color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(_statusText(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
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
    required this.intensity,
    required this.reaction,
  });

  final String habitName;
  final String message;
  final CoachIntensity intensity;
  final CoachReaction reaction;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;
    final muted = dark ? Colors.white70 : AppColors.muted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AngryAvatar(size: 96, intensity: intensity, reaction: reaction),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                habitName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 19),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: muted, fontWeight: FontWeight.w700, height: 1.2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
