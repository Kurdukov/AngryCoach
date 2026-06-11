import 'package:flutter/material.dart';

import '../models/coach_message.dart';
import '../models/habit.dart';
import '../models/stats.dart';
import '../services/coach_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';
import '../widgets/angry_avatar.dart';
import 'focus_screen.dart';
import 'history_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Habit? _habit;
  Stats _stats = Stats.initial();
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
    if (!mounted) {
      return;
    }
    setState(() {
      _habit = habit;
      _stats = stats;
      _message = message;
      _loading = false;
    });
  }

  Future<void> _complete() async {
    final nextStats = CoachService.instance.applySuccess(_stats);
    final message = CoachService.instance.successMessage(nextStats);
    await _saveAction(nextStats, message, 'success');
  }

  Future<void> _fail() async {
    final message = CoachService.instance.failMessage(_stats);
    final nextStats = CoachService.instance.applyFailure(_stats);
    await _saveAction(nextStats, message, 'fail');
  }

  Future<void> _saveAction(Stats stats, String message, String type) async {
    await StorageService.instance.saveStats(stats);
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
    });
  }

  Future<void> _openFocus(Habit habit) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FocusScreen(
          habit: habit,
          stats: _stats,
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
                      icon: Icons.history_rounded,
                      onTap: _openHistory,
                    ),
                    const SizedBox(width: 10),
                    _ThemeToggle(),
                  ],
                ),
                const SizedBox(height: 22),
                _WeekStrip(),
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
                      trailing: Icons.radio_button_unchecked_rounded,
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
                      subtitle: _message,
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
                      onTap: _fail,
                    ),
                    _HabitCard(
                      color: AppColors.blue,
                      icon: Icons.emoji_events_rounded,
                      title: 'Лучшая серия',
                      subtitle: '${_stats.bestStreak} дней до краха',
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
}

class _WeekStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final start = today.subtract(Duration(days: today.weekday - 1));
    final days = List.generate(7, (index) => start.add(Duration(days: index)));
    const labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return SizedBox(
      height: 78,
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
          );
        },
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.label,
    required this.selected,
  });

  final String day;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.ink : AppColors.lime;
    final textColor = selected ? Colors.white : AppColors.ink;

    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
          ),
        ],
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
