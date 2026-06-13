class DailyResult {
  const DailyResult({required this.dateKey, required this.status});

  factory DailyResult.none() {
    return const DailyResult(dateKey: '', status: DailyStatus.pending);
  }

  final String dateKey;
  final DailyStatus status;

  bool get isDoneToday {
    return dateKey == todayKey && status != DailyStatus.pending;
  }

  static String get todayKey {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}

enum DailyStatus { pending, success, fail }
