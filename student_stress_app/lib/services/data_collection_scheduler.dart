import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_stress_service.dart';
import 'digital_habits_service.dart';
import 'physical_activity_service.dart';
import 'sync_service.dart';
import 'backend_service.dart';
import 'daily_score_store.dart';
import 'notification_service.dart';
import 'data_accumulation_service.dart';

/// Manages automated data collection with 3-hour cycles
///
/// NEW FLOW:
/// 1. On app start → collect all 3 scores immediately
/// 2. Every 3 hours → collect all 3 scores again
/// 3. Store each snapshot in DailyScoreStore
/// 4. Calculate daily average → fetch recommendation → show notification
class DataCollectionScheduler {
  static const String _userId = 'student_001';

  final SyncService _syncService;
  final AudioStressService _audioService;
  late final DigitalHabitsService _digitalService;
  late final DataAccumulationService _accumulationService;
  final PhysicalActivityService _physicalActivityService;
  late DailyScoreStore _dailyScoreStore;
  final NotificationService _notificationService = NotificationService();

  late SharedPreferences _prefs;

  Timer? _accumulation3HourTimer;
  Timer? _behaviorTrackingTimer;
  bool _isRunning = false;
  bool _isCollecting = false; // Prevents overlapping collections

  /// Callback to notify HomeScreen when scores are updated
  void Function(int audio, int digital, int physical,
      Map<String, dynamic>? recommendation)? onScoresUpdated;

  DataCollectionScheduler({
    required SyncService syncService,
    required AudioStressService audioService,
    required PhysicalActivityService physicalActivityService,
  })  : _syncService = syncService,
        _audioService = audioService,
        _physicalActivityService = physicalActivityService;

  /// Initialize the scheduler
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _digitalService = DigitalHabitsService(prefs: _prefs);
    _accumulationService = DataAccumulationService(prefs: _prefs);
    _dailyScoreStore = DailyScoreStore(prefs: _prefs);
    await _notificationService.initNotifications();

    // Clean up old data on init
    await _dailyScoreStore.cleanupOldData();
  }

  /// Get the daily score store for reading averages
  DailyScoreStore get dailyScoreStore => _dailyScoreStore;

  /// Start automated data collection
  ///
  /// 1. Immediately collect all 3 scores
  /// 2. Schedule 3-hour repeats
  Future<void> startCollection() async {
    if (_isRunning) {
      print('[Scheduler] Collection already running');
      return;
    }

    _isRunning = true;
    print('[Scheduler] Starting automated collection...');

    await _prefs.setInt(
        'collection_start_time', DateTime.now().millisecondsSinceEpoch);
    await _prefs.setBool('is_collecting', true);

    // STEP 1: Collect all 3 scores IMMEDIATELY on start
    print('[Scheduler] Performing initial score collection...');
    await _collectAllScores();

    // STEP 2: Schedule 3-hour repeating cycle
    _schedule3HourCycle();

    // STEP 3: Start background behavior tracking
    _startBehaviorTracking();

    print('[Scheduler] Automated collection started');
  }

  /// Stop automated data collection
  Future<void> stopCollection() async {
    if (!_isRunning) return;

    _accumulation3HourTimer?.cancel();
    _behaviorTrackingTimer?.cancel();
    _isRunning = false;

    await _prefs.setBool('is_collecting', false);
    print('[Scheduler] Automated collection stopped');
  }

  // ═══════════════════════════════════════════════════════════════
  // CORE: Collect all 3 scores + store + recommend + notify
  // ═══════════════════════════════════════════════════════════════

  /// Collect all 3 stress scores, store them, get recommendation, notify
  ///
  /// This is the main collection method called:
  /// - Immediately on app start
  /// - Every 3 hours automatically
  /// - Can also be triggered manually
  Future<void> _collectAllScores() async {
    if (_isCollecting) {
      print('[Scheduler] Collection already in progress, skipping...');
      return;
    }

    _isCollecting = true;

    try {
      print('\n[Scheduler] ========================================');
      print('[Scheduler] COLLECTING ALL 3 STRESS SCORES');
      print('[Scheduler] ========================================');

      int audioScore = 0;
      int digitalScore = 0;
      int physicalScore = 0;

      // ─────────────────────────────────────────────────────
      // [1/3] AUDIO — Record 10 seconds of ambient sound
      // ─────────────────────────────────────────────────────
      try {
        print('[Scheduler] [1/3] Recording 10s audio...');
        final probs = await _audioService.startMonitoring();
        if (probs.isNotEmpty) {
          audioScore = _audioService.computeAudioScore(probs).toInt();
        } else {
          audioScore = _prefs.getInt('last_audio_score') ?? 0;
        }
        await _prefs.setInt('last_audio_score', audioScore);
        print('[Scheduler] [1/3] Audio score: $audioScore');
      } catch (e) {
        print('[Scheduler] [1/3] Audio failed: $e');
        audioScore = _prefs.getInt('last_audio_score') ?? 0;
      }

      // ─────────────────────────────────────────────────────
      // [2/3] DIGITAL HABITS — Analyze phone usage
      // ─────────────────────────────────────────────────────
      try {
        print('[Scheduler] [2/3] Analyzing digital habits...');
        final digitalResult =
            await _digitalService.analyzeDigitalHabits(userId: _userId);
        digitalScore =
            (digitalResult['digital_score'] as num?)?.toInt() ?? 30;
        print('[Scheduler] [2/3] Digital score: $digitalScore');
      } catch (e) {
        print('[Scheduler] [2/3] Digital habits failed: $e');
        digitalScore = 30;
      }

      // ─────────────────────────────────────────────────────
      // [3/3] PHYSICAL ACTIVITY — Analyze movement
      // ─────────────────────────────────────────────────────
      try {
        print('[Scheduler] [3/3] Analyzing physical activity...');
        final physicalResult =
            await _physicalActivityService.analyzeMovement(_userId);
        physicalScore =
            (physicalResult['physical_stress_score'] as num?)?.toInt() ?? 30;
        print('[Scheduler] [3/3] Physical score: $physicalScore');
      } catch (e) {
        print('[Scheduler] [3/3] Physical activity failed: $e');
        physicalScore = 30;
      }

      // ─────────────────────────────────────────────────────
      // STORE the snapshot in DailyScoreStore
      // ─────────────────────────────────────────────────────
      await _dailyScoreStore.addScoreEntry(
        audioScore: audioScore,
        digitalScore: digitalScore,
        physicalScore: physicalScore,
      );

      // Save individual latest scores for quick access
      await _prefs.setInt('latest_audio_score', audioScore);
      await _prefs.setInt('latest_digital_score', digitalScore);
      await _prefs.setInt('latest_physical_score', physicalScore);

      // ─────────────────────────────────────────────────────
      // SYNC scores to backend
      // ─────────────────────────────────────────────────────
      try {
        print('[Scheduler] Syncing scores to backend...');
        await _syncService.syncAll({
          'user_id': _userId,
          'audio_score': audioScore,
          'digital_components': {
            'app_usage_score': digitalScore,
            'screen_time_score': digitalScore,
            'unlock_frequency_score': digitalScore,
            'time_pattern_score': digitalScore,
          },
          'physical_components': {
            'activity': 'SITTING',
            'physical_stress_score': physicalScore,
            'movement_intensity': 50,
            'pattern_regularity': 50,
          },
        });
        print('[Scheduler] Backend sync done');
      } catch (e) {
        print('[Scheduler] Backend sync failed (non-critical): $e');
      }

      // ─────────────────────────────────────────────────────
      // CALCULATE daily average and GET RECOMMENDATION
      // ─────────────────────────────────────────────────────
      final dailyAvg = _dailyScoreStore.getDailyAverage();
      Map<String, dynamic>? recommendation;

      if (dailyAvg != null) {
        try {
          print('[Scheduler] Fetching recommendation based on daily average...');
          print('[Scheduler]   Daily avg: audio=${dailyAvg['audio']}, '
              'digital=${dailyAvg['digital']}, physical=${dailyAvg['physical']} '
              '(${dailyAvg['count']} collections)');

          final recResult = await BackendService().getRecommendations(
            audioScore: dailyAvg['audio'] as int,
            digitalScore: dailyAvg['digital'] as int,
            physicalScore: dailyAvg['physical'] as int,
          );

          if (recResult['status'] == 'success') {
            recommendation = recResult['data'] as Map<String, dynamic>;
            await _dailyScoreStore.saveRecommendation(recommendation!);
            print('[Scheduler] Recommendation saved');

            // SEND NOTIFICATION
            _sendRecommendationNotification(recommendation, dailyAvg);
          }
        } catch (e) {
          print('[Scheduler] Recommendation fetch failed: $e');
          // Try to use cached recommendation
          recommendation = _dailyScoreStore.getLastRecommendation();
        }
      }

      // ─────────────────────────────────────────────────────
      // NOTIFY HomeScreen via callback
      // ─────────────────────────────────────────────────────
      if (onScoresUpdated != null) {
        onScoresUpdated!(audioScore, digitalScore, physicalScore, recommendation);
      }

      print('[Scheduler] ========================================');
      print('[Scheduler] COLLECTION COMPLETE');
      print('[Scheduler]   Audio: $audioScore');
      print('[Scheduler]   Digital: $digitalScore');
      print('[Scheduler]   Physical: $physicalScore');
      print('[Scheduler]   Today count: ${_dailyScoreStore.getTodayCount()}');
      print('[Scheduler] ========================================\n');
    } catch (e) {
      print('[Scheduler] Collection error: $e');
    } finally {
      _isCollecting = false;
    }
  }

  /// Send a push notification with the top recommendation
  void _sendRecommendationNotification(
    Map<String, dynamic> recommendation,
    Map<String, dynamic> dailyAvg,
  ) {
    try {
      final recs = recommendation['recommendations'] as List<dynamic>?;
      if (recs == null || recs.isEmpty) return;

      final topRec = recs[0] as Map<String, dynamic>;
      final overall = dailyAvg['overall'] as int? ?? 0;
      final stressLevel = DailyScoreStore.getStressLevel(overall);
      final count = dailyAvg['count'] as int? ?? 0;

      _notificationService.showRecommendationNotification(
        title: 'Stress Level: $stressLevel ($overall/100) - $count collections today',
        recommandation: '${topRec['title']}: ${topRec['action']}',
        duration: topRec['duration'] ?? '10 minutes',
      );

      print('[Scheduler] Notification sent');
    } catch (e) {
      print('[Scheduler] Notification error: $e');
    }
  }

  /// Public method to trigger manual collection
  Future<void> collectNow() async {
    await _collectAllScores();
  }

  // ═══════════════════════════════════════════════════════════════
  // TIMERS
  // ═══════════════════════════════════════════════════════════════

  /// Schedule 3-hour repeating cycle
  void _schedule3HourCycle() {
    print('[Scheduler] 3-hour cycle scheduled');

    _accumulation3HourTimer?.cancel();
    _accumulation3HourTimer = Timer.periodic(
      const Duration(hours: 3),
      (timer) async {
        print('[Scheduler] 3-hour cycle triggered (cycle #${timer.tick})');
        await _collectAllScores();
      },
    );
  }

  /// Start background behavior tracking (5-min intervals)
  void _startBehaviorTracking() {
    _behaviorTrackingTimer?.cancel();
    _behaviorTrackingTimer =
        Timer.periodic(const Duration(minutes: 5), (timer) async {
      final elapsed = _accumulationService.getTimeSinceCycleStart().inMinutes;
      print('[Scheduler] [5-min check] ${elapsed}m elapsed in current cycle');
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // PUBLIC ACCESSORS
  // ═══════════════════════════════════════════════════════════════

  bool get isRunning => _isRunning;

  /// Get time until next collection (in minutes)
  int getMinutesUntilNextCollection() {
    if (!_isRunning) return 0;
    final elapsed = _accumulationService.getTimeSinceCycleStart().inMinutes;
    return (180 - elapsed).clamp(0, 180);
  }

  /// Record app unlock event
  Future<void> recordAppUnlock() async {
    await _accumulationService.recordUnlock(
      appName: 'app_unlock',
      screenOnTime: 0,
    );
  }

  /// Get current collection status
  Future<Map<String, dynamic>> getStatus() async {
    final isCollecting = _prefs.getBool('is_collecting') ?? false;
    final startTime = _prefs.getInt('collection_start_time') ?? 0;
    final dailyAvg = _dailyScoreStore.getDailyAverage();

    return {
      'is_collecting': isCollecting,
      'is_running': _isRunning,
      'start_time': startTime > 0
          ? DateTime.fromMillisecondsSinceEpoch(startTime).toString()
          : 'Not started',
      'today_count': _dailyScoreStore.getTodayCount(),
      'daily_average': dailyAvg,
      'minutes_until_next': getMinutesUntilNextCollection(),
    };
  }
}
