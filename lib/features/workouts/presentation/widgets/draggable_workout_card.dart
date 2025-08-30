import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/workout_plan_model.dart';

class DraggableWorkoutCard extends StatelessWidget {
  final DailyWorkout dailyWorkout;
  final bool isToday;
  final bool isEditMode;

  const DraggableWorkoutCard({
    super.key,
    required this.dailyWorkout,
    this.isToday = false,
    this.isEditMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEditMode ? null : () => _showWorkoutDetails(context),
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
                    if (isEditMode) ...[
                      Container(
                        padding: const EdgeInsets.all(AppConstants.spacingXS),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusXS),
                        ),
                        child: const Icon(
                          Icons.drag_handle,
                          size: 16,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingS),
                    ],
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
                    if (!isEditMode) ...[
                      const Icon(
                        Icons.chevron_right,
                        color: AppConstants.textTertiary,
                        size: 20,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppConstants.spacingS),
                Row(
                  children: [
                    Icon(
                      dailyWorkout.isRestDay
                          ? Icons.bedtime
                          : Icons.fitness_center,
                      size: 16,
                      color: dailyWorkout.isRestDay
                          ? AppConstants.textTertiary
                          : AppConstants.primaryColor,
                    ),
                    const SizedBox(width: AppConstants.spacingXS),
                    Expanded(
                      child: Text(
                        dailyWorkout.isRestDay
                            ? 'Rest Day'
                            : '${dailyWorkout.workouts.length} workout${dailyWorkout.workouts.length == 1 ? '' : 's'} • ${dailyWorkout.estimatedDuration} min',
                        style: AppTextStyles.caption.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isEditMode && !dailyWorkout.isRestDay) {
      return Draggable<DailyWorkout>(
        data: dailyWorkout,
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child: Container(
            width: MediaQuery.of(context).size.width - 32,
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(
                color: AppConstants.primaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: card,
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: card,
        ),
        child: card,
      );
    }

    return card;
  }

  void _showWorkoutDetails(BuildContext context) {
    context.push('/workout-details', extra: dailyWorkout);
  }
}
