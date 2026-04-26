import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:workmanager/workmanager.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  /// Initialize the notification service
  Future<void> initNotifications() async {
    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    print('[NotificationService] Initialized successfully');
  }

  /// Callback for notification tap
  static void _onNotificationTap(NotificationResponse details) {
    print('[NotificationService] Notification tapped: ${details.payload}');
    // Handle notification navigation
    // You can navigate to recommendations screen here
  }

  /// Show a simple notification
  Future<void> showNotification({
    required String title,
    required String body,
    String payload = '',
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'recommendations_channel',
      'Stress Recommendations',
      channelDescription: 'Notifications for stress management recommendations',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  /// Show notifications with recommendations
  Future<void> showRecommendationNotification({
    required String title,
    required String recommandation,
    required String duration,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'recommendations_channel',
      'Stress Recommendations',
      channelDescription: 'Notifications for stress management recommendations',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      enableVibration: true,
      playSound: true,
      showWhen: true,
      subText: duration,
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      1,
      title,
      recommandation,
      platformChannelSpecifics,
      payload: 'recommendations',
    );
  }

  /// Schedule periodic notifications every 3 hours
  Future<void> schedulePeriodicRecommendations() async {
    print(
        '[NotificationService] Scheduling periodic recommendations every 3 hours');

    try {
      // Initialize workmanager
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

      // Schedule periodic task every 3 hours (180 minutes)
      await Workmanager().registerPeriodicTask(
        'fetch_recommendations',
        'fetchRecommendationsTask',
        frequency: const Duration(hours: 3),
        initialDelay: const Duration(minutes: 5),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 15),
      );

      print('[NotificationService] Periodic task scheduled successfully');
    } catch (e) {
      print('[NotificationService] Error scheduling periodic task: $e');
    }
  }

  /// Cancel periodic notifications
  Future<void> cancelPeriodicRecommendations() async {
    try {
      await Workmanager().cancelByTag('fetch_recommendations');
      print('[NotificationService] Periodic task cancelled');
    } catch (e) {
      print('[NotificationService] Error cancelling periodic task: $e');
    }
  }

  /// Get recommendations from backend
  Future<Map<String, dynamic>> fetchRecommendationsFromBackend({
    required int audioScore,
    required int digitalScore,
    required int physicalScore,
  }) async {
    try {
      // Will be called from backend_service.dart
      // Returns recommendations data
      return {
        'status': 'pending',
        'message': 'Fetch recommendations from backend',
        'scores': {
          'audio': audioScore,
          'digital': digitalScore,
          'physical': physicalScore,
        }
      };
    } catch (e) {
      print('[NotificationService] Error fetching recommendations: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }
}

/// Callback dispatcher for background tasks (called when app is in background)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == 'fetchRecommendationsTask') {
        print('[Workmanager] Executing background task: $task');

        // Show a generic notification every 3 hours
        final notificationService = NotificationService();

        // You can fetch actual recommendations here
        await notificationService.showRecommendationNotification(
          title: 'Time for stress management!',
          recommandation:
              'It\'s been 3 hours! Check your personalized stress management recommendations.',
          duration: '3-hour interval',
        );

        return true;
      }
      return false;
    } catch (e) {
      print('[Workmanager] Error in background task: $e');
      return false;
    }
  });
}
