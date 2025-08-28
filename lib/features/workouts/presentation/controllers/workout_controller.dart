import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../../../shared/providers/workout_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/user_provider.dart';
import '../services/workout_notification_service.dart';

class WorkoutController {
  static final _logger = Logger();

  static Future<void> loadWorkoutPlanIfNeeded(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    Provider.of<UserProvider>(context, listen: false);
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);

    // Check if user is authenticated
    if (!authProvider.isAuthenticated || authProvider.userModel == null) {
      _logger.w(
          'Cannot load workout plan: user not authenticated or userModel is null');
      return;
    }

    // Check if the current workout plan belongs to the current user
    final currentWorkoutPlan = workoutProvider.currentWorkoutPlan;
    if (currentWorkoutPlan != null) {
      if (currentWorkoutPlan.userId == authProvider.userModel!.id) {
        _logger.d(
            'Workout plan already loaded for current user, skipping API call');
        // Still schedule notifications in case they were missed (non-blocking)
        WorkoutNotificationService.scheduleNotificationsInBackground(context);
        return;
      } else {
        _logger.d(
            'Workout plan belongs to different user, clearing and reloading');
        await workoutProvider.clearWorkoutPlanForUserChange();
      }
    }

    // Load workout plan for current user
    final workoutStyles =
        authProvider.userModel!.preferences.preferredWorkoutStyles;
    _logger.d(
        'Loading workout plan for user ${authProvider.userModel!.id} with styles: $workoutStyles');
    await workoutProvider.loadWorkoutPlan(
        authProvider.userModel!.id, workoutStyles, authProvider.userModel);

    // Schedule notifications after workout plan is loaded (non-blocking)
    WorkoutNotificationService.scheduleNotificationsInBackground(context);
  }

  static Future<void> loadWorkoutPlan(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    Provider.of<UserProvider>(context, listen: false);
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);

    if (authProvider.isAuthenticated && authProvider.userModel != null) {
      final workoutStyles =
          authProvider.userModel!.preferences.preferredWorkoutStyles;
      _logger.d(
          'Force loading workout plan for user ${authProvider.userModel!.id} with styles: $workoutStyles');
      await workoutProvider.loadWorkoutPlan(
          authProvider.userModel!.id, workoutStyles, authProvider.userModel);
    } else {
      _logger.w(
          'Cannot load workout plan: user not authenticated or userModel is null');
    }
  }

  static Future<void> refreshWorkoutPlan(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);

    if (authProvider.isAuthenticated && authProvider.userModel != null) {
      await workoutProvider.clearLocalCache();

      final workoutStyles =
          authProvider.userModel!.preferences.preferredWorkoutStyles;
      _logger
          .d('Refreshing workout plan for user ${authProvider.userModel!.id}');
      await workoutProvider.loadWorkoutPlan(
          authProvider.userModel!.id, workoutStyles, authProvider.userModel);

      // Schedule notifications after workout plan is refreshed (non-blocking)
      WorkoutNotificationService.scheduleNotificationsInBackground(context);
    }
  }

  static bool shouldReloadWorkoutPlan(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);

    return authProvider.isAuthenticated &&
        authProvider.userModel != null &&
        workoutProvider.currentWorkoutPlan != null &&
        workoutProvider.currentWorkoutPlan!.userId !=
            authProvider.userModel!.id;
  }
}
