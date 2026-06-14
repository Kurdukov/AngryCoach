import 'package:flutter/material.dart';

import '../models/coach_intensity.dart';
import '../models/daily_result.dart';
import '../models/failure_reason.dart';
import '../models/habit.dart';
import '../models/stats.dart';
import '../services/coach_service.dart';
import '../theme/app_colors.dart';
import '../widgets/angry_avatar.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({
    super.key,
    required this.habit,
    required this.stats,
    required this.dailyResult,
    required this.intensity,
    required this.onComplete,
    required this.onFail,
    required this.onReminderTimeChanged,
  });

  final Habit habit;
  final Stats stats;
  final DailyResult dailyResult;
  final CoachIntensity intensity;
  final Future<void> Function() onComplete;
  final Future<void> Function(FailureReason reason) onFail;
  final Future<void> Function(String time) onReminderTimeChanged;

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  DailyStatus? _resolvedStatus;
  Stats? _resolvedStats;
  FailureReason? _failureReason;
  late String _plannedReminderTime;
  bool _choosingFailureReason = false;
  bool _submitting = false;
  bool _updatingReminder = false;

  DailyStatus get _status => _resolvedStatus ?? widget.dailyResult.status;
  Stats get _displayStats => _resolvedStats ?? widget.stats;

  @override
  void initState() {
    super.initState();
    _plannedReminderTime = widget.habit.notificationTime;
  }

  Future<void> _submit(
    DailyStatus status, {
    FailureReason? failureReason,
  }) async {
    setState(() => _submitting = true);
    if (status == DailyStatus.success) {
      await widget.onComplete();
    } else {
      await widget.onFail(failureReason ?? FailureReason.other);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _resolvedStatus = status;
      _failureReason = failureReason;
      _resolvedStats = status == DailyStatus.success
          ? CoachService.instance.applySuccess(widget.stats)
          : CoachService.instance.applyFailure(widget.stats);
      _submitting = false;
    });
  }

  Future<void> _pickTomorrowTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(_plannedReminderTime),
      helpText: 'Во сколько завтра добьём?',
      cancelText: 'Отмена',
      confirmText: 'Поставить',
    );
    if (picked == null) {
      return;
    }

    final nextTime = _formatTime(picked);
    setState(() => _updatingReminder = true);
    await widget.onReminderTimeChanged(nextTime);
    if (!mounted) {
      return;
    }
    setState(() {
      _plannedReminderTime = nextTime;
      _updatingReminder = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Завтра тренер придёт в $nextTime. Готовься.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final locked = status != DailyStatus.pending;
    final statusColor = switch (status) {
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
                        _StatusBadge(status: status),
                      ],
                    ),
                    SizedBox(height: compact ? 18 : 28),
                    Text(
                      locked ? _lockedTitle(status) : 'Ежедневный отчёт',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _CoachPanel(
                      habitName: widget.habit.name,
                      message: _coachText(status),
                      intensity: widget.intensity,
                      compact: compact,
                    ),
                    const SizedBox(height: 14),
                    _ContextGrid(
                      reminderTime: _plannedReminderTime,
                      currentStreak: _displayStats.currentStreak,
                      trustLevel: _displayStats.trustLevel,
                      bestStreak: _displayStats.bestStreak,
                    ),
                    SizedBox(height: compact ? 18 : 26),
                    if (locked) ...[
                      _ResultPanel(
                        status: status,
                        failureReason:
                            _failureReason ?? widget.dailyResult.failureReason,
                        beforeStats: widget.stats,
                        afterStats: _displayStats,
                        freshResult: _resolvedStatus != null,
                      ),
                      const SizedBox(height: 12),
                      _TomorrowPlanPanel(
                        reminderTime: _plannedReminderTime,
                        updating: _updatingReminder,
                        onPickTime: _pickTomorrowTime,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Вернуться'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ] else ...[
                      if (_choosingFailureReason) ...[
                        _FailureReasonPanel(
                          submitting: _submitting,
                          onSelect: (reason) =>
                              _submit(DailyStatus.fail, failureReason: reason),
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: _submitting
                              ? null
                              : () => setState(
                                  () => _choosingFailureReason = false,
                                ),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Назад'),
                        ),
                      ] else ...[
                        FilledButton.icon(
                          onPressed: _submitting
                              ? null
                              : () => _submit(DailyStatus.success),
                          icon: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle_rounded),
                          label: Text(_submitting ? 'Сохраняю...' : 'Выполнил'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.ink,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _submitting
                              ? null
                              : () => setState(
                                  () => _choosingFailureReason = true,
                                ),
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
      DailyStatus.success =>
        'Сегодня выполнено. Тренер морщится, но факт есть.',
      DailyStatus.fail => 'Сегодня провалено. Завтра будет новый раунд.',
      DailyStatus.pending =>
        'Докладывай честно. Тренер всё равно почувствует слабину.',
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
    final success = status == DailyStatus.success;
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: AppColors.ink,
      fontWeight: FontWeight.w900,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                success ? Icons.trending_up_rounded : Icons.warning_rounded,
                color: AppColors.ink,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Разбор дня', style: titleStyle),
                    const SizedBox(height: 5),
                    Text(
                      _coachVerdict(),
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _RecapMetric(
                  label: 'Серия',
                  value: freshResult
                      ? _changeValue(
                          beforeStats.currentStreak,
                          afterStats.currentStreak,
                        )
                      : '${afterStats.currentStreak} дн.',
                  detail: freshResult
                      ? _deltaLabel(
                          beforeStats.currentStreak,
                          afterStats.currentStreak,
                        )
                      : 'сейчас',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RecapMetric(
                  label: 'Доверие',
                  value: freshResult
                      ? _changeValue(
                          beforeStats.trustLevel,
                          afterStats.trustLevel,
                          suffix: '%',
                        )
                      : '${afterStats.trustLevel}%',
                  detail: freshResult
                      ? _deltaLabel(
                          beforeStats.trustLevel,
                          afterStats.trustLevel,
                          suffix: '%',
                        )
                      : 'сейчас',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RecapMetric(
                  label: 'Провалы',
                  value: freshResult
                      ? _changeValue(
                          beforeStats.missedDays,
                          afterStats.missedDays,
                        )
                      : '${afterStats.missedDays}',
                  detail: freshResult
                      ? _deltaLabel(
                          beforeStats.missedDays,
                          afterStats.missedDays,
                        )
                      : 'всего',
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

  String _deltaLabel(int before, int after, {String suffix = ''}) {
    final delta = after - before;
    if (delta == 0) {
      return 'без изменений';
    }
    final sign = delta > 0 ? '+' : '';
    return '$sign$delta$suffix';
  }
}

class _RecapMetric extends StatelessWidget {
  const _RecapMetric({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.ink.withValues(alpha: 0.58),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.ink.withValues(alpha: 0.62),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
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
    final timeButton = FilledButton.tonalIcon(
      onPressed: updating ? null : onPickTime,
      icon: updating
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.edit_calendar_rounded),
      label: Text(reminderTime),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        minimumSize: const Size(98, 46),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 330;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.alarm_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'План завтра',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Во сколько завтра добьём?',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!narrow) ...[const SizedBox(width: 10), timeButton],
                ],
              ),
              if (narrow) ...[
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: timeButton),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FailureReasonPanel extends StatelessWidget {
  const _FailureReasonPanel({required this.submitting, required this.onSelect});

  final bool submitting;
  final ValueChanged<FailureReason> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Почему провал?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Выбери честно. Тренер всё равно не поверит, но запишет.',
            style: TextStyle(
              color: AppColors.ink.withValues(alpha: 0.72),
              fontWeight: FontWeight.w800,
              height: 1.16,
            ),
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
                labelStyle: const TextStyle(fontWeight: FontWeight.w900),
                backgroundColor: Colors.white,
                side: BorderSide(color: AppColors.ink.withValues(alpha: 0.18)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          ),
        ],
      ),
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
    required this.intensity,
    required this.compact,
  });

  final String habitName;
  final String message;
  final CoachIntensity intensity;
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
          AngryAvatar(size: compact ? 86 : 104, intensity: intensity),
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
