import 'package:flutter/material.dart';
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
          // Background ring (empty gray ring)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.shade300,
                width: 8,
              ),
            ),
          ),

          // Progress ring (shows consumed calories progress)
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: clampedProgress,
              strokeWidth: 8,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                clampedProgress >= 1.0
                    ? AppConstants.successColor
                    : AppConstants.primaryColor,
              ),
            ),
          ),

          // Center icon
          const Icon(
            Icons.local_fire_department,
            color: Colors.black,
            size: 24,
          ),
        ],
      ),
    );
  }
}
