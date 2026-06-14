import 'package:flutter/material.dart';

import '../models/coach_message.dart';
import '../models/coach_intensity.dart';
import '../models/daily_result.dart';
import '../models/failure_reason.dart';
import '../models/habit.dart';
import '../models/stats.dart';
import '../models/trust_stage.dart';
import '../services/coach_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';
import '../widgets/angry_avatar.dart';
import '../widgets/month_heatmap.dart';
import 'focus_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Habit? _habit;
  Stats _stats = Stats.initial();
  DailyResult _dailyResult = DailyResult.none();
  List<DailyResult> _dailyHistory = const [];
  CoachIntensity _intensity = CoachIntensity.toxic;
  String _message =
      'Я честно ожидал от тебя ноль, но ты всё равно умудряешься удивлять.';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final habit = await StorageService.instance.loadHabit();
    final stats = await StorageService.instance.loadStats();
    final message = await StorageService.instance.loadLastCoachMessage();
    final dailyResult = await StorageService.instance.loadDailyResult();
    final dailyHistory = await StorageService.instance.loadDailyHistory();
    final intensity = await StorageService.instance.loadCoachIntensity();
    if (!mounted) {
      return;
    }
    setState(() {
      _habit = habit;
      _stats = stats;
      _message = message;
      _dailyResult = dailyResult;
      _dailyHistory = dailyHistory;
      _intensity = intensity;
      _loading = false;
    });
  }

  Future<void> _complete() async {
    if (_dailyResult.isDoneToday) {
      _showAlreadyDone();
      return;
    }
    final nextStats = CoachService.instance.applySuccess(_stats);
    final message = CoachService.instance.contextualSuccessMessage(
      nextStats,
      _previousCompletedStatus(),
      intensity: _intensity,
    );
    await _saveAction(nextStats, message, 'success');
  }

  Future<void> _fail(FailureReason reason) async {
    if (_dailyResult.isDoneToday) {
      _showAlreadyDone();
      return;
    }
    final message = CoachService.instance.failMessage(
      _stats,
      intensity: _intensity,
    );
    final nextStats = CoachService.instance.applyFailure(_stats);
    await _saveAction(
      nextStats,
      '$message ${reason.coachLine}',
      'fail',
      reason,
    );
  }

  Future<void> _saveAction(
    Stats stats,
    String message,
    String type, [
    FailureReason? failureReason,
  ]) async {
    final status = type == 'success' ? DailyStatus.success : DailyStatus.fail;
    await StorageService.instance.saveStats(stats);
    await StorageService.instance.saveDailyResult(
      status,
      failureReason: failureReason,
    );
    await StorageService.instance.saveLastCoachMessage(message);
    await StorageService.instance.addHistoryMessage(
      CoachMessage(text: message, date: DateTime.now(), type: type),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _stats = stats;
      _message = message;
      _dailyResult = DailyResult(
        dateKey: DailyResult.todayKey,
        status: status,
        failureReason: failureReason,
      );
      _dailyHistory = [
        DailyResult(
          dateKey: DailyResult.todayKey,
          status: status,
          failureReason: failureReason,
        ),
        ..._dailyHistory.where(
          (result) => result.dateKey != DailyResult.todayKey,
        ),
      ];
    });
  }

  void _showAlreadyDone() {
    final text = _dailyResult.status == DailyStatus.success
        ? 'Сегодня уже засчитано. Не жадничай, герой.'
        : 'Сегодня уже провалено. Дважды падать в одну яму не надо.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _openFocus(Habit habit) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FocusScreen(
          habit: habit,
          stats: _stats,
          dailyResult: _dailyResult,
          intensity: _intensity,
          onComplete: _complete,
          onFail: _fail,
          onReminderTimeChanged: _updateReminderTime,
        ),
      ),
    );
    await _load();
  }

  Future<void> _updateReminderTime(String time) async {
    final habit = _habit;
    if (habit == null) {
      return;
    }

    final nextHabit = Habit(name: habit.name, notificationTime: time);
    await StorageService.instance.updateHabit(nextHabit);
    await NotificationService.instance.scheduleDailyReminder(
      nextHabit.notificationTime,
      habitName: nextHabit.name,
      intensity: _intensity,
    );
    if (!mounted) {
      return;
    }
    setState(() => _habit = nextHabit);
  }

  Future<void> _openStats() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const StatsScreen()));
    await _load();
  }

  Future<void> _openHistory() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
    await _load();
  }

  Future<void> _openSettings(Habit habit) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => SettingsScreen(habit: habit)));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final habit = _habit;
    if (habit == null) {
      return const Scaffold(
        body: Center(
          child: Text('Привычка не найдена. Тренер в замешательстве.'),
        ),
      );
    }

    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 110),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        _headlineText(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: ink,
                              fontWeight: FontWeight.w900,
                              height: 0.95,
                            ),
                      ),
                    ),
                    _ThemeToggle(),
                  ],
                ),
                const SizedBox(height: 18),
                _WeekStrip(results: _dailyHistory),
                const SizedBox(height: 16),
                _TodayPanel(
                  habit: habit,
                  dailyResult: _dailyResult,
                  intensity: _intensity,
                  message: _todayStatusText(),
                  onStart: () => _openFocus(habit),
                  onFail: () => _openFocus(habit),
                ),
                const SizedBox(height: 14),
                _MetricStrip(
                  currentStreak: _stats.currentStreak,
                  trustLevel: _stats.trustLevel,
                  missedDays: _stats.missedDays,
                ),
                const SizedBox(height: 14),
                _TrustStagePanel(trustLevel: _stats.trustLevel),
                const SizedBox(height: 14),
                MonthHeatmap(results: _dailyHistory),
              ],
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 20,
              child: _BottomDock(
                onStats: _openStats,
                onAdd: () => _openFocus(habit),
                onCoach: _openHistory,
                onSettings: () => _openSettings(habit),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _headlineText() {
    return switch (_dailyResult.status) {
      DailyStatus.success => 'Зачёт принят',
      DailyStatus.fail => 'Провал записан',
      DailyStatus.pending =>
        _hasCompletedHistory ? 'Тренер ждёт отчёт' : 'Первый отчёт ждёт тебя',
    };
  }

  String _todayStatusText() {
    return switch (_dailyResult.status) {
      DailyStatus.success => 'Сегодня выполнено. Не привыкай к похвале.',
      DailyStatus.fail => 'Сегодня провалено. Тренер записал.',
      DailyStatus.pending =>
        _hasCompletedHistory
            ? _message
            : 'История пустая. Самое время перестать обещать и нажать кнопку.',
    };
  }

  bool get _hasCompletedHistory {
    return _dailyHistory.any((result) => result.status != DailyStatus.pending);
  }

  DailyStatus? _previousCompletedStatus() {
    for (final result in _dailyHistory) {
      if (result.dateKey == DailyResult.todayKey) {
        continue;
      }
      if (result.status != DailyStatus.pending) {
        return result.status;
      }
    }
    return null;
  }
}

class _TrustStagePanel extends StatelessWidget {
  const _TrustStagePanel({required this.trustLevel});

  final int trustLevel;

  @override
  Widget build(BuildContext context) {
    final stage = TrustStage.fromLevel(trustLevel);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? Colors.white : AppColors.ink;
    final muted = dark ? Colors.white70 : AppColors.muted;
    final tileColor = dark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.86);
    final border = dark
        ? AppColors.darkStroke
        : Colors.white.withValues(alpha: 0.92);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.0 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _stageColor(stage).withValues(alpha: dark ? 0.18 : 0.28),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_stageIcon(stage), color: textColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stage.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$trustLevel%',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  IconData _stageIcon(TrustStage stage) {
    return switch (stage) {
      TrustStage.noTrust => Icons.visibility_off_rounded,
      TrustStage.trial => Icons.gpp_maybe_rounded,
      TrustStage.almostHuman => Icons.psychology_rounded,
      TrustStage.suspiciouslyDisciplined => Icons.diamond_rounded,
    };
  }

  Color _stageColor(TrustStage stage) {
    return switch (stage) {
      TrustStage.noTrust => AppColors.pink,
      TrustStage.trial => AppColors.yellow,
      TrustStage.almostHuman => AppColors.blue,
      TrustStage.suspiciouslyDisciplined => AppColors.green,
    };
  }
}

IconData _statusIcon(DailyStatus status) {
  return switch (status) {
    DailyStatus.success => Icons.check_circle_rounded,
    DailyStatus.fail => Icons.cancel_rounded,
    DailyStatus.pending => Icons.radio_button_unchecked_rounded,
  };
}

String _statusLabel(DailyStatus status) {
  return switch (status) {
    DailyStatus.success => 'выполнено',
    DailyStatus.fail => 'провалено',
    DailyStatus.pending => 'ждёт отчёта',
  };
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.results});

  final List<DailyResult> results;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final start = today.subtract(const Duration(days: 3));
    final days = List.generate(7, (index) => start.add(Duration(days: index)));
    const labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return SizedBox(
      height: 84,
      child: Row(
        children: days.map((day) {
          final selected = _isSameDay(day, today);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _DayChip(
                day: day.day.toString(),
                label: labels[day.weekday - 1],
                selected: selected,
                status: _statusFor(day),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _isSameDay(DateTime day, DateTime anotherDay) {
    return day.day == anotherDay.day &&
        day.month == anotherDay.month &&
        day.year == anotherDay.year;
  }

  DailyStatus _statusFor(DateTime day) {
    final key =
        '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    return results
        .firstWhere(
          (result) => result.dateKey == key,
          orElse: () => DailyResult(dateKey: key, status: DailyStatus.pending),
        )
        .status;
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.label,
    required this.selected,
    required this.status,
  });

  final String day;
  final String label;
  final bool selected;
  final DailyStatus status;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.lime;
    final textColor = selected ? Colors.white : AppColors.ink;
    final statusIcon = switch (status) {
      DailyStatus.success => Icons.check_rounded,
      DailyStatus.fail => Icons.close_rounded,
      DailyStatus.pending => null,
    };

    return SizedBox(
      height: 74,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    day,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (statusIcon != null)
              Positioned(
                right: 8,
                bottom: 7,
                child: Icon(statusIcon, color: textColor, size: 14),
              ),
          ],
        ),
      ),
    );
  }
}

class _TodayPanel extends StatelessWidget {
  const _TodayPanel({
    required this.habit,
    required this.dailyResult,
    required this.intensity,
    required this.message,
    required this.onStart,
    required this.onFail,
  });

  final Habit habit;
  final DailyResult dailyResult;
  final CoachIntensity intensity;
  final String message;
  final VoidCallback onStart;
  final VoidCallback onFail;

  @override
  Widget build(BuildContext context) {
    final isPending = dailyResult.status == DailyStatus.pending;
    final isSuccess = dailyResult.status == DailyStatus.success;
    final gradient = switch (dailyResult.status) {
      DailyStatus.success => const [
        Color(0xFF0B1220),
        Color(0xFF123B5D),
        Color(0xFFBFE5FF),
      ],
      DailyStatus.fail => const [
        Color(0xFF120B14),
        Color(0xFF452033),
        Color(0xFFFFD6E2),
      ],
      DailyStatus.pending => const [
        Color(0xFF0D1117),
        Color(0xFF1C2430),
        Color(0xFFEAF3FF),
      ],
    };
    final panelInk = Colors.white;
    final panelMuted = Colors.white.withValues(alpha: 0.72);

    return Container(
      constraints: const BoxConstraints(minHeight: 340),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
          stops: const [0.0, 0.58, 1.0],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 32,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 34,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -34,
            top: 34,
            child: IgnorePointer(
              child: AngryAvatar(size: 220, intensity: intensity),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 98),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 116),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _statusIcon(dailyResult.status),
                            size: 24,
                            color: panelInk,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _statusLabel(dailyResult.status),
                            style: TextStyle(
                              color: panelInk,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        habit.name,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: panelInk,
                              fontWeight: FontWeight.w900,
                              height: 0.95,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: panelMuted,
                          fontWeight: FontWeight.w800,
                          height: 1.16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: _TodayActions(
              isPending: isPending,
              isSuccess: isSuccess,
              onStart: onStart,
              onFail: onFail,
            ),
          ),
          Positioned(
            right: 18,
            top: 18,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayActions extends StatelessWidget {
  const _TodayActions({
    required this.isPending,
    required this.isSuccess,
    required this.onStart,
    required this.onFail,
  });

  final bool isPending;
  final bool isSuccess;
  final VoidCallback onStart;
  final VoidCallback onFail;

  @override
  Widget build(BuildContext context) {
    if (!isPending) {
      return FilledButton.icon(
        onPressed: onStart,
        icon: Icon(isSuccess ? Icons.visibility_rounded : Icons.replay_rounded),
        label: const Text('Открыть отчёт'),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.ink,
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.fitness_center_rounded),
            label: const Text('Отчитаться'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 58,
          height: 58,
          child: IconButton.filled(
            onPressed: onFail,
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({
    required this.currentStreak,
    required this.trustLevel,
    required this.missedDays,
  });

  final int currentStreak;
  final int trustLevel;
  final int missedDays;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniMetric(
            icon: Icons.local_fire_department_rounded,
            value: '$currentStreak',
            label: 'серия',
            color: AppColors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniMetric(
            icon: Icons.visibility_rounded,
            value: '$trustLevel%',
            label: 'доверие',
            color: AppColors.lime,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniMetric(
            icon: Icons.close_rounded,
            value: '$missedDays',
            label: 'провалы',
            color: AppColors.pink,
          ),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? Colors.white : AppColors.ink;
    final labelColor = dark ? Colors.white70 : AppColors.ink;
    final tileColor = dark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.82);
    final tileBorder = dark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.92);

    return Container(
      height: 92,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tileBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.0 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: labelColor, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = ThemeScope.of(context);
    return IconButton.filledTonal(
      onPressed: controller.toggle,
      icon: Icon(
        controller.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
      ),
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _BottomDock extends StatelessWidget {
  const _BottomDock({
    required this.onStats,
    required this.onAdd,
    required this.onCoach,
    required this.onSettings,
  });

  final VoidCallback onStats;
  final VoidCallback onAdd;
  final VoidCallback onCoach;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dark ? AppColors.darkStroke : AppColors.stroke,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.0 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _DockIcon(icon: Icons.bar_chart_rounded, onTap: onStats),
          _DockIcon(icon: Icons.history_rounded, onTap: onCoach),
          SizedBox(
            width: 58,
            height: 58,
            child: FilledButton(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Icon(Icons.add_rounded),
            ),
          ),
          _DockIcon(icon: Icons.settings_rounded, onTap: onSettings),
        ],
      ),
    );
  }
}

class _DockIcon extends StatelessWidget {
  const _DockIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
