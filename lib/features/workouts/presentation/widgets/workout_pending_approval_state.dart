import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class WorkoutPendingApprovalState extends StatelessWidget {
  const WorkoutPendingApprovalState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Workout Plan Pending Approval',
              style: AppTextStyles.heading3.copyWith(
                color: AppConstants.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              'Your personalized workout plan has been generated and is being reviewed by our trainers. You will be notified once it\'s approved.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingL),
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(
                  color: AppConstants.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Text(
                    'You\'ll receive a notification when approved',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
