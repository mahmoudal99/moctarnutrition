import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/notification_service.dart';
import '../../../../shared/providers/workout_provider.dart';

class WorkoutNotificationSettingsScreen extends StatefulWidget {
  const WorkoutNotificationSettingsScreen({super.key});

  @override
  State<WorkoutNotificationSettingsScreen> createState() =>
      _WorkoutNotificationSettingsScreenState();
}

class _WorkoutNotificationSettingsScreenState
    extends State<WorkoutNotificationSettingsScreen> {
  static final _logger = Logger();

  late UserModel _user;
  late UserPreferences _preferences;

  // Notification settings
  late bool _workoutNotificationsEnabled;
  late TimeOfDay _notificationTime;

  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _user = authProvider.userModel!;
    _preferences = _user.preferences;

    // Initialize notification settings
    _workoutNotificationsEnabled = _preferences.workoutNotificationsEnabled;

    // Parse notification time from string format "HH:mm"
    if (_preferences.workoutNotificationTime != null) {
      final timeParts = _preferences.workoutNotificationTime!.split(':');
      _notificationTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    } else {
      _notificationTime = const TimeOfDay(hour: 9, minute: 0);
    }
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppConstants.surfaceColor,
              hourMinuteTextColor: AppConstants.textPrimary,
              hourMinuteColor: AppConstants.primaryColor.withOpacity(0.1),
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              dialBackgroundColor: AppConstants.surfaceColor,
              dialHandColor: AppConstants.primaryColor,
              dialTextColor: AppConstants.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _notificationTime) {
      setState(() {
        _notificationTime = picked;
        _markAsChanged();
      });
    }
  }

  Future<void> _toggleWorkoutNotifications(bool enabled) async {
    HapticFeedback.lightImpact();

    setState(() {
      _workoutNotificationsEnabled = enabled;
      _markAsChanged();
    });

    if (enabled) {
      // Request notification permission if enabling
      final permissionResult =
          await NotificationService.requestNotificationPermission();
      if (!permissionResult.isGranted) {
        setState(() {
          _workoutNotificationsEnabled = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(permissionResult.message),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
        return;
      }
    }
  }

  Future<void> _savePreferences() async {
    if (!_hasChanges) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert TimeOfDay to string format "HH:mm"
      final notificationTimeString =
          '${_notificationTime.hour.toString().padLeft(2, '0')}:${_notificationTime.minute.toString().padLeft(2, '0')}';

      // Create updated preferences
      final updatedPreferences = _preferences.copyWith(
        workoutNotificationsEnabled: _workoutNotificationsEnabled,
        workoutNotificationTime:
            _workoutNotificationsEnabled ? notificationTimeString : null,
      );

      // Create updated user
      final updatedUser = _user.copyWith(
        preferences: updatedPreferences,
        updatedAt: DateTime.now(),
      );

      // Update in Firebase and local storage
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updateUserProfile(updatedUser);

      // Schedule or cancel workout notifications based on new settings
      if (_workoutNotificationsEnabled) {
        await _scheduleWorkoutNotifications();
      } else {
        await NotificationService.cancelWorkoutNotifications();
      }

      if (mounted) {
        setState(() {
          _hasChanges = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout notification settings updated'),
            backgroundColor: AppConstants.successColor,
          ),
        );

        context.pop();
      }
    } catch (e) {
      _logger.e('Error saving workout notification preferences: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update settings: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _scheduleWorkoutNotifications() async {
    try {
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);

      // Check if workout plan is loaded
      if (workoutProvider.currentWorkoutPlan == null) {
        _logger.d('No workout plan loaded, skipping notification scheduling');
        return;
      }

      final workoutPlan = workoutProvider.currentWorkoutPlan!;
      final notificationTimeString =
          '${_notificationTime.hour.toString().padLeft(2, '0')}:${_notificationTime.minute.toString().padLeft(2, '0')}';

      _logger.d(
          'Scheduling workout notifications for user ${_user.id} at $notificationTimeString');

      // Schedule notifications
      await NotificationService.scheduleWorkoutNotifications(
        dailyWorkouts: workoutPlan.dailyWorkouts,
        notificationTime: notificationTimeString,
        userId: _user.id,
      );

      _logger.i('Workout notifications scheduled successfully');
    } catch (e) {
      _logger.e('Error scheduling workout notifications: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Workout Notifications'),
        backgroundColor: AppConstants.surfaceColor,
        elevation: 0,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _savePreferences,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification toggle
            _buildNotificationToggle(),
            const SizedBox(height: AppConstants.spacingL),

            // Time selection (only show if notifications are enabled)
            if (_workoutNotificationsEnabled) ...[
              _buildTimeSelection(),
              const SizedBox(height: AppConstants.spacingL),
            ],

            // Notification preview
            if (_workoutNotificationsEnabled) ...[
              _buildNotificationPreview(),
              const SizedBox(height: AppConstants.spacingL),
            ],

            // Info text
            _buildInfoText(),
            const SizedBox(height: 128),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationToggle() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppConstants.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.fitness_center,
            color: AppConstants.textSecondary,
            size: 24,
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workout Notifications',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingS),
                Text(
                  'Get daily reminders for your scheduled workouts',
                  style: AppTextStyles.caption.copyWith(
                    color: AppConstants.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _workoutNotificationsEnabled,
            onChanged: _toggleWorkoutNotifications,
            activeColor: AppConstants.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelection() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppConstants.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Time',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Choose when you want to receive workout reminders',
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.textTertiary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          GestureDetector(
            onTap: _selectTime,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingM,
                vertical: AppConstants.spacingS,
              ),
              decoration: BoxDecoration(
                color: AppConstants.backgroundColor,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(
                  color: AppConstants.borderColor,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _notificationTime.format(context),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppConstants.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPreview() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppConstants.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Example Notification',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'This is how your workout notifications will look',
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.textTertiary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          _buildNotificationCard(),
        ],
      ),
    );
  }

  Widget _buildNotificationCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: Colors.grey[200]!,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Notification content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  children: [
                    Text(
                      'TODAY\'S WORKOUT IS READY',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Push Day: Barbell Bench Press, Dumbbell Shoulder Press, Lateral Raise, and 3 more.',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppConstants.primaryColor,
            size: 20,
          ),
          const SizedBox(width: AppConstants.spacingS),
          Expanded(
            child: Text(
              'Notifications will be sent daily at ${_notificationTime.format(context)} for days when you have workouts scheduled. Rest days will be skipped automatically.',
              style: AppTextStyles.caption.copyWith(
                color: AppConstants.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
