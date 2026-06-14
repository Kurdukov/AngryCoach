import 'package:shared_preferences/shared_preferences.dart';

import '../data/coach_messages.dart';
import '../models/coach_message.dart';
import '../models/coach_intensity.dart';
import '../models/daily_result.dart';
import '../models/failure_reason.dart';
import '../models/habit.dart';
import '../models/stats.dart';

class StorageService {
  StorageService._();

  static final instance = StorageService._();

  static const _habitNameKey = 'habitName';
  static const _notificationTimeKey = 'notificationTime';
  static const _currentStreakKey = 'currentStreak';
  static const _bestStreakKey = 'bestStreak';
  static const _missedDaysKey = 'missedDays';
  static const _trustLevelKey = 'trustLevel';
  static const _messageHistoryKey = 'messageHistory';
  static const _lastCoachMessageKey = 'lastCoachMessage';
  static const _dailyResultDateKey = 'dailyResultDate';
  static const _dailyResultStatusKey = 'dailyResultStatus';
  static const _dailyResultFailureReasonKey = 'dailyResultFailureReason';
  static const _dailyHistoryKey = 'dailyHistory';
  static const _coachIntensityKey = 'coachIntensity';

  Future<Habit?> loadHabit() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_habitNameKey);
    final notificationTime = prefs.getString(_notificationTimeKey);
    if (name == null || notificationTime == null) {
      return null;
    }
    return Habit(name: name, notificationTime: notificationTime);
  }

  Future<void> saveHabit(Habit habit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_habitNameKey, habit.name);
    await prefs.setString(_notificationTimeKey, habit.notificationTime);
    await saveStats(Stats.initial());
    await prefs.setString(_lastCoachMessageKey, neutralMessages[1]);
    await prefs.setString(_messageHistoryKey, CoachMessage.listToJson([]));
    await prefs.setString(_dailyHistoryKey, DailyResult.listToJson([]));
    await clearDailyResult();
  }

  Future<void> updateHabit(Habit habit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_habitNameKey, habit.name);
    await prefs.setString(_notificationTimeKey, habit.notificationTime);
  }

  Future<CoachIntensity> loadCoachIntensity() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_coachIntensityKey);
    return CoachIntensity.values.firstWhere(
      (value) => value.name == name,
      orElse: () => CoachIntensity.toxic,
    );
  }

  Future<void> saveCoachIntensity(CoachIntensity intensity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_coachIntensityKey, intensity.name);
  }

  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await saveStats(Stats.initial());
    await prefs.setString(_lastCoachMessageKey, neutralMessages[1]);
    await prefs.setString(_messageHistoryKey, CoachMessage.listToJson([]));
    await prefs.setString(_dailyHistoryKey, DailyResult.listToJson([]));
    await clearDailyResult();
  }

  Future<Stats> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    return Stats(
      currentStreak: prefs.getInt(_currentStreakKey) ?? 0,
      bestStreak: prefs.getInt(_bestStreakKey) ?? 0,
      missedDays: prefs.getInt(_missedDaysKey) ?? 0,
      trustLevel: prefs.getInt(_trustLevelKey) ?? 50,
    );
  }

  Future<void> saveStats(Stats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentStreakKey, stats.currentStreak);
    await prefs.setInt(_bestStreakKey, stats.bestStreak);
    await prefs.setInt(_missedDaysKey, stats.missedDays);
    await prefs.setInt(_trustLevelKey, stats.trustLevel);
  }

  Future<String> loadLastCoachMessage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastCoachMessageKey) ?? neutralMessages[1];
  }

  Future<void> saveLastCoachMessage(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCoachMessageKey, message);
  }

  Future<List<CoachMessage>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_messageHistoryKey);
    if (encoded == null || encoded.isEmpty) {
      return [];
    }
    return CoachMessage.listFromJson(encoded);
  }

  Future<void> addHistoryMessage(CoachMessage message) async {
    final history = await loadHistory();
    history.insert(0, message);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_messageHistoryKey, CoachMessage.listToJson(history));
  }

  Future<DailyResult> loadDailyResult() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = prefs.getString(_dailyResultDateKey) ?? '';
    final statusName = prefs.getString(_dailyResultStatusKey) ?? '';
    final reasonName = prefs.getString(_dailyResultFailureReasonKey);
    final status = DailyStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => DailyStatus.pending,
    );
    if (dateKey != DailyResult.todayKey) {
      return DailyResult.none();
    }
    final reason = FailureReason.values.cast<FailureReason?>().firstWhere(
      (value) => value?.name == reasonName,
      orElse: () => null,
    );
    return DailyResult(dateKey: dateKey, status: status, failureReason: reason);
  }

  Future<void> saveDailyResult(
    DailyStatus status, {
    FailureReason? failureReason,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dailyResultDateKey, DailyResult.todayKey);
    await prefs.setString(_dailyResultStatusKey, status.name);
    if (failureReason == null) {
      await prefs.remove(_dailyResultFailureReasonKey);
    } else {
      await prefs.setString(_dailyResultFailureReasonKey, failureReason.name);
    }
    await _upsertDailyHistory(
      DailyResult(
        dateKey: DailyResult.todayKey,
        status: status,
        failureReason: failureReason,
      ),
    );
  }

  Future<void> clearDailyResult() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dailyResultDateKey);
    await prefs.remove(_dailyResultStatusKey);
    await prefs.remove(_dailyResultFailureReasonKey);
  }

  Future<List<DailyResult>> loadDailyHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_dailyHistoryKey);
    if (encoded == null || encoded.isEmpty) {
      return [];
    }
    return DailyResult.listFromJson(encoded);
  }

  Future<void> _upsertDailyHistory(DailyResult result) async {
    final history = await loadDailyHistory();
    final index = history.indexWhere((item) => item.dateKey == result.dateKey);
    if (index == -1) {
      history.insert(0, result);
    } else {
      history[index] = result;
    }
    history.sort((a, b) => b.dateKey.compareTo(a.dateKey));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _dailyHistoryKey,
      DailyResult.listToJson(history.take(90).toList()),
    );
  }
}
