import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class OnboardingBMIStep extends StatelessWidget {
  final double bmi;
  final String bmiCategory;
  final Color bmiColor;
  final double height;
  final double weight;

  const OnboardingBMIStep({
    super.key,
    required this.bmi,
    required this.bmiCategory,
    required this.bmiColor,
    required this.height,
    required this.weight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          decoration: BoxDecoration(
            color: bmiColor.withOpacity(0.08),
            border: Border.all(color: bmiColor.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          child: Column(
            children: [
              Text('Your BMI', style: AppTextStyles.heading3.copyWith(color: bmiColor)),
              const SizedBox(height: AppConstants.spacingS),
              Text(bmi.toStringAsFixed(1), style: AppTextStyles.heading1.copyWith(color: bmiColor)),
              const SizedBox(height: AppConstants.spacingXS),
              Text(bmiCategory, style: AppTextStyles.bodyMedium.copyWith(color: bmiColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppConstants.spacingS),
              Text('${height.toStringAsFixed(0)}cm, ${weight.toStringAsFixed(1)}kg', style: AppTextStyles.caption.copyWith(color: AppConstants.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spacingL),
        const Text(
          'BMI (Body Mass Index) is a measure of body fat based on height and weight.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
} 