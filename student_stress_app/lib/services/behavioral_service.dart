import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


/// [calculateBehavioralScore] converts the current frequency
/// (resumes / hours since first resume) into a 0-100 stress score.
class BehavioralService with WidgetsBindingObserver {
  // ─── SharedPreferences keys ───────────────────────────────────────────────
  static const String _keyUnlockCount = 'daily_unlock_count';
  static const String _keyFirstUnlockTs = 'first_unlock_timestamp';
  static const String _keyLastResetDate = 'last_reset_date';

  // ─── Scoring thresholds (resumes/hour) ───────────────────────────────────
  //  0–5  → Low     ( 0–34)
  //  6–12 → Moderate (35–64)
  // 13+   → High    (65–100)
  static const double _highThreshold = 15.0;

  int _sessionUnlockCount = 0; 
  DateTime? _firstUnlockTime;

 
  AppLifecycleState? _previousState;

  // ─── Callback called every time a resume is detected ────────────────────
  void Function(int dailyCount)? onUnlockDetected;

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Start observing app lifecycle events.
  Future<void> startListening() async {
    await _resetIfNewDay();
    WidgetsBinding.instance.addObserver(this);
    print('DEBUG: [BehavioralService] Observing app lifecycle for unlocks.');
  }

  /// Stop observing.
  void stopListening() {
    WidgetsBinding.instance.removeObserver(this);
  }

  // ─── App Lifecycle Observer ───────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // We count it as an "unlock/resume" if the app was previously inactive,
    // paused, or hidden, and has now returned to the resumed state.
    if (state == AppLifecycleState.resumed &&
        _previousState != AppLifecycleState.resumed) {
      print('DEBUG: [BehavioralService] App Resumed -> Counting as Unlock!');
      _handleAppResumed();
    }
    _previousState = state;
  }

  Future<void> _handleAppResumed() async {
    await _recordUnlock();
    final count = await getDailyUnlockCount();
    onUnlockDetected?.call(count);
  }

  /// Manually trigger an unlock recording (useful for testing).
  Future<void> recordManualUnlock() async {
    await _recordUnlock();
  }

  /// Returns the current daily unlock count from SharedPreferences.
  Future<int> getDailyUnlockCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUnlockCount) ?? 0;
  }

  /// Returns a stress score (0–100) based on unlock frequency.
  ///
  /// Formula: maps unlocks-per-hour linearly between [0, _highThreshold] → [0, 100].
  Future<int> calculateBehavioralScore() async {
    final count = await getDailyUnlockCount();
    final prefs = await SharedPreferences.getInstance();
    final firstTsMs = prefs.getInt(_keyFirstUnlockTs);

    // If no unlocks have been recorded yet, return neutral score.
    if (count == 0 || firstTsMs == null) return 0;

    final firstTime = DateTime.fromMillisecondsSinceEpoch(firstTsMs);
    final hoursElapsed = DateTime.now().difference(firstTime).inMinutes / 60.0;

    // Avoid division by zero (< 1 minute since first unlock).
    final unlocksPerHour =
        hoursElapsed < (1 / 60) ? count.toDouble() : count / hoursElapsed;

    print(
      'DEBUG: [BehavioralService] $count unlocks over '
      '${hoursElapsed.toStringAsFixed(2)} h = '
      '$unlocksPerHour unlocks/h',
    );

    // Clamp and map to 0–100.
    final score = (unlocksPerHour / _highThreshold * 100).round().clamp(0, 100);
    print('DEBUG: [BehavioralService] Behavioral score = $score');
    return score;
  }

  // ─── Internal helpers ─────────────────────────────────────────────────────

  Future<void> _recordUnlock() async {
    _sessionUnlockCount++;
    final prefs = await SharedPreferences.getInstance();

    // Persist count.
    final prev = prefs.getInt(_keyUnlockCount) ?? 0;
    await prefs.setInt(_keyUnlockCount, prev + 1);

    // Record the time of the very first unlock of the day.
    if (!prefs.containsKey(_keyFirstUnlockTs)) {
      await prefs.setInt(
          _keyFirstUnlockTs, DateTime.now().millisecondsSinceEpoch);
    }
    _firstUnlockTime ??= DateTime.now();

    print(
      'DEBUG: [BehavioralService] Daily unlock count: ${prev + 1}',
    );
  }

  Future<void> _resetIfNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey(DateTime.now());
    final lastDay = prefs.getString(_keyLastResetDate) ?? '';

    if (lastDay != today) {
      await prefs.setInt(_keyUnlockCount, 0);
      await prefs.remove(_keyFirstUnlockTs);
      await prefs.setString(_keyLastResetDate, today);
      _sessionUnlockCount = 0;
      _firstUnlockTime = null;
      print('DEBUG: [BehavioralService] Daily counters reset for $today.');
    }
  }

  static String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
