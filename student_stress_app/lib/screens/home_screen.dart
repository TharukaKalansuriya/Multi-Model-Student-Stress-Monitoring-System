import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/audio_stress_service.dart';
import '../services/data_collection_scheduler.dart';
import '../services/sync_service.dart';
import '../services/physical_activity_service.dart';
import '../services/digital_habits_service.dart';
import '../services/permission_service.dart';
import '../services/notification_service.dart';
import '../services/backend_service.dart';
import '../services/daily_score_store.dart';
import '../theme/app_colors.dart';
import '../widgets/circular_progress_bar.dart';
import 'settings_screen.dart';
import 'user_profile_screen.dart';
import 'recommendations_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const String _userId = 'student_001';

  // Services
  final SyncService _syncService = SyncService();
  final PermissionService _permissionService = PermissionService();
  final PhysicalActivityService _physicalActivityService =
      PhysicalActivityService();
  late final NotificationService _notificationService;
  late final BackendService _backendService;
  late DigitalHabitsService _digitalHabitsService; // for recording unlocks

  late final AudioStressService _audioService = AudioStressService(
    syncService: _syncService,
    userId: _userId,
  );

  late DataCollectionScheduler _scheduler;
  DailyScoreStore? _dailyScoreStore;

  // State
  String _statusMessage = 'Initializing...';
  bool _isInitializing = true;
  bool _isBackendOnline = false;   // Feature 1: offline banner

 
  static const _unlockChannel = MethodChannel('com.student_stress_app/unlock');

  bool _hasPlayedSoundThisCycle = false;

  // Current scores (latest snapshot)
  int _audioScore = 0;
  int _digitalScore = 0;
  int _physicalScore = 0;

  // Daily averages
  int _avgAudioScore = 0;
  int _avgDigitalScore = 0;
  int _avgPhysicalScore = 0;
  int _overallAvgScore = 0;
  int _collectionCount = 0;

  // Latest recommendation for homepage
  Map<String, dynamic>? _latestRecommendation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationService = NotificationService();
    _backendService = BackendService();
    _initializeAndAutoStart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scheduler.stopCollection();
    _audioService.stopMonitoring();
    super.dispose();
  }

 
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshDailyData();
    }
  }

 
  Future<void> _initializeAndAutoStart() async {
    try {
      setState(() {
        _statusMessage = 'Initializing services...';
      });

      // Initialize backend
      await _backendService.initialize();

      // Check backend connectivity immediately (5s timeout, non-blocking)
      _checkConnectivity();

      // Initialize notifications
      await _notificationService.initNotifications();

      // Request microphone permission
      final hasPermission = await _permissionService.isMicrophoneGranted();
      if (!hasPermission) {
        await _permissionService.requestMicrophonePermission();
      }
      
      // Request Digital Habits permissions (Call log, Usage Stats)
      await _permissionService.requestDigitalHabitsPermissions();

      // Initialize scheduler
      _scheduler = DataCollectionScheduler(
        syncService: _syncService,
        audioService: _audioService,
        physicalActivityService: _physicalActivityService,
      );
      await _scheduler.initialize();

      // Initialize DigitalHabitsService with same prefs for unlock tracking
      final prefs = await SharedPreferences.getInstance();
      _digitalHabitsService = DigitalHabitsService(prefs: prefs);

      // Feature 3: Listen for real device unlock events from native BroadcastReceiver
      _unlockChannel.setMethodCallHandler((call) async {
        if (call.method == 'unlock') {
          _digitalHabitsService.recordUnlock();
          print('[HomeScreen] Real device unlock recorded via MethodChannel');
        }
      });

      // Get DailyScoreStore reference
      _dailyScoreStore = _scheduler.dailyScoreStore;

      // Load cached data first (shows immediately while collection happens)
      _loadCachedData();

      // Set callback so scheduler can update the UI
      _scheduler.onScoresUpdated = _onScoresUpdated;

      if (!mounted) return;

      setState(() {
        _statusMessage = 'Collecting scores...';
        _isInitializing = false;
      });

      // AUTO-START: Begin collection immediately
      await _scheduler.startCollection();

      // Schedule periodic background work via WorkManager
      await _notificationService.schedulePeriodicRecommendations();

      if (mounted) {
        setState(() {
          _statusMessage = 'Monitoring active';
        });
      }
    } catch (e) {
      print('[HomeScreen] Init error: $e');
      if (mounted) {
        setState(() {
          _statusMessage = 'Error: $e';
          _isInitializing = false;
        });
      }
    }
  }

  /// Load previously cached scores and recommendation for instant display
  void _loadCachedData() {
    if (_dailyScoreStore == null) return;

    final dailyAvg = _dailyScoreStore!.getDailyAverage();
    final latest = _dailyScoreStore!.getLatestScores();
    final rec = _dailyScoreStore!.getLastRecommendation();

    if (dailyAvg != null) {
      setState(() {
        _avgAudioScore = dailyAvg['audio'] as int;
        _avgDigitalScore = dailyAvg['digital'] as int;
        _avgPhysicalScore = dailyAvg['physical'] as int;
        _overallAvgScore = dailyAvg['overall'] as int;
        _collectionCount = dailyAvg['count'] as int;
      });
    }

    if (latest != null) {
      setState(() {
        _audioScore = (latest['audio'] as num).toInt();
        _digitalScore = (latest['digital'] as num).toInt();
        _physicalScore = (latest['physical'] as num).toInt();
      });
    }

    if (rec != null) {
      setState(() {
        _latestRecommendation = rec;
      });
    }
  }

  /// Callback from DataCollectionScheduler when new scores arrive
  void _onScoresUpdated(int audio, int digital, int physical,
      Map<String, dynamic>? recommendation) {
    if (!mounted) return;

    // Feature 1: re-check connectivity whenever scores arrive (non-blocking)
    _checkConnectivity();

    // Feature 2: play sounds on environment score thresholds
    // Only play when scores actually changed from a real collection, not on init
    final prevAudio = _audioScore;
    if (audio != prevAudio) {
      _playScoreSound(audio);
    }

    setState(() {
      _audioScore = audio;
      _digitalScore = digital;
      _physicalScore = physical;
      _statusMessage = 'Monitoring active';
      _hasPlayedSoundThisCycle = false; // reset for next cycle

      if (recommendation != null) {
        _latestRecommendation = recommendation;
      }
    });

    _refreshDailyData();
  }

  /// Fast connectivity check with 5-second timeout.
  /// Catches ClientException (dropped connection) and SocketException (no network).
  void _checkConnectivity() {
    _backendService.checkHealth().timeout(
      const Duration(seconds: 5),
      onTimeout: () => {'status': 'disconnected'},
    ).then((health) {
      if (mounted) {
        setState(() {
          _isBackendOnline = health['status'] == 'connected';
        });
        print('[HomeScreen] Backend online: $_isBackendOnline');
      }
    }).catchError((e) {
      // ClientException, SocketException, etc. all mean offline
      if (mounted) {
        setState(() => _isBackendOnline = false);
        print('[HomeScreen] Connectivity check failed (offline): $e');
      }
    });
  }


  Future<void> _playScoreSound(int audioScore) async {
    try {
      if (audioScore >= 80) {
        // High stress environment — repeated alert beep
        await SystemSound.play(SystemSoundType.alert);
        await Future.delayed(const Duration(milliseconds: 400));
        await SystemSound.play(SystemSoundType.alert);
        await Future.delayed(const Duration(milliseconds: 400));
        await SystemSound.play(SystemSoundType.alert);
        // Heavy haptic for urgency
        HapticFeedback.heavyImpact();
        print('[HomeScreen] 🔔 High stress sound played (score: $audioScore)');
      } else if (audioScore <= 20 && audioScore > 0) {
        // Low stress environment — single gentle click
        await SystemSound.play(SystemSoundType.click);
        HapticFeedback.lightImpact();
        print('[HomeScreen] 🎵 Low stress sound played (score: $audioScore)');
      }
    } catch (e) {
      print('[HomeScreen] Sound playback error (non-critical): $e');
    }
  }

  /// Refresh daily averages from the store
  void _refreshDailyData() {
    if (_dailyScoreStore == null) return;

    final dailyAvg = _dailyScoreStore!.getDailyAverage();
    if (dailyAvg != null && mounted) {
      setState(() {
        _avgAudioScore = dailyAvg['audio'] as int;
        _avgDigitalScore = dailyAvg['digital'] as int;
        _avgPhysicalScore = dailyAvg['physical'] as int;
        _overallAvgScore = dailyAvg['overall'] as int;
        _collectionCount = dailyAvg['count'] as int;
      });
    }

    // Also refresh recommendation
    final rec = _dailyScoreStore!.getLastRecommendation();
    if (rec != null && mounted) {
      setState(() {
        _latestRecommendation = rec;
      });
    }
  }

  /// Manual "Check Now" — trigger an immediate collection
  Future<void> _checkStressNow() async {
    setState(() {
      _statusMessage = 'Collecting scores...';
    });

    await _scheduler.collectNow();

    if (mounted) {
      setState(() {
        _statusMessage = 'Monitoring active';
      });
    }
  }

  /// Reset all data — clears collections for a fresh start
  Future<void> _resetDemoData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quick Fresh Start'),
        content: const Text(
          'This will clear all collected scores and history.\n\n'
          'Use this before a supervisor demo so results start fresh.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _dailyScoreStore?.clearTodayScores();
      // Also clear the cached last_audio_score so fallback is 0, not 35
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_audio_score');
      await prefs.remove('latest_audio_score');
      await prefs.remove('latest_digital_score');
      await prefs.remove('latest_physical_score');

      setState(() {
        _audioScore = 0;
        _digitalScore = 0;
        _physicalScore = 0;
        _avgAudioScore = 0;
        _avgDigitalScore = 0;
        _avgPhysicalScore = 0;
        _overallAvgScore = 0;
        _collectionCount = 0;
        _latestRecommendation = null;
        _statusMessage = 'Fresh start — collecting scores...';
        _hasPlayedSoundThisCycle = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Fresh start! Collecting new scores now...'),
            backgroundColor: Colors.green,
          ),
        );
      }
      // Immediately start a new collection cycle
      await _scheduler.collectNow();
    }
  }

  /// View full recommendations screen
  void _viewRecommendations() {
    final avg = _dailyScoreStore?.getDailyAverage();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecommendationsScreen(
          audioScore: avg?['audio'] ?? _audioScore,
          digitalScore: avg?['digital'] ?? _digitalScore,
          physicalScore: avg?['physical'] ?? _physicalScore,
        ),
      ),
    );
  }

  
  // BUILD
  

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasScores = _audioScore > 0 || _digitalScore > 0 || _physicalScore > 0;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Stress Dashboard',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(
                Icons.person_outlined,
                color: AppColors.getTextColor(context),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const UserProfileScreen()),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: AppColors.getTextColor(context),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isInitializing
            ? _buildLoadingView()
            : SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status + Collection Count Card
                      _buildStatusCard(),
                      const SizedBox(height: 20),

                      // Feature 1: Offline banner — always visible when backend unreachable
                      if (!_isBackendOnline) ...[
                        _buildOfflineBanner(),
                        const SizedBox(height: 20),
                      ],

                      // Current Scores (latest snapshot) — only show when online
                      if (hasScores && _isBackendOnline) ...[
                        _buildSectionHeader('Current Scores'),
                        const SizedBox(height: 12),
                        _buildScoreCircles(),
                        const SizedBox(height: 24),
                      ],

                      // Daily Average Section
                      if (_collectionCount > 0) ...[
                        _buildSectionHeader(
                            'Daily Average ($_collectionCount collections)'),
                        const SizedBox(height: 12),
                        _buildDailyAverageCard(),
                        const SizedBox(height: 24),
                      ],

                      // Recommendation Card
                      if (_latestRecommendation != null) ...[
                        _buildSectionHeader('Today\'s Recommendation'),
                        const SizedBox(height: 12),
                        _buildRecommendationCard(),
                        const SizedBox(height: 24),
                      ],

                      // Action Buttons
                      _buildSectionHeader('Actions'),
                      const SizedBox(height: 12),
                      _buildActionButtons(),
                      const SizedBox(height: 24),

                      // Info Card
                      _buildInfoCard(isDark),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

 
  // WIDGET BUILDERS
  

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            _statusMessage,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.getSecondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Recording 10s audio sample...',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.getSecondaryTextColor(context).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userId,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 13,
                    color: _scheduler.isRunning
                        ? AppColors.success
                        : AppColors.getSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_collectionCount > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '$_collectionCount collected today',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.getTextColor(context),
        letterSpacing: 0.3,
      ),
    );
  }

 
  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.12),
        border: Border.all(color: Colors.amber.shade700, width: 1.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.amber.shade700, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please connect to internet',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Live scores are unavailable while offline.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCircles() {
    return SizedBox(
      height: 280,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            CircularProgressBar(
              key: ValueKey('audio_$_collectionCount'),
              progress: (_audioScore / 100).clamp(0.0, 1.0),
              score: _audioScore,
              label: 'Environment',
              icon: Icons.mic_none,
              size: 140,
            ),
            const SizedBox(width: 20),
            CircularProgressBar(
              key: ValueKey('digital_$_collectionCount'),
              progress: (_digitalScore / 100).clamp(0.0, 1.0),
              score: _digitalScore,
              label: 'Digital',
              icon: Icons.smartphone,
              size: 140,
            ),
            const SizedBox(width: 20),
            CircularProgressBar(
              key: ValueKey('physical_$_collectionCount'),
              progress: (_physicalScore / 100).clamp(0.0, 1.0),
              score: _physicalScore,
              label: 'Physical',
              icon: Icons.directions_run,
              size: 140,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyAverageCard() {
    final stressLevel = DailyScoreStore.getStressLevel(_overallAvgScore);
    final stressColor = Color(DailyScoreStore.getStressColor(_overallAvgScore));

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: stressColor.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall stress level header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stressColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Overall: $stressLevel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: stressColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$_overallAvgScore/100',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: stressColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Individual averages
            _buildAvgRow('Environment', _avgAudioScore),
            const SizedBox(height: 8),
            _buildAvgRow('Digital Habits', _avgDigitalScore),
            const SizedBox(height: 8),
            _buildAvgRow('Physical Activity', _avgPhysicalScore),
          ],
        ),
      ),
    );
  }

  Widget _buildAvgRow(String label, int score) {
    final color = Color(DailyScoreStore.getStressColor(score));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.getSecondaryTextColor(context),
          ),
        ),
        Row(
          children: [
            SizedBox(
              width: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (score / 100).clamp(0.0, 1.0),
                  backgroundColor: color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 30,
              child: Text(
                '$score',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecommendationCard() {
    final recs = _latestRecommendation?['recommendations'] as List<dynamic>?;
    if (recs == null || recs.isEmpty) return const SizedBox.shrink();

    final topRec = recs[0] as Map<String, dynamic>;
    final title = topRec['title'] as String? ?? 'Recommendation';
    final action = topRec['action'] as String? ?? '';
    final duration = topRec['duration'] as String? ?? '';
    final motivation = topRec['motivation'] as String? ?? '';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: AppColors.primary.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: _viewRecommendations,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getTextColor(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                action,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.getSecondaryTextColor(context),
                  height: 1.5,
                ),
              ),
              if (duration.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        size: 14,
                        color: AppColors.getSecondaryTextColor(context)),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ],
              if (motivation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  motivation,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.primary.withOpacity(0.8),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'View all recommendations →',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('View All Recommendations'),
            onPressed: _viewRecommendations,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.analytics_outlined, size: 18),
            label: const Text('Check Stress Now'),
            onPressed: _checkStressNow,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Quick Fresh Start'),
            onPressed: _resetDemoData,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Card(
      color: isDark
          ? AppColors.darkSurface.withOpacity(0.5)
          : AppColors.lightSurface.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How It Works',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextColor(context),
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoItem('Score collection', 'Every 3 hours + on app start'),
            const SizedBox(height: 8),
            _buildInfoItem('Daily average', 'Sum of all scores / count'),
            const SizedBox(height: 8),
            _buildInfoItem('Recommendations', 'Based on daily average'),
            const SizedBox(height: 8),
            _buildInfoItem('Notifications', 'After each collection cycle'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.getSecondaryTextColor(context),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.getTextColor(context),
          ),
        ),
      ],
    );
  }
}
