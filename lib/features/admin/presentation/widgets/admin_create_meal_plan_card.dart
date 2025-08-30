import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:champions_gym_app/shared/models/user_model.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:champions_gym_app/features/admin/presentation/screens/admin_meal_plan_setup_screen.dart';

class AdminCreateMealPlanCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onMealPlanCreated;

  const AdminCreateMealPlanCard({
    super.key,
    required this.user,
    this.onMealPlanCreated,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        HapticFeedback.mediumImpact();
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AdminMealPlanSetupScreen(user: user),
          ),
        );
        if (result == true) {
          onMealPlanCreated?.call();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppConstants.primaryColor.withOpacity(0.1),
              AppConstants.primaryColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppConstants.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                color: AppConstants.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Meal Plan',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Generate personalized meal plan for ${user.name?.split(' ').first ?? 'this user'}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppConstants.primaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
