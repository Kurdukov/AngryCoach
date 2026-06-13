import 'package:shared_preferences/shared_preferences.dart';

import '../data/coach_messages.dart';
import '../models/coach_message.dart';
import '../models/daily_result.dart';
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
    await clearDailyResult();
  }

  Future<void> updateHabit(Habit habit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_habitNameKey, habit.name);
    await prefs.setString(_notificationTimeKey, habit.notificationTime);
  }

  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await saveStats(Stats.initial());
    await prefs.setString(_lastCoachMessageKey, neutralMessages[1]);
    await prefs.setString(_messageHistoryKey, CoachMessage.listToJson([]));
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
    final status = DailyStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => DailyStatus.pending,
    );
    if (dateKey != DailyResult.todayKey) {
      return DailyResult.none();
    }
    return DailyResult(dateKey: dateKey, status: status);
  }

  Future<void> saveDailyResult(DailyStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dailyResultDateKey, DailyResult.todayKey);
    await prefs.setString(_dailyResultStatusKey, status.name);
  }

  Future<void> clearDailyResult() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dailyResultDateKey);
    await prefs.remove(_dailyResultStatusKey);
  }
}
