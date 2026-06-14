import 'dart:math';

import '../data/coach_messages.dart';
import '../models/coach_intensity.dart';
import '../models/daily_result.dart';
import '../models/stats.dart';
import '../models/trust_stage.dart';

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
    return _shapeTone(
      _trustTone(_pick(pool), stats, success: true),
      intensity,
      success: true,
    );
  }

  String contextualSuccessMessage(
    Stats stats,
    DailyStatus? previousStatus, {
    CoachIntensity intensity = CoachIntensity.toxic,
  }) {
    if (stats.currentStreak == 1 && previousStatus == null) {
      return _shapeTone(
        _trustTone(_pick(firstSuccessMessages), stats, success: true),
        intensity,
        success: true,
      );
    }
    if (previousStatus == DailyStatus.fail) {
      return _shapeTone(
        _trustTone(_pick(comebackMessages), stats, success: true),
        intensity,
        success: true,
      );
    }
    return successMessage(stats, intensity: intensity);
  }

  String failMessage(
    Stats stats, {
    CoachIntensity intensity = CoachIntensity.toxic,
  }) {
    final message = _failMessage(stats);
    return _shapeTone(
      _trustTone(message, stats, success: false),
      intensity,
      success: false,
    );
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
    return TrustStage.fromLevel(trustLevel).label;
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

  String _trustTone(String message, Stats stats, {required bool success}) {
    final stage = TrustStage.fromLevel(stats.trustLevel);
    return success ? stage.successTone(message) : stage.failTone(message);
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
