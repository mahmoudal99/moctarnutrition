import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/workout_plan_model.dart';
import '../../features/workouts/data/workout_service.dart';

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
  Future<void> loadWorkoutPlan(String userId, List<String> workoutStyles) async {
    _setLoading(true);
    _error = null;

    _logger.d('Loading workout plan for user $userId with styles: $workoutStyles');

    try {
      final workoutPlan = _workoutService.getWorkoutPlanForUser(userId, workoutStyles);
      
      if (workoutPlan != null) {
        _logger.d('Workout plan loaded successfully: ${workoutPlan.title}');
        _currentWorkoutPlan = workoutPlan;
      } else {
        _logger.i('No predefined workout plan found for styles: $workoutStyles');
        _error = 'No predefined workout plan available for your selected styles. AI-generated plans coming soon!';
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

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
} 