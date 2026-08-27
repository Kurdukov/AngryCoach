import 'package:flutter/foundation.dart';

import '../models/coach_intensity.dart';
import '../models/coach_message.dart';
import '../models/daily_result.dart';
import '../models/failure_reason.dart';
import '../models/habit.dart';
import '../models/stats.dart';
import '../services/coach_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

enum DailyActionResult { applied, alreadyDone }

/// Single source of truth for the active habit's runtime state.
///
/// Screens used to each own a `_load()` that re-read [StorageService]
/// directly and a pile of `setState` calls after every navigation. This
/// controller centralizes that: it loads once, mutates in place, and
/// notifies — screens just watch it.
class HabitController extends ChangeNotifier {
  Habit? _habit;
  Stats _stats = Stats.initial();
  DailyResult _dailyResult = DailyResult.none();
  List<DailyResult> _dailyHistory = const [];
  CoachIntensity _intensity = CoachIntensity.toxic;
  String _message = '';
  bool _loading = true;

  Habit? get habit => _habit;
  Stats get stats => _stats;
  DailyResult get dailyResult => _dailyResult;
  List<DailyResult> get dailyHistory => _dailyHistory;
  CoachIntensity get intensity => _intensity;
  String get message => _message;
  bool get loading => _loading;

  bool get hasCompletedHistory {
    return _dailyHistory.any((result) => result.status != DailyStatus.pending);
  }

  Future<void> load() async {
    final habit = await StorageService.instance.loadHabit();
    final stats = await StorageService.instance.loadStats();
    final message = await StorageService.instance.loadLastCoachMessage();
    final dailyResult = await StorageService.instance.loadDailyResult();
    final dailyHistory = await StorageService.instance.loadDailyHistory();
    final intensity = await StorageService.instance.loadCoachIntensity();

    _habit = habit;
    _stats = stats;
    _message = message;
    _dailyResult = dailyResult;
    _dailyHistory = dailyHistory;
    _intensity = intensity;
    _loading = false;
    notifyListeners();
  }

  DailyStatus? get _previousCompletedStatus {
    for (final result in _dailyHistory) {
      if (result.dateKey == DailyResult.todayKey) {
        continue;
      }
      if (result.status != DailyStatus.pending) {
        return result.status;
      }
    }
    return null;
  }

  Future<DailyActionResult> completeToday() async {
    if (_dailyResult.isDoneToday) {
      return DailyActionResult.alreadyDone;
    }
    final nextStats = CoachService.instance.applySuccess(_stats);
    final message = CoachService.instance.contextualSuccessMessage(
      nextStats,
      _previousCompletedStatus,
      intensity: _intensity,
    );
    await _applyResult(DailyStatus.success, nextStats, message);
    return DailyActionResult.applied;
  }

  Future<DailyActionResult> failToday(FailureReason reason) async {
    if (_dailyResult.isDoneToday) {
      return DailyActionResult.alreadyDone;
    }
    final baseMessage = CoachService.instance.failMessage(
      _stats,
      intensity: _intensity,
    );
    final nextStats = CoachService.instance.applyFailure(_stats);
    await _applyResult(
      DailyStatus.fail,
      nextStats,
      '$baseMessage ${reason.coachLine}',
      reason,
    );
    return DailyActionResult.applied;
  }

  Future<void> _applyResult(
    DailyStatus status,
    Stats nextStats,
    String message, [
    FailureReason? failureReason,
  ]) async {
    await StorageService.instance.saveStats(nextStats);
    await StorageService.instance.saveDailyResult(
      status,
      failureReason: failureReason,
    );
    await StorageService.instance.saveLastCoachMessage(message);
    await StorageService.instance.addHistoryMessage(
      CoachMessage(
        text: message,
        date: DateTime.now(),
        type: status == DailyStatus.success ? 'success' : 'fail',
      ),
    );

    _stats = nextStats;
    _message = message;
    _dailyResult = DailyResult(
      dateKey: DailyResult.todayKey,
      status: status,
      failureReason: failureReason,
    );
    _dailyHistory = [
      _dailyResult,
      ..._dailyHistory.where(
        (result) => result.dateKey != DailyResult.todayKey,
      ),
    ];
    notifyListeners();
  }

  Future<void> updateReminderTime(String time) async {
    final habit = _habit;
    if (habit == null) {
      return;
    }
    final nextHabit = Habit(name: habit.name, notificationTime: time);
    await StorageService.instance.updateHabit(nextHabit);
    await NotificationService.instance.scheduleDailyReminder(
      nextHabit.notificationTime,
      habitName: nextHabit.name,
      intensity: _intensity,
    );
    _habit = nextHabit;
    notifyListeners();
  }

  Future<void> updateHabitPlan({
    required String name,
    required String time,
    required CoachIntensity intensity,
  }) async {
    final nextHabit = Habit(name: name, notificationTime: time);
    await StorageService.instance.updateHabit(nextHabit);
    await StorageService.instance.saveCoachIntensity(intensity);
    await NotificationService.instance.scheduleDailyReminder(
      nextHabit.notificationTime,
      habitName: nextHabit.name,
      intensity: intensity,
    );
    _habit = nextHabit;
    _intensity = intensity;
    notifyListeners();
  }

  Future<void> resetProgress() async {
    await StorageService.instance.resetProgress();
    await load();
  }
}
