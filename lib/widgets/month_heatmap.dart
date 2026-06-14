import 'package:flutter/material.dart';

import '../models/daily_result.dart';
import '../theme/app_colors.dart';

class MonthHeatmap extends StatelessWidget {
  const MonthHeatmap({super.key, required this.results});

  final List<DailyResult> results;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final leadingEmpty = firstDay.weekday - 1;
    final cells = leadingEmpty + daysInMonth;
    final totalCells = ((cells + 6) ~/ 7) * 7;
    const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dark
              ? AppColors.darkStroke
              : Colors.white.withValues(alpha: 0.92),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.0 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _monthTitle(now),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: dark ? Colors.white : AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(Icons.calendar_month_rounded, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: weekdays
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: dark ? Colors.white54 : AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            itemCount: totalCells,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 7,
              crossAxisSpacing: 7,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - leadingEmpty + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }
              final date = DateTime(now.year, now.month, dayNumber);
              return _MonthDayCell(
                day: dayNumber,
                status: _statusFor(date),
                future: date.isAfter(DateTime(now.year, now.month, now.day)),
                today: _isSameDay(date, now),
              );
            },
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _HeatmapLegend(color: AppColors.green, label: 'победа'),
              _HeatmapLegend(color: AppColors.pink, label: 'провал'),
              _HeatmapLegend(color: AppColors.yellow, label: 'пропуск'),
            ],
          ),
        ],
      ),
    );
  }

  DailyStatus _statusFor(DateTime day) {
    final key = _dateKey(day);
    return results
        .firstWhere(
          (result) => result.dateKey == key,
          orElse: () => DailyResult(dateKey: key, status: DailyStatus.pending),
        )
        .status;
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime day, DateTime anotherDay) {
    return day.day == anotherDay.day &&
        day.month == anotherDay.month &&
        day.year == anotherDay.year;
  }

  String _monthTitle(DateTime date) {
    const months = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.day,
    required this.status,
    required this.future,
    required this.today,
  });

  final int day;
  final DailyStatus status;
  final bool future;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = _background(dark);
    final borderColor = _borderColor(dark);
    final foreground = future
        ? (dark ? Colors.white38 : AppColors.muted)
        : AppColors.ink;

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: today ? 2 : 1,
        ),
      ),
      child: Center(
        child: Text(
          '$day',
          style: TextStyle(
            color: foreground,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Color _background(bool dark) {
    if (future) {
      return dark
          ? Colors.white.withValues(alpha: 0.04)
          : const Color(0xFFF3F5F9);
    }
    return switch (status) {
      DailyStatus.success => AppColors.green,
      DailyStatus.fail => AppColors.pink,
      DailyStatus.pending =>
        dark ? Colors.white.withValues(alpha: 0.08) : AppColors.yellow,
    };
  }

  Color _borderColor(bool dark) {
    if (today) {
      return AppColors.primary;
    }
    if (dark) {
      return AppColors.darkStroke;
    }
    return Colors.white.withValues(alpha: 0.0);
  }
}

class _HeatmapLegend extends StatelessWidget {
  const _HeatmapLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: dark ? Colors.white70 : AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
