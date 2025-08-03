import 'package:flutter/material.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../shared/models/user_model.dart';

class FinalReviewStep extends StatelessWidget {
  final UserPreferences userPreferences;
  final int selectedDays;

  const FinalReviewStep({
    super.key,
    required this.userPreferences,
    required this.selectedDays,
  });

  String _fitnessGoalName(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return 'Weight Loss';
      case FitnessGoal.muscleGain:
        return 'Muscle Gain';
      case FitnessGoal.maintenance:
        return 'Maintenance';
      case FitnessGoal.endurance:
        return 'Endurance';
      case FitnessGoal.strength:
        return 'Strength';
    }
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'days':
        return Icons.calendar_today;
      case 'calories':
        return Icons.local_fire_department;
      case 'goal':
        return Icons.flag;
      case 'restrictions':
        return Icons.no_food;
      case 'workout':
        return Icons.fitness_center;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppConstants.surfaceColor.withOpacity(0.98),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppConstants.spacingL),
              Text(
                'Final Review',
                style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingL),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _reviewRow(
                        icon: _iconFor('days'),
                        label: 'Plan Duration',
                        value: '$selectedDays days',
                      ),
                      const SizedBox(height: 16),
                      _reviewRow(
                        icon: _iconFor('goal'),
                        label: 'Fitness Goal',
                        value: _fitnessGoalName(userPreferences.fitnessGoal),
                      ),
                      const SizedBox(height: 16),
                      _reviewRow(
                        icon: _iconFor('restrictions'),
                        label: 'Dietary Restrictions',
                        value: (userPreferences.dietaryRestrictions.isEmpty ||
                                (userPreferences.dietaryRestrictions.length == 1 &&
                                    userPreferences.dietaryRestrictions.first == 'None'))
                            ? 'None'
                            : userPreferences.dietaryRestrictions.join(', '),
                      ),
                      const SizedBox(height: 16),
                      _reviewRow(
                        icon: _iconFor('workout'),
                        label: 'Preferred Workouts',
                        value: userPreferences.preferredWorkoutStyles.join(', '),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reviewRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppConstants.primaryColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 