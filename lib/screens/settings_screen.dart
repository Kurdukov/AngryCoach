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

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;
    final controller = ThemeScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          children: [
            Text(
              'Пульт тренера',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _habitController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Привычка'),
            ),
            const SizedBox(height: 14),
            _SettingsTile(
              icon: Icons.schedule_rounded,
              title: 'Время напоминания',
              value: _formatTime(_reminderTime),
              onTap: _pickTime,
            ),
            const SizedBox(height: 14),
            _SettingsTile(
              icon: controller.isDark
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              title: 'Тема',
              value: controller.isDark ? 'Темная' : 'Светлая',
              onTap: controller.toggle,
            ),
            const SizedBox(height: 14),
            _IntensityPanel(
              value: _intensity,
              onChanged: (value) => setState(() => _intensity = value),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Сохраняю...' : 'Сохранить'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _resetProgress,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Сбросить прогресс'),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
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
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: dark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(24),
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
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
