import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  "assets/images/dumbbell-01-stroke-rounded.svg",
                  height: 20,
                  color: Colors.black,
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  'No Workout Plan',
                  style: AppTextStyles.heading5,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              'Complete your onboarding to get a personalized workout plan.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
