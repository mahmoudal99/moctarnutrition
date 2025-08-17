import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/meal_model.dart';
import '../models/user_model.dart';
import '../services/nutrition_calculation_service.dart';
import '../services/meal_plan_local_storage_service.dart';
import '../services/meal_plan_firestore_service.dart';

class MealPlanProvider with ChangeNotifier {
  static final _logger = Logger();
  
  MealPlanModel? _mealPlan;
  bool _isLoading = false;
  String? _error;

  MealPlanModel? get mealPlan => _mealPlan;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setMealPlan(MealPlanModel mealPlan) {
    _mealPlan = mealPlan;
    _error = null;
    notifyListeners();
  }

  void clearMealPlan() {
    _mealPlan = null;
    _error = null;
    _isLoading = false; // Ensure loading state is reset
    notifyListeners();
  }

  /// Load meal plan with caching strategy
  Future<void> loadMealPlan(String userId) async {
    _setLoading(true);
    _error = null;

    _logger.d('Loading meal plan for user: $userId');

    try {
      // First, try to load from local storage
      final localMealPlan = await MealPlanLocalStorageService.loadMealPlan(userId);
      
      if (localMealPlan != null) {
        _logger.d('Found meal plan in local storage: ${localMealPlan.title}');
        _mealPlan = localMealPlan;
        
        // Check if the local plan is fresh (less than 24 hours old)
        final isFresh = await MealPlanLocalStorageService.isMealPlanFresh();
        if (isFresh) {
          _logger.d('Local meal plan is fresh, using cached data');
          _setLoading(false);
          return;
        } else {
          _logger.d('Local meal plan is stale, refreshing from server');
        }
      }

      // Try to load from Firestore (server-side storage)
      try {
        final firestoreMealPlan = await MealPlanFirestoreService.getMealPlan(userId);
        
        if (firestoreMealPlan != null) {
          _logger.d('Found meal plan in Firestore: ${firestoreMealPlan.title}');
          _mealPlan = firestoreMealPlan;
          
          // Save to local storage for future use
          try {
            await MealPlanLocalStorageService.saveMealPlan(firestoreMealPlan);
            _logger.d('Meal plan saved to local storage');
          } catch (e) {
            _logger.w('Failed to save meal plan to local storage: $e');
          }
          
          _setLoading(false);
          return;
        }
      } on FirebaseException catch (e) {
        _logger.w('Firebase error loading from Firestore: ${e.code} - ${e.message}');
        if (e.code == 'failed-precondition') {
          _logger.i('Trying fallback query without ordering');
          try {
            final fallbackMealPlan = await MealPlanFirestoreService.getMealPlanFallback(userId);
            if (fallbackMealPlan != null) {
              _logger.d('Found meal plan using fallback query: ${fallbackMealPlan.title}');
              _mealPlan = fallbackMealPlan;
              
              // Save to local storage for future use
              try {
                await MealPlanLocalStorageService.saveMealPlan(fallbackMealPlan);
                _logger.d('Meal plan saved to local storage');
              } catch (e) {
                _logger.w('Failed to save meal plan to local storage: $e');
              }
              
              _setLoading(false);
              return;
            }
          } catch (fallbackError) {
            _logger.w('Fallback query also failed: $fallbackError');
          }
        }
        // If we have local data, use it as fallback
        if (localMealPlan != null) {
          _logger.i('Using local meal plan as fallback due to Firestore error');
          _mealPlan = localMealPlan;
          _setLoading(false);
          return;
        }
        // Re-throw if no local fallback available
        rethrow;
      } catch (e) {
        _logger.w('Failed to load from Firestore: $e');
        // If we have local data, use it as fallback
        if (localMealPlan != null) {
          _logger.i('Using local meal plan as fallback due to Firestore error');
          _mealPlan = localMealPlan;
          _setLoading(false);
          return;
        }
        // Re-throw if no local fallback available
        rethrow;
      }

      // No meal plan found
      _logger.i('No meal plan found for user: $userId');
      _mealPlan = null;
      _setLoading(false);
    } catch (e) {
      _logger.e('Error loading meal plan: $e');
      _error = 'Failed to load meal plan: $e';
      _setLoading(false);
    }
  }

  /// Load meal plan by ID (for admin or specific access)
  Future<void> loadMealPlanById(String mealPlanId) async {
    _setLoading(true);
    _error = null;

    _logger.d('Loading meal plan by ID: $mealPlanId');

    try {
      final mealPlan = await MealPlanFirestoreService.getMealPlanById(mealPlanId);
      
      if (mealPlan != null) {
        _logger.d('Found meal plan: ${mealPlan.title}');
        _mealPlan = mealPlan;
      } else {
        _logger.i('No meal plan found with ID: $mealPlanId');
        _mealPlan = null;
      }
      
      _setLoading(false);
    } catch (e) {
      _logger.e('Error loading meal plan by ID: $e');
      _error = 'Failed to load meal plan: $e';
      _setLoading(false);
    }
  }

  /// Refresh meal plan from server (force refresh)
  Future<void> refreshMealPlan(String userId) async {
    _logger.d('Force refreshing meal plan for user: $userId');
    
    // Clear local cache to force refresh
    await MealPlanLocalStorageService.clearMealPlan();
    
    // Reload from server
    await loadMealPlan(userId);
  }

  /// Clear local cache
  Future<void> clearLocalCache() async {
    _logger.d('Clearing local meal plan cache');
    await MealPlanLocalStorageService.clearMealPlan();
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