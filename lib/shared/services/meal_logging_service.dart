import 'logging_service.dart';
import '../models/meal_model.dart';
import 'daily_consumption_service.dart';

/// Service responsible for managing meal logging and consumption tracking
class MealLoggingService {
  // Remove old logger instance
  // static final _logger = Logger();

  /// Mark a meal as consumed and update the meal day's consumed nutrition
  static Future<void> markMealAsConsumed(
      Meal meal, MealDay mealDay, String userId, DateTime date) async {
    LoggingService.logMealOperation(
      'Marking meal as consumed',
      mealName: meal.name,
      metadata: {
        'userId': userId,
        'date': date.toIso8601String(),
        'mealId': meal.id,
      },
    );

    meal.isConsumed = true;
    mealDay.calculateConsumedNutrition();

    // Update consumption in the daily consumption service
    await DailyConsumptionService.updateMealConsumption(
        userId, date, meal.id, true);

    LoggingService.meal.d('Updated consumed nutrition for ${mealDay.date}:');
    LoggingService.meal.d(
        '  Calories: ${mealDay.consumedCalories.toStringAsFixed(1)}/${mealDay.totalCalories.toStringAsFixed(1)}');
    LoggingService.meal.d(
        '  Protein: ${mealDay.consumedProtein.toStringAsFixed(1)}g/${mealDay.totalProtein.toStringAsFixed(1)}g');
    LoggingService.meal.d(
        '  Carbs: ${mealDay.consumedCarbs.toStringAsFixed(1)}g/${mealDay.totalCarbs.toStringAsFixed(1)}g');
    LoggingService.meal.d(
        '  Fat: ${mealDay.consumedFat.toStringAsFixed(1)}g/${mealDay.totalFat.toStringAsFixed(1)}g');
  }

  /// Mark a meal as not consumed and update the meal day's consumed nutrition
  static Future<void> markMealAsNotConsumed(
      Meal meal, MealDay mealDay, String userId, DateTime date) async {
    LoggingService.logMealOperation(
      'Marking meal as not consumed',
      mealName: meal.name,
      metadata: {
        'userId': userId,
        'date': date.toIso8601String(),
        'mealId': meal.id,
      },
    );

    meal.isConsumed = false;
    mealDay.calculateConsumedNutrition();

    // Update consumption in the daily consumption service
    await DailyConsumptionService.updateMealConsumption(
        userId, date, meal.id, false);

    LoggingService.meal.d('Updated consumed nutrition for ${mealDay.date}:');
    LoggingService.meal.d(
        '  Calories: ${mealDay.consumedCalories.toStringAsFixed(1)}/${mealDay.totalCalories.toStringAsFixed(1)}');
    LoggingService.meal.d(
        '  Protein: ${mealDay.consumedProtein.toStringAsFixed(1)}g/${mealDay.totalProtein.toStringAsFixed(1)}g');
    LoggingService.meal.d(
        '  Carbs: ${mealDay.consumedCarbs.toStringAsFixed(1)}g/${mealDay.totalCarbs.toStringAsFixed(1)}g');
    LoggingService.meal.d(
        '  Fat: ${mealDay.consumedFat.toStringAsFixed(1)}g/${mealDay.totalFat.toStringAsFixed(1)}g');
  }

  /// Toggle meal consumption status
  static Future<void> toggleMealConsumption(
      Meal meal, MealDay mealDay, String userId, DateTime date) async {
    if (meal.isConsumed) {
      await markMealAsNotConsumed(meal, mealDay, userId, date);
    } else {
      await markMealAsConsumed(meal, mealDay, userId, date);
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
  static Future<void> resetMealDayConsumption(
      MealDay mealDay, String userId, DateTime date) async {
    LoggingService.meal.i('Resetting consumption for meal day ${mealDay.date}');

    for (final meal in mealDay.meals) {
      meal.isConsumed = false;
      // Update consumption in the daily consumption service
      await DailyConsumptionService.updateMealConsumption(
          userId, date, meal.id, false);
    }

    mealDay.calculateConsumedNutrition();
    LoggingService.meal.d('Reset completed - all meals marked as not consumed');
  }

  /// Mark all meals in a meal day as consumed
  static Future<void> markAllMealsAsConsumed(
      MealDay mealDay, String userId, DateTime date) async {
    LoggingService.meal.i('Marking all meals as consumed for meal day ${mealDay.date}');

    for (final meal in mealDay.meals) {
      meal.isConsumed = true;
      // Update consumption in the daily consumption service
      await DailyConsumptionService.updateMealConsumption(
          userId, date, meal.id, true);
    }

    mealDay.calculateConsumedNutrition();
    LoggingService.meal.d('All meals marked as consumed');
  }
}
