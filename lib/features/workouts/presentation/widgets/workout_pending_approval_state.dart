import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_constants.dart';

class WorkoutPendingApprovalState extends StatelessWidget {
  const WorkoutPendingApprovalState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingL),
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
                  'Plan Pending Approval',
                  style: AppTextStyles.heading5,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              'Your personalized workout plan is being reviewed by our trainers. You will be notified once it\'s approved.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
