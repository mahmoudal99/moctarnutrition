import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/workout_model.dart';
import 'exercise_details_sheet.dart';

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onAdd;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: AppConstants.shadowS,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showExerciseDetails(context);
          },
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
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
                            exercise.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingXS),
                          Text(
                            exercise.description,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppConstants.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppConstants.primaryColor,
                      tooltip: 'Add exercise',
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingS),
                Row(
                  children: [
                    _buildExerciseInfo(
                      Icons.fitness_center,
                      '${exercise.sets} sets',
                    ),
                    const SizedBox(width: AppConstants.spacingM),
                    _buildExerciseInfo(
                      Icons.repeat,
                      exercise.duration != null
                          ? '${exercise.duration}s'
                          : '${exercise.reps} reps',
                    ),
                    const SizedBox(width: AppConstants.spacingM),
                    _buildExerciseInfo(
                      Icons.category,
                      exercise.muscleGroups.first,
                    ),
                  ],
                ),
                if (exercise.equipment != null) ...[
                  const SizedBox(height: AppConstants.spacingS),
                  Text(
                    'Equipment: ${exercise.equipment}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppConstants.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseInfo(IconData icon, String text) {
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

  void _showExerciseDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseDetailsSheet(
        exercise: exercise,
        onAdd: onAdd,
      ),
    );
  }
}
