import 'package:flutter/material.dart';
import '../../../../shared/models/meal_model.dart';
import '../../../../core/constants/app_constants.dart';

class NextMealCard extends StatelessWidget {
  final MealDay? currentDayMeals;
  final DateTime selectedDate;

  const NextMealCard({
    super.key,
    required this.currentDayMeals,
    required this.selectedDate,
  });

  Meal? _getNextMeal() {
    if (currentDayMeals == null || currentDayMeals!.meals.isEmpty) {
      return null;
    }

    final now = DateTime.now();
    final currentTime = now.hour * 60 + now.minute; // Convert to minutes since midnight
    
    // Define meal time ranges (in minutes since midnight)
    const breakfastStart = 6 * 60; // 6:00 AM
    const breakfastEnd = 10 * 60; // 10:00 AM
    const lunchStart = 11 * 60; // 11:00 AM
    const lunchEnd = 15 * 60; // 3:00 PM
    const dinnerStart = 17 * 60; // 5:00 PM
    const dinnerEnd = 21 * 60; // 9:00 PM
    const snackStart = 14 * 60; // 2:00 PM
    const snackEnd = 16 * 60; // 4:00 PM

    // Find the next meal based on current time
    Meal? nextMeal;
    
    if (currentTime < breakfastStart) {
      // Before breakfast - next meal is breakfast
      nextMeal = currentDayMeals!.meals.firstWhere(
        (meal) => meal.type == MealType.breakfast,
        orElse: () => currentDayMeals!.meals.first,
      );
    } else if (currentTime < breakfastEnd) {
      // During breakfast time - next meal is lunch
      nextMeal = currentDayMeals!.meals.firstWhere(
        (meal) => meal.type == MealType.lunch,
        orElse: () => currentDayMeals!.meals.first,
      );
    } else if (currentTime < lunchStart) {
      // Between breakfast and lunch - next meal is lunch
      nextMeal = currentDayMeals!.meals.firstWhere(
        (meal) => meal.type == MealType.lunch,
        orElse: () => currentDayMeals!.meals.first,
      );
    } else if (currentTime < lunchEnd) {
      // During lunch time - next meal is snack or dinner
      nextMeal = currentDayMeals!.meals.firstWhere(
        (meal) => meal.type == MealType.snack || meal.type == MealType.dinner,
        orElse: () => currentDayMeals!.meals.first,
      );
    } else if (currentTime < dinnerStart) {
      // Between lunch and dinner - next meal is dinner
      nextMeal = currentDayMeals!.meals.firstWhere(
        (meal) => meal.type == MealType.dinner,
        orElse: () => currentDayMeals!.meals.first,
      );
    } else if (currentTime < dinnerEnd) {
      // During dinner time - next meal is tomorrow's breakfast
      nextMeal = currentDayMeals!.meals.firstWhere(
        (meal) => meal.type == MealType.breakfast,
        orElse: () => currentDayMeals!.meals.first,
      );
    } else {
      // After dinner - next meal is tomorrow's breakfast
      nextMeal = currentDayMeals!.meals.firstWhere(
        (meal) => meal.type == MealType.breakfast,
        orElse: () => currentDayMeals!.meals.first,
      );
    }

    return nextMeal;
  }

  String _getMealTypeText(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  String _getTimeUntilText(MealType type) {
    final now = DateTime.now();
    final currentTime = now.hour * 60 + now.minute;
    
    int targetTime;
    switch (type) {
      case MealType.breakfast:
        targetTime = 8 * 60; // 8:00 AM
        break;
      case MealType.lunch:
        targetTime = 12 * 60; // 12:00 PM
        break;
      case MealType.dinner:
        targetTime = 18 * 60; // 6:00 PM
        break;
      case MealType.snack:
        targetTime = 15 * 60; // 3:00 PM
        break;
    }
    
    if (currentTime >= targetTime) {
      return 'Coming up next';
    }
    
    final minutesUntil = targetTime - currentTime;
    if (minutesUntil < 60) {
      return 'In $minutesUntil min';
    } else {
      final hours = minutesUntil ~/ 60;
      final minutes = minutesUntil % 60;
      if (minutes == 0) {
        return 'In $hours hr';
      } else {
        return 'In $hours hr $minutes min';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextMeal = _getNextMeal();
    
    if (nextMeal == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.restaurant_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Meals Planned',
              style: AppTextStyles.heading5,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your meal plan to see upcoming meals',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next Meal',
          style: AppTextStyles.heading5.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getMealTypeText(nextMeal.type),
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                nextMeal.name,
                style: AppTextStyles.heading5.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (nextMeal.description.isNotEmpty)
                Text(
                  nextMeal.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Calories
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${nextMeal.nutrition.calories.round()} cal',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Prep time
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppConstants.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: AppConstants.warningColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${nextMeal.prepTime + nextMeal.cookTime} min',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppConstants.warningColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Meal status indicator
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: nextMeal.isConsumed
                          ? AppConstants.successColor
                          : AppConstants.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
