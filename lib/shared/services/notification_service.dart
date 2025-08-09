import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

/// Service to handle notification permissions and local notifications
class NotificationService {
  static final Logger _logger = Logger();
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
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
        // For iOS, we'll use a simple approach - try to get the implementation
        // and assume if we can get it, basic notifications are possible
        final iosImpl = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();

        if (iosImpl == null) return false;

        // Since checkPermissions API seems to have changed, let's use the
        // permission_handler for iOS as well for consistency
        final status = await Permission.notification.status;
        return status == PermissionStatus.granted;
      } else {
        // For Android, use permission_handler
        final status = await Permission.notification.status;
        return status == PermissionStatus.granted;
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
        0,
        'Champions Gym',
        'Notifications are now enabled! 💪',
        notificationDetails,
      );

      _logger.i('Test notification sent');
    } catch (e) {
      _logger.e('Error showing test notification: $e');
    }
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
