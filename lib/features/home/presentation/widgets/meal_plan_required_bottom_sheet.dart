import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_constants.dart';

class MealPlanRequiredBottomSheet extends StatelessWidget {
  const MealPlanRequiredBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                "assets/images/file-01-stroke-rounded.svg",
                height: 20,
                color: Colors.black,
              ),
              SizedBox(width: 10),
              Text(
                'Meal Plan Required',
                style: AppTextStyles.heading5,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'You can log food once your meal plan is ready.',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }
}
