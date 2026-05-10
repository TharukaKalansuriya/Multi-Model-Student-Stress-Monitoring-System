import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'backend_service.dart';

/// Physical Activity Service
///
/// Collects accelerometer and gyroscope sensor data from the device
/// and sends it to the backend for ML-based movement analysis.
///
/// Uses: Random Forest model trained on UCI HAR Dataset
/// Returns: Activity type and movement-based stress score (0-100°)
///
/// Supported Activities:
/// - WALKING
/// - WALKING_UPSTAIRS
/// - WALKING_DOWNSTAIRS
/// - SITTING
/// - STANDING
/// - LAYING
///
/// NOW uses BackendService.getBackendUrl() for centralized URL management.
class PhysicalActivityService {
  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  double _currentAccX = 0.0;
  double _currentAccY = 9.8;
  double _currentAccZ = 0.0;
  
  double _currentGyroX = 0.0;
  double _currentGyroY = 0.0;
  double _currentGyroZ = 0.0;

  PhysicalActivityService() {
    _initSensors();
  }

  void _initSensors() {
    try {
      _accSub = accelerometerEventStream().listen((AccelerometerEvent event) {
        _currentAccX = event.x;
        _currentAccY = event.y;
        _currentAccZ = event.z;
      });

      _gyroSub = gyroscopeEventStream().listen((GyroscopeEvent event) {
        _currentGyroX = event.x;
        _currentGyroY = event.y;
        _currentGyroZ = event.z;
      });
    } catch (e) {
      print('[PhysicalActivity] Error initializing hardware sensors: $e');
    }
  }

  void dispose() {
    _accSub?.cancel();
    _gyroSub?.cancel();
  }

  /// Analyze current movement/activity pattern
  ///
  /// This would normally collect live sensor data, but for demo purposes
  /// we simulate sensor readings based on common daily patterns.
  /// On failure, returns a local fallback instead of throwing.
  Future<Map<String, dynamic>> analyzeMovement(
    String userId, {
    double? accX,
    double? accY,
    double? accZ,
    double? gyroX,
    double? gyroY,
    double? gyroZ,
    List<String>? activityHistory,
    int sittingDurationMinutes = 0,
  }) async {
    try {
      final backendUrl = BackendService.getBackendUrl();

      print('\n[PhysicalActivity] Preparing movement analysis...');
      print('  User: $userId');
      print('  Backend URL: $backendUrl');

      // Build request body
      final body = {
        'user_id': userId,
        'acc_x': accX ?? _currentAccX,
        'acc_y': accY ?? _currentAccY,
        'acc_z': accZ ?? _currentAccZ,
        'gyro_x': gyroX ?? _currentGyroX,
        'gyro_y': gyroY ?? _currentGyroY,
        'gyro_z': gyroZ ?? _currentGyroZ,
        'activity_history': activityHistory ?? _getSimulatedActivityHistory(),
        'sitting_duration_minutes': sittingDurationMinutes,
      };

      print('[PhysicalActivity] Sensor readings:');
      print(
          '  Accelerometer: (${body['acc_x']}, ${body['acc_y']}, ${body['acc_z']})');
      print(
          '  Gyroscope: (${body['gyro_x']}, ${body['gyro_y']}, ${body['gyro_z']})');
      print('  Activity history: ${body['activity_history']}');

      print(
          '[PhysicalActivity] Sending to backend: $backendUrl/analyze-movement');

      // Send to backend
      final response = await http
          .post(
            Uri.parse('$backendUrl/analyze-movement'),
            headers: BackendService.getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Movement analysis timeout'),
          );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        print(
            '[PhysicalActivity] ✓ Analysis complete: ${result['activity']} (${result['physical_stress_score']}°)');
        return result;
      } else {
        print('[PhysicalActivity] ❌ Backend error: ${response.statusCode}');
        print('[PhysicalActivity] Using local fallback...');
        return _calculateLocalFallback(
            activityHistory ?? _getSimulatedActivityHistory());
      }
    } on Exception catch (e) {
      print('[PhysicalActivity] ❌ ERROR: $e');
      print('[PhysicalActivity] Using local fallback...');
      return _calculateLocalFallback(
          activityHistory ?? _getSimulatedActivityHistory());
    }
  }

  /// Calculate local fallback when backend is unreachable
  Map<String, dynamic> _calculateLocalFallback(List<String> activityHistory) {
    // Determine most common activity
    final activityCounts = <String, int>{};
    for (final activity in activityHistory) {
      activityCounts[activity] = (activityCounts[activity] ?? 0) + 1;
    }

    String primaryActivity = 'SITTING';
    int maxCount = 0;
    activityCounts.forEach((activity, count) {
      if (count > maxCount) {
        maxCount = count;
        primaryActivity = activity;
      }
    });

    // Calculate local stress score
    final activityScore = activityStressScores[primaryActivity] ?? 30;
    final sedentaryActivities = activityHistory
        .where((a) => a == 'SITTING' || a == 'LAYING')
        .length;
    final sedentaryRatio = sedentaryActivities / activityHistory.length;

    final physicalStressScore =
        (activityScore * 0.6 + sedentaryRatio * 100 * 0.4).round().clamp(0, 100);
    final movementIntensity = (100 - sedentaryRatio * 100).round().clamp(0, 100);

    print('[PhysicalActivity] Local fallback: $primaryActivity, score=$physicalStressScore');

    return {
      'status': 'Fallback',
      'activity': primaryActivity,
      'activity_score': activityScore,
      'movement_intensity': movementIntensity,
      'pattern_regularity': 50,
      'physical_stress_score': physicalStressScore,
      'stress_level': physicalStressScore < 35
          ? 'Low'
          : physicalStressScore < 65
              ? 'Moderate'
              : 'High',
      'components': {
        'activity_stress': activityScore,
        'sedentary_ratio': (sedentaryRatio * 100).round(),
      },
      'recommendations': [],
      'model': 'Local Fallback (UCI HAR-based rules)',
    };
  }

  // Simulated sensor data for testing
  // Use sensors_plus or device_sensors package

  double _getSimulatedAccX() => 0.1 + (DateTime.now().microsecond % 100) / 100;
  double _getSimulatedAccY() => 9.8 + (DateTime.now().second % 10) / 10;
  double _getSimulatedAccZ() => 0.2 + (DateTime.now().millisecond % 50) / 100;

  double _getSimulatedGyroX() =>
      0.01 + (DateTime.now().microsecond % 10) / 1000;
  double _getSimulatedGyroY() =>
      0.02 + (DateTime.now().millisecond % 20) / 1000;
  double _getSimulatedGyroZ() => 0.01 + (DateTime.now().second % 5) / 1000;

  List<String> _getSimulatedActivityHistory() {
    final hour = DateTime.now().hour;

    // Simulate realistic activity patterns based on time of day
    if (hour >= 6 && hour < 9) {
      return ['WALKING', 'WALKING', 'STANDING', 'WALKING']; // Morning commute
    } else if (hour >= 9 && hour < 12) {
      return ['SITTING', 'SITTING', 'STANDING', 'SITTING']; // Morning classes
    } else if (hour >= 12 && hour < 14) {
      return ['WALKING', 'STANDING', 'SITTING', 'SITTING']; // Lunch break
    } else if (hour >= 14 && hour < 17) {
      return ['SITTING', 'SITTING', 'STANDING', 'SITTING']; // Afternoon classes
    } else if (hour >= 17 && hour < 20) {
      return [
        'WALKING',
        'WALKING_DOWNSTAIRS',
        'STANDING',
        'WALKING'
      ]; // Evening commute
    } else {
      return [
        'LAYING',
        'LAYING',
        'STANDING',
        'LAYING'
      ]; // Night: mostly resting
    }
  }

  /// Get activity stress mapping (for local reference)
  static const Map<String, int> activityStressScores = {
    'WALKING': 35,
    'WALKING_UPSTAIRS': 45,
    'WALKING_DOWNSTAIRS': 40,
    'SITTING': 25,
    'STANDING': 30,
    'LAYING': 15,
  };

  /// Describe activity for UI display
  static String describeActivity(String activity) {
    switch (activity) {
      case 'WALKING':
        return 'Walking';
      case 'WALKING_UPSTAIRS':
        return 'Climbing stairs';
      case 'WALKING_DOWNSTAIRS':
        return 'Descending stairs';
      case 'SITTING':
        return 'Sitting';
      case 'STANDING':
        return 'Standing';
      case 'LAYING':
        return 'Laying/Resting';
      default:
        return 'Unknown activity';
    }
  }

  /// Get activity emoji for UI
  static String getActivityEmoji(String activity) {
    switch (activity) {
      case 'WALKING':
        return '🚶';
      case 'WALKING_UPSTAIRS':
        return '⬆️';
      case 'WALKING_DOWNSTAIRS':
        return '⬇️';
      case 'SITTING':
        return '🪑';
      case 'STANDING':
        return '🧍';
      case 'LAYING':
        return '🛏️';
      default:
        return '❓';
    }
  }
}
