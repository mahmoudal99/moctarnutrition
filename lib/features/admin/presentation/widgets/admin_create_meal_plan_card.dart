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
      child: Card(
        color: Colors.white,
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.restaurant_menu,
                    color: AppConstants.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Create Meal Plan',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppConstants.textTertiary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
