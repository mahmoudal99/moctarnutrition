import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class ActivityRing extends StatelessWidget {
  final int caloriesBurned;
  final int targetCalories;

  const ActivityRing({
    super.key,
    required this.caloriesBurned,
    required this.targetCalories,
  });

  @override
  Widget build(BuildContext context) {
    final progress = targetCalories > 0 ? caloriesBurned / targetCalories : 0.0;
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
          
          // Progress ring (empty for now)
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: 0.0, // Empty ring as shown in screenshot
              strokeWidth: 8,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.grey,
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
