import 'package:flutter/material.dart';

import '../models/daily_result.dart';
import '../models/stats.dart';
import '../services/coach_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

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
    final failDays = _dailyHistory
        .where((result) => result.status == DailyStatus.fail)
        .length;
    final lastSeven = _lastDays(7);

    return Scaffold(
      appBar: AppBar(title: const Text('Статистика')),
      body: SafeArea(
        child: stats == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Text(
                    'Панель прогресса',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _TrustPanel(
                    trustLevel: stats.trustLevel,
                    successRate: successRate,
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.18,
                    children: [
                      _MetricCard(
                        color: AppColors.orange,
                        icon: Icons.local_fire_department_rounded,
                        title: 'Текущая серия',
                        value: '${stats.currentStreak}',
                        subtitle: 'дней подряд',
                      ),
                      _MetricCard(
                        color: AppColors.lime,
                        icon: Icons.emoji_events_rounded,
                        title: 'Рекорд',
                        value: '${stats.bestStreak}',
                        subtitle: 'лучший забег',
                      ),
                      _MetricCard(
                        color: AppColors.pink,
                        icon: Icons.close_rounded,
                        title: 'Провалы',
                        value: '$failDays',
                        subtitle: 'в журнале',
                      ),
                      _MetricCard(
                        color: AppColors.blue,
                        icon: Icons.fact_check_rounded,
                        title: 'Дней учёта',
                        value: '$completedDays',
                        subtitle: 'решений принято',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
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

class _TrustPanel extends StatelessWidget {
  const _TrustPanel({required this.trustLevel, required this.successRate});

  final int trustLevel;
  final int successRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$trustLevel%',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 0.9,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  CoachService.instance.trustLabel(trustLevel),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: trustLevel / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.24),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.lime),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Выполнение: $successRate%. Тренер делает вид, что не впечатлён.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.ink, size: 24),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.ink.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SevenDayStrip extends StatelessWidget {
  const _SevenDayStrip({required this.results});

  final List<DailyResult> results;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: results.asMap().entries.map((entry) {
        final index = entry.key;
        final result = entry.value;
        final color = switch (result.status) {
          DailyStatus.success => AppColors.lime,
          DailyStatus.fail => AppColors.pink,
          DailyStatus.pending =>
            dark ? const Color(0xFF24252C) : const Color(0xFFEDEEF2),
        };
        final icon = switch (result.status) {
          DailyStatus.success => Icons.check_rounded,
          DailyStatus.fail => Icons.close_rounded,
          DailyStatus.pending => Icons.remove_rounded,
        };
        return Expanded(
          child: Container(
            height: 54,
            margin: EdgeInsets.only(right: index == results.length - 1 ? 0 : 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: dark ? const Color(0xFF2A2B32) : AppColors.ink,
              ),
            ),
            child: Icon(
              icon,
              color: result.status == DailyStatus.pending && dark
                  ? Colors.white
                  : AppColors.ink,
            ),
          ),
        );
      }).toList(),
    );
  }
}
