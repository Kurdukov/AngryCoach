import 'package:flutter/material.dart';

import '../models/coach_message.dart';
import '../models/habit.dart';
import '../models/stats.dart';
import '../services/coach_service.dart';
import '../services/storage_service.dart';
import '../widgets/angry_avatar.dart';
import '../widgets/coach_message_card.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('ANGRY COACH')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const Center(child: AngryAvatar()),
            const SizedBox(height: 18),
            CoachMessageCard(message: _message),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Привычка:',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      habit.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 18),
                    _MetricLine(
                      label: 'Текущая серия:',
                      value: '${_stats.currentStreak} дня',
                    ),
                    _MetricLine(
                      label: 'Лучший результат:',
                      value: '${_stats.bestStreak} дней 🏆',
                    ),
                    _MetricLine(
                      label: 'Напоминание:',
                      value: habit.notificationTime,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(onPressed: _complete, child: const Text('Я СДЕЛАЛ')),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _fail, child: const Text('СНОВА ПРОВАЛ')),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openStats,
                    icon: const Icon(Icons.bar_chart_rounded),
                    label: const Text('Статистика'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openHistory,
                    icon: const Icon(Icons.history_rounded),
                    label: const Text('История'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFFFFC107),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
