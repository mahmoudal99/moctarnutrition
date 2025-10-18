import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class WorkoutSuccessState extends StatelessWidget {
  final String message;
  final VoidCallback onContinue;

  const WorkoutSuccessState({
    super.key,
    required this.message,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppConstants.successColor,
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Success!',
              style: AppTextStyles.heading3.copyWith(
                color: AppConstants.successColor,
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingL),
            ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: AppConstants.surfaceColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingL,
                  vertical: AppConstants.spacingM,
                ),
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
