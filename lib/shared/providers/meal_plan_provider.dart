import 'package:flutter/material.dart';
import '../models/meal_model.dart';
import '../services/nutrition_calculation_service.dart';

class MealPlanProvider with ChangeNotifier {
  MealPlanModel? _mealPlan;

  MealPlanProvider();

  MealPlanModel? get mealPlan => _mealPlan;



  void setMealPlan(MealPlanModel mealPlan) {
    _mealPlan = mealPlan;
    notifyListeners();
  }



  Future<void> replaceNonCompliantIngredient(
    String mealId,
    String oldIngredientName,
    RecipeIngredient newIngredient,
  ) async {
    if (_mealPlan == null) return;

    final mealDay = _mealPlan!.mealDays.firstWhere(
      (day) => day.meals.any((m) => m.id == mealId),
    );
    final meal = mealDay.meals.firstWhere((m) => m.id == mealId);
    final ingredientIndex = meal.ingredients
        .indexWhere((i) => i.name == oldIngredientName);

    if (ingredientIndex != -1) {
      meal.ingredients[ingredientIndex] = newIngredient;
      
      // Recalculate meal nutrition using the new service
      NutritionCalculationService.applyCalculatedNutritionToMeal(meal);
      
      // Recalculate meal day totals using the new service
      NutritionCalculationService.applyCalculatedNutritionToMealDay(mealDay);
      
      notifyListeners();
    }
  }




} 