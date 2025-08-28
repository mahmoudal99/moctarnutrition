import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/notification_service.dart';

/// A toggle widget for managing device notification permissions
class NotificationsToggle extends StatefulWidget {
  const NotificationsToggle({super.key});

  @override
  State<NotificationsToggle> createState() => _NotificationsToggleState();
}

class _NotificationsToggleState extends State<NotificationsToggle> {
  static final _logger = AppLogger.instance;

  bool _notificationsEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissionStatus();
  }

  /// Check current device notification permission status
  Future<void> _checkCurrentPermissionStatus() async {
    try {
      await NotificationService.initialize();
      final isEnabled = await NotificationService.areNotificationsEnabled();
      if (mounted) {
        setState(() => _notificationsEnabled = isEnabled);
      }
    } catch (e) {
      _logger.e('Error checking notification permission status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading:
          const Icon(Icons.notifications, color: AppConstants.textSecondary),
      title: Text(
        'Notifications',
        style: AppTextStyles.bodyMedium,
      ),
      subtitle: Text(
        'Allow app to send notifications and alerts',
        style: AppTextStyles.caption.copyWith(
          color: AppConstants.textTertiary,
        ),
      ),
      trailing: Switch(
        value: _notificationsEnabled,
        onChanged: _isLoading ? null : _handleNotificationToggle,
        activeColor: AppConstants.primaryColor,
      ),
      onTap: _isLoading
          ? null
          : () => _handleNotificationToggle(!_notificationsEnabled),
    );
  }

  /// Handle the notification toggle change
  Future<void> _handleNotificationToggle(bool enabled) async {
    HapticFeedback.lightImpact();

    setState(() => _isLoading = true);

    try {
      if (enabled) {
        // User wants to enable notifications - request permission
        final permissionResult =
            await NotificationService.requestNotificationPermission();

        if (permissionResult.isGranted) {
          setState(() => _notificationsEnabled = true);
          await NotificationService.showTestNotification();
        } else {
          setState(() => _notificationsEnabled = false);
        }
      } else {
        // User wants to disable notifications - cancel all notifications
        await NotificationService.cancelAllNotifications();
        setState(() => _notificationsEnabled = false);
      }
    } catch (e) {
      _logger.e('Error handling notification toggle: $e');
      // Revert to previous state on error
      setState(() => _notificationsEnabled = !enabled);
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
