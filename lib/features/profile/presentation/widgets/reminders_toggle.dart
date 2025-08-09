import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/notification_service.dart';

/// A toggle widget for managing weekly check-in reminders
class RemindersToggle extends StatefulWidget {
  const RemindersToggle({super.key});

  @override
  State<RemindersToggle> createState() => _RemindersToggleState();
}

class _RemindersToggleState extends State<RemindersToggle> {
  static final Logger _logger = Logger();
  static const String _remindersPrefKey = 'reminders_enabled';
  
  bool _remindersEnabled = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPreference();
  }

  /// Load saved reminders preference from SharedPreferences
  Future<void> _loadSavedPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedValue = prefs.getBool(_remindersPrefKey) ?? false;
      
      _logger.d('Loaded saved reminders preference: $savedValue');
      if (mounted) {
        setState(() {
          _remindersEnabled = savedValue;
          _isInitialized = true;
        });
      }
    } catch (e) {
      _logger.e('Error loading reminders preference: $e');
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  /// Save reminders preference to SharedPreferences
  Future<void> _savePreference(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_remindersPrefKey, enabled);
      _logger.d('Saved reminders preference: $enabled');
    } catch (e) {
      _logger.e('Error saving reminders preference: $e');
    }
  }

  /// Handle reminder toggle changes
  Future<void> _handleReminderToggle(bool enabled) async {
    HapticFeedback.lightImpact();
    
    try {
      if (enabled) {
        await _enableReminders();
      } else {
        await _disableReminders();
      }
    } catch (e) {
      _logger.e('Error handling reminders toggle: $e');
      // Revert toggle state on error
      if (mounted) {
        setState(() => _remindersEnabled = !enabled);
      }
    }
  }

  /// Enable weekly check-in reminders
  Future<void> _enableReminders() async {
    try {
      _logger.d('Checking notification permissions for reminders...');
      
      // Check if notification permissions are granted first with retry logic
      bool hasPermission = await NotificationService.areNotificationsEnabled();
      _logger.d('Permission check result: $hasPermission');
      
      // If permission check fails, try again after a short delay (permission_handler delay issue)
      if (!hasPermission) {
        _logger.d('First permission check failed, retrying after delay...');
        await Future.delayed(const Duration(milliseconds: 1000));
        hasPermission = await NotificationService.areNotificationsEnabled();
        _logger.d('Permission check retry result: $hasPermission');
      }
      
      if (!hasPermission) {
        _logger.w('Cannot enable reminders: notification permission not granted');
        if (mounted) {
          setState(() => _remindersEnabled = false);
        }
        await _savePreference(false);
        return;
      }

      _logger.d('Permissions granted, scheduling weekly reminders...');
      // Schedule weekly reminders
      await NotificationService.scheduleWeeklyCheckinReminder();
      
      if (mounted) {
        setState(() => _remindersEnabled = true);
      }
      await _savePreference(true);
      
      _logger.i('Weekly check-in reminders enabled successfully');
    } catch (e) {
      _logger.e('Error enabling reminders: $e');
      // If scheduling failed, keep toggle off
      if (mounted) {
        setState(() => _remindersEnabled = false);
      }
      await _savePreference(false);
      rethrow;
    }
  }

  /// Disable weekly check-in reminders
  Future<void> _disableReminders() async {
    try {
      // Cancel weekly reminders
      await NotificationService.cancelWeeklyCheckinReminder();
      
      if (mounted) {
        setState(() => _remindersEnabled = false);
      }
      await _savePreference(false);
      
      _logger.i('Weekly check-in reminders disabled');
    } catch (e) {
      _logger.e('Error disabling reminders: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.alarm, color: AppConstants.textSecondary),
      title: Text(
        'Reminders',
        style: AppTextStyles.bodyMedium,
      ),
      subtitle: Text(
        'Weekly check-in reminders (Sundays at 9 AM)',
        style: AppTextStyles.caption.copyWith(
          color: AppConstants.textTertiary,
        ),
      ),
      trailing: _isInitialized
          ? Switch(
              value: _remindersEnabled,
              onChanged: _handleReminderToggle,
              activeColor: AppConstants.primaryColor,
            )
          : Switch(
              value: false, // Show as off by default
              onChanged: null, // Disabled until initialized
              activeColor: AppConstants.primaryColor,
            ),
      onTap: _isInitialized ? () => _handleReminderToggle(!_remindersEnabled) : null,
    );
  }
}