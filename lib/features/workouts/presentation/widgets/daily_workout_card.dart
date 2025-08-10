import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/workout_plan_model.dart';
import '../../../../shared/models/workout_model.dart';

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
            if (!dailyWorkout.isRestDay) {
              _showWorkoutDetails(context);
            }
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
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppConstants.primaryColor
                            : AppConstants.textTertiary.withOpacity(0.08),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusS),
                      ),
                      child: Icon(
                        _getDayIcon(),
                        color: isToday
                            ? AppConstants.surfaceColor
                            : AppConstants.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingM),
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
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!dailyWorkout.isRestDay) ...[
                      Icon(
                        Icons.chevron_right,
                        color: AppConstants.textTertiary,
                        size: 20,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 0),
                if (dailyWorkout.isRestDay)
                  ...[]
                else ...[
                  Text(
                    dailyWorkout.description,
                    style: AppTextStyles.caption,
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
          color: AppConstants.textSecondary,
        ),
        const SizedBox(width: AppConstants.spacingXS),
        Text(
          text,
          style: AppTextStyles.caption,
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
                Icon(
                  Icons.fitness_center,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppConstants.spacingM),
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
          // Workout list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              itemCount: dailyWorkout.workouts.length,
              itemBuilder: (context, index) {
                final workout = dailyWorkout.workouts[index];
                return _WorkoutCard(workout: workout);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final WorkoutModel workout;

  const _WorkoutCard({
    required this.workout,
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
          Text(
            workout.title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXS),
          Text(
            workout.description,
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Exercises:',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          ...workout.exercises
              .map((exercise) => _ExerciseItem(exercise: exercise)),
        ],
      ),
    );
  }
}

class _ExerciseItem extends StatelessWidget {
  final Exercise exercise;

  const _ExerciseItem({
    required this.exercise,
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  exercise.description,
                  style: AppTextStyles.caption,
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
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                exercise.duration != null
                    ? '${exercise.duration}s'
                    : '${exercise.reps} reps',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
