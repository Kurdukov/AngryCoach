import 'package:flutter/material.dart';

import '../models/coach_message.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<CoachMessage>? _messages;

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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;

    return Scaffold(
      appBar: AppBar(title: const Text('История')),
      body: SafeArea(
        child: messages == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Архив унижений',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (messages.isEmpty)
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
                        'Пока пусто. Но мы оба знаем, что это ненадолго.',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  else
                    ...messages.map(
                      (message) => _HistoryTile(message: message),
                    ),
                ],
              ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.message});

  final CoachMessage message;

  @override
  Widget build(BuildContext context) {
    final isSuccess = message.type == 'success';
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
          _formatDate(message.date),
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '"${message.text}"',
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
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
}
