import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
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
    final picked = await showTimePicker(context: context, initialTime: _reminderTime);
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
          _HabitStep(controller: _habitController, onNext: _next, onBack: _back),
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

class _OnboardingScaffold extends StatelessWidget {
  const _OnboardingScaffold({
    required this.step,
    required this.title,
    this.subtitle,
    this.leading,
    required this.body,
    this.footer,
  });

  final int step;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;
    final muted = dark ? Colors.white70 : AppColors.muted;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Row(
              children: [
                if (leading != null) leading! else const SizedBox(width: 48),
                const Spacer(),
                _StepIndicator(current: step, total: 3),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w900,
                      height: 0.98,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                    ),
                  ],
                  const SizedBox(height: 24),
                  body,
                ],
              ),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: footer,
            ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (index) {
        final active = index <= current;
        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Container(
            width: active ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.accent
                  : (dark ? AppColors.darkStroke : AppColors.stroke),
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
          ),
        );
      }),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;
    final muted = dark ? Colors.white70 : AppColors.muted;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 52),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _StepIndicator(current: 0, total: 3),
                  const SizedBox(height: 28),
                  Text(
                    'Angry Coach',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Трекер привычек, который не делает вид, что ты молодец просто за установку приложения.',
                    style: TextStyle(color: muted, fontWeight: FontWeight.w700, height: 1.2),
                  ),
                  const SizedBox(height: 36),
                  const Center(child: AngryAvatar(size: 200)),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: FilledButton(onPressed: onNext, child: const Text('Начать')),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Без аккаунта. Данные остаются на телефоне.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HabitStep extends StatelessWidget {
  const _HabitStep({required this.controller, required this.onNext, required this.onBack});

  final TextEditingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      step: 1,
      leading: IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded)),
      title: 'Выбери одну привычку',
      subtitle: 'Одну. Не весь список фантазий на новую жизнь.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Название привычки',
              hintText: 'Тренировка, чтение, вода...',
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Pill(text: 'Тренировка', controller: controller),
              _Pill(text: 'Чтение', controller: controller),
              _Pill(text: 'Без сахара', controller: controller),
            ],
          ),
          const SizedBox(height: 28),
          const _CoachBubble(
            text: 'Начни с малого. Большие планы у тебя уже проваливались.',
          ),
        ],
      ),
      footer: FilledButton(onPressed: onNext, child: const Text('Дальше')),
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

    return _OnboardingScaffold(
      step: 2,
      leading: IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded)),
      title: 'Когда тебя пинать?',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TimeCard(time: reminderTime, onTap: onPickTime),
          const SizedBox(height: 14),
          _TipTile(icon: Icons.task_alt_rounded, text: habit),
          const SizedBox(height: 10),
          _TipTile(
            icon: Icons.notifications_active_rounded,
            text: 'Ежедневное напоминание в $reminderTime',
            onTap: onPickTime,
          ),
          const SizedBox(height: 10),
          const _TipTile(
            icon: Icons.psychology_alt_rounded,
            text: 'Сарказм включен. Терапия нет.',
          ),
        ],
      ),
      footer: FilledButton.icon(
        onPressed: saving ? null : onNext,
        icon: saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.check_rounded),
        label: Text(saving ? 'Готовлю...' : 'Готово'),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ActionChip(
      onPressed: () => controller.text = text,
      label: Text(text),
      avatar: const Icon(Icons.add_rounded, size: 18),
      backgroundColor: dark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
      labelStyle: TextStyle(
        color: dark ? Colors.white : AppColors.ink,
        fontWeight: FontWeight.w800,
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: dark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Row(
          children: [
            Icon(Icons.alarm_rounded, color: AppColors.accent, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                time,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                ),
              ),
            ),
            Icon(Icons.edit_rounded, color: ink.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _CoachBubble extends StatelessWidget {
  const _CoachBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const AngryAvatar(size: 64),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: ink, fontWeight: FontWeight.w800, height: 1.2),
          ),
        ),
      ],
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
