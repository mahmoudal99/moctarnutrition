import 'package:logger/logger.dart';
import '../models/meal_model.dart';

/// Service responsible for calculating nutrition totals from ingredient data
/// This ensures all math is done by the app, not the model
class NutritionCalculationService {
  static final _logger = Logger();

  /// Calculate nutrition for a single meal from its ingredients
  static NutritionInfo calculateMealNutrition(Meal meal) {
    _logger.i('Calculating nutrition for meal: ${meal.name}');

    double totalCalories = 0.0;
    double totalProtein = 0.0;
    double totalCarbs = 0.0;
    double totalFat = 0.0;
    double totalFiber = 0.0;
    double totalSugar = 0.0;
    double totalSodium = 0.0;

    for (final ingredient in meal.ingredients) {
      if (ingredient.nutrition != null) {
        // Use model-provided ingredient nutrition data
        totalCalories += ingredient.nutrition!.calories;
        totalProtein += ingredient.nutrition!.protein;
        totalCarbs += ingredient.nutrition!.carbs;
        totalFat += ingredient.nutrition!.fat;
        totalFiber += ingredient.nutrition!.fiber;
        totalSugar += ingredient.nutrition!.sugar;
        totalSodium += ingredient.nutrition!.sodium;

        _logger.d(
            'Added ${ingredient.name}: ${ingredient.nutrition!.calories.toStringAsFixed(1)} cal');
      } else {
        _logger.w('No nutrition data available for ${ingredient.name}');
      }
    }

    final calculatedNutrition = NutritionInfo(
      calories: totalCalories,
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
      fiber: totalFiber,
      sugar: totalSugar,
      sodium: totalSodium,
    );

    _logger.i(
        'Meal ${meal.name} nutrition calculated: ${totalCalories.toStringAsFixed(1)} cal, ${totalProtein.toStringAsFixed(1)}g protein');

    return calculatedNutrition;
  }

  /// Calculate nutrition for a meal day from its meals
  static Map<String, double> calculateMealDayNutrition(MealDay mealDay) {
    _logger.i('Calculating nutrition for meal day: ${mealDay.date}');

    double totalCalories = 0.0;
    double totalProtein = 0.0;
    double totalCarbs = 0.0;
    double totalFat = 0.0;
    double totalFiber = 0.0;
    double totalSugar = 0.0;
    double totalSodium = 0.0;

    for (final meal in mealDay.meals) {
      final mealNutrition = calculateMealNutrition(meal);
      totalCalories += mealNutrition.calories;
      totalProtein += mealNutrition.protein;
      totalCarbs += mealNutrition.carbs;
      totalFat += mealNutrition.fat;
      totalFiber += mealNutrition.fiber;
      totalSugar += mealNutrition.sugar;
      totalSodium += mealNutrition.sodium;
    }

    final dayNutrition = {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
      'fiber': totalFiber,
      'sugar': totalSugar,
      'sodium': totalSodium,
    };

    _logger.i(
        'Day ${mealDay.date} nutrition calculated: ${totalCalories.toStringAsFixed(1)} cal, ${totalProtein.toStringAsFixed(1)}g protein');

    return dayNutrition;
  }

  /// Calculate nutrition for an entire meal plan
  static Map<String, double> calculateMealPlanNutrition(
      MealPlanModel mealPlan) {
    _logger.i('Calculating nutrition for meal plan: ${mealPlan.title}');

    double totalCalories = 0.0;
    double totalProtein = 0.0;
    double totalCarbs = 0.0;
    double totalFat = 0.0;
    double totalFiber = 0.0;
    double totalSugar = 0.0;
    double totalSodium = 0.0;

    for (final mealDay in mealPlan.mealDays) {
      final dayNutrition = calculateMealDayNutrition(mealDay);
      totalCalories += dayNutrition['calories'] ?? 0.0;
      totalProtein += dayNutrition['protein'] ?? 0.0;
      totalCarbs += dayNutrition['carbs'] ?? 0.0;
      totalFat += dayNutrition['fat'] ?? 0.0;
      totalFiber += dayNutrition['fiber'] ?? 0.0;
      totalSugar += dayNutrition['sugar'] ?? 0.0;
      totalSodium += dayNutrition['sodium'] ?? 0.0;
    }

    final planNutrition = {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
      'fiber': totalFiber,
      'sugar': totalSugar,
      'sodium': totalSodium,
    };

    _logger.i(
        'Meal plan nutrition calculated: ${totalCalories.toStringAsFixed(1)} cal, ${totalProtein.toStringAsFixed(1)}g protein');

    return planNutrition;
  }

  /// Validate nutrition ranges and flag potential issues
  static Map<String, dynamic> validateNutritionRanges(
    Map<String, double> nutrition,
    String context,
    int targetCalories,
  ) {
    final issues = <String>[];
    final warnings = <String>[];

    // Calorie validation
    final calories = nutrition['calories'] ?? 0.0;
    final calorieDiff = (calories - targetCalories).abs();
    final caloriePercentDiff = (calorieDiff / targetCalories) * 100;

    if (caloriePercentDiff > 20) {
      issues.add(
          'Calories (${calories.toStringAsFixed(0)}) differ by ${caloriePercentDiff.toStringAsFixed(1)}% from target ($targetCalories)');
    } else if (caloriePercentDiff > 10) {
      warnings.add(
          'Calories (${calories.toStringAsFixed(0)}) differ by ${caloriePercentDiff.toStringAsFixed(1)}% from target ($targetCalories)');
    }

    // Macronutrient balance validation
    final protein = nutrition['protein'] ?? 0.0;
    final carbs = nutrition['carbs'] ?? 0.0;
    final fat = nutrition['fat'] ?? 0.0;

    if (calories > 0) {
      final proteinPercent = (protein * 4 / calories) * 100;
      final carbsPercent = (carbs * 4 / calories) * 100;
      final fatPercent = (fat * 9 / calories) * 100;

      if (proteinPercent < 10 || proteinPercent > 50) {
        warnings.add(
            'Protein is ${proteinPercent.toStringAsFixed(1)}% of calories (recommended: 10-50%)');
      }
      if (carbsPercent < 20 || carbsPercent > 70) {
        warnings.add(
            'Carbs are ${carbsPercent.toStringAsFixed(1)}% of calories (recommended: 20-70%)');
      }
      if (fatPercent < 15 || fatPercent > 50) {
        warnings.add(
            'Fat is ${fatPercent.toStringAsFixed(1)}% of calories (recommended: 15-50%)');
      }
    }

    // Sodium validation
    final sodium = nutrition['sodium'] ?? 0.0;
    if (sodium > 2300) {
      warnings.add(
          'Sodium (${sodium.toStringAsFixed(0)}mg) exceeds daily limit (2300mg)');
    }

    // Sugar validation
    final sugar = nutrition['sugar'] ?? 0.0;
    if (sugar > 50) {
      warnings.add('Sugar (${sugar.toStringAsFixed(1)}g) is high');
    }

    return {
      'isValid': issues.isEmpty,
      'issues': issues,
      'warnings': warnings,
      'context': context,
    };
  }

  /// Apply nutrition calculations to a meal and update its nutrition data
  static void applyCalculatedNutritionToMeal(Meal meal) {
    final calculatedNutrition = calculateMealNutrition(meal);
    meal.nutrition = calculatedNutrition;
  }

  /// Apply nutrition calculations to a meal day and update its totals
  static void applyCalculatedNutritionToMealDay(MealDay mealDay) {
    final dayNutrition = calculateMealDayNutrition(mealDay);

    mealDay.totalCalories = dayNutrition['calories'] ?? 0.0;
    mealDay.totalProtein = dayNutrition['protein'] ?? 0.0;
    mealDay.totalCarbs = dayNutrition['carbs'] ?? 0.0;
    mealDay.totalFat = dayNutrition['fat'] ?? 0.0;
  }

  /// Apply nutrition calculations to a meal plan and update its totals
  static void applyCalculatedNutritionToMealPlan(MealPlanModel mealPlan) {
    final planNutrition = calculateMealPlanNutrition(mealPlan);

    mealPlan.totalCalories = planNutrition['calories'] ?? 0.0;
    mealPlan.totalProtein = planNutrition['protein'] ?? 0.0;
    mealPlan.totalCarbs = planNutrition['carbs'] ?? 0.0;
    mealPlan.totalFat = planNutrition['fat'] ?? 0.0;
  }

  /// Get a summary of nutrition calculation results
  static Map<String, dynamic> getCalculationSummary(
    Map<String, double> nutrition,
    String context,
  ) {
    return {
      'context': context,
      'calories': nutrition['calories']?.toStringAsFixed(1) ?? '0.0',
      'protein': '${nutrition['protein']?.toStringAsFixed(1) ?? '0.0'}g',
      'carbs': '${nutrition['carbs']?.toStringAsFixed(1) ?? '0.0'}g',
      'fat': '${nutrition['fat']?.toStringAsFixed(1) ?? '0.0'}g',
      'fiber': '${nutrition['fiber']?.toStringAsFixed(1) ?? '0.0'}g',
      'sugar': '${nutrition['sugar']?.toStringAsFixed(1) ?? '0.0'}g',
      'sodium': '${nutrition['sodium']?.toStringAsFixed(0) ?? '0'}mg',
    };
  }
}
