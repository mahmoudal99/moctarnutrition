import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class WorkoutEmptyState extends StatelessWidget {
  final VoidCallback onUpdatePreferences;

  const WorkoutEmptyState({
    super.key,
    required this.onUpdatePreferences,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No Workout Plan',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              'Complete your onboarding to get a personalized workout plan.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingL),
            ElevatedButton(
              onPressed: onUpdatePreferences,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: AppConstants.surfaceColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingL,
                  vertical: AppConstants.spacingM,
                ),
              ),
              child: const Text('Update Preferences'),
            ),
          ],
        ),
      ),
    );
  }
}
