import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class WaitingForMealPlan extends StatelessWidget {
  const WaitingForMealPlan({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plan'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.hourglass_empty,
                size: 64,
                color: AppConstants.primaryColor,
              ),
              const SizedBox(height: AppConstants.spacingL),
              Text(
                'Your meal plan will be ready shortly!',
                style: AppTextStyles.heading4,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingM),
              Text(
                'Moctar will prepare your meal plan. You will receive a message when it is ready.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppConstants.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 