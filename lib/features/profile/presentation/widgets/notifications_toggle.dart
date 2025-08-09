import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/notification_service.dart';

/// A toggle widget for managing device notification permissions (device-local only)
class NotificationsToggle extends StatefulWidget {
  const NotificationsToggle({super.key});

  @override
  State<NotificationsToggle> createState() => _NotificationsToggleState();
}

class _NotificationsToggleState extends State<NotificationsToggle> with WidgetsBindingObserver {
  static final Logger _logger = Logger();
  bool _notificationsEnabled = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize notification service and check current permission status
    _initializeNotificationState();
    // Listen for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User returned to app, check current permission status
      _checkCurrentPermissionStatus();
    }
  }

  /// Initialize notification service and check current permission status
  Future<void> _initializeNotificationState() async {
    await NotificationService.initialize();
    await _checkCurrentPermissionStatus();
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  /// Check current device notification permission status
  Future<void> _checkCurrentPermissionStatus() async {
    try {
      final isEnabled = await NotificationService.areNotificationsEnabled();
      if (mounted && isEnabled != _notificationsEnabled) {
        setState(() => _notificationsEnabled = isEnabled);
      }
    } catch (e) {
      _logger.e('Error checking notification permission status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.notifications, color: AppConstants.textSecondary),
      title: Text(
        'Notifications',
        style: AppTextStyles.bodyMedium,
      ),
      trailing: _isInitialized
          ? Switch(
              value: _notificationsEnabled,
              onChanged: _handleNotificationToggle,
              activeColor: AppConstants.primaryColor,
            )
          : const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
      onTap: _isInitialized ? () => _handleNotificationToggle(!_notificationsEnabled) : null,
    );
  }

  /// Handle the notification toggle change (device-local only)
  Future<void> _handleNotificationToggle(bool enabled) async {
    HapticFeedback.lightImpact();

    try {
      if (enabled) {
        // User wants to enable notifications - request permission
        await _enableNotifications();
      } else {
        // User wants to disable notifications - cancel all notifications
        await _disableNotifications();
      }
    } catch (e) {
      _logger.e('Error handling notification toggle: $e');
      // Refresh current status in case something went wrong
      await _checkCurrentPermissionStatus();
    }
  }

  /// Enable notifications by requesting permission
  Future<void> _enableNotifications() async {
    try {
      _logger.d('Requesting notification permission...');

      // Request notification permission
      final permissionResult = await NotificationService.requestNotificationPermission();

      if (permissionResult.isGranted) {
        // Permission granted - update local state and show test notification
        if (mounted) {
          setState(() => _notificationsEnabled = true);
        }
        await NotificationService.showTestNotification();
      } else if (permissionResult.isPermanentlyDenied) {
        // Permission permanently denied - open settings directly
        await NotificationService.openNotificationSettings();
      } else {
        // Permission denied - do nothing, user can try again
        _logger.d('Notification permission denied');
      }
    } catch (e) {
      _logger.e('Error enabling notifications: $e');
      rethrow;
    }
  }

  /// Disable notifications by cancelling all notifications
  Future<void> _disableNotifications() async {
    try {
      _logger.d('Disabling notifications...');
      
      // Cancel all pending notifications
      await NotificationService.cancelAllNotifications();
      
      // Update local state
      if (mounted) {
        setState(() => _notificationsEnabled = false);
      }
    } catch (e) {
      _logger.e('Error disabling notifications: $e');
      rethrow;
    }
  }
}
