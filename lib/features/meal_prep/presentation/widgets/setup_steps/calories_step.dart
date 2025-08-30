import 'package:flutter/material.dart';
import '../../../../../core/constants/app_constants.dart';
import 'personalized_title.dart';

class CaloriesStep extends StatelessWidget {
  final int targetCalories;
  final ValueChanged<int> onChanged;
  final String? userName;
  final int?
      clientTargetCalories; // Client's calculated calories from onboarding

  const CaloriesStep({
    super.key,
    required this.targetCalories,
    required this.onChanged,
    this.userName,
    this.clientTargetCalories,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PersonalizedTitle(
          userName: userName,
          title: 'Set {name}\'s Daily Calorie Target',
          fallbackTitle: 'Set Your Daily Calorie Target',
        ),

        // Show client's calculated calories if available
        if (clientTargetCalories != null) ...[
          const SizedBox(height: AppConstants.spacingM),
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: AppConstants.successColor.withOpacity(0.1),
              border: Border.all(
                color: AppConstants.successColor.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calculate,
                  color: AppConstants.successColor,
                  size: 20,
                ),
                const SizedBox(width: AppConstants.spacingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Client\'s calculated target: $clientTargetCalories calories',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppConstants.successColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Based on age, weight, height, activity level, and fitness goal',
                        style: AppTextStyles.caption.copyWith(
                          color: AppConstants.successColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppConstants.spacingL),

        // Show if admin has adjusted from client's choice
        if (clientTargetCalories != null &&
            targetCalories != clientTargetCalories) ...[
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: AppConstants.warningColor.withOpacity(0.1),
              border: Border.all(
                color: AppConstants.warningColor.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.edit,
                  color: AppConstants.warningColor,
                  size: 20,
                ),
                const SizedBox(width: AppConstants.spacingS),
                Expanded(
                  child: Text(
                    'Admin adjusted from ${clientTargetCalories} to $targetCalories calories',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppConstants.warningColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
        ],

        Slider(
          value: targetCalories.toDouble(),
          min: 1200,
          max: 4000,
          divisions: 28,
          label: '$targetCalories cal',
          onChanged: (value) => onChanged(value.round()),
        ),
        const SizedBox(height: AppConstants.spacingS),
        Text(
          '$targetCalories calories per day',
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingL),
      ],
    );
  }
}
