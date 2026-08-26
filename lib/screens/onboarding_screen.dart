import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/theme_controller.dart';
import '../widgets/angry_avatar.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _habitController = TextEditingController();

  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  int _page = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _habitController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _habitController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page == 1 && _habitController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Назови привычку. Мне надо знать, за что тебя ругать.'),
        ),
      );
      return;
    }

    if (_page == 2) {
      await _start();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _back() async {
    if (_page == 0) {
      return;
    }
    await _pageController.previousPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.primary,
            secondary: AppColors.lime,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  Future<void> _start() async {
    if (_saving) {
      return;
    }

    final name = _habitController.text.trim();
    if (name.isEmpty) {
      await _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    setState(() => _saving = true);
    final time = _formatTime(_reminderTime);
    await StorageService.instance.saveHabit(
      Habit(name: name, notificationTime: time),
    );
    await NotificationService.instance.scheduleDailyReminder(
      time,
      habitName: name,
    );

    if (!mounted) {
      return;
    }

    await Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (value) => setState(() => _page = value),
        children: [
          _WelcomeStep(onNext: _next),
          _HabitStep(
            controller: _habitController,
            onNext: _next,
            onBack: _back,
          ),
          _ReminderStep(
            habitName: _habitController.text.trim(),
            reminderTime: _formatTime(_reminderTime),
            saving: _saving,
            onPickTime: _pickTime,
            onNext: _next,
            onBack: _back,
          ),
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: _ThemeButton(isOnColor: true),
              ),
              const SizedBox(height: 18),
              const _StepIndicator(current: 0, total: 3, onColor: true),
              const SizedBox(height: 26),
              Text(
                'Angry Coach',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Трекер привычек, который не делает вид, что ты молодец просто за установку приложения.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.18,
                ),
              ),
              const Spacer(),
              const _HeroCoach(),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 62,
                child: FilledButton(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.ink,
                  ),
                  child: const Text('Начать'),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Без аккаунта. Данные остаются на телефоне.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitStep extends StatelessWidget {
  const _HabitStep({
    required this.controller,
    required this.onNext,
    required this.onBack,
  });

  final TextEditingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopBar(onBack: onBack),
            const SizedBox(height: 18),
            const _StepIndicator(current: 1, total: 3),
            const SizedBox(height: 24),
            Text(
              'Выбери одну привычку',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: ink,
                fontWeight: FontWeight.w900,
                height: 0.98,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Одну. Не весь список фантазий на новую жизнь.',
              style: TextStyle(
                color: dark ? Colors.white70 : AppColors.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Название привычки',
                hintText: 'Тренировка, чтение, вода...',
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Pill(text: 'Тренировка', controller: controller),
                _Pill(text: 'Чтение', controller: controller),
                _Pill(text: 'Без сахара', controller: controller),
              ],
            ),
            const Spacer(),
            _CoachBubble(
              text: 'Начни с малого. Большие планы у тебя уже проваливались.',
              color: AppColors.yellow,
            ),
            const SizedBox(height: 18),
            FilledButton(onPressed: onNext, child: const Text('Дальше')),
          ],
        ),
      ),
    );
  }
}

class _ReminderStep extends StatelessWidget {
  const _ReminderStep({
    required this.habitName,
    required this.reminderTime,
    required this.saving,
    required this.onPickTime,
    required this.onNext,
    required this.onBack,
  });

  final String habitName;
  final String reminderTime;
  final bool saving;
  final VoidCallback onPickTime;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final habit = habitName.isEmpty ? 'Твоя привычка' : habitName;

    return Container(
      color: AppColors.lime,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(onBack: onBack, onColor: true),
              const SizedBox(height: 18),
              const _StepIndicator(current: 2, total: 3, onColor: true),
              const SizedBox(height: 22),
              Text(
                'Когда тебя пинать?',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                  height: 0.98,
                ),
              ),
              const SizedBox(height: 14),
              _TimeCard(time: reminderTime, onTap: onPickTime),
              const SizedBox(height: 16),
              _TipTile(icon: Icons.task_alt_rounded, text: habit),
              const SizedBox(height: 12),
              _TipTile(
                icon: Icons.notifications_active_rounded,
                text: 'Ежедневное напоминание в $reminderTime',
                onTap: onPickTime,
              ),
              const SizedBox(height: 12),
              const _TipTile(
                icon: Icons.psychology_alt_rounded,
                text: 'Сарказм включен. Терапия нет.',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 62,
                child: FilledButton(
                  onPressed: saving ? null : onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.ink,
                  ),
                  child: saving
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : const Text('Готово'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, this.onColor = false});

  final VoidCallback onBack;
  final bool onColor;

  @override
  Widget build(BuildContext context) {
    final color = onColor ? AppColors.ink : null;

    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          color: color,
        ),
        const Spacer(),
        _ThemeButton(isOnColor: onColor),
      ],
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton({required this.isOnColor});

  final bool isOnColor;

  @override
  Widget build(BuildContext context) {
    final controller = ThemeScope.of(context);
    final foreground = isOnColor ? AppColors.ink : null;

    return IconButton.filledTonal(
      onPressed: controller.toggle,
      icon: Icon(
        controller.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
      ),
      color: foreground,
      style: IconButton.styleFrom(
        backgroundColor: isOnColor
            ? Colors.white.withValues(alpha: 0.35)
            : null,
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.current,
    required this.total,
    this.onColor = false,
  });

  final int current;
  final int total;
  final bool onColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (index) {
        final active = index <= current;
        return Expanded(
          child: Container(
            height: 5,
            margin: EdgeInsets.only(right: index == total - 1 ? 0 : 8),
            decoration: BoxDecoration(
              color: active
                  ? (onColor ? Colors.white : AppColors.primary)
                  : (onColor
                        ? Colors.white.withValues(alpha: 0.22)
                        : AppColors.stroke),
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
          ),
        );
      }),
    );
  }
}

class _HeroCoach extends StatelessWidget {
  const _HeroCoach();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Column(
        children: [
          const AngryAvatar(size: 210),
          const SizedBox(height: 10),
          Text(
            'Одна привычка. Один отчёт в день. Никакой мотивационной ваты.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.controller});

  final String text;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: () => controller.text = text,
      label: Text(text),
      avatar: const Icon(Icons.add_rounded, size: 18),
      backgroundColor: AppColors.lime,
      side: const BorderSide(color: AppColors.ink),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      labelStyle: const TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({required this.time, required this.onTap});

  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            const Icon(Icons.alarm_rounded, color: AppColors.ink, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                time,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                ),
              ),
            ),
            const Icon(Icons.edit_rounded, color: AppColors.ink),
          ],
        ),
      ),
    );
  }
}

class _CoachBubble extends StatelessWidget {
  const _CoachBubble({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const AngryAvatar(size: 76),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipTile extends StatelessWidget {
  const _TipTile({required this.icon, required this.text, this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.14)),
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
      ),
    );
  }
}
