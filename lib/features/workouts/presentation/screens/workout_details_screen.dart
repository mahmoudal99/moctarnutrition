import 'package:champions_gym_app/shared/widgets/app_bar_title.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/workout_plan_model.dart';
import '../../../../shared/models/workout_model.dart';
import '../../../../shared/providers/workout_provider.dart';
import 'add_workout_screen.dart';
import 'add_exercise_screen.dart';

class WorkoutDetailsScreen extends StatefulWidget {
  final DailyWorkout dailyWorkout;

  const WorkoutDetailsScreen({
    super.key,
    required this.dailyWorkout,
  });

  @override
  State<WorkoutDetailsScreen> createState() => _WorkoutDetailsScreenState();
}

class _WorkoutDetailsScreenState extends State<WorkoutDetailsScreen> {
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, workoutProvider, child) {
        // Get the current daily workout from the provider to ensure real-time updates
        final currentDailyWorkout =
            workoutProvider.getWorkoutForDay(widget.dailyWorkout.dayName);

        return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          appBar: AppBar(
            title: AppBarTitle(
                title:
                    currentDailyWorkout?.title ?? widget.dailyWorkout.title),
            backgroundColor: AppConstants.surfaceColor,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppConstants.textPrimary),
            titleTextStyle: AppTextStyles.heading5.copyWith(
              color: AppConstants.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            actions: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _isEditMode = !_isEditMode;
                  });
                },
                icon: Icon(_isEditMode ? Icons.check : Icons.edit, size: 20,),
                tooltip: _isEditMode ? 'Done' : 'Edit',
                color: AppConstants.textTertiary,
              ),
            ],
          ),
          body: (currentDailyWorkout?.isRestDay ?? widget.dailyWorkout.isRestDay) ||
                  (currentDailyWorkout?.workouts.isEmpty ??
                      widget.dailyWorkout.workouts.isEmpty)
              ? _buildRestDayContent(context)
              : _buildWorkoutContent(
                  context,
                  currentDailyWorkout ?? widget.dailyWorkout,
                  _isEditMode,
                ),
          floatingActionButton:
              (!(currentDailyWorkout?.isRestDay ?? widget.dailyWorkout.isRestDay) &&
                      !(currentDailyWorkout?.workouts.isEmpty ??
                          widget.dailyWorkout.workouts.isEmpty))
                  ? FloatingActionButton.extended(
                      onPressed: () => _navigateToAddWorkout(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Workout'),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    )
                  : null,
          extendBody: true, // This might help with the bottom bar issue
        );
      },
    );
  }

  Widget _buildRestDayContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Benefits of rest
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(
                color: AppConstants.textTertiary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.psychology,
                      color: AppConstants.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    Text(
                      'Why Rest Days Matter',
                      style: AppTextStyles.heading5.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingM),
                ..._getRestDayBenefits(),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingXL),

          // Motivational message
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.primaryColor.withOpacity(0.1),
                  AppConstants.primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(
                color: AppConstants.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 32,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(height: AppConstants.spacingM),
                Text(
                  'You\'re doing great!',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingS),
                Text(
                  'Rest is just as important as training. Your body needs time to recover and grow stronger.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppConstants.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRestDayIcon() {
    final restDayMessage = widget.dailyWorkout.restDay?.toLowerCase() ?? '';

    if (restDayMessage.contains('active') || restDayMessage.contains('light')) {
      return Icons.directions_walk;
    } else if (restDayMessage.contains('stretch') ||
        restDayMessage.contains('flexibility')) {
      return Icons.accessibility;
    } else if (restDayMessage.contains('yoga') ||
        restDayMessage.contains('meditation')) {
      return Icons.self_improvement;
    } else {
      return Icons.bedtime;
    }
  }

  String _getRestDayTitle() {
    final restDayMessage = widget.dailyWorkout.restDay?.toLowerCase() ?? '';

    if (restDayMessage.contains('active')) {
      return 'Active Recovery';
    } else if (restDayMessage.contains('stretch')) {
      return 'Stretching Day';
    } else if (restDayMessage.contains('yoga')) {
      return 'Yoga Day';
    } else {
      return 'Rest Day';
    }
  }

  List<Widget> _getRestDayBenefits() {
    final restDayMessage = widget.dailyWorkout.restDay?.toLowerCase() ?? '';
    final benefits = <Widget>[];

    if (restDayMessage.contains('active') || restDayMessage.contains('light')) {
      benefits.addAll([
        _buildRestBenefit(
          Icons.directions_walk,
          'Active Recovery',
          'Light movement promotes blood flow and recovery',
        ),
        const SizedBox(height: AppConstants.spacingS),
        _buildRestBenefit(
          Icons.healing,
          'Muscle Repair',
          'Gentle activity helps muscles recover faster',
        ),
        const SizedBox(height: AppConstants.spacingS),
        _buildRestBenefit(
          Icons.psychology,
          'Mental Clarity',
          'Light exercise reduces stress and improves mood',
        ),
      ]);
    } else if (restDayMessage.contains('stretch') ||
        restDayMessage.contains('flexibility')) {
      benefits.addAll([
        _buildRestBenefit(
          Icons.accessibility,
          'Flexibility',
          'Improves range of motion and joint health',
        ),
        const SizedBox(height: AppConstants.spacingS),
        _buildRestBenefit(
          Icons.healing,
          'Muscle Recovery',
          'Stretching helps release muscle tension',
        ),
        const SizedBox(height: AppConstants.spacingS),
        _buildRestBenefit(
          Icons.trending_up,
          'Injury Prevention',
          'Better flexibility reduces injury risk',
        ),
      ]);
    } else if (restDayMessage.contains('yoga') ||
        restDayMessage.contains('meditation')) {
      benefits.addAll([
        _buildRestBenefit(
          Icons.self_improvement,
          'Mind-Body Connection',
          'Yoga promotes mental and physical balance',
        ),
        const SizedBox(height: AppConstants.spacingS),
        _buildRestBenefit(
          Icons.psychology,
          'Stress Relief',
          'Meditation and breathing reduce stress',
        ),
        const SizedBox(height: AppConstants.spacingS),
        _buildRestBenefit(
          Icons.healing,
          'Recovery',
          'Gentle poses aid muscle recovery',
        ),
      ]);
    } else {
      benefits.addAll([
        _buildRestBenefit(
          Icons.healing,
          'Muscle Recovery',
          'Allows muscles to repair and grow stronger',
        ),
        const SizedBox(height: AppConstants.spacingS),
        _buildRestBenefit(
          Icons.psychology,
          'Mental Refresh',
          'Reduces mental fatigue and improves focus',
        ),
        const SizedBox(height: AppConstants.spacingS),
        _buildRestBenefit(
          Icons.trending_up,
          'Performance Boost',
          'Prevents overtraining and improves future workouts',
        ),
      ]);
    }

    return benefits;
  }

  Widget _buildRestBenefit(IconData icon, String title, String description) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppConstants.primaryColor,
        ),
        const SizedBox(width: AppConstants.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              Text(
                description,
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutContent(BuildContext context,
      DailyWorkout currentDailyWorkout, bool isEditMode) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingM,
        AppConstants.spacingM,
        AppConstants.spacingM,
        128,
      ),
      itemCount: currentDailyWorkout.workouts.length,
      itemBuilder: (context, index) {
        final workout = currentDailyWorkout.workouts[index];
        return _WorkoutCard(
          workout: workout,
          dayName: currentDailyWorkout.dayName,
          dailyWorkout: currentDailyWorkout,
          onRemove: () =>
              _removeWorkout(context, workout.id, currentDailyWorkout),
          isEditMode: isEditMode,
        );
      },
    );
  }

  void _navigateToAddWorkout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddWorkoutScreen(dailyWorkout: widget.dailyWorkout),
      ),
    ).then((result) {
      // If a workout was successfully added, the UI will automatically update
      // because the WorkoutProvider notifies listeners when the workout plan changes
      if (result == true) {
        // The workout was added successfully, no need to do anything
        // as the provider will trigger a rebuild
      }
    });
  }

  void _removeWorkout(BuildContext context, String workoutId,
      DailyWorkout currentDailyWorkout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Workout'),
        content: const Text(
            'Are you sure you want to remove this workout from your plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmRemoveWorkout(context, workoutId, currentDailyWorkout);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.errorColor,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveWorkout(BuildContext context, String workoutId,
      DailyWorkout currentDailyWorkout) async {
    try {
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      await workoutProvider.removeWorkoutFromDay(
          currentDailyWorkout.dayName, workoutId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout removed from plan'),
            backgroundColor: AppConstants.primaryColor,
          ),
        );
        Navigator.pop(context); // Close the screen
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove workout. Please try again.'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }
}

class _WorkoutCard extends StatelessWidget {
  final WorkoutModel workout;
  final String dayName;
  final VoidCallback? onRemove;
  final DailyWorkout dailyWorkout;
  final bool isEditMode;

  const _WorkoutCard({
    required this.workout,
    required this.dayName,
    required this.dailyWorkout,
    this.onRemove,
    required this.isEditMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  workout.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isEditMode && onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppConstants.errorColor,
                  tooltip: 'Remove workout',
                ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingXS),
          Text(
            workout.description,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Exercises:',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          ...workout.exercises.map((exercise) => _ExerciseItem(
                exercise: exercise,
                dayName: dayName,
                workoutId: workout.id,
                onRemove: () => _removeExercise(
                    context, exercise.id, dailyWorkout, workout.id),
                isEditMode: isEditMode,
              )),
          const SizedBox(height: AppConstants.spacingM),
          // Add exercise button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  _navigateToAddExercise(context, workout, dailyWorkout),
              icon: const Icon(Icons.add),
              label: const Text('Add Exercise'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: AppConstants.textTertiary),
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.spacingS,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _removeExercise(BuildContext context, String exerciseId,
      DailyWorkout currentDailyWorkout, String workoutId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Exercise'),
        content: const Text(
            'Are you sure you want to remove this exercise from your workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmRemoveExercise(
                  context, exerciseId, currentDailyWorkout, workoutId);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.errorColor,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveExercise(BuildContext context, String exerciseId,
      DailyWorkout currentDailyWorkout, String workoutId) async {
    try {
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      await workoutProvider.removeExerciseFromWorkout(
        currentDailyWorkout.dayName,
        workoutId,
        exerciseId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exercise removed from workout'),
            backgroundColor: AppConstants.primaryColor,
          ),
        );
        Navigator.pop(context); // Close the screen
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove exercise. Please try again.'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  void _navigateToAddExercise(BuildContext context, WorkoutModel workout,
      DailyWorkout currentDailyWorkout) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExerciseScreen(
          dailyWorkout: currentDailyWorkout,
          workout: workout,
        ),
      ),
    ).then((result) {
      // If an exercise was successfully added, the UI will automatically update
      // because the WorkoutProvider notifies listeners when the workout plan changes
      if (result == true) {
        // The exercise was added successfully, no need to do anything
        // as the provider will trigger a rebuild
      }
    });
  }
}

class _ExerciseItem extends StatelessWidget {
  final Exercise exercise;
  final String dayName;
  final String workoutId;
  final VoidCallback? onRemove;
  final bool isEditMode;

  const _ExerciseItem({
    required this.exercise,
    required this.dayName,
    required this.workoutId,
    this.onRemove,
    required this.isEditMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      padding: const EdgeInsets.all(AppConstants.spacingS),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Row(
        children: [
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
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingS),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${exercise.sets} sets',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppConstants.primaryColor,
                ),
              ),
              Text(
                exercise.duration != null
                    ? '${exercise.duration}s'
                    : '${exercise.reps} reps',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppConstants.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (isEditMode && onRemove != null) ...[
            const SizedBox(width: AppConstants.spacingS),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline),
              color: AppConstants.errorColor,
              tooltip: 'Remove exercise',
              iconSize: 20,
            ),
          ],
        ],
      ),
    );
  }
}
