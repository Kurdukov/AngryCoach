import 'package:flutter/material.dart';

import '../models/coach_message.dart';
import '../models/daily_result.dart';
import '../models/habit.dart';
import '../models/stats.dart';
import '../services/coach_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';
import '../widgets/angry_avatar.dart';
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
    if (!mounted) {
      return;
    }
    setState(() {
      _habit = habit;
      _stats = stats;
      _message = message;
      _dailyResult = dailyResult;
      _dailyHistory = dailyHistory;
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
    );
    await _saveAction(nextStats, message, 'success');
  }

  Future<void> _fail() async {
    if (_dailyResult.isDoneToday) {
      _showAlreadyDone();
      return;
    }
    final message = CoachService.instance.failMessage(_stats);
    final nextStats = CoachService.instance.applyFailure(_stats);
    await _saveAction(nextStats, message, 'fail');
  }

  Future<void> _saveAction(Stats stats, String message, String type) async {
    final status = type == 'success' ? DailyStatus.success : DailyStatus.fail;
    await StorageService.instance.saveStats(stats);
    await StorageService.instance.saveDailyResult(status);
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
      _dailyResult = DailyResult(dateKey: DailyResult.todayKey, status: status);
      _dailyHistory = [
        DailyResult(dateKey: DailyResult.todayKey, status: status),
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
          onComplete: _complete,
          onFail: _fail,
        ),
      ),
    );
    await _load();
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Доброе утро,\nАндрей',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              color: ink,
                              fontWeight: FontWeight.w900,
                              height: 0.95,
                            ),
                      ),
                    ),
                    _RoundIcon(
                      icon: Icons.settings_rounded,
                      onTap: () => _openSettings(habit),
                    ),
                    const SizedBox(width: 10),
                    _ThemeToggle(),
                  ],
                ),
                const SizedBox(height: 22),
                _WeekStrip(results: _dailyHistory),
                const SizedBox(height: 22),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 0.92,
                  children: [
                    _HabitCard(
                      color: AppColors.yellow,
                      icon: Icons.fitness_center_rounded,
                      title: habit.name,
                      subtitle: 'Нажми и встреться с тренером',
                      trailing: _statusIcon(),
                      onTap: () => _openFocus(habit),
                    ),
                    _HabitCard(
                      color: AppColors.lime,
                      icon: Icons.psychology_alt_rounded,
                      title: 'Доверие тренера',
                      subtitle: '${_stats.trustLevel}% хрупкого уважения',
                      trailing: Icons.visibility_rounded,
                      onTap: _openStats,
                    ),
                    _HabitCard(
                      color: dark
                          ? AppColors.darkCard
                          : const Color(0xFFF0F1F4),
                      icon: Icons.chat_bubble_rounded,
                      title: 'Последний наезд',
                      subtitle: _todayStatusText(),
                      trailing: Icons.check_circle_rounded,
                      muted: true,
                      onTap: _openHistory,
                    ),
                    _HabitCard(
                      color: AppColors.pink,
                      icon: Icons.wallet_rounded,
                      title: 'Провалы',
                      subtitle: '${_stats.missedDays} отговорок в архиве',
                      trailing: Icons.radio_button_unchecked_rounded,
                      onTap: _dailyResult.isDoneToday
                          ? _showAlreadyDone
                          : _fail,
                    ),
                    _HabitCard(
                      color: AppColors.blue,
                      icon: Icons.emoji_events_rounded,
                      title: 'Лучшая серия',
                      subtitle: _weekSummary(),
                      trailing: Icons.radio_button_unchecked_rounded,
                      onTap: _openStats,
                    ),
                    _HabitCard(
                      color: dark
                          ? const Color(0xFF24252C)
                          : const Color(0xFFF4F5F7),
                      icon: Icons.bedtime_rounded,
                      title: 'Напоминание',
                      subtitle: 'Тренер орет в ${habit.notificationTime}',
                      trailing: Icons.alarm_rounded,
                      muted: true,
                      onTap: () => _openFocus(habit),
                    ),
                  ],
                ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon() {
    return switch (_dailyResult.status) {
      DailyStatus.success => Icons.check_circle_rounded,
      DailyStatus.fail => Icons.cancel_rounded,
      DailyStatus.pending => Icons.radio_button_unchecked_rounded,
    };
  }

  String _todayStatusText() {
    return switch (_dailyResult.status) {
      DailyStatus.success => 'Сегодня выполнено. Не привыкай к похвале.',
      DailyStatus.fail => 'Сегодня провалено. Тренер записал.',
      DailyStatus.pending => _message,
    };
  }

  String _weekSummary() {
    final lastSeven = _lastDays(7);
    final successCount = lastSeven
        .where((result) => result.status == DailyStatus.success)
        .length;
    final failCount = lastSeven
        .where((result) => result.status == DailyStatus.fail)
        .length;
    if (successCount == 0 && failCount == 0) {
      return '${_stats.bestStreak} дней до краха';
    }
    return '$successCount побед, $failCount провалов за неделю';
  }

  List<DailyResult> _lastDays(int count) {
    final today = DateTime.now();
    return List.generate(count, (index) {
      final day = today.subtract(Duration(days: index));
      final key = _dateKey(day);
      return _dailyHistory.firstWhere(
        (result) => result.dateKey == key,
        orElse: () => DailyResult(dateKey: key, status: DailyStatus.pending),
      );
    });
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
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

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.results});

  final List<DailyResult> results;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final start = today.subtract(Duration(days: today.weekday - 1));
    final days = List.generate(7, (index) => start.add(Duration(days: index)));
    const labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final day = days[index];
          final selected =
              day.day == today.day &&
              day.month == today.month &&
              day.year == today.year;
          return _DayChip(
            day: day.day.toString(),
            label: labels[index],
            selected: selected,
            status: _statusFor(day),
          );
        },
      ),
    );
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
    final color = selected ? AppColors.ink : AppColors.lime;
    final textColor = selected ? Colors.white : AppColors.ink;
    final statusIcon = switch (status) {
      DailyStatus.success => Icons.check_rounded,
      DailyStatus.fail => Icons.close_rounded,
      DailyStatus.pending => null,
    };

    return SizedBox(
      width: 72,
      height: 74,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
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

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    this.muted = false,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final IconData trailing;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final textColor = muted && Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : AppColors.ink;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: textColor, size: 30),
                const Spacer(),
                Icon(trailing, color: textColor, size: 28),
              ],
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.68),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onTap,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _BottomDock extends StatelessWidget {
  const _BottomDock({
    required this.onStats,
    required this.onAdd,
    required this.onCoach,
  });

  final VoidCallback onStats;
  final VoidCallback onAdd;
  final VoidCallback onCoach;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.0 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: onStats, icon: const Icon(Icons.home_rounded)),
          SizedBox(
            width: 58,
            height: 58,
            child: FilledButton(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Icon(Icons.add_rounded),
            ),
          ),
          IconButton(onPressed: onCoach, icon: const AngryAvatar(size: 36)),
        ],
      ),
    );
  }
}
