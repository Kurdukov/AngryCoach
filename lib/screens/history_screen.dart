import 'package:flutter/material.dart';

import '../models/coach_message.dart';
import '../models/daily_result.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

enum _HistoryFilter { all, success, fail }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<CoachMessage>? _messages;
  List<DailyResult>? _dailyHistory;
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final messages = await StorageService.instance.loadHistory();
    final dailyHistory = await StorageService.instance.loadDailyHistory();
    if (!mounted) {
      return;
    }
    setState(() {
      _messages = messages;
      _dailyHistory = dailyHistory;
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = _messages;
    final dailyHistory = _dailyHistory;

    return Scaffold(
      appBar: AppBar(title: const Text('Журнал')),
      body: SafeArea(
        child: messages == null || dailyHistory == null
            ? const Center(child: CircularProgressIndicator())
            : _HistoryContent(
                messages: messages,
                dailyHistory: dailyHistory,
                filter: _filter,
                onFilterChanged: (filter) => setState(() => _filter = filter),
              ),
      ),
    );
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({
    required this.messages,
    required this.dailyHistory,
    required this.filter,
    required this.onFilterChanged,
  });

  final List<CoachMessage> messages;
  final List<DailyResult> dailyHistory;
  final _HistoryFilter filter;
  final ValueChanged<_HistoryFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;
    final completed = dailyHistory
        .where((result) => result.status != DailyStatus.pending)
        .length;
    final successes = dailyHistory
        .where((result) => result.status == DailyStatus.success)
        .length;
    final fails = dailyHistory
        .where((result) => result.status == DailyStatus.fail)
        .length;
    final successRate = completed == 0
        ? 0
        : ((successes / completed) * 100).round();
    final filtered = _filteredResults();
    final latestMessage = messages.isEmpty ? null : messages.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Text(
          'Архив дисциплины',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: ink,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        if (latestMessage != null) ...[
          _LatestMessageCard(message: latestMessage),
          const SizedBox(height: 14),
        ],
        _SummaryPanel(
          completed: completed,
          successes: successes,
          fails: fails,
          successRate: successRate,
        ),
        const SizedBox(height: 16),
        _FilterBar(selected: filter, onChanged: onFilterChanged),
        const SizedBox(height: 16),
        if (dailyHistory.isEmpty)
          const _EmptyHistory()
        else if (filtered.isEmpty)
          _EmptyFilter(filter: filter)
        else
          ...filtered.map(
            (result) => _HistoryTile(
              result: result,
              message: _messageForDate(result.dateKey),
            ),
          ),
      ],
    );
  }

  List<DailyResult> _filteredResults() {
    return dailyHistory.where((result) {
      return switch (filter) {
        _HistoryFilter.all => result.status != DailyStatus.pending,
        _HistoryFilter.success => result.status == DailyStatus.success,
        _HistoryFilter.fail => result.status == DailyStatus.fail,
      };
    }).toList();
  }

  CoachMessage? _messageForDate(String dateKey) {
    for (final message in messages) {
      if (_dateKey(message.date) == dateKey) {
        return message;
      }
    }
    return null;
  }
}

class _LatestMessageCard extends StatelessWidget {
  const _LatestMessageCard({required this.message});

  final CoachMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.campaign_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Последний наезд',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message.text,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.16,
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

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.completed,
    required this.successes,
    required this.fails,
    required this.successRate,
  });

  final int completed;
  final int successes;
  final int fails;
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
          Text(
            completed == 0 ? '0 дней' : '$successRate%',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            completed == 0
                ? 'журнал пока пустой'
                : 'выполнения по записанным дням',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  color: AppColors.lime,
                  value: successes,
                  label: 'побед',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  color: AppColors.pink,
                  value: fails,
                  label: 'провалов',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  color: AppColors.blue,
                  value: completed,
                  label: 'дней',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.color,
    required this.value,
    required this.label,
  });

  final Color color;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
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

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final _HistoryFilter selected;
  final ValueChanged<_HistoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_HistoryFilter>(
      segments: const [
        ButtonSegment(
          value: _HistoryFilter.all,
          icon: Icon(Icons.list_rounded),
          label: Text('Все'),
        ),
        ButtonSegment(
          value: _HistoryFilter.success,
          icon: Icon(Icons.check_rounded),
          label: Text('Победы'),
        ),
        ButtonSegment(
          value: _HistoryFilter.fail,
          icon: Icon(Icons.close_rounded),
          label: Text('Провалы'),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.lime,
        selectedForegroundColor: AppColors.ink,
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.result, required this.message});

  final DailyResult result;
  final CoachMessage? message;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = _palette(result.status, dark);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 8,
              decoration: BoxDecoration(
                color: palette.accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: palette.badge,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _statusIcon(result.status),
                            color: palette.icon,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _formatDate(result.dateKey),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: palette.text,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        _StatusChip(status: result.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message == null
                          ? _fallbackText(result.status)
                          : message!.text,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.text.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w700,
                        height: 1.18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final DailyStatus status;

  @override
  Widget build(BuildContext context) {
    final isPositive = status == DailyStatus.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: isPositive ? AppColors.lime : AppColors.pink,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.ink),
      ),
      child: Text(
        _statusLabel(status),
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return _EmptyState(
      icon: Icons.edit_calendar_rounded,
      title: 'Пока пусто',
      text: 'Тренер точит карандаш и ждёт первый записанный день.',
    );
  }
}

class _EmptyFilter extends StatelessWidget {
  const _EmptyFilter({required this.filter});

  final _HistoryFilter filter;

  @override
  Widget build(BuildContext context) {
    final text = switch (filter) {
      _HistoryFilter.all => 'Тут пока нечего фильтровать.',
      _HistoryFilter.success => 'Побед нет. Неловко, но поправимо.',
      _HistoryFilter.fail => 'Провалов нет. Тренер подозрительно молчит.',
    };
    return _EmptyState(
      icon: Icons.filter_alt_off_rounded,
      title: 'Ничего не найдено',
      text: text,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? Colors.white : AppColors.ink;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : AppColors.lime,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dark ? const Color(0xFF2A2B32) : AppColors.ink,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
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

class _HistoryPalette {
  const _HistoryPalette({
    required this.background,
    required this.badge,
    required this.accent,
    required this.border,
    required this.icon,
    required this.text,
  });

  final Color background;
  final Color badge;
  final Color accent;
  final Color border;
  final Color icon;
  final Color text;
}

_HistoryPalette _palette(DailyStatus status, bool dark) {
  final card = dark ? AppColors.darkCard : Colors.white;
  final border = dark ? const Color(0xFF2A2B32) : const Color(0xFFE1E2EA);
  return switch (status) {
    DailyStatus.success => _HistoryPalette(
      background: AppColors.lime,
      badge: Colors.white.withValues(alpha: 0.56),
      accent: AppColors.green,
      border: Colors.transparent,
      icon: AppColors.ink,
      text: AppColors.ink,
    ),
    DailyStatus.fail => _HistoryPalette(
      background: AppColors.pink,
      badge: Colors.white.withValues(alpha: 0.48),
      accent: AppColors.ink,
      border: Colors.transparent,
      icon: AppColors.ink,
      text: AppColors.ink,
    ),
    DailyStatus.pending => _HistoryPalette(
      background: card,
      badge: dark ? const Color(0xFF24252C) : const Color(0xFFF0F1F4),
      accent: AppColors.muted,
      border: border,
      icon: dark ? Colors.white : AppColors.ink,
      text: dark ? Colors.white : AppColors.ink,
    ),
  };
}

IconData _statusIcon(DailyStatus status) {
  return switch (status) {
    DailyStatus.success => Icons.check_circle_rounded,
    DailyStatus.fail => Icons.cancel_rounded,
    DailyStatus.pending => Icons.radio_button_unchecked_rounded,
  };
}

String _statusLabel(DailyStatus status) {
  return switch (status) {
    DailyStatus.success => 'выполнено',
    DailyStatus.fail => 'провал',
    DailyStatus.pending => 'тишина',
  };
}

String _fallbackText(DailyStatus status) {
  return switch (status) {
    DailyStatus.success => 'Выполнено. Редкий случай, когда журналу приятно.',
    DailyStatus.fail => 'Провал. Отговорка не приложена, но мы догадываемся.',
    DailyStatus.pending => 'День без решения. Очень смелая стратегия.',
  };
}

String _formatDate(String dateKey) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final parts = dateKey.split('-');
  final date = DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
  final itemDay = DateTime(date.year, date.month, date.day);
  final difference = today.difference(itemDay).inDays;
  if (difference == 0) {
    return 'Сегодня';
  }
  if (difference == 1) {
    return 'Вчера';
  }
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
