import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/notification_service.dart';
import '../../../../shared/services/logging_service.dart';

/// A toggle widget for managing device notification permissions
class NotificationsToggle extends StatefulWidget {
  const NotificationsToggle({super.key});

  @override
  State<NotificationsToggle> createState() => _NotificationsToggleState();
}

class _NotificationsToggleState extends State<NotificationsToggle> {
  // Initialize with cached value to prevent flicker
  late bool _notificationsEnabled;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with cached value synchronously to prevent flicker
    _notificationsEnabled = NotificationService.getCachedNotificationPermission() ?? false;
    _initializeNotificationState();
  }

  /// Initialize notification state and verify current status
  void _initializeNotificationState() {
    // Load and verify current permission status
    _loadCachedPermissionStatus();
  }

  /// Load cached permission status from storage to prevent UI flicker
  Future<void> _loadCachedPermissionStatus() async {
    try {
      // Initialize the service first
      await NotificationService.initialize();
      
      // Get the permission status (this will use cache if available)
      final isEnabled = await NotificationService.areNotificationsEnabled();
      if (mounted) {
        setState(() => _notificationsEnabled = isEnabled);
      }
    } catch (e) {
      LoggingService.instance.e('Error loading cached permission status: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading:
          const Icon(Icons.notifications, color: Colors.black, size: 16,),
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
      LoggingService.instance.e('Error handling notification toggle: $e');
      // Revert to previous state on error
      setState(() => _notificationsEnabled = !enabled);
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
