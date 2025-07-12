import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class OnboardingWelcomeStep extends StatelessWidget {
  const OnboardingWelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            gradient: AppConstants.primaryGradient,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            boxShadow: AppConstants.shadowM,
          ),
          child: const Icon(
            Icons.fitness_center,
            size: 70,
            color: AppConstants.surfaceColor,
          ),
        ),
        const SizedBox(height: AppConstants.spacingL),
        Text(
          'Ready to transform your fitness journey?',
          style: AppTextStyles.heading3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingS),
        Text(
          'We\'ll create a personalized experience just for you with AI-powered meal plans and expert trainer guidance.',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
} 