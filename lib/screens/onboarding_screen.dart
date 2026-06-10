import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../widgets/angry_avatar.dart';
import '../widgets/coach_message_card.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _habitController = TextEditingController();
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void dispose() {
    _habitController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFFFFC107)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  Future<void> _start() async {
    final name = _habitController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сначала назови привычку. Я подожду. Недовольно.'),
        ),
      );
      return;
    }

    final time = _formatTime(_reminderTime);
    await StorageService.instance.saveHabit(
      Habit(name: name, notificationTime: time),
    );
    await NotificationService.instance.scheduleDailyReminder(time);

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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 28),
            Text(
              'ANGRY COACH',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 28),
            const Center(child: AngryAvatar(size: 118)),
            const SizedBox(height: 24),
            const CoachMessageCard(
              message: 'Какое обещание ты собираешься нарушить на этот раз?',
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _habitController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Название привычки',
                hintText: 'Тренировка',
                filled: true,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.notifications_active_outlined),
              label: Text('Время напоминания: ${_formatTime(_reminderTime)}'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _start,
              child: const Text('НАЧАТЬ РАЗОЧАРОВЫВАТЬ ТРЕНЕРА'),
            ),
          ],
        ),
      ),
    );
  }
}
