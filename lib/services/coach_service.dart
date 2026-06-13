import 'dart:math';

import '../data/coach_messages.dart';
import '../models/coach_intensity.dart';
import '../models/daily_result.dart';
import '../models/stats.dart';

class CoachService {
  CoachService._();

  static final instance = CoachService._();
  final Random _random = Random();

  String successMessage(
    Stats stats, {
    CoachIntensity intensity = CoachIntensity.toxic,
  }) {
    final pool = stats.currentStreak >= 6
        ? strongStreakMessages
        : successMessages;
    return _shapeTone(_pick(pool), intensity, success: true);
  }

  String contextualSuccessMessage(
    Stats stats,
    DailyStatus? previousStatus, {
    CoachIntensity intensity = CoachIntensity.toxic,
  }) {
    if (stats.currentStreak == 1 && previousStatus == null) {
      return _shapeTone(_pick(firstSuccessMessages), intensity, success: true);
    }
    if (previousStatus == DailyStatus.fail) {
      return _shapeTone(_pick(comebackMessages), intensity, success: true);
    }
    return successMessage(stats, intensity: intensity);
  }

  String failMessage(
    Stats stats, {
    CoachIntensity intensity = CoachIntensity.toxic,
  }) {
    final message = _failMessage(stats);
    return _shapeTone(message, intensity, success: false);
  }

  String _failMessage(Stats stats) {
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

  String notificationMessage({
    CoachIntensity intensity = CoachIntensity.toxic,
  }) {
    return _shapeTone(_pick(notificationMessages), intensity, success: false);
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

  String _shapeTone(
    String message,
    CoachIntensity intensity, {
    required bool success,
  }) {
    return switch (intensity) {
      CoachIntensity.sarcastic =>
        success
            ? '$message Так держать. Да, это почти похвала.'
            : '$message Соберись, у тебя всё ещё есть шанс.',
      CoachIntensity.toxic => message,
      CoachIntensity.ruthless =>
        success
            ? '$message Завтра докажи, что это не случайный всплеск.'
            : '$message Отговорки в мусор. Завтра без спектакля.',
    };
  }
}
