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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: bmiColor.withOpacity(0.08),
              border: Border.all(color: bmiColor.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: Column(
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: bmi.toStringAsFixed(1),
                        style: AppTextStyles.heading1.copyWith(
                          color: bmiColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 38,
                        ),
                      ),
                      TextSpan(
                        text: ' – ',
                        style: AppTextStyles.heading2.copyWith(
                          color: bmiColor,
                          fontWeight: FontWeight.normal,
                          fontSize: 28,
                        ),
                      ),
                      TextSpan(
                        text: bmiCategory,
                        style: AppTextStyles.heading2.copyWith(
                          color: bmiColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTextStyles.caption.copyWith(
                      color: AppConstants.textSecondary,
                      fontSize: 14,
                    ),
                    children: [
                      const TextSpan(text: '(Based on your height: '),
                      TextSpan(
                        text: '${height.toStringAsFixed(0)} cm',
                        style: AppTextStyles.caption.copyWith(
                          color: bmiColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const TextSpan(text: ' and weight: '),
                      TextSpan(
                        text: '${weight.toStringAsFixed(1)} kg',
                        style: AppTextStyles.caption.copyWith(
                          color: bmiColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const TextSpan(text: ')'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppConstants.textPrimary),
              children: [
                const TextSpan(text: 'Understanding your '),
                TextSpan(
                  text: 'BMI',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: bmiColor,
                  ),
                ),
                const TextSpan(text: ' helps us build a '),
                TextSpan(
                  text: 'fitness and meal plan',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: " that's right for your body."),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
