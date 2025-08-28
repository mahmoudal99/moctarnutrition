import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/meal_model.dart';
import '../../../../shared/services/meal_logging_service.dart';
import '../../../../shared/providers/meal_plan_provider.dart';
import '../screens/meal_detail_screen.dart';
import 'package:logger/logger.dart';

class MealCard extends StatefulWidget {
  final Meal meal;
  final String dayTitle;
  final VoidCallback? onTap;
  final MealDay? mealDay; // Add mealDay parameter

  const MealCard({
    super.key,
    required this.meal,
    required this.dayTitle,
    this.onTap,
    this.mealDay, // Add mealDay parameter
  });

  @override
  State<MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<MealCard> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap ??
          () {
            HapticFeedback.lightImpact();
            _navigateToMealDetail(context);
          },
      borderRadius: BorderRadius.circular(AppConstants.radiusS),
      child: Card(
        elevation: 8,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingS),
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
                          widget.meal.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: widget.meal.isConsumed
                                ? TextDecoration.lineThrough
                                : null,
                            color: widget.meal.isConsumed
                                ? AppConstants.textSecondary
                                : AppConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(
                          height: AppConstants.spacingS,
                        ),
                        Text(
                          widget.meal.description,
                          style: AppTextStyles.caption.copyWith(
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${widget.meal.nutrition.calories} cal',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: widget.meal.isConsumed
                              ? AppConstants.primaryColor
                              : AppConstants.accentColor,
                        ),
                      ),
                      if (widget.meal.isConsumed)
                        Text(
                          '✓ Consumed',
                          style: AppTextStyles.caption.copyWith(
                            color: AppConstants.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingS),
              Row(
                children: [
                  const SizedBox(width: AppConstants.spacingS),
                  _buildNutritionChip('P',
                      '${widget.meal.nutrition.protein.toStringAsFixed(0)}g'),
                  const SizedBox(width: AppConstants.spacingS),
                  _buildNutritionChip('C',
                      '${widget.meal.nutrition.carbs.toStringAsFixed(0)}g'),
                  const SizedBox(width: AppConstants.spacingS),
                  _buildNutritionChip(
                      'F', '${widget.meal.nutrition.fat.toStringAsFixed(0)}g'),
                  const Spacer(),
                  // Mark as Consumed Button - Removed, now handled at section level
                  const SizedBox(width: AppConstants.spacingS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppConstants.textSecondary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.visibility,
                          size: 12,
                          color: AppConstants.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'View',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            color: AppConstants.textSecondary,
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
      ),
    );
  }

  Widget _buildNutritionChip(String label, String value) {
    Color chipColor;
    switch (label) {
      case 'P':
        chipColor = AppConstants.proteinColor;
        break;
      case 'C':
        chipColor = AppConstants.carbsColor;
        break;
      case 'F':
        chipColor = AppConstants.fatColor;
        break;
      default:
        chipColor = AppConstants.primaryColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingXS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusXS),
      ),
      child: Text(
        '$label: $value',
        style: AppTextStyles.caption.copyWith(
          color: chipColor,
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
          meal: widget.meal,
          dayTitle: widget.dayTitle,
        ),
      ),
    );
  }
}
