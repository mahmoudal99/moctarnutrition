import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service to handle notification permissions and local notifications
class NotificationService {
  static final Logger _logger = Logger();
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;
  static int _nextNotificationId = 1000; // Start from 1000 to avoid conflicts

  /// Notification ID constants for different types
  static const int TEST_NOTIFICATION_ID = 1;
  static const int WEEKLY_CHECKIN_REMINDER_ID = 2;
  static const int WORKOUT_REMINDER_ID = 3;
  static const int MEAL_REMINDER_ID = 4;
  static const int PROGRESS_REMINDER_ID = 5;

  /// Generate a unique notification ID
  static int _generateNotificationId() {
    return _nextNotificationId++;
  }

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone data
      tz.initializeTimeZones();
      
      // Initialize local notifications plugin
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
      _logger.i('NotificationService initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize NotificationService: $e');
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    _logger.d('Notification tapped: ${response.payload}');
    // Handle notification tap logic here
  }

  /// Check if notification permissions are granted
  static Future<bool> areNotificationsEnabled() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // For iOS, check through flutter_local_notifications directly
        final iosImpl = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        
        if (iosImpl == null) {
          _logger.d('iOS implementation not available');
          return false;
        }

        // Use the same method as in the permission request to check permissions
        try {
          final bool? result = await iosImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          _logger.d('iOS notification permission check result: $result');
          return result ?? false;
        } catch (e) {
          _logger.e('Error checking iOS notification permissions: $e');
          return false;
        }
      } else {
        // For Android, use permission_handler
        final status = await Permission.notification.status;
        final isGranted = status == PermissionStatus.granted;
        _logger.d('Android notification permission: status=$status, isGranted=$isGranted');
        return isGranted;
      }
    } catch (e) {
      _logger.e('Error checking notification permission: $e');
      return false;
    }
  }

  /// Request notification permissions
  static Future<NotificationPermissionResult>
      requestNotificationPermission() async {
    try {
      _logger.d('Requesting notification permission...');

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // For iOS, request permission through the local notifications plugin
        final bool? result = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );

        if (result == true) {
          _logger.i('iOS notification permission granted');
          return NotificationPermissionResult.granted;
        } else {
          _logger.w('iOS notification permission denied');
          return NotificationPermissionResult.denied;
        }
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        // For Android, use permission_handler
        final status = await Permission.notification.request();

        switch (status) {
          case PermissionStatus.granted:
            _logger.i('Android notification permission granted');
            return NotificationPermissionResult.granted;
          case PermissionStatus.denied:
            _logger.w('Android notification permission denied');
            return NotificationPermissionResult.denied;
          case PermissionStatus.permanentlyDenied:
            _logger.w('Android notification permission permanently denied');
            return NotificationPermissionResult.permanentlyDenied;
          case PermissionStatus.restricted:
            _logger.w('Android notification permission restricted');
            return NotificationPermissionResult.restricted;
          default:
            _logger
                .w('Android notification permission unknown status: $status');
            return NotificationPermissionResult.denied;
        }
      } else {
        // For other platforms (Web, Desktop), assume granted
        _logger.i(
            'Platform ${defaultTargetPlatform.name} - assuming notifications are supported');
        return NotificationPermissionResult.granted;
      }
    } catch (e) {
      _logger.e('Error requesting notification permission: $e');
      return NotificationPermissionResult.error;
    }
  }

  /// Open app settings for notification permissions
  static Future<bool> openNotificationSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      _logger.e('Error opening notification settings: $e');
      return false;
    }
  }

  /// Show a test notification (requires permission)
  static Future<void> showTestNotification() async {
    try {
      if (!await areNotificationsEnabled()) {
        _logger.w('Cannot show notification: permission not granted');
        return;
      }

      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'champions_gym_general',
        'General Notifications',
        channelDescription: 'General notifications for Champions Gym app',
        importance: Importance.max,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        TEST_NOTIFICATION_ID,
        'Champions Gym',
        'Notifications are now enabled! 💪',
        notificationDetails,
      );

      _logger.i('Test notification sent');
    } catch (e) {
      _logger.e('Error showing test notification: $e');
    }
  }

  /// Schedule weekly check-in reminders for Sundays at 9 AM
  static Future<void> scheduleWeeklyCheckinReminder() async {
    try {
      if (!await areNotificationsEnabled()) {
        _logger.w('Cannot schedule reminder: permission not granted');
        return;
      }

      // Cancel any existing weekly reminders first
      await cancelWeeklyCheckinReminder();

      // Get next Sunday at 9 AM
      final nextSunday = _getNextSunday9AM();
      
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'weekly_checkin',
        'Weekly Check-in Reminders',
        channelDescription: 'Weekly reminders to complete check-in',
        importance: Importance.max,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        WEEKLY_CHECKIN_REMINDER_ID,
        'Weekly Check-in Reminder 📊',
        'Don\'t forget to complete your weekly check-in! Track your progress and stay motivated 💪',
        nextSunday,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );

      _logger.i('Weekly check-in reminder scheduled for: $nextSunday');
    } catch (e) {
      _logger.e('Error scheduling weekly reminder: $e');
    }
  }

  /// Cancel weekly check-in reminder
  static Future<void> cancelWeeklyCheckinReminder() async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(WEEKLY_CHECKIN_REMINDER_ID);
      _logger.i('Weekly check-in reminder cancelled');
    } catch (e) {
      _logger.e('Error cancelling weekly reminder: $e');
    }
  }

  /// Schedule workout reminder
  static Future<void> scheduleWorkoutReminder({
    required DateTime scheduledTime,
    String title = 'Workout Reminder 💪',
    String body = 'Time for your workout! Stay consistent and crush your goals!',
  }) async {
    try {
      if (!await areNotificationsEnabled()) {
        _logger.w('Cannot schedule workout reminder: permission not granted');
        return;
      }

      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'workout_reminders',
        'Workout Reminders',
        channelDescription: 'Reminders for scheduled workouts',
        importance: Importance.max,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _generateNotificationId(),
        title,
        body,
        tzScheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      _logger.i('Workout reminder scheduled for: $scheduledTime');
    } catch (e) {
      _logger.e('Error scheduling workout reminder: $e');
    }
  }

  /// Schedule meal reminder
  static Future<void> scheduleMealReminder({
    required DateTime scheduledTime,
    String mealType = 'meal',
    String title = 'Meal Reminder 🍽️',
    String body = 'Time to eat! Don\'t forget to log your meal.',
  }) async {
    try {
      if (!await areNotificationsEnabled()) {
        _logger.w('Cannot schedule meal reminder: permission not granted');
        return;
      }

      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'meal_reminders',
        'Meal Reminders',
        channelDescription: 'Reminders for meal times',
        importance: Importance.max,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _generateNotificationId(),
        title,
        body,
        tzScheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      _logger.i('Meal reminder scheduled for: $scheduledTime');
    } catch (e) {
      _logger.e('Error scheduling meal reminder: $e');
    }
  }

  /// Cancel specific notification by ID
  static Future<void> cancelNotification(int notificationId) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(notificationId);
      _logger.i('Notification cancelled: $notificationId');
    } catch (e) {
      _logger.e('Error cancelling notification $notificationId: $e');
    }
  }

  /// Cancel all notifications of a specific type
  static Future<void> cancelNotificationType(int notificationTypeId) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(notificationTypeId);
      _logger.i('Notification type cancelled: $notificationTypeId');
    } catch (e) {
      _logger.e('Error cancelling notification type $notificationTypeId: $e');
    }
  }

  /// Get next Sunday at 9 AM in local timezone
  static tz.TZDateTime _getNextSunday9AM() {
    final now = tz.TZDateTime.now(tz.local);
    final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
    
    var nextSunday = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + daysUntilSunday,
      9, // 9 AM
      0, // 0 minutes
    );

    // If it's already past 9 AM on Sunday, schedule for next week
    if (nextSunday.isBefore(now)) {
      nextSunday = nextSunday.add(const Duration(days: 7));
    }

    return nextSunday;
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      _logger.i('All notifications cancelled');
    } catch (e) {
      _logger.e('Error cancelling notifications: $e');
    }
  }
}

/// Result of notification permission request
enum NotificationPermissionResult {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  error,
}

/// Extension to provide user-friendly messages for permission results
extension NotificationPermissionResultExtension
    on NotificationPermissionResult {
  String get message {
    switch (this) {
      case NotificationPermissionResult.granted:
        return 'Notifications enabled successfully!';
      case NotificationPermissionResult.denied:
        return 'Notification permission was denied. You can enable it anytime in settings.';
      case NotificationPermissionResult.permanentlyDenied:
        return 'Notification permission was permanently denied. Please enable it in app settings.';
      case NotificationPermissionResult.restricted:
        return 'Notification permission is restricted on this device.';
      case NotificationPermissionResult.error:
        return 'An error occurred while requesting notification permission.';
    }
  }

  bool get isGranted => this == NotificationPermissionResult.granted;

  bool get isPermanentlyDenied =>
      this == NotificationPermissionResult.permanentlyDenied;
}
