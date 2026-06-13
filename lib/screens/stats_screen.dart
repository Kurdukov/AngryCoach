import 'package:flutter/material.dart';

import '../models/daily_result.dart';
import '../models/stats.dart';
import '../services/coach_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/stat_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Stats? _stats;
  List<DailyResult> _dailyHistory = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await StorageService.instance.loadStats();
    final dailyHistory = await StorageService.instance.loadDailyHistory();
    if (!mounted) {
      return;
    }
    setState(() {
      _stats = stats;
      _dailyHistory = dailyHistory;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;
    final completedDays = _dailyHistory
        .where((result) => result.status != DailyStatus.pending)
        .length;
    final successDays = _dailyHistory
        .where((result) => result.status == DailyStatus.success)
        .length;
    final successRate = completedDays == 0
        ? 0
        : ((successDays / completedDays) * 100).round();
    final lastSeven = _lastDays(7);

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
                      color: ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      CoachService.instance.trustLabel(stats.trustLevel),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                    subtitle: 'не расслабляйся, это число хрупкое',
                  ),
                  StatCard(
                    title: 'Процент выполнения',
                    value: '$successRate%',
                    subtitle: completedDays == 0
                        ? 'статистика пока смотрит в пустоту'
                        : 'из дней, где ты принял решение',
                  ),
                  StatCard(
                    title: 'Дней в журнале',
                    value: '$completedDays',
                    subtitle: 'тренер ведет учет, как налоговая',
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Последние 7 дней',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SevenDayStrip(results: lastSeven),
                ],
              ),
      ),
    );
  }

  List<DailyResult> _lastDays(int count) {
    final today = DateTime.now();
    return List.generate(count, (index) {
      final day = today.subtract(Duration(days: count - index - 1));
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
}

class _SevenDayStrip extends StatelessWidget {
  const _SevenDayStrip({required this.results});

  final List<DailyResult> results;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: results.map((result) {
        final color = switch (result.status) {
          DailyStatus.success => AppColors.lime,
          DailyStatus.fail => AppColors.pink,
          DailyStatus.pending => const Color(0xFFEDEEF2),
        };
        final icon = switch (result.status) {
          DailyStatus.success => Icons.check_rounded,
          DailyStatus.fail => Icons.close_rounded,
          DailyStatus.pending => Icons.remove_rounded,
        };
        return Expanded(
          child: Container(
            height: 54,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.ink),
            ),
            child: Icon(icon, color: AppColors.ink),
          ),
        );
      }).toList(),
    );
  }
}
