import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/workout_plan_model.dart';
import '../../../../shared/models/workout_model.dart';
import '../../../../shared/providers/workout_provider.dart';
import '../screens/add_workout_screen.dart';
import '../screens/add_exercise_screen.dart';

class DailyWorkoutCard extends StatelessWidget {
  final DailyWorkout dailyWorkout;
  final bool isToday;

  const DailyWorkoutCard({
    super.key,
    required this.dailyWorkout,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showWorkoutDetails(context);
          },
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: isToday
                  ? AppConstants.primaryColor.withOpacity(0.08)
                  : AppConstants.surfaceColor,
              border: Border.all(
                color: isToday
                    ? AppConstants.primaryColor.withOpacity(0.3)
                    : AppConstants.textTertiary.withOpacity(0.2),
                width: isToday ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              boxShadow: isToday ? AppConstants.shadowS : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                dailyWorkout.dayName,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isToday
                                      ? AppConstants.primaryColor
                                      : AppConstants.textPrimary,
                                ),
                              ),
                              if (isToday) ...[
                                const SizedBox(width: AppConstants.spacingS),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppConstants.spacingS,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppConstants.primaryColor,
                                    borderRadius: BorderRadius.circular(
                                        AppConstants.radiusXS),
                                  ),
                                  child: Text(
                                    'TODAY',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppConstants.surfaceColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppConstants.spacingXS),
                          Text(
                            dailyWorkout.title,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppConstants.textTertiary,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 0),
                if (dailyWorkout.isRestDay) ...[
                  Text(
                    dailyWorkout.restDay ?? 'Time to rest and recover!',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  Row(
                    children: [
                      _buildWorkoutInfo(
                        Icons.bedtime,
                        'Rest Day',
                      ),
                      const SizedBox(width: AppConstants.spacingM),
                      _buildWorkoutInfo(
                        Icons.healing,
                        'Recovery',
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    dailyWorkout.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  Row(
                    children: [
                      _buildWorkoutInfo(
                        Icons.fitness_center,
                        '${dailyWorkout.workouts.length} workout${dailyWorkout.workouts.length != 1 ? 's' : ''}',
                      ),
                      const SizedBox(width: AppConstants.spacingM),
                      _buildWorkoutInfo(
                        Icons.timer,
                        '${dailyWorkout.estimatedDuration} min',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: AppConstants.primaryColor,
        ),
        const SizedBox(width: AppConstants.spacingXS),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppConstants.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  IconData _getDayIcon() {
    if (dailyWorkout.isRestDay) {
      return Icons.bedtime;
    }

    // Return different icons based on workout focus
    final title = dailyWorkout.title.toLowerCase();
    if (title.contains('chest') || title.contains('push')) {
      return Icons.fitness_center;
    } else if (title.contains('back') || title.contains('pull')) {
      return Icons.accessibility_new;
    } else if (title.contains('leg') || title.contains('lower')) {
      return Icons.directions_run;
    } else if (title.contains('shoulder')) {
      return Icons.sports_gymnastics;
    } else if (title.contains('arm')) {
      return Icons.fitness_center;
    } else if (title.contains('core')) {
      return Icons.accessibility;
    } else if (title.contains('full')) {
      return Icons.all_inclusive;
    } else {
      return Icons.fitness_center;
    }
  }

  void _showWorkoutDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WorkoutDetailsSheet(dailyWorkout: dailyWorkout),
    );
  }
}

class _WorkoutDetailsSheet extends StatelessWidget {
  final DailyWorkout dailyWorkout;

  const _WorkoutDetailsSheet({
    required this.dailyWorkout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusL),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: AppConstants.spacingM),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppConstants.textTertiary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dailyWorkout.title,
                        style: AppTextStyles.heading5.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        dailyWorkout.dayName,
                        style: AppTextStyles.caption.copyWith(
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(),
          // Content based on whether it's a rest day or workout day
          Expanded(
            child: dailyWorkout.isRestDay
                ? _buildRestDayContent(context)
                : _buildWorkoutContent(context),
          ),
          // Add workout button (only for workout days)
          if (!dailyWorkout.isRestDay)
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToAddWorkout(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Workout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: AppConstants.surfaceColor,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.spacingM,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRestDayContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Rest day title
          Text(
            _getRestDayTitle(),
            style: AppTextStyles.heading4.copyWith(
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          // Rest day message
          Text(
            dailyWorkout.restDay ?? 'Time to rest and recover!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppConstants.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingXL),
          // Benefits of rest
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
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
                Text(
                  'Why Rest Days Matter:',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingS),
                ..._getRestDayBenefits(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRestDayIcon() {
    final restDayMessage = dailyWorkout.restDay?.toLowerCase() ?? '';

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
    final restDayMessage = dailyWorkout.restDay?.toLowerCase() ?? '';

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
    final restDayMessage = dailyWorkout.restDay?.toLowerCase() ?? '';
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

  Widget _buildWorkoutContent(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      itemCount: dailyWorkout.workouts.length,
      itemBuilder: (context, index) {
        final workout = dailyWorkout.workouts[index];
        return _WorkoutCard(
          workout: workout,
          dayName: dailyWorkout.dayName,
          dailyWorkout: dailyWorkout,
          onRemove: () => _removeWorkout(context, workout.id),
        );
      },
    );
  }

  void _navigateToAddWorkout(BuildContext context) {
    Navigator.pop(context); // Close the current modal
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddWorkoutScreen(dailyWorkout: dailyWorkout),
      ),
    );
  }

  void _navigateToAddExercise(BuildContext context, WorkoutModel workout) {
    Navigator.pop(context); // Close the current modal
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExerciseScreen(
          dailyWorkout: dailyWorkout,
          workout: workout,
        ),
      ),
    );
  }

  void _removeWorkout(BuildContext context, String workoutId) {
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
              _confirmRemoveWorkout(context, workoutId);
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

  void _confirmRemoveWorkout(BuildContext context, String workoutId) async {
    try {
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      await workoutProvider.removeWorkoutFromDay(
          dailyWorkout.dayName, workoutId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout removed from plan'),
            backgroundColor: AppConstants.primaryColor,
          ),
        );
        Navigator.pop(context); // Close the modal
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

  const _WorkoutCard({
    required this.workout,
    required this.dayName,
    required this.dailyWorkout,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      padding: const EdgeInsets.all(AppConstants.spacingM),
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
              Expanded(
                child: Text(
                  workout.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onRemove != null)
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
                onRemove: () => _removeExercise(context, exercise.id),
              )),
          const SizedBox(height: AppConstants.spacingM),
          // Add exercise button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _navigateToAddExercise(context, workout),
              icon: const Icon(Icons.add),
              label: const Text('Add Exercise'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstants.primaryColor,
                side: const BorderSide(color: AppConstants.primaryColor),
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

  void _removeExercise(BuildContext context, String exerciseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Exercise'),
        content: const Text('Are you sure you want to remove this exercise from your workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmRemoveExercise(context, exerciseId);
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

  void _confirmRemoveExercise(BuildContext context, String exerciseId) async {
    try {
      final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
      await workoutProvider.removeExerciseFromWorkout(
        dayName, 
        workout.id, 
        exerciseId,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exercise removed from workout'),
            backgroundColor: AppConstants.primaryColor,
          ),
        );
        Navigator.pop(context); // Close the modal
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

  void _navigateToAddExercise(BuildContext context, WorkoutModel workout) {
    Navigator.pop(context); // Close the current modal
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExerciseScreen(
          dailyWorkout: dailyWorkout,
          workout: workout,
        ),
      ),
    );
  }
}

class _ExerciseItem extends StatelessWidget {
  final Exercise exercise;
  final String dayName;
  final String workoutId;
  final VoidCallback? onRemove;

  const _ExerciseItem({
    required this.exercise,
    required this.dayName,
    required this.workoutId,
    this.onRemove,
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
                // Text(
                //   exercise.description,
                //   style: AppTextStyles.bodySmall.copyWith(
                //     color: AppConstants.textSecondary,
                //   ),
                // ),
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
          if (onRemove != null) ...[
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
