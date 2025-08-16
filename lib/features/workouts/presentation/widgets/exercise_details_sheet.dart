import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/workout_model.dart';

class ExerciseDetailsSheet extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onAdd;

  const ExerciseDetailsSheet({
    super.key,
    required this.exercise,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
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
                        exercise.name,
                        style: AppTextStyles.heading5.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        exercise.muscleGroups.join(', '),
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
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              children: [
                Text(
                  exercise.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingL),
                _buildDetailRow('Sets', '${exercise.sets}'),
                _buildDetailRow(
                  'Reps/Duration', 
                  exercise.duration != null 
                      ? '${exercise.duration} seconds'
                      : '${exercise.reps} reps',
                ),
                if (exercise.equipment != null)
                  _buildDetailRow('Equipment', exercise.equipment!),
                if (exercise.tempo != null)
                  _buildDetailRow('Tempo', exercise.tempo!),
                if (exercise.restTime != null)
                  _buildDetailRow('Rest Time', '${exercise.restTime} seconds'),
                const SizedBox(height: AppConstants.spacingL),
                Text(
                  'Muscle Groups',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingS),
                Wrap(
                  spacing: AppConstants.spacingS,
                  children: exercise.muscleGroups.map((muscleGroup) => 
                    Chip(
                      label: Text(muscleGroup),
                      backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                      labelStyle: AppTextStyles.bodySmall.copyWith(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ).toList(),
                ),
                const SizedBox(height: AppConstants.spacingL),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onAdd();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: AppConstants.surfaceColor,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppConstants.spacingM,
                      ),
                    ),
                    child: const Text('Add to Workout'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 