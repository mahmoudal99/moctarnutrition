import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/workout_model.dart';
import '../../../../shared/models/workout_plan_model.dart';
import '../../../../shared/providers/workout_provider.dart';
import '../../../../shared/providers/exercise_provider.dart';
import '../widgets/exercise_card.dart';
import '../widgets/exercise_search_filter.dart';

class AddExerciseScreen extends StatefulWidget {
  final DailyWorkout dailyWorkout;
  final WorkoutModel workout;

  const AddExerciseScreen({
    super.key,
    required this.dailyWorkout,
    required this.workout,
  });

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  static final _logger = Logger();

  @override
  void initState() {
    super.initState();
    // The ExerciseProvider will automatically load exercises in its constructor
  }

  Future<void> _addExerciseToWorkout(Exercise exercise) async {
    try {
      // Check if this is a temporary workout (from add workout screen)
      if (widget.workout.id == 'temp_workout') {
        // For temporary workouts, just return the exercise to be added
        final exerciseWithOrder = Exercise(
          id: exercise.id,
          name: exercise.name,
          description: exercise.description,
          videoUrl: exercise.videoUrl,
          imageUrl: exercise.imageUrl,
          sets: exercise.sets,
          reps: exercise.reps,
          tempo: exercise.tempo,
          duration: exercise.duration,
          restTime: exercise.restTime,
          equipment: exercise.equipment,
          muscleGroups: exercise.muscleGroups,
          order: widget.workout.exercises.length + 1,
          formCues: exercise.formCues,
        );
        
        if (mounted) {
          // Provide haptic feedback for successful addition
          HapticFeedback.lightImpact();
          
          Navigator.pop(context, exerciseWithOrder); // Return the exercise
        }
      } else {
        // For existing workouts, add to the actual workout
        final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
        
        // Set the correct order for the new exercise
        final newOrder = widget.workout.exercises.length + 1;
        final exerciseWithOrder = Exercise(
          id: exercise.id,
          name: exercise.name,
          description: exercise.description,
          videoUrl: exercise.videoUrl,
          imageUrl: exercise.imageUrl,
          sets: exercise.sets,
          reps: exercise.reps,
          tempo: exercise.tempo,
          duration: exercise.duration,
          restTime: exercise.restTime,
          equipment: exercise.equipment,
          muscleGroups: exercise.muscleGroups,
          order: newOrder,
          formCues: exercise.formCues,
        );
        
        await workoutProvider.addExerciseToWorkout(
          widget.dailyWorkout.dayName, 
          widget.workout.id, 
          exerciseWithOrder,
        );
        
        if (mounted) {
          // Provide haptic feedback for successful addition
          HapticFeedback.lightImpact();
          
          Navigator.pop(context, true); // Return true to indicate success
        }
      }
    } catch (e) {
      _logger.e('Failed to add exercise to workout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add exercise. Please try again.'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ExerciseProvider(),
      child: Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          title: Text('Add Exercise to ${widget.workout.title}'),
          backgroundColor: AppConstants.surfaceColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppConstants.textPrimary),
          titleTextStyle: AppTextStyles.heading5.copyWith(
            color: AppConstants.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        body: Consumer<ExerciseProvider>(
          builder: (context, exerciseProvider, child) {
            return Column(
              children: [
                // Search and filter section
                ExerciseSearchFilter(),
                
                // Exercises list
                Expanded(
                  child: exerciseProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : exerciseProvider.error != null
                          ? _buildErrorState(exerciseProvider)
                          : _buildExercisesList(exerciseProvider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(ExerciseProvider exerciseProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppConstants.errorColor,
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Oops!',
              style: AppTextStyles.heading4.copyWith(
                color: AppConstants.errorColor,
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              exerciseProvider.error!,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingL),
            ElevatedButton(
              onPressed: exerciseProvider.refreshExercises,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: AppConstants.surfaceColor,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExercisesList(ExerciseProvider exerciseProvider) {
    if (!exerciseProvider.hasFilteredResults) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: AppConstants.textTertiary,
              ),
              const SizedBox(height: AppConstants.spacingM),
              Text(
                'No exercises found',
                style: AppTextStyles.heading4.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingS),
              Text(
                'Try adjusting your search or filter criteria',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppConstants.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      itemCount: exerciseProvider.filteredExercises.length,
      itemBuilder: (context, index) {
        final exercise = exerciseProvider.filteredExercises[index];
        return ExerciseCard(
          exercise: exercise,
          onAdd: () => _addExerciseToWorkout(exercise),
        );
      },
    );
  }
} 