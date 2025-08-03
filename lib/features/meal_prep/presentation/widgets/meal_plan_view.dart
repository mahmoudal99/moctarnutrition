import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/meal_model.dart';
import 'meal_day_card.dart';
import 'nutrition_summary_card.dart';

class MealPlanView extends StatelessWidget {
  final MealPlanModel mealPlan;
  final VoidCallback? onMealTap;

  const MealPlanView({
    super.key,
    required this.mealPlan,
    this.onMealTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NutritionSummaryCard(mealPlan: mealPlan),
          const SizedBox(height: AppConstants.spacingM),
          _buildMealDaysList(),
        ],
      ),
    );
  }

  Widget _buildMealDaysList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Meal Plan',
          style: AppTextStyles.heading4,
        ),
        const SizedBox(height: AppConstants.spacingS),
        ...mealPlan.mealDays.map((mealDay) {
          return MealDayCard(
            mealDay: mealDay,
            dayNumber: mealPlan.mealDays.indexOf(mealDay) + 1,
            onMealTap: onMealTap,
          );
        }).toList(),
      ],
    );
  }
} 