import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../shared/models/meal_model.dart';
import '../../../../core/constants/app_constants.dart';

class NextMealCard extends StatelessWidget {
  final MealDay? currentDayMeals;
  final DateTime selectedDate;
  final bool isCheatDay;
  final String? cheatDayName;

  const NextMealCard({
    super.key,
    required this.currentDayMeals,
    required this.selectedDate,
    this.isCheatDay = false,
    this.cheatDayName,
  });

  Meal? _getNextMeal() {
    if (isCheatDay ||
        currentDayMeals == null ||
        currentDayMeals!.meals.isEmpty) {
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

    // Debug: Show all meals with their types
    for (int i = 0; i < availableMeals.length; i++) {
      final meal = availableMeals[i];
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
      if (breakfastMeals.isNotEmpty) {
        nextMeal = breakfastMeals.first;
      } else if (lunchMeals.isNotEmpty) {
        nextMeal = lunchMeals.first;
      } else {
        nextMeal = availableMeals.first;
      }
    } else if (currentTime < breakfastWindow + 4 * 60) {
      // Between 6 AM and 10 AM - still breakfast time, next meal is breakfast
      if (breakfastMeals.isNotEmpty) {
        nextMeal = breakfastMeals.first;
      } else if (lunchMeals.isNotEmpty) {
        nextMeal = lunchMeals.first;
      } else {
        nextMeal = availableMeals.first;
      }
    } else if (currentTime < lunchWindow) {
      // Between 10 AM and 12 PM - next meal is lunch
      if (lunchMeals.isNotEmpty) {
        nextMeal = lunchMeals.first;
      } else if (dinnerMeals.isNotEmpty) {
        nextMeal = dinnerMeals.first;
      } else {
        nextMeal = availableMeals.first;
      }
    } else if (currentTime < snackWindow) {
      // Between 12 PM and 3 PM - next meal is snack or dinner
      if (snackMeals.isNotEmpty) {
        nextMeal = snackMeals.first;
      } else if (dinnerMeals.isNotEmpty) {
        nextMeal = dinnerMeals.first;
      } else {
        nextMeal = availableMeals.first;
      }
    } else if (currentTime < dinnerWindow) {
      // Between 3 PM and 6 PM - next meal is dinner
      if (dinnerMeals.isNotEmpty) {
        nextMeal = dinnerMeals.first;
      } else {
        nextMeal = availableMeals.first;
      }
    } else {
      // After 6 PM - next meal is tomorrow's breakfast, but for now show first meal
      if (breakfastMeals.isNotEmpty) {
        nextMeal = breakfastMeals.first;
      } else {
        nextMeal = availableMeals.first;
      }
    }

    // Special case: if it's very late (after 10 PM), show tomorrow's breakfast
    if (currentTime >= 22 * 60 && breakfastMeals.isNotEmpty) {
      nextMeal = breakfastMeals.first;
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

  @override
  Widget build(BuildContext context) {
    final nextMeal = _getNextMeal();

    if (isCheatDay) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enjoy your break, no meals scheduled today.',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      );
    }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  "assets/images/add-to-list-stroke-rounded.svg",
                  height: 20,
                  color: Colors.black,
                ),
                const SizedBox(width: 10),
                Text('No Meal Plan Yet', style: AppTextStyles.heading5),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your next meal will show here when your meal plan is ready!',
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
                  const SizedBox(
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
