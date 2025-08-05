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
              Image.asset(
                "assets/images/mealplan_graphic.png",
                height: 225,
              ),
              const SizedBox(height: AppConstants.spacingS),
              // Status message
              Text(
                'You will receive an email when your plan is ready.',
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
