import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/coach_intensity.dart';
import '../models/coach_reaction.dart';
import '../state/habit_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/theme_controller.dart';
import '../widgets/angry_avatar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _habitController;
  late TimeOfDay _reminderTime;
  late CoachIntensity _intensity;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final controller = context.read<HabitController>();
    final habit = controller.habit!;
    _habitController = TextEditingController(text: habit.name);
    final parts = habit.notificationTime.split(':');
    _reminderTime = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 9,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
    _intensity = controller.intensity;
  }

  @override
  void dispose() {
    _habitController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _reminderTime);
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
    await context.read<HabitController>().updateHabitPlan(
      name: name,
      time: _formatTime(_reminderTime),
      intensity: _intensity,
    );

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _resetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Сбросить прогресс?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AngryAvatar(size: 88, intensity: _intensity, reaction: CoachReaction.reset),
              const SizedBox(height: 12),
              const Text(
                'Серия, провалы, доверие и история исчезнут. Тренер запомнит только твой позорный страх перед кнопкой.',
              ),
            ],
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

    if (confirmed != true || !mounted) {
      return;
    }

    await context.read<HabitController>().resetProgress();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
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
    final muted = dark ? Colors.white70 : AppColors.muted;
    final theme = context.watch<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Тренерская')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save_rounded),
          label: Text(_saving ? 'Сохраняю...' : 'Сохранить план'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 18),
          children: [
            _HabitPreview(name: _habitNamePreview, time: _formatTime(_reminderTime), intensity: _intensity),
            const SizedBox(height: 22),
            _SectionLabel('Привычка'),
            TextField(
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
            const SizedBox(height: 6),
            _SectionLabel('Расписание'),
            _SettingsRow(
              icon: Icons.schedule_rounded,
              title: 'Напоминание',
              value: _formatTime(_reminderTime),
              onTap: _pickTime,
            ),
            const Divider(height: 24),
            _SettingsRow(
              icon: theme.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              title: 'Тема',
              value: theme.isDark ? 'Тёмная' : 'Светлая',
              onTap: theme.toggle,
            ),
            const SizedBox(height: 22),
            _SectionLabel('Тон тренера'),
            SegmentedButton<CoachIntensity>(
              segments: CoachIntensity.values
                  .map((intensity) => ButtonSegment(value: intensity, label: Text(intensity.shortLabel)))
                  .toList(),
              selected: {_intensity},
              onSelectionChanged: (selection) => setState(() => _intensity = selection.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 8),
            Text(_intensity.label, style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 28),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Сброс прогресса', style: TextStyle(color: ink, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(
                        'Серия, доверие и журнал начнутся заново.',
                        style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _resetProgress,
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  child: const Text('Сбросить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        text,
        style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 15),
      ),
    );
  }
}

class _HabitPreview extends StatelessWidget {
  const _HabitPreview({required this.name, required this.time, required this.intensity});

  final String name;
  final String time;
  final CoachIntensity intensity;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;
    final muted = dark ? Colors.white70 : AppColors.muted;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: [
          AngryAvatar(size: 68, intensity: intensity),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  '$time · ${intensity.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
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
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
            ),
            Text(value, style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: muted),
          ],
        ),
      ),
    );
  }
}
