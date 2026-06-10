import 'package:flutter/material.dart';

import '../models/stats.dart';
import '../services/coach_service.dart';
import '../services/storage_service.dart';
import '../widgets/stat_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Stats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await StorageService.instance.loadStats();
    if (!mounted) {
      return;
    }
    setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;

    return Scaffold(
      appBar: AppBar(title: const Text('Статистика')),
      body: SafeArea(
        child: stats == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Статистика разочарований',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  StatCard(
                    title: 'Текущая серия',
                    value: '${stats.currentStreak}',
                    subtitle: 'дней без позорного отступления',
                  ),
                  StatCard(
                    title: 'Лучший результат',
                    value: '${stats.bestStreak}',
                    subtitle: 'тренер почти поверил',
                  ),
                  StatCard(
                    title: 'Всего провалов',
                    value: '${stats.missedDays}',
                    subtitle: 'архив грусти пополняется',
                  ),
                  StatCard(
                    title: 'Уровень доверия тренера',
                    value: '${stats.trustLevel}%',
                    subtitle: CoachService.instance.trustLabel(
                      stats.trustLevel,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
