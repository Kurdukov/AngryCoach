import 'dart:convert';

import 'failure_reason.dart';

class DailyResult {
  const DailyResult({
    required this.dateKey,
    required this.status,
    this.failureReason,
  });

  factory DailyResult.none() {
    return const DailyResult(dateKey: '', status: DailyStatus.pending);
  }

  final String dateKey;
  final DailyStatus status;
  final FailureReason? failureReason;

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
    return {
      'dateKey': dateKey,
      'status': status.name,
      if (failureReason != null) 'failureReason': failureReason!.name,
    };
  }

  factory DailyResult.fromMap(Map<String, dynamic> map) {
    final statusName = map['status'] as String? ?? '';
    final reasonName = map['failureReason'] as String?;
    return DailyResult(
      dateKey: map['dateKey'] as String? ?? '',
      status: DailyStatus.values.firstWhere(
        (value) => value.name == statusName,
        orElse: () => DailyStatus.pending,
      ),
      failureReason: FailureReason.values.cast<FailureReason?>().firstWhere(
        (value) => value?.name == reasonName,
        orElse: () => null,
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
