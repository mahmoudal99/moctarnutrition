import 'package:logger/logger.dart';
import '../models/meal_model.dart';

/// Service responsible for managing meal logging and consumption tracking
class MealLoggingService {
  static final _logger = Logger();

  /// Mark a meal as consumed and update the meal day's consumed nutrition
  static void markMealAsConsumed(Meal meal, MealDay mealDay) {
    _logger.i('Marking meal "${meal.name}" as consumed');
    
    meal.isConsumed = true;
    mealDay.calculateConsumedNutrition();
    
    _logger.d('Updated consumed nutrition for ${mealDay.date}:');
    _logger.d('  Calories: ${mealDay.consumedCalories.toStringAsFixed(1)}/${mealDay.totalCalories.toStringAsFixed(1)}');
    _logger.d('  Protein: ${mealDay.consumedProtein.toStringAsFixed(1)}g/${mealDay.totalProtein.toStringAsFixed(1)}g');
    _logger.d('  Carbs: ${mealDay.consumedCarbs.toStringAsFixed(1)}g/${mealDay.totalCarbs.toStringAsFixed(1)}g');
    _logger.d('  Fat: ${mealDay.consumedFat.toStringAsFixed(1)}g/${mealDay.totalFat.toStringAsFixed(1)}g');
  }

  /// Mark a meal as not consumed and update the meal day's consumed nutrition
  static void markMealAsNotConsumed(Meal meal, MealDay mealDay) {
    _logger.i('Marking meal "${meal.name}" as not consumed');
    
    meal.isConsumed = false;
    mealDay.calculateConsumedNutrition();
    
    _logger.d('Updated consumed nutrition for ${mealDay.date}:');
    _logger.d('  Calories: ${mealDay.consumedCalories.toStringAsFixed(1)}/${mealDay.totalCalories.toStringAsFixed(1)}');
    _logger.d('  Protein: ${mealDay.consumedProtein.toStringAsFixed(1)}g/${mealDay.totalProtein.toStringAsFixed(1)}g');
    _logger.d('  Carbs: ${mealDay.consumedCarbs.toStringAsFixed(1)}g/${mealDay.totalCarbs.toStringAsFixed(1)}g');
    _logger.d('  Fat: ${mealDay.consumedFat.toStringAsFixed(1)}g/${mealDay.totalFat.toStringAsFixed(1)}g');
  }

  /// Toggle meal consumption status
  static void toggleMealConsumption(Meal meal, MealDay mealDay) {
    if (meal.isConsumed) {
      markMealAsNotConsumed(meal, mealDay);
    } else {
      markMealAsConsumed(meal, mealDay);
    }
  }

  /// Get the consumption status for a specific meal type on a given day
  static Map<MealType, bool> getMealTypeConsumptionStatus(MealDay mealDay) {
    final status = <MealType, bool>{};

    for (final meal in mealDay.meals) {
      status[meal.type] = meal.isConsumed;
    }

    return status;
  }

  /// Get the total consumed calories for a specific meal type on a given day
  static double getConsumedCaloriesForMealType(
      MealDay mealDay, MealType mealType) {
    double total = 0.0;

    for (final meal in mealDay.meals) {
      if (meal.type == mealType && meal.isConsumed) {
        total += meal.nutrition.calories;
      }
    }

    return total;
  }

  /// Get a summary of consumption progress for a meal day
  static Map<String, dynamic> getConsumptionSummary(MealDay mealDay) {
    mealDay.calculateConsumedNutrition();

    final totalMeals = mealDay.meals.length;
    final consumedMeals = mealDay.meals.where((meal) => meal.isConsumed).length;
    final consumptionPercentage =
        totalMeals > 0 ? (consumedMeals / totalMeals) * 100 : 0.0;

    return {
      'totalMeals': totalMeals,
      'consumedMeals': consumedMeals,
      'consumptionPercentage': consumptionPercentage,
      'consumedCalories': mealDay.consumedCalories,
      'remainingCalories': mealDay.remainingCalories,
      'consumedProtein': mealDay.consumedProtein,
      'remainingProtein': mealDay.remainingProtein,
      'consumedCarbs': mealDay.consumedCarbs,
      'remainingCarbs': mealDay.remainingCarbs,
      'consumedFat': mealDay.consumedFat,
      'remainingFat': mealDay.remainingFat,
    };
  }

  /// Reset all meals in a meal day to not consumed
  static void resetMealDayConsumption(MealDay mealDay) {
    _logger.i('Resetting consumption for meal day ${mealDay.date}');

    for (final meal in mealDay.meals) {
      meal.isConsumed = false;
    }

    mealDay.calculateConsumedNutrition();
    _logger.d('Reset completed - all meals marked as not consumed');
  }

  /// Mark all meals in a meal day as consumed
  static void markAllMealsAsConsumed(MealDay mealDay) {
    _logger.i('Marking all meals as consumed for meal day ${mealDay.date}');

    for (final meal in mealDay.meals) {
      meal.isConsumed = true;
    }

    mealDay.calculateConsumedNutrition();
    _logger.d('All meals marked as consumed');
  }
}
