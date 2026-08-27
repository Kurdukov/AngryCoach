import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/daily_result.dart';
import '../models/trust_stage.dart';
import '../services/coach_service.dart';
import '../state/habit_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../widgets/inline_stat_row.dart';
import '../widgets/month_heatmap.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HabitController>();
    final stats = controller.stats;
    final dailyHistory = controller.dailyHistory;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;

    final completedDays = dailyHistory.where((r) => r.status != DailyStatus.pending).length;
    final successDays = dailyHistory.where((r) => r.status == DailyStatus.success).length;
    final successRate = completedDays == 0 ? 0 : ((successDays / completedDays) * 100).round();
    final failDays = dailyHistory.where((r) => r.status == DailyStatus.fail).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Статистика')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _TrustPanel(
              completedDays: completedDays,
              trustLevel: stats.trustLevel,
              successRate: successRate,
              verdict: _coachVerdict(
                completedDays: completedDays,
                trustLevel: stats.trustLevel,
                successRate: successRate,
                currentStreak: stats.currentStreak,
                failDays: failDays,
              ),
            ),
            const SizedBox(height: 20),
            InlineStatRow(
              items: [
                InlineStat(
                  icon: Icons.local_fire_department_rounded,
                  value: '${stats.currentStreak}',
                  label: 'серия',
                ),
                InlineStat(
                  icon: Icons.emoji_events_rounded,
                  value: '${stats.bestStreak}',
                  label: 'рекорд',
                ),
                InlineStat(
                  icon: Icons.close_rounded,
                  value: '$failDays',
                  label: 'провалы',
                  accent: failDays > 0 ? AppColors.danger : null,
                ),
                InlineStat(
                  icon: Icons.fact_check_rounded,
                  value: '$completedDays',
                  label: 'дней учёта',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Календарь месяца',
              style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 17),
            ),
            const SizedBox(height: 12),
            MonthHeatmap(results: dailyHistory),
            const SizedBox(height: 24),
            Text(
              'Последние 7 дней',
              style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 17),
            ),
            const SizedBox(height: 12),
            _SevenDayStrip(results: _lastDays(dailyHistory, 7)),
          ],
        ),
      ),
    );
  }

  List<DailyResult> _lastDays(List<DailyResult> dailyHistory, int count) {
    final today = DateTime.now();
    return List.generate(count, (index) {
      final day = today.subtract(Duration(days: count - index - 1));
      final key = _dateKey(day);
      return dailyHistory.firstWhere(
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

  String _coachVerdict({
    required int completedDays,
    required int trustLevel,
    required int successRate,
    required int currentStreak,
    required int failDays,
  }) {
    if (completedDays == 0) {
      return 'Журнал пуст. Первый отчёт решит, кто тут хозяин.';
    }
    if (currentStreak >= 7 && trustLevel >= 70) {
      return 'Серия уже похожа на дисциплину. Не испорти красивую статистику.';
    }
    if (successRate >= 75) {
      return 'Выглядит прилично. Тренер всё равно проверит завтра.';
    }
    if (failDays >= 5 || trustLevel < 35) {
      return 'Картина тревожная. Отговорки размножаются быстрее прогресса.';
    }
    if (successRate == 0) {
      return 'Данных мало. Тренер пока смотрит молча, но недобро.';
    }
    return 'Есть движение, но расслабляться рано. Очень рано.';
  }
}

class _TrustPanel extends StatelessWidget {
  const _TrustPanel({
    required this.completedDays,
    required this.trustLevel,
    required this.successRate,
    required this.verdict,
  });

  final int completedDays;
  final int trustLevel;
  final int successRate;
  final String verdict;

  @override
  Widget build(BuildContext context) {
    final stage = TrustStage.fromLevel(trustLevel);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppRadii.lg),
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, height: 1.05),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: trustLevel / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.24),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            completedDays == 0
                ? 'Пока нет закрытых дней. Нажми отчёт, и тренер начнёт считать.'
                : 'Уровень: ${stage.label}. Выполнение: $successRate%.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.psychology_alt_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${stage.summary} $verdict',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, height: 1.14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SevenDayStrip extends StatelessWidget {
  const _SevenDayStrip({required this.results});

  final List<DailyResult> results;

  String _weekdayLabel(String dateKey) {
    const labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final parts = dateKey.split('-');
    if (parts.length != 3) {
      return '';
    }
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    return labels[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final neutral = dark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt;
    final neutralText = dark ? Colors.white : AppColors.ink;

    return Row(
      children: results.asMap().entries.map((entry) {
        final index = entry.key;
        final result = entry.value;
        final color = switch (result.status) {
          DailyStatus.success => AppColors.success,
          DailyStatus.fail => AppColors.danger,
          DailyStatus.pending => neutral,
        };
        final textColor = result.status == DailyStatus.pending ? neutralText : Colors.white;
        final icon = switch (result.status) {
          DailyStatus.success => Icons.check_rounded,
          DailyStatus.fail => Icons.close_rounded,
          DailyStatus.pending => Icons.remove_rounded,
        };
        return Expanded(
          child: Container(
            height: 54,
            margin: EdgeInsets.only(right: index == results.length - 1 ? 0 : 8),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadii.sm)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: textColor, size: 18),
                const SizedBox(height: 2),
                Text(
                  _weekdayLabel(result.dateKey),
                  style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
