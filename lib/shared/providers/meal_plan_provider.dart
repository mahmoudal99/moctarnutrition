import 'package:flutter/material.dart';
import '../models/meal_model.dart';
import '../services/nutrition_verification_service.dart';

class MealPlanProvider with ChangeNotifier {
  MealPlanModel? _mealPlan;
  // Cache verification results by meal ID
  final Map<String, MealVerificationResult> _verificationCache = {};
  // Track meal data hash to detect changes
  final Map<String, String> _mealDataHashes = {};

  MealPlanProvider();

  MealPlanModel? get mealPlan => _mealPlan;

  // Get cached verification result or verify if needed
  Future<MealVerificationResult> getMealVerification(Meal meal) async {
    final mealHash = _generateMealHash(meal);
    final cachedHash = _mealDataHashes[meal.id];
    
    // If we have a cached result and the meal hasn't changed, return cached result
    if (_verificationCache.containsKey(meal.id) && cachedHash == mealHash) {
      return _verificationCache[meal.id]!;
    }
    
    // Otherwise, verify the meal and cache the result
    final verificationResult = await NutritionVerificationService.verifyMeal(meal);
    
    // Automatically apply high-confidence corrections (>60% confidence)
    final highConfidenceCorrections = verificationResult.ingredientVerifications
        .where((v) => v.confidence > 0.6 && v.suggestedCorrection != null)
        .toList();
    
    print('🔍 Verification result for meal ${meal.name}:');
    print('  - Total ingredients: ${verificationResult.ingredientVerifications.length}');
    print('  - High confidence corrections: ${highConfidenceCorrections.length}');
    for (final verification in verificationResult.ingredientVerifications) {
      print('  - ${verification.ingredientName}: ${(verification.confidence * 100).toInt()}% confidence, has correction: ${verification.suggestedCorrection != null}');
      if (verification.suggestedCorrection != null) {
        print('    - Correction data: ${verification.suggestedCorrection}');
      }
    }
    
    if (highConfidenceCorrections.isNotEmpty) {
      // Apply corrections automatically
      await applyMealCorrections(meal.id, verificationResult);
      
      // Notify about automatic corrections
      _notifyAutomaticCorrections(highConfidenceCorrections);
      
      // Get the updated meal and re-verify
      Meal? updatedMeal;
      if (_mealPlan != null) {
        for (final mealDay in _mealPlan!.mealDays) {
          final foundMeal = mealDay.meals.where((m) => m.id == meal.id).firstOrNull;
          if (foundMeal != null) {
            updatedMeal = foundMeal;
            break;
          }
        }
      }
      
      if (updatedMeal != null) {
        // Re-verify the updated meal
        final updatedVerificationResult = await NutritionVerificationService.verifyMeal(updatedMeal);
        _verificationCache[meal.id] = updatedVerificationResult;
        _mealDataHashes[meal.id] = _generateMealHash(updatedMeal);
        return updatedVerificationResult;
      }
    }
    
    _verificationCache[meal.id] = verificationResult;
    _mealDataHashes[meal.id] = mealHash;
    
    return verificationResult;
  }

  // Clear verification cache for a specific meal (when it's modified)
  void clearMealVerificationCache(String mealId) {
    _verificationCache.remove(mealId);
    _mealDataHashes.remove(mealId);
  }

  // Generate a hash of meal data to detect changes
  String _generateMealHash(Meal meal) {
    final ingredientsData = meal.ingredients.map((i) => 
      '${i.name}:${i.amount}:${i.unit}:${i.nutrition?.calories}:${i.nutrition?.protein}:${i.nutrition?.carbs}:${i.nutrition?.fat}'
    ).join('|');
    
    return '${meal.id}:$ingredientsData';
  }

  // Notify about automatic corrections (this will be handled by the UI)
  void _notifyAutomaticCorrections(List<IngredientVerificationDetail> corrections) {
    // This method can be extended to show notifications or log corrections
    print('Automatically applied ${corrections.length} high-confidence corrections');
    for (final correction in corrections) {
      print('  - ${correction.ingredientName}: ${(correction.confidence * 100).toInt()}% confidence');
    }
  }

  void setMealPlan(MealPlanModel mealPlan) {
    _mealPlan = mealPlan;
    // Clear all verification cache when meal plan changes
    _verificationCache.clear();
    _mealDataHashes.clear();
    notifyListeners();
  }

  Future<void> applyMealCorrections(String mealId, MealVerificationResult verificationResult) async {
    if (_mealPlan == null) return;

    final mealDay = _mealPlan!.mealDays.firstWhere(
      (day) => day.meals.any((m) => m.id == mealId),
      orElse: () => throw Exception('Meal not found'),
    );
    
    final meal = mealDay.meals.firstWhere((m) => m.id == mealId);
    
    print('🔧 Applying corrections to meal: ${meal.name}');
    print('  - Verifications to apply: ${verificationResult.ingredientVerifications.length}');

    // Apply corrections to ingredients
    int appliedCount = 0;
    for (final verification in verificationResult.ingredientVerifications) {
      final ingredientIndex = meal.ingredients
          .indexWhere((i) => i.name == verification.ingredientName);
      
      if (ingredientIndex != -1 && verification.suggestedCorrection != null) {
        print('  ✅ Applying correction to ${verification.ingredientName}');
        print('    - Old calories: ${meal.ingredients[ingredientIndex].nutrition?.calories ?? 0}');
        print('    - New calories: ${verification.suggestedCorrection!['calories'] ?? 0}');
        
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
        appliedCount++;
      } else {
        print('  ❌ Skipping ${verification.ingredientName}: ingredient not found or no correction data');
      }
    }
    
    print('  📊 Applied $appliedCount corrections');

    // Recalculate meal nutrition
    meal.nutrition = _calculateMealNutrition(meal);

    // Recalculate meal day totals
    mealDay.totalCalories = mealDay.meals.fold(0.0, (sum, m) => sum + m.nutrition.calories);
    mealDay.totalProtein = mealDay.meals.fold(0.0, (sum, m) => sum + m.nutrition.protein);
    mealDay.totalCarbs = mealDay.meals.fold(0.0, (sum, m) => sum + m.nutrition.carbs);
    mealDay.totalFat = mealDay.meals.fold(0.0, (sum, m) => sum + m.nutrition.fat);

    // Clear verification cache for this meal since it was modified
    clearMealVerificationCache(mealId);

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
      
      // Clear verification cache for this meal since it was modified
      clearMealVerificationCache(mealId);
      
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