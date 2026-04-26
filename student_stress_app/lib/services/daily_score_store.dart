import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores all score snapshots collected throughout the day and calculates daily averages.
///
/// Each snapshot = {audio, digital, physical, timestamp}
/// At any point, getDailyAverage() returns:
///   sum(audio) / count, sum(digital) / count, sum(physical) / count
///
/// Data is keyed by date (e.g. "daily_scores_2026-04-19") so old days auto-separate.
class DailyScoreStore {
  static const String _keyPrefix = 'daily_scores_';
  static const String _keyLastRecommendation = 'last_daily_recommendation';
  static const String _keyLastRecTime = 'last_recommendation_time';

  final SharedPreferences _prefs;

  DailyScoreStore({required SharedPreferences prefs}) : _prefs = prefs;

  /// Get today's storage key
  String get _todayKey =>
      '$_keyPrefix${DateTime.now().toIso8601String().split('T')[0]}';

  // ═══════════════════════════════════════════════════════════════════
  // WRITE
  // ═══════════════════════════════════════════════════════════════════

  /// Add a score snapshot from a collection cycle
  Future<void> addScoreEntry({
    required int audioScore,
    required int digitalScore,
    required int physicalScore,
  }) async {
    final entries = _getTodayEntries();

    entries.add({
      'audio': audioScore,
      'digital': digitalScore,
      'physical': physicalScore,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await _prefs.setString(_todayKey, jsonEncode(entries));

    print('[DailyScoreStore] Entry #${entries.length} added: '
        'audio=$audioScore, digital=$digitalScore, physical=$physicalScore');
  }

  /// Save the latest recommendation for homepage display
  Future<void> saveRecommendation(Map<String, dynamic> recommendation) async {
    await _prefs.setString(_keyLastRecommendation, jsonEncode(recommendation));
    await _prefs.setString(
        _keyLastRecTime, DateTime.now().toIso8601String());
    print('[DailyScoreStore] Recommendation saved');
  }

  // ═══════════════════════════════════════════════════════════════════
  // READ
  // ═══════════════════════════════════════════════════════════════════

  /// Get all entries collected today
  List<Map<String, dynamic>> _getTodayEntries() {
    final raw = _prefs.getString(_todayKey);
    if (raw == null) return [];

    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('[DailyScoreStore] Error reading entries: $e');
      return [];
    }
  }

  /// Get today's collection count
  int getTodayCount() => _getTodayEntries().length;

  /// Get all today's entries (public)
  List<Map<String, dynamic>> getTodayEntries() => _getTodayEntries();

  /// Calculate daily average scores
  ///
  /// Returns {audio: avg, digital: avg, physical: avg, count: N}
  /// Returns null if no entries today
  Map<String, dynamic>? getDailyAverage() {
    final entries = _getTodayEntries();
    if (entries.isEmpty) return null;

    int totalAudio = 0;
    int totalDigital = 0;
    int totalPhysical = 0;

    for (final entry in entries) {
      totalAudio += (entry['audio'] as num).toInt();
      totalDigital += (entry['digital'] as num).toInt();
      totalPhysical += (entry['physical'] as num).toInt();
    }

    final count = entries.length;

    final avgAudio = (totalAudio / count).round();
    final avgDigital = (totalDigital / count).round();
    final avgPhysical = (totalPhysical / count).round();
    final overallAvg = ((avgAudio + avgDigital + avgPhysical) / 3).round();

    print('[DailyScoreStore] Daily average ($count collections): '
        'audio=$avgAudio, digital=$avgDigital, physical=$avgPhysical, '
        'overall=$overallAvg');

    return {
      'audio': avgAudio,
      'digital': avgDigital,
      'physical': avgPhysical,
      'overall': overallAvg,
      'count': count,
      'entries': entries,
    };
  }

  /// Get the latest individual scores (most recent snapshot)
  Map<String, dynamic>? getLatestScores() {
    final entries = _getTodayEntries();
    if (entries.isEmpty) return null;
    return entries.last;
  }

  /// Get the saved recommendation for homepage display
  Map<String, dynamic>? getLastRecommendation() {
    final raw = _prefs.getString(_keyLastRecommendation);
    if (raw == null) return null;

    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      print('[DailyScoreStore] Error reading recommendation: $e');
      return null;
    }
  }

  /// Get the last recommendation time
  DateTime? getLastRecommendationTime() {
    final raw = _prefs.getString(_keyLastRecTime);
    if (raw == null) return null;
    try {
      return DateTime.parse(raw);
    } catch (e) {
      return null;
    }
  }

  /// Get stress level label from average score
  static String getStressLevel(int averageScore) {
    if (averageScore < 30) return 'Low';
    if (averageScore < 50) return 'Moderate';
    if (averageScore < 75) return 'High';
    return 'Critical';
  }

  /// Get stress level color
  static int getStressColor(int averageScore) {
    if (averageScore < 30) return 0xFF4CAF50; // Green
    if (averageScore < 50) return 0xFFFF9800; // Orange
    if (averageScore < 75) return 0xFFFF5722; // Deep Orange
    return 0xFFF44336; // Red
  }

  // ═══════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════

  /// Clean up old data (keep only last 7 days)
  Future<void> cleanupOldData() async {
    final keys = _prefs.getKeys();
    final today = DateTime.now();

    for (final key in keys) {
      if (key.startsWith(_keyPrefix)) {
        final dateStr = key.replaceFirst(_keyPrefix, '');
        try {
          final date = DateTime.parse(dateStr);
          if (today.difference(date).inDays > 7) {
            await _prefs.remove(key);
            print('[DailyScoreStore] Cleaned up old data: $key');
          }
        } catch (_) {}
      }
    }
  }
}
