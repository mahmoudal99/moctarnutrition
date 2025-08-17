import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/workout_plan_model.dart';
import '../models/workout_model.dart';
import '../models/user_model.dart';
import '../../features/workouts/data/workout_service.dart';
import '../services/workout_plan_storage_service.dart';
import '../services/workout_plan_local_storage_service.dart';
import '../services/notification_service.dart';

class WorkoutProvider extends ChangeNotifier {
  static final _logger = Logger();
  
  WorkoutPlanModel? _currentWorkoutPlan;
  bool _isLoading = false;
  String? _error;

  WorkoutPlanModel? get currentWorkoutPlan => _currentWorkoutPlan;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final WorkoutService _workoutService = WorkoutService();

  // Load workout plan based on user's selected workout styles
  Future<void> loadWorkoutPlan(String userId, List<String> workoutStyles, UserModel? user) async {
    _setLoading(true);
    _error = null;

    _logger.d('Loading workout plan for user $userId with styles: $workoutStyles');

    try {
      // First, try to load from local storage
      final localWorkoutPlan = await WorkoutPlanLocalStorageService.loadWorkoutPlan(userId);
      
      if (localWorkoutPlan != null) {
        _logger.d('Found workout plan in local storage: ${localWorkoutPlan.title}');
        _currentWorkoutPlan = localWorkoutPlan;
        
        // Check if the local plan is fresh (less than 24 hours old)
        final isFresh = await WorkoutPlanLocalStorageService.isWorkoutPlanFresh();
        if (isFresh) {
          _logger.d('Local workout plan is fresh, using cached data');
          // Schedule notifications for fresh local plan
          if (user != null) {
            await _scheduleWorkoutNotifications(user);
          }
          return;
        } else {
          _logger.d('Local workout plan is stale, refreshing from server');
        }
      }

      // Try to load from Firestore (server-side storage)
      final storedWorkoutPlan = await WorkoutPlanStorageService.getWorkoutPlan(userId);
      
      if (storedWorkoutPlan != null) {
        _logger.d('Found stored workout plan: ${storedWorkoutPlan.title}');
        _currentWorkoutPlan = storedWorkoutPlan;
        
        // Save to local storage for future use
        try {
          await WorkoutPlanLocalStorageService.saveWorkoutPlan(storedWorkoutPlan);
          _logger.d('Workout plan saved to local storage');
        } catch (e) {
          _logger.w('Failed to save workout plan to local storage: $e');
        }
        
        // Schedule notifications for stored workout plan
        if (user != null) {
          await _scheduleWorkoutNotifications(user);
        }
        return;
      }

      // If no stored plan, check for predefined plans
      final predefinedWorkoutPlan = _workoutService.getWorkoutPlanForUser(userId, workoutStyles);
      
      if (predefinedWorkoutPlan != null) {
        _logger.d('Using predefined workout plan: ${predefinedWorkoutPlan.title}');
        _currentWorkoutPlan = predefinedWorkoutPlan;
        
        // Save predefined plan to both Firestore and local storage
        try {
          await WorkoutPlanStorageService.saveWorkoutPlan(predefinedWorkoutPlan);
          await WorkoutPlanLocalStorageService.saveWorkoutPlan(predefinedWorkoutPlan);
          _logger.d('Predefined workout plan saved to both storage locations');
        } catch (e) {
          _logger.w('Failed to save predefined workout plan: $e');
          // Don't fail the operation if saving fails
        }
        
        // Schedule notifications for predefined workout plan
        if (user != null) {
          await _scheduleWorkoutNotifications(user);
        }
      } else {
        _logger.i('No predefined workout plan found for styles: $workoutStyles. Generating AI plan...');
        
        if (user != null) {
          try {
            final aiWorkoutPlan = await _workoutService.generateAIWorkoutPlan(user, userId);
            _logger.d('AI workout plan generated successfully: ${aiWorkoutPlan.title}');
            
            // Save AI-generated plan to both Firestore and local storage
            try {
              await WorkoutPlanStorageService.saveWorkoutPlan(aiWorkoutPlan);
              await WorkoutPlanLocalStorageService.saveWorkoutPlan(aiWorkoutPlan);
              _logger.d('AI workout plan saved to both storage locations');
            } catch (e) {
              _logger.w('Failed to save AI workout plan: $e');
              // Don't fail the operation if saving fails
            }
            
            _currentWorkoutPlan = aiWorkoutPlan;
            
            // Schedule notifications for AI-generated workout plan
            if (user != null) {
              await _scheduleWorkoutNotifications(user);
            }
          } catch (e) {
            _logger.e('Failed to generate AI workout plan: $e');
            _error = 'Failed to generate personalized workout plan. Please try again later.';
          }
        } else {
          _error = 'Unable to generate personalized workout plan. Please update your profile preferences.';
        }
      }
    } catch (e) {
      _logger.e('Error loading workout plan: $e');
      _error = 'Failed to load workout plan: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Get today's workout
  DailyWorkout? getTodayWorkout() {
    if (_currentWorkoutPlan == null) return null;
    
    final today = DateTime.now();
    final dayOfWeek = today.weekday; // 1 = Monday, 7 = Sunday
    
    // Map weekday to day name
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final todayName = dayNames[dayOfWeek - 1];
    
    return _currentWorkoutPlan!.dailyWorkouts.firstWhere(
      (day) => day.dayName == todayName,
      orElse: () => _currentWorkoutPlan!.dailyWorkouts.first,
    );
  }

  // Get workout for specific day
  DailyWorkout? getWorkoutForDay(String dayName) {
    if (_currentWorkoutPlan == null) return null;
    
    return _currentWorkoutPlan!.dailyWorkouts.firstWhere(
      (day) => day.dayName == dayName,
      orElse: () => _currentWorkoutPlan!.dailyWorkouts.first,
    );
  }

  // Clear current workout plan
  void clearWorkoutPlan() {
    _currentWorkoutPlan = null;
    _error = null;
    notifyListeners();
  }

  // Clear workout plan for user change
  Future<void> clearWorkoutPlanForUserChange() async {
    _logger.d('Clearing workout plan for user change');
    _currentWorkoutPlan = null;
    _error = null;
    notifyListeners();
  }

  // Clear local cache
  Future<void> clearLocalCache() async {
    try {
      await WorkoutPlanLocalStorageService.clearWorkoutPlan();
      _logger.d('Local workout plan cache cleared');
    } catch (e) {
      _logger.e('Failed to clear local cache: $e');
    }
  }

  // Regenerate workout plan (for when user changes preferences)
  Future<void> regenerateWorkoutPlan(String userId, List<String> workoutStyles, UserModel user) async {
    _logger.i('Regenerating workout plan for user: $userId');
    
    try {
      // Deactivate current workout plans
      await WorkoutPlanStorageService.deactivateUserWorkoutPlans(userId);
      
      // Clear local cache
      await clearLocalCache();
      
      // Clear current plan
      _currentWorkoutPlan = null;
      notifyListeners();
      
      // Load new plan (this will generate new AI plan or use predefined)
      await loadWorkoutPlan(userId, workoutStyles, user);
      
      // Schedule notifications for regenerated workout plan
      if (_currentWorkoutPlan != null && user != null) {
        await _scheduleWorkoutNotifications(user);
      }
      
      _logger.i('Workout plan regenerated successfully');
    } catch (e) {
      _logger.e('Failed to regenerate workout plan: $e');
      _error = 'Failed to regenerate workout plan. Please try again.';
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Schedule workout notifications if user has enabled them
  Future<void> _scheduleWorkoutNotifications(UserModel user) async {
    try {
      // Check if user has workout notifications enabled
      if (!user.preferences.workoutNotificationsEnabled ||
          user.preferences.workoutNotificationTime == null) {
        _logger.d('Workout notifications not enabled or missing time preference');
        return;
      }

      // Check if workout plan is loaded
      if (_currentWorkoutPlan == null) {
        _logger.d('No workout plan loaded, skipping notification scheduling');
        return;
      }

      final notificationTime = user.preferences.workoutNotificationTime!;

      _logger.d('Scheduling workout notifications for user ${user.id} at $notificationTime');

      // Schedule notifications
      await NotificationService.scheduleWorkoutNotifications(
        dailyWorkouts: _currentWorkoutPlan!.dailyWorkouts,
        notificationTime: notificationTime,
        userId: user.id,
      );

      _logger.i('Workout notifications scheduled successfully');
    } catch (e) {
      _logger.e('Error scheduling workout notifications: $e');
    }
  }

  // Add workout to a specific day
  Future<void> addWorkoutToDay(String dayName, WorkoutModel workout) async {
    if (_currentWorkoutPlan == null) {
      _logger.w('Cannot add workout: no current workout plan');
      return;
    }

    try {
      _logger.d('Adding workout "${workout.title}" to $dayName');
      
      // Find the day to update
      final dayIndex = _currentWorkoutPlan!.dailyWorkouts.indexWhere(
        (day) => day.dayName == dayName,
      );

      if (dayIndex == -1) {
        _logger.w('Day $dayName not found in workout plan');
        return;
      }

      // Create updated daily workout with new workout added
      final currentDay = _currentWorkoutPlan!.dailyWorkouts[dayIndex];
      final updatedWorkouts = List<WorkoutModel>.from(currentDay.workouts)..add(workout);
      
      // Recalculate estimated duration
      final newDuration = updatedWorkouts.fold<int>(
        0, 
        (total, w) => total + w.estimatedDuration,
      );

      final updatedDay = DailyWorkout(
        id: currentDay.id,
        dayName: currentDay.dayName,
        title: currentDay.title,
        description: currentDay.description,
        workouts: updatedWorkouts,
        estimatedDuration: newDuration,
        restDay: currentDay.restDay,
      );

      // Create updated workout plan
      final updatedDailyWorkouts = List<DailyWorkout>.from(_currentWorkoutPlan!.dailyWorkouts);
      updatedDailyWorkouts[dayIndex] = updatedDay;

      final updatedWorkoutPlan = _currentWorkoutPlan!.copyWith(
        dailyWorkouts: updatedDailyWorkouts,
        updatedAt: DateTime.now(),
      );

      // Update the current workout plan
      _currentWorkoutPlan = updatedWorkoutPlan;

      // Save to storage
      await _saveUpdatedWorkoutPlan(updatedWorkoutPlan);
      
      _logger.d('Successfully added workout to $dayName');
      notifyListeners();
    } catch (e) {
      _logger.e('Failed to add workout to day: $e');
      _error = 'Failed to add workout. Please try again.';
      notifyListeners();
    }
  }

  // Remove workout from a specific day
  Future<void> removeWorkoutFromDay(String dayName, String workoutId) async {
    if (_currentWorkoutPlan == null) {
      _logger.w('Cannot remove workout: no current workout plan');
      return;
    }

    try {
      _logger.d('Removing workout $workoutId from $dayName');
      
      // Find the day to update
      final dayIndex = _currentWorkoutPlan!.dailyWorkouts.indexWhere(
        (day) => day.dayName == dayName,
      );

      if (dayIndex == -1) {
        _logger.w('Day $dayName not found in workout plan');
        return;
      }

      // Create updated daily workout with workout removed
      final currentDay = _currentWorkoutPlan!.dailyWorkouts[dayIndex];
      final updatedWorkouts = currentDay.workouts.where((w) => w.id != workoutId).toList();
      
      // Recalculate estimated duration
      final newDuration = updatedWorkouts.fold<int>(
        0, 
        (total, w) => total + w.estimatedDuration,
      );

      final updatedDay = DailyWorkout(
        id: currentDay.id,
        dayName: currentDay.dayName,
        title: currentDay.title,
        description: currentDay.description,
        workouts: updatedWorkouts,
        estimatedDuration: newDuration,
        restDay: currentDay.restDay,
      );

      // Create updated workout plan
      final updatedDailyWorkouts = List<DailyWorkout>.from(_currentWorkoutPlan!.dailyWorkouts);
      updatedDailyWorkouts[dayIndex] = updatedDay;

      final updatedWorkoutPlan = _currentWorkoutPlan!.copyWith(
        dailyWorkouts: updatedDailyWorkouts,
        updatedAt: DateTime.now(),
      );

      // Update the current workout plan
      _currentWorkoutPlan = updatedWorkoutPlan;

      // Save to storage
      await _saveUpdatedWorkoutPlan(updatedWorkoutPlan);
      
      _logger.d('Successfully removed workout from $dayName');
      notifyListeners();
    } catch (e) {
      _logger.e('Failed to remove workout from day: $e');
      _error = 'Failed to remove workout. Please try again.';
      notifyListeners();
    }
  }

  // Save updated workout plan to storage
  Future<void> _saveUpdatedWorkoutPlan(WorkoutPlanModel updatedPlan) async {
    try {
      // Save to both Firestore and local storage
      await WorkoutPlanStorageService.saveWorkoutPlan(updatedPlan);
      await WorkoutPlanLocalStorageService.saveWorkoutPlan(updatedPlan);
      _logger.d('Updated workout plan saved to storage');
    } catch (e) {
      _logger.e('Failed to save updated workout plan: $e');
      throw e;
    }
  }

  // Add exercise to a specific workout in a specific day
  Future<void> addExerciseToWorkout(String dayName, String workoutId, Exercise exercise) async {
    if (_currentWorkoutPlan == null) {
      _logger.w('Cannot add exercise: no current workout plan');
      return;
    }

    try {
      _logger.d('Adding exercise "${exercise.name}" to workout $workoutId on $dayName');
      
      // Find the day to update
      final dayIndex = _currentWorkoutPlan!.dailyWorkouts.indexWhere(
        (day) => day.dayName == dayName,
      );

      if (dayIndex == -1) {
        _logger.w('Day $dayName not found in workout plan');
        return;
      }

      // Find the workout to update
      final day = _currentWorkoutPlan!.dailyWorkouts[dayIndex];
      final workoutIndex = day.workouts.indexWhere((w) => w.id == workoutId);

      if (workoutIndex == -1) {
        _logger.w('Workout $workoutId not found in day $dayName');
        return;
      }

      // Create updated workout with new exercise added
      final currentWorkout = day.workouts[workoutIndex];
      final updatedExercises = List<Exercise>.from(currentWorkout.exercises)..add(exercise);
      
      // Recalculate estimated duration (rough estimate: 2 minutes per exercise)
      final newDuration = currentWorkout.estimatedDuration + 2;

      final updatedWorkout = currentWorkout.copyWith(
        exercises: updatedExercises,
        estimatedDuration: newDuration,
        updatedAt: DateTime.now(),
      );

      // Create updated daily workout
      final updatedWorkouts = List<WorkoutModel>.from(day.workouts);
      updatedWorkouts[workoutIndex] = updatedWorkout;

      final updatedDay = DailyWorkout(
        id: day.id,
        dayName: day.dayName,
        title: day.title,
        description: day.description,
        workouts: updatedWorkouts,
        estimatedDuration: updatedWorkouts.fold<int>(0, (total, w) => total + w.estimatedDuration),
        restDay: day.restDay,
      );

      // Create updated workout plan
      final updatedDailyWorkouts = List<DailyWorkout>.from(_currentWorkoutPlan!.dailyWorkouts);
      updatedDailyWorkouts[dayIndex] = updatedDay;

      final updatedWorkoutPlan = _currentWorkoutPlan!.copyWith(
        dailyWorkouts: updatedDailyWorkouts,
        updatedAt: DateTime.now(),
      );

      // Update the current workout plan
      _currentWorkoutPlan = updatedWorkoutPlan;

      // Save to storage
      await _saveUpdatedWorkoutPlan(updatedWorkoutPlan);
      
      _logger.d('Successfully added exercise to workout on $dayName');
      notifyListeners();
    } catch (e) {
      _logger.e('Failed to add exercise to workout: $e');
      _error = 'Failed to add exercise. Please try again.';
      notifyListeners();
    }
  }

  // Remove exercise from a specific workout in a specific day
  Future<void> removeExerciseFromWorkout(String dayName, String workoutId, String exerciseId) async {
    if (_currentWorkoutPlan == null) {
      _logger.w('Cannot remove exercise: no current workout plan');
      return;
    }

    try {
      _logger.d('Removing exercise $exerciseId from workout $workoutId on $dayName');
      
      // Find the day to update
      final dayIndex = _currentWorkoutPlan!.dailyWorkouts.indexWhere(
        (day) => day.dayName == dayName,
      );

      if (dayIndex == -1) {
        _logger.w('Day $dayName not found in workout plan');
        return;
      }

      // Find the workout to update
      final day = _currentWorkoutPlan!.dailyWorkouts[dayIndex];
      final workoutIndex = day.workouts.indexWhere((w) => w.id == workoutId);

      if (workoutIndex == -1) {
        _logger.w('Workout $workoutId not found in day $dayName');
        return;
      }

      // Create updated workout with exercise removed
      final currentWorkout = day.workouts[workoutIndex];
      final updatedExercises = currentWorkout.exercises.where((e) => e.id != exerciseId).toList();
      
      // Recalculate estimated duration
      final newDuration = currentWorkout.estimatedDuration - 2; // Rough estimate

      final updatedWorkout = currentWorkout.copyWith(
        exercises: updatedExercises,
        estimatedDuration: newDuration > 0 ? newDuration : 1,
        updatedAt: DateTime.now(),
      );

      // Create updated daily workout
      final updatedWorkouts = List<WorkoutModel>.from(day.workouts);
      updatedWorkouts[workoutIndex] = updatedWorkout;

      final updatedDay = DailyWorkout(
        id: day.id,
        dayName: day.dayName,
        title: day.title,
        description: day.description,
        workouts: updatedWorkouts,
        estimatedDuration: updatedWorkouts.fold<int>(0, (total, w) => total + w.estimatedDuration),
        restDay: day.restDay,
      );

      // Create updated workout plan
      final updatedDailyWorkouts = List<DailyWorkout>.from(_currentWorkoutPlan!.dailyWorkouts);
      updatedDailyWorkouts[dayIndex] = updatedDay;

      final updatedWorkoutPlan = _currentWorkoutPlan!.copyWith(
        dailyWorkouts: updatedDailyWorkouts,
        updatedAt: DateTime.now(),
      );

      // Update the current workout plan
      _currentWorkoutPlan = updatedWorkoutPlan;

      // Save to storage
      await _saveUpdatedWorkoutPlan(updatedWorkoutPlan);
      
      _logger.d('Successfully removed exercise from workout on $dayName');
      notifyListeners();
    } catch (e) {
      _logger.e('Failed to remove exercise from workout: $e');
      _error = 'Failed to remove exercise. Please try again.';
      notifyListeners();
    }
  }
} 