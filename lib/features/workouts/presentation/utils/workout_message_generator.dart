import '../../../../shared/models/workout_plan_model.dart';
import '../../../../shared/models/workout_model.dart';

class WorkoutMessageGenerator {
  static String generateWorkoutMessage(DailyWorkout? todayWorkout) {
    if (todayWorkout == null) {
      return 'Ready for your workout?';
    }

    if (todayWorkout.isRestDay) {
      return 'Time to rest and recover!';
    }

    final workoutCount = todayWorkout.workouts.length;

    if (workoutCount == 1) {
      final workout = todayWorkout.workouts.first;
      return _getCategorySpecificMessage(workout.category);
    } else if (workoutCount > 1) {
      return 'Ready for your $workoutCount-workout session?';
    } else {
      return 'Ready for your workout?';
    }
  }

  static String _getCategorySpecificMessage(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.strength:
        return 'Ready to build strength?';
      case WorkoutCategory.cardio:
        return 'Ready to boost your cardio?';
      case WorkoutCategory.hiit:
        return 'Ready for an intense HIIT session?';
      case WorkoutCategory.flexibility:
        return 'Ready to improve flexibility?';
      case WorkoutCategory.yoga:
        return 'Ready for your yoga practice?';
      case WorkoutCategory.pilates:
        return 'Ready for your Pilates session?';
      default:
        final categoryName = category.toString().split('.').last.toLowerCase();
        return 'Ready for your $categoryName workout?';
    }
  }
}
