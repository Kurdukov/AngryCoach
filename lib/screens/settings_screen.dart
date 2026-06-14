import 'package:flutter/material.dart';

import '../models/coach_intensity.dart';
import '../models/habit.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.habit});

  final Habit habit;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _habitController;
  late TimeOfDay _reminderTime;
  CoachIntensity _intensity = CoachIntensity.toxic;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _habitController = TextEditingController(text: widget.habit.name);
    final parts = widget.habit.notificationTime.split(':');
    _reminderTime = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 9,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
    _loadIntensity();
  }

  Future<void> _loadIntensity() async {
    final intensity = await StorageService.instance.loadCoachIntensity();
    if (!mounted) {
      return;
    }
    setState(() => _intensity = intensity);
  }

  @override
  void dispose() {
    _habitController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  Future<void> _save() async {
    final name = _habitController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Привычка без названия? Смело. Но нет.')),
      );
      return;
    }

    setState(() => _saving = true);
    final habit = Habit(
      name: name,
      notificationTime: _formatTime(_reminderTime),
    );
    await StorageService.instance.updateHabit(habit);
    await StorageService.instance.saveCoachIntensity(_intensity);
    await NotificationService.instance.scheduleDailyReminder(
      habit.notificationTime,
      habitName: habit.name,
      intensity: _intensity,
    );

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  Future<void> _resetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Сбросить прогресс?'),
          content: const Text(
            'Серия, провалы, доверие и история исчезнут. Тренер запомнит только твой позорный страх перед кнопкой.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Сбросить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await StorageService.instance.resetProgress();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get _habitNamePreview {
    final name = _habitController.text.trim();
    return name.isEmpty ? 'Новая привычка' : name;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;
    final controller = ThemeScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: Text(_saving ? 'Сохраняю...' : 'Сохранить привычку'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
          children: [
            Text(
              'Привычка',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: ink,
                fontWeight: FontWeight.w900,
                height: 0.95,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Настрой цель, время пинка и жёсткость тренера.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: dark ? Colors.white70 : AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 22),
            _HabitPreview(
              name: _habitNamePreview,
              time: _formatTime(_reminderTime),
              intensity: _intensity,
            ),
            const SizedBox(height: 18),
            _SettingsSection(
              title: 'Что тренируем',
              child: TextField(
                controller: _habitController,
                onChanged: (_) => setState(() {}),
                textCapitalization: TextCapitalization.sentences,
                maxLength: 34,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  helperText: 'Коротко и конкретно, без романа в трёх томах.',
                  prefixIcon: Icon(Icons.fitness_center_rounded),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _SettingsSection(
              title: 'Режим',
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.schedule_rounded,
                    title: 'Напоминание',
                    value: _formatTime(_reminderTime),
                    onTap: _pickTime,
                  ),
                  const SizedBox(height: 10),
                  _ReminderPreview(
                    habitName: _habitNamePreview,
                    time: _formatTime(_reminderTime),
                    intensity: _intensity,
                  ),
                  const SizedBox(height: 10),
                  _SettingsTile(
                    icon: controller.isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    title: 'Тема',
                    value: controller.isDark ? 'Темная' : 'Светлая',
                    onTap: controller.toggle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SettingsSection(
              title: 'Тренер',
              child: _IntensityPanel(
                value: _intensity,
                onChanged: (value) => setState(() => _intensity = value),
              ),
            ),
            const SizedBox(height: 14),
            _DangerZone(onReset: _resetProgress),
          ],
        ),
      ),
    );
  }
}

class _HabitPreview extends StatelessWidget {
  const _HabitPreview({
    required this.name,
    required this.time,
    required this.intensity,
  });

  final String name;
  final String time;
  final CoachIntensity intensity;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF151922), Color(0xFF0C111A)]
              : const [Colors.white, Color(0xFFEAF3FF)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: dark ? AppColors.darkStroke : Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.0 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.sports_martial_arts_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$time · ${intensity.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: dark ? Colors.white70 : AppColors.muted,
                    fontWeight: FontWeight.w800,
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

class _ReminderPreview extends StatelessWidget {
  const _ReminderPreview({
    required this.habitName,
    required this.time,
    required this.intensity,
  });

  final String habitName;
  final String time;
  final CoachIntensity intensity;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;
    final body = _bodyText();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dark ? AppColors.darkStroke : AppColors.stroke,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.notifications_active_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Превью напоминания · $time',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ink, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: dark ? Colors.white70 : AppColors.muted,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _bodyText() {
    final coachLine = switch (intensity) {
      CoachIntensity.sarcastic => 'Тренер почти вежливо напоминает.',
      CoachIntensity.toxic => 'Тренер уже смотрит недобро.',
      CoachIntensity.ruthless => 'Тренер не принимает легенды про занятость.',
    };
    return '$habitName. $coachLine';
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _IntensityPanel extends StatelessWidget {
  const _IntensityPanel({required this.value, required this.onChanged});

  final CoachIntensity value;
  final ValueChanged<CoachIntensity> onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dark ? AppColors.darkStroke : AppColors.stroke,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Жёсткость тренера',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SegmentedButton<CoachIntensity>(
            segments: CoachIntensity.values
                .map(
                  (intensity) => ButtonSegment(
                    value: intensity,
                    label: Text(intensity.shortLabel),
                  ),
                )
                .toList(),
            selected: {value},
            onSelectionChanged: (selection) => onChanged(selection.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: 10),
          Text(
            value.label,
            style: TextStyle(
              color: dark ? Colors.white70 : AppColors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerZone extends StatelessWidget {
  const _DangerZone({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.pink),
      ),
      child: Row(
        children: [
          const Icon(Icons.restart_alt_rounded, color: AppColors.pink),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Сброс прогресса',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Серия, доверие и журнал начнутся заново.',
                  style: TextStyle(
                    color: dark ? Colors.white70 : AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onReset, child: const Text('Сбросить')),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;
    final muted = dark ? Colors.white70 : AppColors.muted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: dark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: dark ? AppColors.darkStroke : AppColors.stroke,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: muted),
          ],
        ),
      ),
    );
  }
}
