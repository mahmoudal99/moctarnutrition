import 'package:flutter/material.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../shared/models/user_model.dart';
import 'personalized_title.dart';

class FinalReviewStep extends StatelessWidget {
  final UserPreferences userPreferences;
  final int selectedDays;
  final String? userName;
  final String? cheatDay;
  final int targetCalories;
  final FitnessGoal? selectedFitnessGoal;

  const FinalReviewStep({
    super.key,
    required this.userPreferences,
    required this.selectedDays,
    this.userName,
    this.cheatDay,
    required this.targetCalories,
    this.selectedFitnessGoal,
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

  String _getMealFrequencyDisplay() {
    final mealTimingJson = userPreferences.mealTimingPreferences;
    if (mealTimingJson == null) {
      return '3 meals (default)';
    }

    final mealFrequency = mealTimingJson['mealFrequency'] as String?;
    if (mealFrequency == null) {
      return '3 meals (default)';
    }

    switch (mealFrequency) {
      case 'threeMeals':
        return '3 meals';
      case 'threeMealsOneSnack':
        return '3 meals + 1 snack';
      case 'fourMeals':
        return '4 meals';
      case 'fourMealsOneSnack':
        return '4 meals + 1 snack';
      case 'fiveMeals':
        return '5 meals';
      case 'fiveMealsOneSnack':
        return '5 meals + 1 snack';
      case 'intermittentFasting':
        final fastingType = mealTimingJson['fastingType'] as String?;
        switch (fastingType) {
          case 'sixteenEight':
            return '16:8 Intermittent Fasting';
          case 'eighteenSix':
            return '18:6 Intermittent Fasting';
          case 'twentyFour':
            return '20:4 Intermittent Fasting';
          case 'alternateDay':
            return 'Alternate Day Fasting';
          case 'fiveTwo':
            return '5:2 Fasting';
          case 'custom':
            return 'Custom Fasting';
          default:
            return '16:8 Intermittent Fasting';
        }
      case 'custom':
        return 'Custom';
      default:
        return '3 meals (default)';
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
      case 'cheat':
        return Icons.cake;
      case 'meals':
        return Icons.restaurant;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppConstants.spacingL),
            PersonalizedTitle(
              userName: userName,
              title: '{name}\'s Final Review',
              fallbackTitle: 'Final Review',
              style:
                  AppTextStyles.heading4.copyWith(fontWeight: FontWeight.bold),
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
                      icon: _iconFor('calories'),
                      label: 'Daily Calories',
                      value: '$targetCalories calories',
                      isFromClient:
                          targetCalories == userPreferences.targetCalories,
                      clientValue: userPreferences.targetCalories > 0
                          ? '${userPreferences.targetCalories} calories (client)'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _reviewRow(
                      icon: _iconFor('goal'),
                      label: 'Fitness Goal',
                      value: selectedFitnessGoal != null ? _fitnessGoalName(selectedFitnessGoal!) : _fitnessGoalName(userPreferences.fitnessGoal),
                      isFromClient: selectedFitnessGoal == null,
                      clientValue:
                          '${_fitnessGoalName(userPreferences.fitnessGoal)} (client)',
                    ),
                    const SizedBox(height: 16),
                    _reviewRow(
                      icon: _iconFor('meals'),
                      label: 'Meal Frequency',
                      value: _getMealFrequencyDisplay(),
                    ),
                    const SizedBox(height: 16),
                    _reviewRow(
                      icon: _iconFor('cheat'),
                      label: 'Cheat Day',
                      value: cheatDay ?? 'No cheat day',
                    ),
                    const SizedBox(height: 16),
                    _reviewRow(
                      icon: _iconFor('restrictions'),
                      label: 'Dietary Restrictions',
                      value: (userPreferences.dietaryRestrictions.isEmpty ||
                              (userPreferences.dietaryRestrictions.length ==
                                      1 &&
                                  userPreferences.dietaryRestrictions.first ==
                                      'None'))
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
    );
  }

  Widget _reviewRow({
    required IconData icon,
    required String label,
    required String value,
    bool isFromClient = false,
    String? clientValue,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isFromClient
                ? AppConstants.successColor.withOpacity(0.08)
                : AppConstants.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(10),
          child: Icon(icon,
              color: isFromClient
                  ? AppConstants.successColor
                  : AppConstants.primaryColor,
              size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  if (isFromClient) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppConstants.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'CLIENT',
                        style: AppTextStyles.caption.copyWith(
                          color: AppConstants.successColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              if (clientValue != null && !isFromClient) ...[
                const SizedBox(height: 2),
                Text(
                  clientValue,
                  style: AppTextStyles.caption.copyWith(
                    color: AppConstants.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
