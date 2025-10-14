import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'logging_service.dart';
import '../models/workout_plan_model.dart';

class WorkoutPlanLocalStorageService {
  // Remove old logger instance
  // static final _logger = Logger();
  static const String _workoutPlanKey = 'workout_plan';
  static const String _lastUpdatedKey = 'workout_plan_last_updated';
  static const String _userIdKey = 'workout_plan_user_id';

  /// Save workout plan to local storage
  static Future<void> saveWorkoutPlan(WorkoutPlanModel workoutPlan) async {
    try {
      LoggingService.workout.d('Saving workout plan to local storage: ${workoutPlan.id}');

      final prefs = await SharedPreferences.getInstance();
      final workoutPlanJson = jsonEncode(workoutPlan.toJson());

      await prefs.setString(_workoutPlanKey, workoutPlanJson);
      await prefs.setString(_lastUpdatedKey, DateTime.now().toIso8601String());
      await prefs.setString(_userIdKey, workoutPlan.userId);

      LoggingService.workout.i('Workout plan saved to local storage successfully');
    } catch (e) {
      LoggingService.workout.e('Failed to save workout plan to local storage: $e');
      rethrow;
    }
  }

  /// Load workout plan from local storage
  static Future<WorkoutPlanModel?> loadWorkoutPlan(String userId) async {
    try {
      LoggingService.workout.d('Loading workout plan from local storage for user: $userId');

      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString(_userIdKey);
      
      LoggingService.workout.d('Stored user ID: $storedUserId, Current user ID: $userId');
      LoggingService.workout.d('User IDs match: ${storedUserId == userId}');

      // Check if the stored plan is for the current user
      if (storedUserId != userId) {
        LoggingService.workout.d('Stored workout plan is for different user, clearing cache');
        await clearWorkoutPlan();
        return null;
      }

      final workoutPlanJson = prefs.getString(_workoutPlanKey);
      if (workoutPlanJson == null) {
        LoggingService.workout.d('No workout plan found in local storage');
        return null;
      }

      final workoutPlanData =
          jsonDecode(workoutPlanJson) as Map<String, dynamic>;
      final workoutPlan = WorkoutPlanModel.fromJson(workoutPlanData);

      LoggingService.workout.i('Workout plan loaded from local storage: ${workoutPlan.id}');
      return workoutPlan;
    } catch (e) {
      LoggingService.workout.e('Failed to load workout plan from local storage: $e');
      return null;
    }
  }

  /// Check if local workout plan is fresh (less than 24 hours old)
  static Future<bool> isWorkoutPlanFresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdatedString = prefs.getString(_lastUpdatedKey);

      if (lastUpdatedString == null) return false;

      final lastUpdated = DateTime.parse(lastUpdatedString);
      final now = DateTime.now();
      final difference = now.difference(lastUpdated);

      // Consider fresh if less than 24 hours old
      return difference.inHours < 24;
    } catch (e) {
      LoggingService.workout.e('Failed to check workout plan freshness: $e');
      return false;
    }
  }

  /// Clear workout plan from local storage
  static Future<void> clearWorkoutPlan() async {
    try {
      LoggingService.workout.d('Clearing workout plan from local storage');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_workoutPlanKey);
      await prefs.remove(_lastUpdatedKey);
      await prefs.remove(_userIdKey);

      LoggingService.workout.i('Workout plan cleared from local storage');
    } catch (e) {
      LoggingService.workout.e('Failed to clear workout plan from local storage: $e');
    }
  }

  /// Get last updated timestamp
  static Future<DateTime?> getLastUpdated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdatedString = prefs.getString(_lastUpdatedKey);

      if (lastUpdatedString == null) return null;

      return DateTime.parse(lastUpdatedString);
    } catch (e) {
      LoggingService.workout.e('Failed to get last updated timestamp: $e');
      return null;
    }
  }
}
