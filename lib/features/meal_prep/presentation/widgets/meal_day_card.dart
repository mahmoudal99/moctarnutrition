import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/meal_model.dart';
import 'meal_card.dart';

class MealDayCard extends StatelessWidget {
  final MealDay mealDay;
  final int dayNumber;
  final VoidCallback? onMealTap;

  const MealDayCard({
    super.key,
    required this.mealDay,
    required this.dayNumber,
    this.onMealTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: ExpansionTile(
        title: Text(
          'Day $dayNumber',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${mealDay.totalCalories} calories',
          style: AppTextStyles.caption.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
        children: mealDay.meals.map((meal) {
          return MealCard(
            meal: meal,
            dayTitle: 'Day $dayNumber',
            onTap: onMealTap,
          );
        }).toList(),
      ),
    );
  }
}
