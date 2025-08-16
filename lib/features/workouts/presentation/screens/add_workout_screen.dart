import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/workout_model.dart';
import '../../../../shared/models/workout_plan_model.dart';
import '../../../../shared/providers/workout_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import 'add_exercise_screen.dart';

class AddWorkoutScreen extends StatefulWidget {
  final DailyWorkout dailyWorkout;

  const AddWorkoutScreen({
    super.key,
    required this.dailyWorkout,
  });

  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  static final _logger = Logger();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  WorkoutDifficulty _selectedDifficulty = WorkoutDifficulty.beginner;
  List<Exercise> _exercises = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Custom Workout';
    _descriptionController.text = 'Your personalized workout';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addExercise() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExerciseScreen(
          dailyWorkout: widget.dailyWorkout,
          workout: WorkoutModel(
            id: 'temp_workout',
            title: _titleController.text.trim().isEmpty ? 'Custom Workout' : _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty ? 'Your personalized workout' : _descriptionController.text.trim(),
            trainerId: 'temp',
            trainerName: 'You',
            difficulty: _selectedDifficulty,
            category: WorkoutCategory.strength, // Will be overridden
            estimatedDuration: 0,
            exercises: _exercises,
            tags: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      ),
    ).then((result) {
      if (result != null) {
        if (result is Exercise) {
          // Exercise was added from library
          setState(() {
            _exercises.add(result);
          });
        } else if (result == true) {
          // Exercise was added to existing workout
          setState(() {
            // The exercise list will be updated when we return
          });
        }
      }
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
      // Reorder exercises
      for (int i = 0; i < _exercises.length; i++) {
        _exercises[i] = Exercise(
          id: _exercises[i].id,
          name: _exercises[i].name,
          description: _exercises[i].description,
          videoUrl: _exercises[i].videoUrl,
          imageUrl: _exercises[i].imageUrl,
          sets: _exercises[i].sets,
          reps: _exercises[i].reps,
          tempo: _exercises[i].tempo,
          duration: _exercises[i].duration,
          restTime: _exercises[i].restTime,
          equipment: _exercises[i].equipment,
          muscleGroups: _exercises[i].muscleGroups,
          order: i + 1,
          formCues: _exercises[i].formCues,
        );
      }
    });
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final exercise = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, exercise);
      
      // Reorder exercises
      for (int i = 0; i < _exercises.length; i++) {
        _exercises[i] = Exercise(
          id: _exercises[i].id,
          name: _exercises[i].name,
          description: _exercises[i].description,
          videoUrl: _exercises[i].videoUrl,
          imageUrl: _exercises[i].imageUrl,
          sets: _exercises[i].sets,
          reps: _exercises[i].reps,
          tempo: _exercises[i].tempo,
          duration: _exercises[i].duration,
          restTime: _exercises[i].restTime,
          equipment: _exercises[i].equipment,
          muscleGroups: _exercises[i].muscleGroups,
          order: i + 1,
          formCues: _exercises[i].formCues,
        );
      }
    });
  }

  Future<void> _createWorkout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one exercise to your workout'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);

      // Get user's preferred workout category from onboarding
      final userPreferences = authProvider.userModel?.preferences;
      final preferredWorkoutStyles = userPreferences?.preferredWorkoutStyles ?? ['strength'];
      
      // Map workout styles to category (default to strength if no clear mapping)
      WorkoutCategory workoutCategory = WorkoutCategory.strength;
      if (preferredWorkoutStyles.contains('cardio')) {
        workoutCategory = WorkoutCategory.cardio;
      } else if (preferredWorkoutStyles.contains('hiit')) {
        workoutCategory = WorkoutCategory.hiit;
      } else if (preferredWorkoutStyles.contains('yoga')) {
        workoutCategory = WorkoutCategory.yoga;
      } else if (preferredWorkoutStyles.contains('pilates')) {
        workoutCategory = WorkoutCategory.pilates;
      } else if (preferredWorkoutStyles.contains('flexibility')) {
        workoutCategory = WorkoutCategory.flexibility;
      }
      
      // Create custom workout
      final workout = WorkoutModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        trainerId: authProvider.userModel?.id ?? 'user',
        trainerName: authProvider.userModel?.name ?? 'You',
        difficulty: _selectedDifficulty,
        category: workoutCategory,
        estimatedDuration: _exercises.length * 3, // Rough estimate: 3 minutes per exercise
        exercises: _exercises,
        tags: [workoutCategory.toString().split('.').last],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await workoutProvider.addWorkoutToDay(widget.dailyWorkout.dayName, workout);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created "${workout.title}" for ${widget.dailyWorkout.dayName}'),
            backgroundColor: AppConstants.primaryColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      _logger.e('Failed to create workout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create workout. Please try again.'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text('Create Workout for ${widget.dailyWorkout.dayName}'),
        backgroundColor: AppConstants.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.textPrimary),
        titleTextStyle: AppTextStyles.heading5.copyWith(
          color: AppConstants.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Workout details form
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                children: [
                  // Workout title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Workout Title',
                      hintText: 'e.g., Upper Body Strength',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a workout title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  
                  // Workout description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Brief description of your workout',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  
                  // Difficulty selection
                  Text(
                    'Difficulty',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  DropdownButtonFormField<WorkoutDifficulty>(
                    value: _selectedDifficulty,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: WorkoutDifficulty.values.map((difficulty) {
                      return DropdownMenuItem(
                        value: difficulty,
                        child: Text(difficulty.toString().split('.').last),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedDifficulty = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppConstants.spacingL),
                  
                  // Exercises section
                  Row(
                    children: [
                      Text(
                        'Exercises (${_exercises.length})',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _addExercise,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Exercise'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: AppConstants.surfaceColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  
                  // Exercises list
                  if (_exercises.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppConstants.spacingL),
                      decoration: BoxDecoration(
                        color: AppConstants.surfaceColor,
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                        border: Border.all(
                          color: AppConstants.textTertiary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 48,
                            color: AppConstants.textTertiary,
                          ),
                          const SizedBox(height: AppConstants.spacingM),
                          Text(
                            'No exercises yet',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppConstants.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingS),
                          Text(
                            'Tap "Add Exercise" to start building your workout',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppConstants.textTertiary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _exercises.length,
                      onReorder: _reorderExercises,
                      itemBuilder: (context, index) {
                        final exercise = _exercises[index];
                        return _ExerciseCard(
                          key: ValueKey(exercise.id),
                          exercise: exercise,
                          onRemove: () => _removeExercise(index),
                        );
                      },
                    ),
                ],
              ),
            ),
            
            // Create workout button
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: AppConstants.surfaceColor,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.spacingM,
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: AppConstants.surfaceColor)
                      : const Text('Create Workout'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onRemove;

  const _ExerciseCard({
    required Key key,
    required this.exercise,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Drag handle
          Icon(
            Icons.drag_handle,
            color: AppConstants.textTertiary,
            size: 20,
          ),
          const SizedBox(width: AppConstants.spacingS),
          
          // Exercise number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusXS),
            ),
            child: Center(
              child: Text(
                '${exercise.order}',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppConstants.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spacingS),
          
          // Exercise details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                Text(
                  '${exercise.sets} sets × ${exercise.duration != null ? '${exercise.duration}s' : '${exercise.reps} reps'}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Remove button
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline),
            color: AppConstants.errorColor,
            tooltip: 'Remove exercise',
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}
