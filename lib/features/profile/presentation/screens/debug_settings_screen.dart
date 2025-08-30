import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/notification_service.dart';
import '../../../../shared/providers/auth_provider.dart' as app_auth;
import '../../../../shared/providers/workout_provider.dart';

class DebugSettingsScreen extends StatefulWidget {
  const DebugSettingsScreen({super.key});

  @override
  State<DebugSettingsScreen> createState() => _DebugSettingsScreenState();
}

class _DebugSettingsScreenState extends State<DebugSettingsScreen> {
  static final _logger = Logger();
  List<PendingNotificationRequest> _pendingNotifications = [];
  bool _isLoading = true;
  bool _hasWeeklyReminder = false;
  int _weeklyReminderCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingNotifications();
  }

  Future<void> _loadPendingNotifications() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final pendingNotifications =
          await FlutterLocalNotificationsPlugin().pendingNotificationRequests();

      _logger.d('Found ${pendingNotifications.length} pending notifications');

      // Check if weekly reminders are scheduled (IDs 2-9)
      final weeklyReminders = pendingNotifications
          .where((notification) => notification.id >= 2 && notification.id < 10)
          .length;
      final hasWeeklyReminder = weeklyReminders > 0;

      // Sort notifications by scheduled time (earliest first)
      final sortedNotifications =
          List<PendingNotificationRequest>.from(pendingNotifications);
      sortedNotifications.sort((a, b) {
        // Sort by notification type and then by ID
        // Weekly reminders (IDs 2-9) come first, sorted by week
        // Then workout notifications (IDs 1000+) sorted by day
        if (a.id >= 2 && a.id < 10 && b.id >= 1000) return -1;
        if (b.id >= 2 && b.id < 10 && a.id >= 1000) return 1;

        // Within the same type, sort by ID (which corresponds to chronological order)
        return a.id.compareTo(b.id);
      });

      setState(() {
        _pendingNotifications = sortedNotifications;
        _hasWeeklyReminder = hasWeeklyReminder;
        _weeklyReminderCount = weeklyReminders;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error loading pending notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      await FlutterLocalNotificationsPlugin().cancelAll();
      await _loadPendingNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications cleared'),
            backgroundColor: AppConstants.primaryColor,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error clearing notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to clear notifications'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _testNotification() async {
    try {
      await NotificationService.showTestNotification();
      await _loadPendingNotifications();
    } catch (e) {
      _logger.e('Error sending test notification: $e');
    }
  }

  Future<void> _scheduleWeeklyReminder() async {
    try {
      await NotificationService.scheduleWeeklyCheckinReminder();
      await _loadPendingNotifications();
    } catch (e) {
      _logger.e('Error scheduling weekly reminder: $e');
    }
  }

  Future<void> _cancelWeeklyReminder() async {
    try {
      await NotificationService.cancelWeeklyCheckinReminder();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Weekly check-in reminder cancelled'),
            backgroundColor: AppConstants.primaryColor,
          ),
        );
      }

      // Reload pending notifications after cancelling
      await _loadPendingNotifications();
    } catch (e) {
      _logger.e('Error cancelling weekly reminder: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to cancel weekly reminder'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _debugScheduleWorkouts() async {
    try {
      // Get current user and workout plan from providers
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);

      if (authProvider.userModel == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No user logged in'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
        return;
      }

      if (workoutProvider.currentWorkoutPlan == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No workout plan loaded'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
        return;
      }

      final user = authProvider.userModel!;
      final workoutPlan = workoutProvider.currentWorkoutPlan!;

      _logger.d(
          'Debug: Scheduling workout notifications for ${workoutPlan.dailyWorkouts.length} days');
      _logger.d(
          'Debug: User notification time: ${user.preferences.workoutNotificationTime}');
      _logger.d(
          'Debug: Notifications enabled: ${user.preferences.workoutNotificationsEnabled}');

      await NotificationService.scheduleWorkoutNotifications(
        dailyWorkouts: workoutPlan.dailyWorkouts,
        notificationTime: user.preferences.workoutNotificationTime ?? '09:00',
        userId: user.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout notifications scheduled (check logs)'),
            backgroundColor: AppConstants.primaryColor,
          ),
        );
      }

      // Reload pending notifications
      await _loadPendingNotifications();
    } catch (e) {
      _logger.e('Error in debug workout scheduling: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  String _getEstimatedScheduledTime(int notificationId) {
    if (notificationId >= 2 && notificationId < 10) {
      // Weekly reminders (IDs 2-9) - every Sunday at 9 AM
      final weekOffset = notificationId - 2;
      final targetDate = DateTime.now().add(Duration(days: weekOffset * 7));
      final daysUntilSunday = (DateTime.sunday - targetDate.weekday) % 7;
      final nextSunday = targetDate.add(Duration(days: daysUntilSunday));
      return '${nextSunday.toString().split(' ')[0]} 09:00 (Sunday)';
    } else if (notificationId >= 1000) {
      // Workout notifications (IDs 1000+) - daily at user's preferred time
      final dayOffset = notificationId - 1000;
      final targetDate = DateTime.now().add(Duration(days: dayOffset));
      return '${targetDate.toString().split(' ')[0]} (${_getDayName(targetDate.weekday)})';
    }
    return 'Unknown';
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return 'Unknown';
    }
  }

  void _showNotificationAnalysis() {
    final workoutNotifications =
        _pendingNotifications.where((n) => n.id >= 1000).length;
    final weeklyReminders =
        _pendingNotifications.where((n) => n.id >= 2 && n.id < 10).length;
    final otherNotifications =
        _pendingNotifications.where((n) => n.id != 2 && n.id < 1000).length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Analysis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Pending: ${_pendingNotifications.length}/64'),
            const SizedBox(height: AppConstants.spacingS),
            Text('Workout Notifications: $workoutNotifications'),
            Text('Weekly Check-in: $weeklyReminders'),
            Text('Other Notifications: $otherNotifications'),
            const SizedBox(height: AppConstants.spacingS),
            Text('Available Slots: ${64 - _pendingNotifications.length}'),
            const SizedBox(height: AppConstants.spacingM),
            const Text(
              'Note: iOS allows up to 64 pending notifications. We should be scheduling more workout notifications.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Debug Settings'),
        backgroundColor: AppConstants.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.textPrimary),
        titleTextStyle: AppTextStyles.heading5.copyWith(
          color: AppConstants.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          IconButton(
            onPressed: _loadPendingNotifications,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              children: [
                // Debug Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Debug Information',
                          style: AppTextStyles.heading5.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingS),
                        Text(
                          'Pending Notifications: ${_pendingNotifications.length}',
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: AppConstants.spacingXS),
                        Text(
                          'Weekly Check-in Reminders: ${_hasWeeklyReminder ? '✅ $_weeklyReminderCount scheduled' : '❌ Not Scheduled'}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: _hasWeeklyReminder
                                ? AppConstants.primaryColor
                                : AppConstants.errorColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingXS),
                        Text(
                          'Available Slots: ${64 - _pendingNotifications.length}/64',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: (64 - _pendingNotifications.length) < 10
                                ? AppConstants.errorColor
                                : AppConstants.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingXS),
                        Text(
                          'Weekly Check-in Reminder: ${_hasWeeklyReminder ? 'Scheduled' : 'Not Scheduled'}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: _hasWeeklyReminder
                                ? AppConstants.primaryColor
                                : AppConstants.errorColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingM),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _testNotification,
                                icon: const Icon(Icons.notifications),
                                label: const Text('Test Notification'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.primaryColor,
                                  foregroundColor: AppConstants.surfaceColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingS),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _clearAllNotifications,
                                icon: const Icon(Icons.clear_all),
                                label: const Text('Clear All'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.errorColor,
                                  foregroundColor: AppConstants.surfaceColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingM),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _scheduleWeeklyReminder,
                                icon: const Icon(Icons.schedule),
                                label: const Text('Schedule Weekly'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.primaryColor,
                                  foregroundColor: AppConstants.surfaceColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingS),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _cancelWeeklyReminder,
                                icon: const Icon(Icons.cancel),
                                label: const Text('Cancel Weekly'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.errorColor,
                                  foregroundColor: AppConstants.surfaceColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingM),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _scheduleWeeklyReminder,
                                icon: const Icon(Icons.schedule),
                                label: const Text('Schedule Weekly'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.primaryColor,
                                  foregroundColor: AppConstants.surfaceColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingS),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _cancelWeeklyReminder,
                                icon: const Icon(Icons.cancel),
                                label: const Text('Cancel Weekly'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.errorColor,
                                  foregroundColor: AppConstants.surfaceColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingS),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showNotificationAnalysis,
                            icon: const Icon(Icons.analytics),
                            label: const Text('Analyze Notifications'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.textSecondary,
                              foregroundColor: AppConstants.surfaceColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingS),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _debugScheduleWorkouts,
                            icon: const Icon(Icons.fitness_center),
                            label: const Text('Debug: Schedule Workouts'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              foregroundColor: AppConstants.surfaceColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.spacingL),

                // Pending Notifications List
                if (_pendingNotifications.isNotEmpty) ...[
                  Text(
                    'Pending Notifications',
                    style: AppTextStyles.heading5.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  ..._pendingNotifications
                      .map((notification) => Card(
                            margin: const EdgeInsets.only(
                                bottom: AppConstants.spacingS),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppConstants.primaryColor.withOpacity(0.1),
                                child: const Icon(
                                  Icons.notifications,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                              title: Text(
                                notification.title ?? 'No Title',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (notification.body != null)
                                    Text(
                                      notification.body!,
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  const SizedBox(
                                      height: AppConstants.spacingXS),
                                  Text(
                                    'ID: ${notification.id} • ${_getEstimatedScheduledTime(notification.id)}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppConstants.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                onPressed: () async {
                                  try {
                                    await FlutterLocalNotificationsPlugin()
                                        .cancel(notification.id);
                                    await _loadPendingNotifications();

                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Notification cancelled'),
                                          backgroundColor:
                                              AppConstants.primaryColor,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    _logger
                                        .e('Error cancelling notification: $e');
                                  }
                                },
                                icon: const Icon(Icons.cancel),
                                color: AppConstants.errorColor,
                              ),
                            ),
                          ))
                      ,
                ] else ...[
                  // Empty State
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingL),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.notifications_off,
                            size: 64,
                            color: AppConstants.textTertiary,
                          ),
                          const SizedBox(height: AppConstants.spacingM),
                          Text(
                            'No Pending Notifications',
                            style: AppTextStyles.heading5.copyWith(
                              color: AppConstants.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingS),
                          Text(
                            'All scheduled notifications have been delivered or cancelled',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppConstants.textTertiary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 128),
              ],
            ),
    );
  }
}
