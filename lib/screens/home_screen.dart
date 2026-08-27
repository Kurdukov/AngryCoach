import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/coach_intensity.dart';
import '../models/coach_reaction.dart';
import '../models/daily_result.dart';
import '../models/habit.dart';
import '../models/trust_stage.dart';
import '../state/habit_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/theme_controller.dart';
import '../widgets/angry_avatar.dart';
import '../widgets/inline_stat_row.dart';
import 'focus_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openFocus(BuildContext context, {bool failureIntent = false}) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FocusScreen(startInFailureFlow: failureIntent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HabitController>();

    if (controller.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final habit = controller.habit;
    if (habit == null) {
      return const Scaffold(
        body: Center(
          child: Text('Привычка не найдена. Тренер в замешательстве.'),
        ),
      );
    }

    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;
    final dailyResult = controller.dailyResult;
    final stats = controller.stats;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 108),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        _headlineText(controller),
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
                    const _ThemeToggle(),
                  ],
                ),
                const SizedBox(height: 18),
                _WeekStrip(results: controller.dailyHistory),
                const SizedBox(height: 18),
                _TodayPanel(
                  habit: habit,
                  dailyResult: dailyResult,
                  intensity: controller.intensity,
                  reaction: _coachReaction(controller),
                  message: _todayStatusText(controller),
                  onStart: () => _openFocus(context),
                  onFail: () => _openFocus(context, failureIntent: true),
                ),
                const SizedBox(height: 22),
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
                      accent: AppColors.accent,
                    ),
                    InlineStat(
                      icon: Icons.close_rounded,
                      value: '${stats.missedDays}',
                      label: 'провалы',
                      accent: stats.missedDays > 0 ? AppColors.danger : null,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _TrustStageRow(trustLevel: stats.trustLevel),
              ],
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 20,
              child: _BottomDock(
                onStats: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StatsScreen()),
                ),
                onAdd: () => _openFocus(context),
                onHistory: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
                onSettings: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _headlineText(HabitController controller) {
    return switch (controller.dailyResult.status) {
      DailyStatus.success => 'Зачёт принят',
      DailyStatus.fail => 'Провал записан',
      DailyStatus.pending => controller.hasCompletedHistory
          ? 'Тренер ждёт отчёт'
          : 'Первый отчёт ждёт тебя',
    };
  }

  String _todayStatusText(HabitController controller) {
    return switch (controller.dailyResult.status) {
      DailyStatus.success => 'Сегодня выполнено. Не привыкай к похвале.',
      DailyStatus.fail => 'Сегодня провалено. Тренер записал.',
      DailyStatus.pending => controller.hasCompletedHistory
          ? controller.message
          : 'История пустая. Самое время перестать обещать и нажать кнопку.',
    };
  }

  CoachReaction _coachReaction(HabitController controller) {
    return switch (controller.dailyResult.status) {
      DailyStatus.success => controller.stats.currentStreak >= 3
          ? CoachReaction.streak
          : CoachReaction.success,
      DailyStatus.fail => CoachReaction.fail,
      DailyStatus.pending => CoachReaction.idle,
    };
  }
}

class _TrustStageRow extends StatelessWidget {
  const _TrustStageRow({required this.trustLevel});

  final int trustLevel;

  @override
  Widget build(BuildContext context) {
    final stage = TrustStage.fromLevel(trustLevel);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;
    final muted = dark ? Colors.white60 : AppColors.muted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(_stageIcon(stage), color: AppColors.accent, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stage.label,
                style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                stage.summary,
                style: TextStyle(color: muted, fontWeight: FontWeight.w700, height: 1.2),
              ),
            ],
          ),
        ),
      ],
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
      height: 62,
      child: Row(
        children: days.map((day) {
          final selected = _isSameDay(day, today);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final baseBg = dark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt;
    final color = selected ? AppColors.accent : baseBg;
    final textColor = selected
        ? Colors.white
        : (dark ? Colors.white : AppColors.ink);
    final statusIcon = switch (status) {
      DailyStatus.success => Icons.check_rounded,
      DailyStatus.fail => Icons.close_rounded,
      DailyStatus.pending => null,
    };
    final statusColor = switch (status) {
      DailyStatus.success => AppColors.success,
      DailyStatus.fail => AppColors.danger,
      DailyStatus.pending => textColor,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 2),
          if (statusIcon != null)
            Icon(statusIcon, color: statusColor, size: 13)
          else
            Text(
              label,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.7),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}

class _TodayPanel extends StatelessWidget {
  const _TodayPanel({
    required this.habit,
    required this.dailyResult,
    required this.intensity,
    required this.reaction,
    required this.message,
    required this.onStart,
    required this.onFail,
  });

  final Habit habit;
  final DailyResult dailyResult;
  final CoachIntensity intensity;
  final CoachReaction reaction;
  final String message;
  final VoidCallback onStart;
  final VoidCallback onFail;

  @override
  Widget build(BuildContext context) {
    final isPending = dailyResult.status == DailyStatus.pending;
    final isSuccess = dailyResult.status == DailyStatus.success;
    final panelInk = Colors.white;
    final panelMuted = Colors.white.withValues(alpha: 0.7);

    return Container(
      constraints: const BoxConstraints(minHeight: 344),
      decoration: BoxDecoration(
        color: const Color(0xFF14161F),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: 4,
            top: 28,
            child: IgnorePointer(
              child: AngryAvatar(size: 160, intensity: intensity, reaction: reaction),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 92),
            child: Padding(
              padding: const EdgeInsets.only(right: 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_statusIcon(dailyResult.status), size: 22, color: panelInk),
                      const SizedBox(width: 8),
                      Text(
                        _statusLabel(dailyResult.status),
                        style: TextStyle(color: panelInk, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    habit.name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: panelInk,
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: panelMuted, fontWeight: FontWeight.w700, height: 1.2),
                  ),
                ],
              ),
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
        style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.ink),
      );
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.fitness_center_rounded),
            label: const Text('Отчитаться'),
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.ink),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 58,
          height: 58,
          child: Tooltip(
            message: 'Отметить провал',
            child: IconButton.filled(
              onPressed: onFail,
              icon: const Icon(Icons.close_rounded),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    return IconButton(
      onPressed: controller.toggle,
      icon: Icon(controller.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
    );
  }
}

class _BottomDock extends StatelessWidget {
  const _BottomDock({
    required this.onStats,
    required this.onAdd,
    required this.onHistory,
    required this.onSettings,
  });

  final VoidCallback onStats;
  final VoidCallback onAdd;
  final VoidCallback onHistory;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _DockIcon(icon: Icons.bar_chart_rounded, onTap: onStats),
          _DockIcon(icon: Icons.history_rounded, onTap: onHistory),
          SizedBox(
            width: 54,
            height: 54,
            child: FilledButton(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
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
    return IconButton(onPressed: onTap, icon: Icon(icon));
  }
}
