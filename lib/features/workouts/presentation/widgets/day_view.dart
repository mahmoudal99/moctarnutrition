import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/workout_plan_model.dart';
import '../../../../shared/models/workout_model.dart';

class DayView extends StatelessWidget {
  final DailyWorkout dailyWorkout;

  const DayView({
    super.key,
    required this.dailyWorkout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDayHeader(),
        const SizedBox(height: AppConstants.spacingL),
        if (dailyWorkout.isRestDay)
          _buildRestDayContent()
        else
          _buildWorkoutContent(),
      ],
    );
  }

  Widget _buildDayHeader() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.spacingM),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: AppConstants.shadowS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: AppConstants.spacingS),
              Text(
                dailyWorkout.dayName,
                style: AppTextStyles.heading4.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingS,
                  vertical: AppConstants.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: dailyWorkout.isRestDay
                      ? AppConstants.primaryColor.withOpacity(0.1)
                      : AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: Text(
                  dailyWorkout.isRestDay ? 'Rest Day' : 'Workout Day',
                  style: AppTextStyles.caption.copyWith(
                    color: dailyWorkout.isRestDay
                        ? AppConstants.primaryColor
                        : AppConstants.surfaceColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (!dailyWorkout.isRestDay) ...[
            const SizedBox(height: AppConstants.spacingS),
            Text(
              '${dailyWorkout.workouts.length} workout${dailyWorkout.workouts.length != 1 ? 's' : ''} • ${dailyWorkout.estimatedDuration} min',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRestDayContent() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.spacingM),
      padding: const EdgeInsets.all(AppConstants.spacingXL),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: AppConstants.shadowS,
      ),
      child: Column(
        children: [
          Icon(
            Icons.bedtime,
            size: 64,
            color: AppConstants.primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Rest Day',
            style: AppTextStyles.heading4.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Take time to recover and prepare for your next workout.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppConstants.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutContent() {
    return Column(
      children: dailyWorkout.workouts.map((workout) {
        return Container(
          margin: const EdgeInsets.all(AppConstants.spacingM),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            boxShadow: AppConstants.shadowS,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWorkoutHeader(workout),
              if (workout.exercises.isNotEmpty) ...[
                const Divider(height: 1),
                _buildExercisesList(workout),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWorkoutHeader(WorkoutModel workout) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingM),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingS,
                  vertical: AppConstants.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: _getCategoryColor(workout.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: Text(
                  workout.category.toString().split('.').last,
                  style: AppTextStyles.caption.copyWith(
                    color: _getCategoryColor(workout.category),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (workout.description.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spacingXS),
            Text(
              workout.description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppConstants.spacingS),
          Row(
            children: [
              _buildWorkoutInfo(
                Icons.fitness_center,
                '${workout.exercises.length} exercises',
              ),
              const SizedBox(width: AppConstants.spacingM),
              _buildWorkoutInfo(
                Icons.schedule,
                '${workout.estimatedDuration} min',
              ),
              const SizedBox(width: AppConstants.spacingM),
              _buildWorkoutInfo(
                Icons.trending_up,
                workout.difficulty.toString().split('.').last,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: AppConstants.textTertiary,
        ),
        const SizedBox(width: AppConstants.spacingXS),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: AppConstants.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildExercisesList(WorkoutModel workout) {
    return Column(
      children: workout.exercises.map((exercise) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingS,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: Center(
                  child: Text(
                    '${exercise.order}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${exercise.sets} sets • ${exercise.duration != null ? '${exercise.duration}s' : '${exercise.reps} reps'}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (exercise.equipment != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingS,
                    vertical: AppConstants.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.textTertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                  child: Text(
                    exercise.equipment!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppConstants.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getCategoryColor(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.strength:
        return const Color(0xFF10B981);
      case WorkoutCategory.cardio:
        return const Color(0xFF3B82F6);
      case WorkoutCategory.hiit:
        return const Color(0xFFEF4444);
      case WorkoutCategory.flexibility:
        return const Color(0xFF8B5CF6);
      case WorkoutCategory.yoga:
        return const Color(0xFF06B6D4);
      case WorkoutCategory.pilates:
        return const Color(0xFFEC4899);
      default:
        return AppConstants.primaryColor;
    }
  }
} 