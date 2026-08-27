import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/coach_message.dart';
import '../models/daily_result.dart';
import '../services/storage_service.dart';
import '../state/habit_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

enum _HistoryFilter { all, success, fail }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<CoachMessage>? _messages;
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final messages = await StorageService.instance.loadHistory();
    if (!mounted) {
      return;
    }
    setState(() => _messages = messages);
  }

  @override
  Widget build(BuildContext context) {
    final messages = _messages;
    final dailyHistory = context.watch<HabitController>().dailyHistory;

    return Scaffold(
      appBar: AppBar(title: const Text('Журнал')),
      body: SafeArea(
        child: messages == null
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
    final completed = dailyHistory.where((r) => r.status != DailyStatus.pending).length;
    final successes = dailyHistory.where((r) => r.status == DailyStatus.success).length;
    final fails = dailyHistory.where((r) => r.status == DailyStatus.fail).length;
    final successRate = completed == 0 ? 0 : ((successes / completed) * 100).round();
    final filtered = _filteredResults();
    final latestMessage = messages.isEmpty ? null : messages.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        if (latestMessage != null) ...[
          _LatestMessageCard(message: latestMessage),
          const SizedBox(height: 16),
        ],
        _SummaryPanel(completed: completed, successes: successes, fails: fails, successRate: successRate),
        const SizedBox(height: 18),
        _FilterBar(selected: filter, onChanged: onFilterChanged),
        const SizedBox(height: 8),
        if (dailyHistory.isEmpty)
          const _EmptyState(
            icon: Icons.edit_calendar_rounded,
            title: 'Пока пусто',
            text: 'Тренер точит карандаш и ждёт первый записанный день.',
          )
        else if (filtered.isEmpty)
          _EmptyState(
            icon: Icons.filter_alt_off_rounded,
            title: 'Ничего не найдено',
            text: switch (filter) {
              _HistoryFilter.all => 'Тут пока нечего фильтровать.',
              _HistoryFilter.success => 'Побед нет. Неловко, но поправимо.',
              _HistoryFilter.fail => 'Провалов нет. Тренер подозрительно молчит.',
            },
          )
        else
          ...List.generate(filtered.length * 2 - 1, (index) {
            if (index.isOdd) {
              return Divider(
                height: 22,
                color: ink.withValues(alpha: dark ? 0.08 : 0.06),
              );
            }
            final result = filtered[index ~/ 2];
            return _HistoryTile(result: result, message: _messageForDate(result.dateKey));
          }),
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
      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppRadii.md)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Последний наезд', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  message.text,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, height: 1.16),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadii.lg)),
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
          const SizedBox(height: 4),
          Text(
            completed == 0 ? 'журнал пока пустой' : 'выполнения по записанным дням',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _SummaryMetric(value: successes, label: 'побед'),
              const SizedBox(width: 22),
              _SummaryMetric(value: fails, label: 'провалов'),
              const SizedBox(width: 22),
              _SummaryMetric(value: completed, label: 'дней'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, height: 1),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ],
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
        ButtonSegment(value: _HistoryFilter.all, icon: Icon(Icons.list_rounded), label: Text('Все')),
        ButtonSegment(value: _HistoryFilter.success, icon: Icon(Icons.check_rounded), label: Text('Победы')),
        ButtonSegment(value: _HistoryFilter.fail, icon: Icon(Icons.close_rounded), label: Text('Провалы')),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
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
    final ink = dark ? Colors.white : AppColors.ink;
    final muted = dark ? Colors.white70 : AppColors.muted;
    final accent = switch (result.status) {
      DailyStatus.success => AppColors.success,
      DailyStatus.fail => AppColors.danger,
      DailyStatus.pending => muted,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(_statusIcon(result.status), color: accent, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDate(result.dateKey),
                      style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                  ),
                  _StatusChip(status: result.status, color: accent),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                message == null ? _fallbackText(result.status) : message!.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: muted, fontWeight: FontWeight.w700, height: 1.18),
              ),
              if (result.failureReason != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Причина: ${result.failureReason!.label}',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.color});

  final DailyStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Text(
        _statusLabel(status),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;
    final muted = dark ? Colors.white70 : AppColors.muted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Icon(icon, color: muted, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(text, style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
  final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
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
