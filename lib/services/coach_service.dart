import 'dart:math';

import '../data/coach_messages.dart';
import '../models/daily_result.dart';
import '../models/stats.dart';

class CoachService {
  CoachService._();

  static final instance = CoachService._();
  final Random _random = Random();

  String successMessage(Stats stats) {
    final pool = stats.currentStreak >= 6
        ? strongStreakMessages
        : successMessages;
    return _pick(pool);
  }

  String contextualSuccessMessage(Stats stats, DailyStatus? previousStatus) {
    if (stats.currentStreak == 1 && previousStatus == null) {
      return _pick(firstSuccessMessages);
    }
    if (previousStatus == DailyStatus.fail) {
      return _pick(comebackMessages);
    }
    return successMessage(stats);
  }

  String failMessage(Stats stats) {
    if (stats.currentStreak >= 3) {
      return _pick(streakBrokenMessages);
    }
    if (stats.missedDays == 0) {
      return _pick(firstFailMessages);
    }
    if (stats.missedDays >= 5) {
      return _pick(longFailMessages);
    }
    return _pick(repeatedFailMessages);
  }

  String notificationMessage() {
    return _pick(notificationMessages);
  }

  String trustLabel(int trustLevel) {
    if (trustLevel >= 80) {
      return 'Подозрительно хорошо';
    }
    if (trustLevel >= 50) {
      return 'Пока терпимо';
    }
    if (trustLevel >= 20) {
      return 'На тонком льду';
    }
    return 'Моральное разрушение';
  }

  Stats applySuccess(Stats stats) {
    final currentStreak = stats.currentStreak + 1;
    return stats.copyWith(
      currentStreak: currentStreak,
      bestStreak: max(stats.bestStreak, currentStreak),
      trustLevel: min(100, stats.trustLevel + 5),
    );
  }

  Stats applyFailure(Stats stats) {
    return stats.copyWith(
      currentStreak: 0,
      missedDays: stats.missedDays + 1,
      trustLevel: max(0, stats.trustLevel - 10),
    );
  }

  String _pick(List<String> messages) {
    return messages[_random.nextInt(messages.length)];
  }
}
