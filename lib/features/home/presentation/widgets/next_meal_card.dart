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
    final currentTime =
        now.hour * 60 + now.minute; // Convert to minutes since midnight

    // Get all available meal types for today
    final availableMeals = currentDayMeals!.meals;
    final breakfastMeals =
        availableMeals.where((m) => m.type == MealType.breakfast).toList();
    final lunchMeals =
        availableMeals.where((m) => m.type == MealType.lunch).toList();
    final dinnerMeals =
        availableMeals.where((m) => m.type == MealType.dinner).toList();
    final snackMeals =
        availableMeals.where((m) => m.type == MealType.snack).toList();

    // Debug logging
    print('NextMealCard Debug:');
    print('  Current time: ${now.hour}:${now.minute.toString().padLeft(2, '0')} (${currentTime} minutes)');
    print('  Available meals: ${availableMeals.length}');
    print('  Breakfast meals: ${breakfastMeals.length}');
    print('  Lunch meals: ${lunchMeals.length}');
    print('  Dinner meals: ${dinnerMeals.length}');
    print('  Snack meals: ${snackMeals.length}');
    
    // Debug: Show all meals with their types
    for (int i = 0; i < availableMeals.length; i++) {
      final meal = availableMeals[i];
      print('  Meal $i: ${meal.name} (${meal.type.name})');
    }

    // Define meal time windows (in minutes since midnight)
    const breakfastWindow = 6 * 60; // 6:00 AM
    const lunchWindow = 12 * 60; // 12:00 PM (noon)
    const snackWindow = 15 * 60; // 3:00 PM
    const dinnerWindow = 18 * 60; // 6:00 PM

    // Find the next meal based on current time and available meals
    Meal? nextMeal;

    if (currentTime < breakfastWindow) {
      // Before 6 AM - next meal is breakfast
      print('  Time window: Before 6 AM - showing breakfast');
      if (breakfastMeals.isNotEmpty) {
        nextMeal = breakfastMeals.first;
      } else if (lunchMeals.isNotEmpty) {
        nextMeal = lunchMeals.first;
      } else {
        nextMeal = availableMeals.first;
      }
    } else if (currentTime < breakfastWindow + 4 * 60) {
      // Between 6 AM and 10 AM - still breakfast time, next meal is breakfast
      print('  Time window: 6 AM - 10 AM - showing breakfast');
      if (breakfastMeals.isNotEmpty) {
        nextMeal = breakfastMeals.first;
      } else if (lunchMeals.isNotEmpty) {
        nextMeal = lunchMeals.first;
      } else {
        nextMeal = availableMeals.first;
      }
    } else if (currentTime < lunchWindow) {
      // Between 10 AM and 12 PM - next meal is lunch
      print('  Time window: 10 AM - 12 PM - showing lunch');
      if (lunchMeals.isNotEmpty) {
        nextMeal = lunchMeals.first;
      } else if (dinnerMeals.isNotEmpty) {
        nextMeal = dinnerMeals.first;
      } else {
        nextMeal = availableMeals.first;
      }
    } else if (currentTime < snackWindow) {
      // Between 12 PM and 3 PM - next meal is snack or dinner
      print('  Time window: 12 PM - 3 PM - showing snack/dinner');
      if (snackMeals.isNotEmpty) {
        nextMeal = snackMeals.first;
      } else if (dinnerMeals.isNotEmpty) {
        nextMeal = dinnerMeals.first;
      } else {
        nextMeal = availableMeals.first;
      }
    } else if (currentTime < dinnerWindow) {
      // Between 3 PM and 6 PM - next meal is dinner
      print('  Time window: 3 PM - 6 PM - showing dinner');
      if (dinnerMeals.isNotEmpty) {
        nextMeal = dinnerMeals.first;
      } else {
        nextMeal = availableMeals.first;
      }
    } else {
      // After 6 PM - next meal is tomorrow's breakfast, but for now show first meal
      print('  Time window: After 6 PM - showing breakfast');
      if (breakfastMeals.isNotEmpty) {
        nextMeal = breakfastMeals.first;
      } else {
        nextMeal = availableMeals.first;
      }
    }

    // Special case: if it's very late (after 10 PM), show tomorrow's breakfast
    if (currentTime >= 22 * 60 && breakfastMeals.isNotEmpty) {
      print('  Special case: After 10 PM - showing breakfast');
      nextMeal = breakfastMeals.first;
    }
    
    print('  Selected meal: ${nextMeal?.name} (${nextMeal?.type.name})');
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
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingM,
              vertical: AppConstants.spacingM),
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
              Text(
                nextMeal.name,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (nextMeal.description.isNotEmpty)
                Text(
                  nextMeal.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getMealTypeText(nextMeal.type),
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: AppConstants.spacingS,
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${nextMeal.nutrition.calories.round()} cal',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        color: AppConstants.primaryColor,
                      ),
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
