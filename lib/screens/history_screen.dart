import 'package:flutter/material.dart';

import '../models/coach_message.dart';
import '../models/daily_result.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<CoachMessage>? _messages;
  List<DailyResult>? _dailyHistory;

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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;

    return Scaffold(
      appBar: AppBar(title: const Text('История')),
      body: SafeArea(
        child: messages == null || dailyHistory == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Журнал тренера',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (dailyHistory.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.lime,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: dark ? Colors.transparent : AppColors.ink,
                        ),
                      ),
                      child: const Text(
                        'Пока пусто. Тренер точит карандаш и ждёт первый день.',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  else
                    ...dailyHistory.map(
                      (result) => _HistoryTile(
                        result: result,
                        message: _messageForDate(messages, result.dateKey),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  CoachMessage? _messageForDate(List<CoachMessage> messages, String dateKey) {
    for (final message in messages) {
      if (_dateKey(message.date) == dateKey) {
        return message;
      }
    }
    return null;
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.result, required this.message});

  final DailyResult result;
  final CoachMessage? message;

  @override
  Widget build(BuildContext context) {
    final isSuccess = result.status == DailyStatus.success;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSuccess ? AppColors.lime : AppColors.pink,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.ink),
      ),
      child: ListTile(
        leading: Icon(
          isSuccess ? Icons.check_circle_outline : Icons.error_outline,
          color: AppColors.ink,
        ),
        title: Text(
          _formatDate(result.dateKey),
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            message == null
                ? _fallbackText(result.status)
                : '"${message!.text}"',
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
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

  String _fallbackText(DailyStatus status) {
    return switch (status) {
      DailyStatus.success => 'Выполнено. Редкий случай, когда журналу приятно.',
      DailyStatus.fail => 'Провал. Отговорка не приложена, но мы догадываемся.',
      DailyStatus.pending => 'День без решения. Очень смелая стратегия.',
    };
  }
}
