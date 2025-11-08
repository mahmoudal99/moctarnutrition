import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:champions_gym_app/shared/models/user_model.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:champions_gym_app/features/admin/presentation/screens/admin_meal_plan_setup_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    final firstName = _resolveFirstName();

    return DottedBorder(
      color: AppConstants.carbsColor,
      strokeWidth: 1,
      dashPattern: const [6, 4],
      borderType: BorderType.RRect,
      radius: const Radius.circular(16),
      child: InkWell(
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
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        child: Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
          ),
          color: AppConstants.carbsColor.withOpacity(0.05),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          "assets/images/add-to-list-stroke-rounded.svg",
                          color: Colors.black,
                          height: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Create Meal Plan',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    Text(
                      '$firstName does not have a meal plan yet,\ngenerate one to get them started.',
                      style: AppTextStyles.bodySmall.copyWith(
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
      ),
    );
  }

  String _resolveFirstName() {
    final trimmedName = user.name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      final parts = trimmedName.split(RegExp(r'\s+'));
      if (parts.isNotEmpty) {
        return parts.first;
      }
    }

    final emailPrefix = user.email.split('@').first.trim();
    if (emailPrefix.isNotEmpty) {
      return emailPrefix;
    }

    return 'This client';
  }
}
