import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/workout_plan_model.dart';
import '../models/user_model.dart';
import '../../features/workouts/data/workout_service.dart';
import '../services/workout_plan_storage_service.dart';
import '../services/workout_plan_local_storage_service.dart';

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
} 