import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_usage/app_usage.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import 'backend_service.dart';
/// Digital Habits Data Collection Service
///
/// Collects:
/// - Phone unlocks (from app resume events)
/// - Screen time (approximated from activity)
/// - App usage patterns (installed/used apps)
/// - Communication frequency (calls/messages)
///
/// Integrates with student life dataset to predict stress from digital behavior
///

class DigitalHabitsService {
  static const String _prefixUnlocks = 'daily_unlock_count';
  static const String _prefixScreenTime = 'daily_screen_time';
  static const String _prefixAppUsage = 'app_usage_log';
  static const String _prefixCalls = 'daily_calls';
  static const String _prefixMessages = 'daily_messages';
  static const String _prefixLastReset = 'habits_reset_date';

  // App categories for classification
  static const Map<String, List<String>> appCategories = {
    'Social': [
      'facebook',
      'twitter',
      'instagram',
      'snapchat',
      'whatsapp',
      'telegram',
      'messenger',
      'tiktok'
    ],
    'Academic': [
      'gmail',
      'canvas',
      'gradescope',
      'piazza',
      'onenote',
      'studyblue',
      'coursera'
    ],
    'Productivity': [
      'calendar',
      'todoist',
      'notion',
      'drive',
      'slack',
      'trello',
      'asana'
    ],
    'Entertainment': [
      'youtube',
      'netflix',
      'gaming',
      'reddit',
      'twitch',
      'spotify',
      'tiktok'
    ],
    'Communication': [
      'phone',
      'sms',
      'messages',
      'facetime',
      'skype',
      'viber',
      'line'
    ],
    'Health': ['health', 'fitness', 'meditation', 'strava', 'myfitnesspal'],
    'Utility': ['maps', 'camera', 'browser', 'settings', 'files']
  };

  final SharedPreferences prefs;

  DigitalHabitsService({required this.prefs}) {
    _initializeDaily();
  }

  /// Get current backend URL (delegates to BackendService)
  static String getBackendUrl() => BackendService.getBackendUrl();

  /// Initialize daily counters
  void _initializeDaily() {
    final lastReset = prefs.getString(_prefixLastReset);
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastReset != today) {
      // Reset daily counters
      prefs.remove(_prefixUnlocks);
      prefs.remove(_prefixScreenTime);
      prefs.remove(_prefixAppUsage);
      prefs.remove(_prefixCalls);
      prefs.remove(_prefixMessages);
      prefs.setString(_prefixLastReset, today);

      print('[DigitalHabits] Daily reset for $today');
    }
  }

  /// Record an unlock event
  void recordUnlock() {
    final current = prefs.getInt(_prefixUnlocks) ?? 0;
    prefs.setInt(_prefixUnlocks, current + 1);
    print('[DigitalHabits] Unlock recorded. Total: ${current + 1}');
  }

  /// Get today's unlock count
  int getUnlockCount() {
    return prefs.getInt(_prefixUnlocks) ?? 0;
  }

  /// Record app usage
  void recordAppUsage(String appName, int timeMs) {
    try {
      String? jsonStr = prefs.getString(_prefixAppUsage);
      List<Map<String, dynamic>> appUsage = [];

      if (jsonStr != null) {
        appUsage = List<Map<String, dynamic>>.from(jsonDecode(jsonStr) as List);
      }

      // Check if app already exists in log
      final existingIndex =
          appUsage.indexWhere((item) => item['app'] == appName);

      if (existingIndex >= 0) {
        appUsage[existingIndex]['time_ms'] += timeMs;
      } else {
        appUsage.add({
          'app': appName,
          'time_ms': timeMs,
          'timestamp': DateTime.now().toIso8601String()
        });
      }

      prefs.setString(_prefixAppUsage, jsonEncode(appUsage));
    } catch (e) {
      print('[DigitalHabits] Error recording app usage: $e');
    }
  }

  /// Get app usage list
  Future<List<Map<String, dynamic>>> getAppUsageList() async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = DateTime(endDate.year, endDate.month, endDate.day);
      List<AppUsageInfo> infoList = await AppUsage().getAppUsage(startDate, endDate);
      
      List<Map<String, dynamic>> appUsage = [];
      for (var info in infoList) {
        // Only include apps with at least 1 minute of usage
        if (info.usage.inSeconds > 60) {
          appUsage.add({
            'app': info.packageName,
            'time_ms': info.usage.inMilliseconds,
            'timestamp': info.endDate.toIso8601String()
          });
        }
      }
      return appUsage;
    } catch (e) {
      print('[DigitalHabits] Error getting real app usage: $e');
      return [];
    }
  }

  /// Get total screen time from real usage
  Future<int> calculateScreenTime() async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = DateTime(endDate.year, endDate.month, endDate.day);
      List<AppUsageInfo> infoList = await AppUsage().getAppUsage(startDate, endDate);
      
      int totalSeconds = 0;
      for (var info in infoList) {
        totalSeconds += info.usage.inSeconds;
      }
      return totalSeconds ~/ 60; // Convert to minutes
    } catch (e) {
      print('[DigitalHabits] Failed to calculate screen time: $e');
      return 0;
    }
  }

  /// Get real call count from native logs
  Future<int> getRealCallCount() async {
    try {
      if (await Permission.phone.request().isGranted) {
        DateTime now = DateTime.now();
        DateTime midnight = DateTime(now.year, now.month, now.day);
        
        Iterable<CallLogEntry> entries = await CallLog.query(
          dateFrom: midnight.millisecondsSinceEpoch,
          dateTo: now.millisecondsSinceEpoch,
        );
        return entries.length;
      }
      return 0;
    } catch (e) {
      print('[DigitalHabits] Error reading call log: $e');
      return 0;
    }
  }

  /// Record message (skipped due to strict Google Play SMS rules)
  void recordMessage() { }
  int getMessageCount() { return 0; }

  /// Detect late night usage (after 23:00) using real timestamps
  Future<bool> detectLateNightUsage() async {
    try {
      DateTime now = DateTime.now();
      DateTime yesterday = now.subtract(const Duration(hours: 12));
      List<AppUsageInfo> infoList = await AppUsage().getAppUsage(yesterday, now);
      
      for (var info in infoList) {
        if (info.usage.inSeconds > 0) {
          if (info.endDate.hour >= 23 || info.endDate.hour < 5) {
            return true;
          }
        }
      }
    } catch (e) {
      print('[DigitalHabits] Error detecting late night usage: $e');
    }
    return false;
  }

  /// Detect morning rush (multiple unlocks 5-8am)
  bool detectMorningRush() {
    // This would need timestamp data from unlock tracking
    // For now, return false (can be enhanced later)
    return false;
  }

  /// Get list of installed apps
  Future<List<String>> getInstalledApps() async {
    // Currently returning empty list, device apps retrieval can be implemented natively.
    return [];
  }

  /// Categorize an app
  String categorizeApp(String appName) {
    final appLower = appName.toLowerCase();

    for (final category in appCategories.entries) {
      if (category.value.any((app) => appLower.contains(app))) {
        return category.key;
      }
    }

    return 'Utility';
  }

  /// Send digital habits data to backend for analysis with retry logic
  /// On failure, returns a local fallback score instead of throwing
  Future<Map<String, dynamic>> analyzeDigitalHabits({
    required String userId,
    int maxRetries = 2,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final unlocks = getUnlockCount();
    final screenTimeMins = await calculateScreenTime();
    final calls = await getRealCallCount();
    final messages = getMessageCount();
    final appUsage = await getAppUsageList();
    final lateNight = await detectLateNightUsage();
    final morningRush = detectMorningRush();

    print('[DigitalHabits] Preparing analysis:');
    print('  Unlocks: $unlocks');
    print('  Screen time: ${screenTimeMins}m');
    print('  Calls: $calls');
    print('  Messages: $messages');
    print('  Late night: $lateNight');

    final requestBody = {
      'user_id': userId,
      'unlocks': unlocks,
      'screen_time': screenTimeMins,
      'app_usage': appUsage,
      'call_log': calls,
      'messages': messages,
      'late_night_usage': lateNight,
      'morning_rush': morningRush,
    };

    final backendUrl = BackendService.getBackendUrl();

    // Try to send to backend with retry logic
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        print(
            '[DigitalHabits] Sending to backend (attempt ${attempt + 1}/${maxRetries + 1}, timeout: ${timeout.inSeconds}s): $backendUrl/analyze-digital-habits');

        final response = await http
            .post(
              Uri.parse('$backendUrl/analyze-digital-habits'),
              headers: BackendService.getHeaders(),
              body: jsonEncode(requestBody),
            )
            .timeout(timeout);

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body) as Map<String, dynamic>;
          print('[DigitalHabits] Analysis complete: '
              'Score = ${result['digital_score']}');
          return result;
        } else {
          print('[DigitalHabits] Server error: ${response.statusCode}');
          if (attempt < maxRetries) {
            // Wait before retry with exponential backoff
            await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
          }
        }
      } catch (e) {
        print('[DigitalHabits] Attempt ${attempt + 1} failed: $e');
        if (attempt < maxRetries) {
          // Wait before retry with exponential backoff
          await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
        }
      }
    }

    // Backend unavailable - return local fallback instead of crashing
    print(
        '[DigitalHabits] ⚠️ Backend unavailable after ${maxRetries + 1} attempts. Using local fallback.');
    return _calculateLocalFallback(unlocks, screenTimeMins, calls, messages, lateNight);
  }

  /// Calculate a local fallback score when backend is unreachable
  Map<String, dynamic> _calculateLocalFallback(
      int unlocks, int screenTimeMins, int calls, int messages, bool lateNight) {
    // Simple local scoring algorithm
    double unlockScore = (unlocks / 80.0 * 100).clamp(0, 100);
    double screenScore = (screenTimeMins / 240.0 * 100).clamp(0, 100);
    double commScore = ((calls + messages) / 50.0 * 100).clamp(0, 100);
    double timeScore = lateNight ? 70.0 : 20.0;

    double digitalScore = (unlockScore * 0.3 + screenScore * 0.3 +
        commScore * 0.2 + timeScore * 0.2);

    print('[DigitalHabits] Local fallback score: $digitalScore');

    return {
      'status': 'Fallback',
      'digital_score': digitalScore.round(),
      'components': {
        'app_usage_score': screenScore.round(),
        'screen_time_score': screenScore.round(),
        'unlock_frequency_score': unlockScore.round(),
        'time_pattern_score': timeScore.round(),
        'communication_score': commScore.round(),
      },
      'stress_factors': [],
      'behavior_analysis': 'Local fallback - backend was unreachable',
      'recommendations': [],
    };
  }

  /// Get digital score only (lightweight call)
  Future<double> getDigitalScore({required String userId}) async {
    final result = await analyzeDigitalHabits(userId: userId);
    final score = (result['digital_score'] as num?)?.toDouble() ?? 0.0;
    print('[DigitalHabits] Digital score retrieved: $score');
    return score;
  }

  /// Generate daily report
  Future<Map<String, dynamic>> generateDailyReport() async {
    return {
      'date': DateTime.now().toIso8601String().split('T')[0],
      'unlocks': getUnlockCount(),
      'screen_time_minutes': await calculateScreenTime(),
      'calls': await getRealCallCount(),
      'messages': getMessageCount(),
      'app_usage_categories': await _summarizeAppUsage(),
      'late_night_usage': await detectLateNightUsage(),
      'morning_rush': detectMorningRush(),
    };
  }

  /// Summarize app usage by category
  Future<Map<String, int>> _summarizeAppUsage() async {
    final appUsage = await getAppUsageList();
    final summary = <String, int>{};

    for (final app in appUsage) {
      final category = categorizeApp(app['app'] as String);
      final time = (app['time_ms'] as int? ?? 0) ~/ 60000; // Convert to minutes

      summary[category] = (summary[category] ?? 0) + time;
    }

    return summary;
  }
}
