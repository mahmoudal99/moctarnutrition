import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/workout_plan_model.dart';

class WorkoutPlanHeader extends StatelessWidget {
  final WorkoutPlanModel workoutPlan;

  const WorkoutPlanHeader({
    super.key,
    required this.workoutPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workoutPlan.title,
                      style: AppTextStyles.heading5.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Text(
                      _getWorkoutTypeLabel(workoutPlan.type),
                      style: AppTextStyles.caption.copyWith(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            workoutPlan.description,
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Row(
            children: [
              _buildStatItem(
                Icons.calendar_today,
                '${workoutPlan.dailyWorkouts.length} days',
                'Program Length',
              ),
              const SizedBox(width: AppConstants.spacingL),
              _buildStatItem(
                Icons.timer,
                '${_calculateTotalDuration()} min',
                'Total Time',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppConstants.textSecondary,
          ),
          const SizedBox(width: AppConstants.spacingXS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWorkoutTypeIcon(WorkoutPlanType type) {
    switch (type) {
      case WorkoutPlanType.strength:
        return Icons.fitness_center;
      case WorkoutPlanType.bodybuilding:
        return Icons.sports_gymnastics;
      case WorkoutPlanType.cardio:
        return Icons.favorite;
      case WorkoutPlanType.hiit:
        return Icons.timer;
      case WorkoutPlanType.running:
        return Icons.directions_run;
      case WorkoutPlanType.ai_generated:
        return Icons.psychology;
    }
  }

  String _getWorkoutTypeLabel(WorkoutPlanType type) {
    switch (type) {
      case WorkoutPlanType.strength:
        return 'Strength Training';
      case WorkoutPlanType.bodybuilding:
        return 'Body Building';
      case WorkoutPlanType.cardio:
        return 'Cardio';
      case WorkoutPlanType.hiit:
        return 'HIIT';
      case WorkoutPlanType.running:
        return 'Running';
      case WorkoutPlanType.ai_generated:
        return 'Generated';
    }
  }

  int _calculateTotalDuration() {
    return workoutPlan.dailyWorkouts
        .fold(0, (sum, day) => sum + day.estimatedDuration);
  }
}
