import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/meal_model.dart';
import '../screens/meal_detail_screen.dart';

class MealCard extends StatelessWidget {
  final Meal meal;
  final String dayTitle;
  final VoidCallback? onTap;

  const MealCard({
    super.key,
    required this.meal,
    required this.dayTitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {
        HapticFeedback.lightImpact();
        _navigateToMealDetail(context);
      },
      borderRadius: BorderRadius.circular(AppConstants.radiusS),
      child: Container(
        margin: const EdgeInsets.all(AppConstants.spacingS),
        padding: const EdgeInsets.all(AppConstants.spacingS),
        decoration: BoxDecoration(
          color: AppConstants.backgroundColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
          border: Border.all(
            color: AppConstants.textTertiary.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(width: AppConstants.spacingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        meal.description,
                        style: AppTextStyles.caption.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${meal.nutrition.calories} cal',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppConstants.accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingS),
            Row(
              children: [
                _buildNutritionChip(
                    'P', '${meal.nutrition.protein.toStringAsFixed(0)}g'),
                const SizedBox(width: AppConstants.spacingS),
                _buildNutritionChip(
                    'C', '${meal.nutrition.carbs.toStringAsFixed(0)}g'),
                const SizedBox(width: AppConstants.spacingS),
                _buildNutritionChip(
                    'F', '${meal.nutrition.fat.toStringAsFixed(0)}g'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppConstants.primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility,
                        size: 12,
                        color: AppConstants.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'View Recipe',
                        style: AppTextStyles.caption.copyWith(
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingXS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusXS),
      ),
      child: Text(
        '$label: $value',
        style: AppTextStyles.caption.copyWith(
          color: AppConstants.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Color _getMealTypeColor(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return AppConstants.warningColor;
      case MealType.lunch:
        return AppConstants.accentColor;
      case MealType.dinner:
        return AppConstants.primaryColor;
      case MealType.snack:
        return AppConstants.secondaryColor;
    }
  }

  IconData _getMealTypeIcon(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return Icons.wb_sunny;
      case MealType.lunch:
        return Icons.restaurant;
      case MealType.dinner:
        return Icons.dinner_dining;
      case MealType.snack:
        return Icons.coffee;
    }
  }

  void _navigateToMealDetail(BuildContext context) {
    // Add haptic feedback
    HapticFeedback.lightImpact();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealDetailScreen(
          meal: meal,
          dayTitle: dayTitle,
        ),
      ),
    );
  }
} 