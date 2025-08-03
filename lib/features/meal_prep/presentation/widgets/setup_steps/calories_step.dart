import 'package:flutter/material.dart';
import '../../../../../core/constants/app_constants.dart';

class CaloriesStep extends StatelessWidget {
  final int targetCalories;
  final ValueChanged<int> onChanged;

  const CaloriesStep({
    super.key,
    required this.targetCalories,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Set Your Daily Calorie Target',
          style: AppTextStyles.heading4,
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