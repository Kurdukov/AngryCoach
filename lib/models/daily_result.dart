import 'dart:convert';

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

  Map<String, dynamic> toMap() {
    return {'dateKey': dateKey, 'status': status.name};
  }

  factory DailyResult.fromMap(Map<String, dynamic> map) {
    final statusName = map['status'] as String? ?? '';
    return DailyResult(
      dateKey: map['dateKey'] as String? ?? '',
      status: DailyStatus.values.firstWhere(
        (value) => value.name == statusName,
        orElse: () => DailyStatus.pending,
      ),
    );
  }

  static String listToJson(List<DailyResult> results) {
    return jsonEncode(results.map((result) => result.toMap()).toList());
  }

  static List<DailyResult> listFromJson(String encoded) {
    final decoded = jsonDecode(encoded) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(DailyResult.fromMap)
        .where((result) => result.dateKey.isNotEmpty)
        .toList();
  }
}

enum DailyStatus { pending, success, fail }
