import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/providers/workout_provider.dart';
import '../widgets/workout_loading_state.dart';
import '../widgets/workout_generation_loading_state.dart';
import '../widgets/workout_error_state.dart';
import '../widgets/workout_empty_state.dart';
import '../controllers/workout_controller.dart';

class WorkoutViewBuilder {
  static const Widget _generationLoadingState = WorkoutGenerationLoadingState();
  static const Widget _loadingState = WorkoutLoadingState();

  static Widget buildLoadingState() {
    return Consumer<WorkoutProvider>(
      builder: (context, workoutProvider, child) {
        // Use generation loading state if we're generating a new workout plan
        if (workoutProvider.isGenerating) {
          return _generationLoadingState;
        }
        // Use regular loading state for loading existing workouts
        return _loadingState;
      },
    );
  }

  static Widget buildErrorState(String error, BuildContext context) {
    return WorkoutErrorState(
      error: error,
      onRetry: () => WorkoutController.loadWorkoutPlan(context),
    );
  }

  static Widget buildNoWorkoutPlanState(BuildContext context) {
    return WorkoutEmptyState(
      onUpdatePreferences: () {
        Navigator.pushNamed(context, '/profile');
      },
    );
  }
}
