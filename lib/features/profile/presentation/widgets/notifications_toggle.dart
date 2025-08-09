import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const String _notificationPrefKey = 'notifications_enabled';
  
  bool _notificationsEnabled = false;
  bool _isInitialized = false;
  DateTime? _lastPermissionGrantTime;

  @override
  void initState() {
    super.initState();
    // Initialize notification service and load saved preference
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
      _logger.d('App resumed, current toggle state: $_notificationsEnabled');
      
      // Don't check permission status if we just granted permission recently
      // This prevents the permission_handler delay from incorrectly setting toggle to false
      if (_lastPermissionGrantTime != null) {
        final timeSinceGrant = DateTime.now().difference(_lastPermissionGrantTime!);
        if (timeSinceGrant.inSeconds < 5) {
          _logger.d('Skipping permission check - recently granted permission ${timeSinceGrant.inSeconds}s ago');
          return;
        }
      }
      
      // Add a small delay to allow system to update permission status
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _checkCurrentPermissionStatus();
        }
      });
    }
  }

  /// Initialize notification service and load saved preference
  Future<void> _initializeNotificationState() async {
    await NotificationService.initialize();
    await _loadSavedPreference();
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  /// Load saved notification preference from SharedPreferences
  Future<void> _loadSavedPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedValue = prefs.getBool(_notificationPrefKey);
      
      if (savedValue != null) {
        _logger.d('Loaded saved notification preference: $savedValue');
        // Only update if we have a saved preference and it's different from current state
        if (mounted && savedValue != _notificationsEnabled) {
          setState(() => _notificationsEnabled = savedValue);
        }
      } else {
        _logger.d('No saved notification preference found, defaulting to false');
      }
    } catch (e) {
      _logger.e('Error loading notification preference: $e');
    }
  }

  /// Save notification preference to SharedPreferences
  Future<void> _savePreference(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationPrefKey, enabled);
      _logger.d('Saved notification preference: $enabled');
    } catch (e) {
      _logger.e('Error saving notification preference: $e');
    }
  }

  /// Check current device notification permission status (only when user interacts)
  Future<void> _checkCurrentPermissionStatus() async {
    try {
      final isEnabled = await NotificationService.areNotificationsEnabled();
      _logger.d('Permission check: isEnabled=$isEnabled, currentToggleState=$_notificationsEnabled');
      
      if (mounted && isEnabled != _notificationsEnabled) {
        _logger.d('Updating toggle state from $_notificationsEnabled to $isEnabled');
        setState(() => _notificationsEnabled = isEnabled);
        // Save the new state
        await _savePreference(isEnabled);
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
      subtitle: Text(
        'Allow app to send notifications and alerts',
        style: AppTextStyles.caption.copyWith(
          color: AppConstants.textTertiary,
        ),
      ),
      trailing: _isInitialized
          ? Switch(
              value: _notificationsEnabled,
              onChanged: _handleNotificationToggle,
              activeColor: AppConstants.primaryColor,
            )
          : Switch(
              value: false, // Show as off by default
              onChanged: null, // Disabled until initialized
              activeColor: AppConstants.primaryColor,
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
      // Only refresh status if there was an error
      await _checkCurrentPermissionStatus();
    }
  }

  /// Enable notifications by requesting permission
  Future<void> _enableNotifications() async {
    try {
      _logger.d('Requesting notification permission...');

      // Request notification permission
      final permissionResult = await NotificationService.requestNotificationPermission();
      _logger.d('Permission result: $permissionResult');

      if (permissionResult.isGranted) {
        // Permission granted - record the time and update local state
        _lastPermissionGrantTime = DateTime.now();
        _logger.d('Permission granted! Setting toggle to true');
        if (mounted) {
          setState(() => _notificationsEnabled = true);
        }
        // Save the preference
        await _savePreference(true);
        _logger.d('Toggle state after setting: $_notificationsEnabled');
        await NotificationService.showTestNotification();
      } else if (permissionResult.isPermanentlyDenied) {
        // Permission permanently denied - open settings directly
        _logger.d('Permission permanently denied');
        await NotificationService.openNotificationSettings();
        // Keep toggle off since permission was denied
        if (mounted) {
          setState(() => _notificationsEnabled = false);
        }
        await _savePreference(false);
      } else {
        // Permission denied - revert toggle to off
        _logger.d('Notification permission denied');
        if (mounted) {
          setState(() => _notificationsEnabled = false);
        }
        await _savePreference(false);
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
      
      // Clear the grant time and update local state
      _lastPermissionGrantTime = null;
      if (mounted) {
        setState(() => _notificationsEnabled = false);
      }
      // Save the preference
      await _savePreference(false);
    } catch (e) {
      _logger.e('Error disabling notifications: $e');
      rethrow;
    }
  }
}
