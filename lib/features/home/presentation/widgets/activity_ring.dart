import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../core/constants/app_constants.dart';

class ActivityRing extends StatelessWidget {
  final int consumedCalories;
  final int targetCalories;

  const ActivityRing({
    super.key,
    required this.consumedCalories,
    required this.targetCalories,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate progress based on consumed calories vs target
    final progress =
        targetCalories > 0 ? consumedCalories / targetCalories : 0.0;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress ring (shows consumed calories progress)
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: clampedProgress,
              strokeWidth: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                clampedProgress >= 1.0
                    ? AppConstants.successColor
                    : AppConstants.primaryColor,
              ),
            ),
          ),

          // Center icon
          SvgPicture.asset(
            "assets/images/fire-stroke-rounded.svg",
            color: Colors.black,
            height: 24,
          ),
        ],
      ),
    );
  }
}
