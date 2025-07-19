import 'package:flutter/material.dart';
import '../models/meal_model.dart';
import '../services/nutrition_verification_service.dart';

class MealPlanProvider with ChangeNotifier {
  MealPlanModel? _mealPlan;

  MealPlanProvider();

  MealPlanModel? get mealPlan => _mealPlan;

  void setMealPlan(MealPlanModel mealPlan) {
    _mealPlan = mealPlan;
    notifyListeners();
  }

  Future<void> applyMealCorrections(String mealId, MealVerificationResult verificationResult) async {
    if (_mealPlan == null) return;

    final mealDay = _mealPlan!.mealDays.firstWhere(
      (day) => day.meals.any((m) => m.id == mealId),
      orElse: () => throw Exception('Meal not found'),
    );
    
    final meal = mealDay.meals.firstWhere((m) => m.id == mealId);

    // Apply corrections to ingredients
    for (final verification in verificationResult.ingredientVerifications) {
      final ingredientIndex = meal.ingredients
          .indexWhere((i) => i.name == verification.ingredientName);
      
      if (ingredientIndex != -1 && verification.suggestedCorrection != null) {
        meal.ingredients[ingredientIndex] = RecipeIngredient(
          name: meal.ingredients[ingredientIndex].name,
          amount: meal.ingredients[ingredientIndex].amount,
          unit: meal.ingredients[ingredientIndex].unit,
          notes: meal.ingredients[ingredientIndex].notes,
          nutrition: NutritionInfo(
            calories: verification.suggestedCorrection!['calories'] ?? 0.0,
            protein: verification.suggestedCorrection!['protein'] ?? 0.0,
            carbs: verification.suggestedCorrection!['carbs'] ?? 0.0,
            fat: verification.suggestedCorrection!['fat'] ?? 0.0,
            fiber: verification.suggestedCorrection!['fiber'] ?? 0.0,
            sugar: verification.suggestedCorrection!['sugar'] ?? 0.0,
            sodium: verification.suggestedCorrection!['sodium'] ?? 0.0,
          ),
        );
      }
    }

    // Recalculate meal nutrition
    meal.nutrition = _calculateMealNutrition(meal);

    // Recalculate meal day totals
    mealDay.totalCalories = mealDay.meals.fold(0.0, (sum, m) => sum + m.nutrition.calories);
    mealDay.totalProtein = mealDay.meals.fold(0.0, (sum, m) => sum + m.nutrition.protein);
    mealDay.totalCarbs = mealDay.meals.fold(0.0, (sum, m) => sum + m.nutrition.carbs);
    mealDay.totalFat = mealDay.meals.fold(0.0, (sum, m) => sum + m.nutrition.fat);

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
      meal.nutrition = _calculateMealNutrition(meal);
      
      // Recalculate meal day totals
      mealDay.totalCalories = mealDay.meals.fold(0.0, (sum, m) => sum + m.nutrition.calories);
      mealDay.totalProtein = mealDay.meals.fold(0.0, (sum, m) => sum + m.nutrition.protein);
      mealDay.totalCarbs = mealDay.meals.fold(0.0, (sum, m) => sum + m.nutrition.carbs);
      mealDay.totalFat = mealDay.meals.fold(0.0, (sum, m) => sum + m.nutrition.fat);
      
      notifyListeners();
    }
  }

  NutritionInfo _calculateMealNutrition(Meal meal) {
    double calories = 0, protein = 0, carbs = 0, fat = 0, fiber = 0, sugar = 0, sodium = 0;
    
    for (final ingredient in meal.ingredients) {
      if (ingredient.nutrition != null) {
        calories += ingredient.nutrition!.calories;
        protein += ingredient.nutrition!.protein;
        carbs += ingredient.nutrition!.carbs;
        fat += ingredient.nutrition!.fat;
        fiber += ingredient.nutrition!.fiber;
        sugar += ingredient.nutrition!.sugar;
        sodium += ingredient.nutrition!.sodium;
      }
    }
    
    return NutritionInfo(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      sugar: sugar,
      sodium: sodium,
    );
  }

  Future<void> applyAutomaticCorrections() async {
    if (_mealPlan == null) return;

    for (final mealDay in _mealPlan!.mealDays) {
      for (final meal in mealDay.meals) {
        final verificationResult = await NutritionVerificationService.verifyMeal(meal);
        
        // Apply corrections for high-confidence USDA data (>80%)
        final highConfidenceCorrections = verificationResult.ingredientVerifications
            .where((v) => v.confidence > 0.8 && v.suggestedCorrection != null)
            .toList();
        
        if (highConfidenceCorrections.isNotEmpty) {
          final correctedResult = MealVerificationResult(
            isVerified: verificationResult.isVerified,
            confidence: verificationResult.confidence,
            message: verificationResult.message,
            ingredientVerifications: highConfidenceCorrections,
          );
          
          await applyMealCorrections(meal.id, correctedResult);
        }
      }
    }
  }
} 