import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/workout_provider.dart';
import '../../../../shared/services/notification_service.dart';

class WorkoutNotificationService {
  static final _logger = Logger();

  /// Schedule workout notifications in background (non-blocking)
  static void scheduleNotificationsInBackground(BuildContext context) {
    // Schedule notifications in background to avoid blocking UI
    Future.microtask(() async {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);

        // Check if user is authenticated and has workout notifications enabled
        if (!authProvider.isAuthenticated ||
            authProvider.userModel == null ||
            !authProvider.userModel!.preferences.workoutNotificationsEnabled ||
            authProvider.userModel!.preferences.workoutNotificationTime == null) {
          _logger.d('Workout notifications not enabled or missing time preference');
          return;
        }

        // Check if workout plan is loaded
        if (workoutProvider.currentWorkoutPlan == null) {
          _logger.d('No workout plan loaded, skipping notification scheduling');
          return;
        }

        // Check if notifications are already scheduled to avoid unnecessary processing
        final pendingNotifications = await FlutterLocalNotificationsPlugin()
            .pendingNotificationRequests();
        final workoutNotifications =
            pendingNotifications.where((n) => n.id >= 1000).length;

        if (workoutNotifications > 30) {
          _logger.d('Workout notifications already scheduled ($workoutNotifications), skipping');
          return;
        }

        final user = authProvider.userModel!;
        final workoutPlan = workoutProvider.currentWorkoutPlan!;
        final notificationTime = user.preferences.workoutNotificationTime!;

        _logger.d('Scheduling workout notifications in background for user ${user.id} at $notificationTime');

        // Schedule notifications
        await NotificationService.scheduleWorkoutNotifications(
          dailyWorkouts: workoutPlan.dailyWorkouts,
          notificationTime: notificationTime,
          userId: user.id,
        );
      } catch (e) {
        _logger.e('Error scheduling workout notifications in background: $e');
      }
    });
  }
}
