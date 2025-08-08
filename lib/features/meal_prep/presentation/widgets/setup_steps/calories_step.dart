import 'package:flutter/material.dart';
import '../../../../../core/constants/app_constants.dart';
import 'personalized_title.dart';

class CaloriesStep extends StatelessWidget {
  final int targetCalories;
  final ValueChanged<int> onChanged;
  final String? userName;

  const CaloriesStep({
    super.key,
    required this.targetCalories,
    required this.onChanged,
    this.userName,
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
        const SizedBox(height: AppConstants.spacingL),
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
