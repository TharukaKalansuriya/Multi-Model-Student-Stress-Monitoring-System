import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for accumulating and managing behavioral data for 3-hour sync cycles
///
/// Stores:
/// - Phone unlocks (timestamped)
/// - Screen time (per app, timestamped)
/// - Calls (count with timestamps)
/// - Messages (count with timestamps)
/// - Late night usage (flagged periods)
/// - App usage patterns
///
/// Syncs every 3 hours with audio clip
class DataAccumulationService {
  static const String _prefixAccumulatedData = 'accumulated_behavioral_data';
  static const String _prefixLastSyncTime = 'last_sync_time';
  static const String _prefixSyncCycle = 'current_sync_cycle';
  static const Duration _syncInterval = Duration(hours: 3);

  final SharedPreferences _prefs;

  DataAccumulationService({required SharedPreferences prefs}) : _prefs = prefs {
    _initializeAccumulatedData();
  }

  /// Initialize or load accumulated data
  void _initializeAccumulatedData() {
    String? dataJson = _prefs.getString(_prefixAccumulatedData);

    if (dataJson == null) {
      _resetAccumulatedData();
    }
  }

  /// Reset accumulated data to empty state
  Future<void> _resetAccumulatedData() async {
    final initialData = {
      'unlocks': {
        'count': 0,
        'timestamps': <String>[],
        'details': <Map<String, dynamic>>[]
      },
      'screen_time': {
        'total_minutes': 0,
        'app_sessions': <Map<String, dynamic>>[],
      },
      'calls': {
        'count': 0,
        'timestamps': <String>[],
      },
      'messages': {
        'count': 0,
        'timestamps': <String>[],
      },
      'late_night_usage': {
        'detected': false,
        'periods': <Map<String, dynamic>>[],
      },
      'app_usage': <Map<String, dynamic>>[],
      'cycle_start_time': DateTime.now().toIso8601String(),
      'last_updated': DateTime.now().toIso8601String(),
    };

    await _prefs.setString(_prefixAccumulatedData, jsonEncode(initialData));
    print(
        '[DataAccumulation] Initialized new accumulation cycle at ${initialData['cycle_start_time']}');
  }

  /// Get current accumulated data
  Map<String, dynamic> getAccumulatedData() {
    String? dataJson = _prefs.getString(_prefixAccumulatedData);
    if (dataJson == null) {
      _resetAccumulatedData();
      return {};
    }

    return jsonDecode(dataJson) as Map<String, dynamic>;
  }

  /// Record an unlock event with timestamp and context
  Future<void> recordUnlock({
    String? appName = 'unknown',
    int screenOnTime = 0,
  }) async {
    try {
      final data = getAccumulatedData();
      final unlocks = data['unlocks'] as Map<String, dynamic>;

      final timestamp = DateTime.now().toIso8601String();

      (unlocks['timestamps'] as List).add(timestamp);
      (unlocks['count'] as int) + 1;

      (unlocks['details'] as List).add({
        'timestamp': timestamp,
        'app': appName,
        'screen_on_duration_seconds': screenOnTime,
      });

      data['last_updated'] = DateTime.now().toIso8601String();
      await _prefs.setString(_prefixAccumulatedData, jsonEncode(data));

      print(
          '[DataAccumulation] Unlock recorded. Total: ${unlocks['count'] + 1}');
    } catch (e) {
      print('[DataAccumulation] Error recording unlock: $e');
    }
  }

  /// Record screen time for an app session
  Future<void> recordScreenTime({
    required String appName,
    required int durationSeconds,
    String? category = 'Utility',
  }) async {
    try {
      final data = getAccumulatedData();
      final screenTime = data['screen_time'] as Map<String, dynamic>;

      (screenTime['total_minutes'] as int) + (durationSeconds ~/ 60);

      (screenTime['app_sessions'] as List).add({
        'app': appName,
        'duration_seconds': durationSeconds,
        'category': category,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Also add to app_usage for compatibility
      _addToAppUsage(data, appName, durationSeconds * 1000, category);

      data['last_updated'] = DateTime.now().toIso8601String();
      await _prefs.setString(_prefixAccumulatedData, jsonEncode(data));

      print(
          '[DataAccumulation] Screen time recorded: $appName ($durationSeconds seconds)');
    } catch (e) {
      print('[DataAccumulation] Error recording screen time: $e');
    }
  }

  /// Add to app usage tracking
  void _addToAppUsage(
      Map<String, dynamic> data, String appName, int timeMs, String? category) {
    final appUsage = data['app_usage'] as List;
    final existingIndex = appUsage.indexWhere((item) => item['app'] == appName);

    if (existingIndex >= 0) {
      appUsage[existingIndex]['time_ms'] += timeMs;
    } else {
      appUsage.add({
        'app': appName,
        'time_ms': timeMs,
        'category': category,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Record a call
  Future<void> recordCall() async {
    try {
      final data = getAccumulatedData();
      final calls = data['calls'] as Map<String, dynamic>;

      (calls['count'] as int) + 1;
      (calls['timestamps'] as List).add(DateTime.now().toIso8601String());

      data['last_updated'] = DateTime.now().toIso8601String();
      await _prefs.setString(_prefixAccumulatedData, jsonEncode(data));

      print('[DataAccumulation] Call recorded. Total: ${calls['count'] + 1}');
    } catch (e) {
      print('[DataAccumulation] Error recording call: $e');
    }
  }

  /// Record a message
  Future<void> recordMessage() async {
    try {
      final data = getAccumulatedData();
      final messages = data['messages'] as Map<String, dynamic>;

      (messages['count'] as int) + 1;
      (messages['timestamps'] as List).add(DateTime.now().toIso8601String());

      data['last_updated'] = DateTime.now().toIso8601String();
      await _prefs.setString(_prefixAccumulatedData, jsonEncode(data));

      print(
          '[DataAccumulation] Message recorded. Total: ${messages['count'] + 1}');
    } catch (e) {
      print('[DataAccumulation] Error recording message: $e');
    }
  }

  /// Detect late night usage (after 23:00 or before 06:00)
  Future<void> detectAndRecordLateNightUsage() async {
    try {
      final now = DateTime.now();
      final hour = now.hour;

      if (hour >= 23 || hour < 6) {
        final data = getAccumulatedData();
        final lateNight = data['late_night_usage'] as Map<String, dynamic>;

        (lateNight['detected'] as bool);
        ((lateNight['periods'] as List).add({
          'timestamp': now.toIso8601String(),
          'duration_context': 'detected_at_hour_$hour',
        }));

        data['last_updated'] = DateTime.now().toIso8601String();
        await _prefs.setString(_prefixAccumulatedData, jsonEncode(data));

        print(
            '[DataAccumulation] Late night usage detected at ${now.hour}:${now.minute}');
      }
    } catch (e) {
      print('[DataAccumulation] Error detecting late night usage: $e');
    }
  }

  /// Get time elapsed since cycle started
  Duration getTimeSinceCycleStart() {
    try {
      final data = getAccumulatedData();
      final cycleStart = data['cycle_start_time'] as String?;

      if (cycleStart == null) return Duration.zero;

      final startTime = DateTime.parse(cycleStart);
      return DateTime.now().difference(startTime);
    } catch (e) {
      print('[DataAccumulation] Error getting cycle duration: $e');
      return Duration.zero;
    }
  }

  /// Check if it's time to sync (3 hours elapsed)
  bool shouldSync() {
    return getTimeSinceCycleStart().inMinutes >= 180; // 3 hours
  }

  /// Prepare data for backend sync (called with audio clip)
  Future<Map<String, dynamic>> prepareDataForSync({
    int? audioScore,
  }) async {
    try {
      final data = getAccumulatedData();

      // Calculate derived metrics
      final unlockCount = (data['unlocks'] as Map)['count'] as int;
      final callCount = (data['calls'] as Map)['count'] as int;
      final messageCount = (data['messages'] as Map)['count'] as int;
      final screenTimeTotalMinutes =
          (data['screen_time'] as Map)['total_minutes'] as int;
      final lateNightDetected =
          (data['late_night_usage'] as Map)['detected'] as bool;
      final appUsage = (data['app_usage'] as List).cast<Map<String, dynamic>>();
      final cycleStart = data['cycle_start_time'] as String;

      // Calculate unlock rate (per hour)
      final cycleDuration = getTimeSinceCycleStart();
      final hoursElapsed = cycleDuration.inMinutes / 60.0;
      final unlockRate = hoursElapsed > 0
          ? unlockCount / hoursElapsed
          : unlockCount.toDouble();

      // Prepare sync payload
      final syncPayload = {
        'user_id': 'student_001',
        'timestamp': DateTime.now().toIso8601String(),
        'sync_cycle_start': cycleStart,
        'audio_score': audioScore ?? 0,
        'behavioral_data': {
          'unlocks': {
            'count': unlockCount,
            'rate_per_hour': unlockRate.toStringAsFixed(2),
            'timestamps': (data['unlocks'] as Map)['timestamps'],
          },
          'screen_time': {
            'total_minutes': screenTimeTotalMinutes,
            'app_sessions': (data['screen_time'] as Map)['app_sessions'],
          },
          'calls': {
            'count': callCount,
            'timestamps': (data['calls'] as Map)['timestamps'],
          },
          'messages': {
            'count': messageCount,
            'timestamps': (data['messages'] as Map)['timestamps'],
          },
          'late_night_usage': {
            'detected': lateNightDetected,
            'periods': (data['late_night_usage'] as Map)['periods'],
          },
          'app_usage': appUsage,
        },
      };

      print('[DataAccumulation] Sync payload prepared:');
      print(
          '  - Unlocks: $unlockCount (rate: ${unlockRate.toStringAsFixed(1)}/hr)');
      print('  - Screen time: ${screenTimeTotalMinutes}m');
      print('  - Calls: $callCount');
      print('  - Messages: $messageCount');
      print('  - Late night: $lateNightDetected');
      print('  - Audio score: $audioScore');

      return syncPayload;
    } catch (e) {
      print('[DataAccumulation] Error preparing sync data: $e');
      rethrow;
    }
  }

  /// Clear accumulated data and start new cycle (called after successful sync)
  Future<void> clearCycleData() async {
    try {
      await _resetAccumulatedData();
      await _prefs.setString(
          _prefixLastSyncTime, DateTime.now().toIso8601String());
      print('[DataAccumulation] Cycle cleared, new cycle started');
    } catch (e) {
      print('[DataAccumulation] Error clearing cycle: $e');
    }
  }

  /// Get summary of accumulated data
  Map<String, dynamic> getSummary() {
    try {
      final data = getAccumulatedData();
      return {
        'unlocks': (data['unlocks'] as Map)['count'],
        'screen_time_minutes': (data['screen_time'] as Map)['total_minutes'],
        'calls': (data['calls'] as Map)['count'],
        'messages': (data['messages'] as Map)['count'],
        'late_night_detected': (data['late_night_usage'] as Map)['detected'],
        'cycle_elapsed_minutes': getTimeSinceCycleStart().inMinutes,
        'should_sync': shouldSync(),
        'last_updated': data['last_updated'],
      };
    } catch (e) {
      print('[DataAccumulation] Error getting summary: $e');
      return {};
    }
  }
}
