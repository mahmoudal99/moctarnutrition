import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_model.dart';
import '../models/user_model.dart';

class MealPlanStorageService {
  static const String _mealPlanKeyPrefix = 'meal_plan_';
  static const String _dietPreferencesKeyPrefix = 'diet_preferences_';

  /// Save the current meal plan to shared preferences
  static Future<void> saveMealPlan(MealPlanModel mealPlan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mealPlanJson = jsonEncode(mealPlan.toJson());
      final key = '${_mealPlanKeyPrefix}${mealPlan.userId}';
      await prefs.setString(key, mealPlanJson);
      print('Meal plan saved to shared preferences for user ${mealPlan.userId}');
    } catch (e) {
      print('Error saving meal plan to shared preferences: $e');
      throw Exception('Failed to save meal plan: $e');
    }
  }

  /// Load the current meal plan from shared preferences
  static Future<MealPlanModel?> loadMealPlan(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_mealPlanKeyPrefix}$userId';
      final mealPlanJson = prefs.getString(key);
      if (mealPlanJson == null) return null;
      
      final Map<String, dynamic> map = jsonDecode(mealPlanJson);
      final mealPlan = MealPlanModel.fromJson(map);
      print('Meal plan loaded from shared preferences for user $userId');
      return mealPlan;
    } catch (e) {
      print('Error loading meal plan from shared preferences: $e');
      return null;
    }
  }

  /// Save diet plan preferences to shared preferences
  static Future<void> saveDietPreferences(DietPlanPreferences preferences, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = jsonEncode(_dietPreferencesToJson(preferences));
      final key = '${_dietPreferencesKeyPrefix}$userId';
      await prefs.setString(key, preferencesJson);
      print('Diet preferences saved to shared preferences for user $userId');
    } catch (e) {
      print('Error saving diet preferences to shared preferences: $e');
      throw Exception('Failed to save diet preferences: $e');
    }
  }

  /// Load diet plan preferences from shared preferences
  static Future<DietPlanPreferences?> loadDietPreferences(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_dietPreferencesKeyPrefix}$userId';
      final preferencesJson = prefs.getString(key);
      if (preferencesJson == null) return null;
      
      final Map<String, dynamic> map = jsonDecode(preferencesJson);
      final preferences = _dietPreferencesFromJson(map);
      print('Diet preferences loaded from shared preferences for user $userId');
      return preferences;
    } catch (e) {
      print('Error loading diet preferences from shared preferences: $e');
      return null;
    }
  }

  /// Clear all meal plan data from shared preferences
  static Future<void> clearMealPlanData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mealPlanKey = '${_mealPlanKeyPrefix}$userId';
      final dietPreferencesKey = '${_dietPreferencesKeyPrefix}$userId';
      await prefs.remove(mealPlanKey);
      await prefs.remove(dietPreferencesKey);
      print('Meal plan data cleared from shared preferences for user $userId');
    } catch (e) {
      print('Error clearing meal plan data: $e');
    }
  }

  /// Check if a meal plan exists in storage
  static Future<bool> hasMealPlan(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_mealPlanKeyPrefix}$userId';
      return prefs.containsKey(key);
    } catch (e) {
      print('Error checking meal plan existence: $e');
      return false;
    }
  }

  /// Convert DietPlanPreferences to JSON
  static Map<String, dynamic> _dietPreferencesToJson(DietPlanPreferences preferences) {
    return {
      'age': preferences.age,
      'gender': preferences.gender,
      'weight': preferences.weight,
      'height': preferences.height,
      'fitnessGoal': preferences.fitnessGoal.toString().split('.').last,
      'activityLevel': preferences.activityLevel.toString().split('.').last,
      'dietaryRestrictions': preferences.dietaryRestrictions,
      'preferredWorkoutStyles': preferences.preferredWorkoutStyles,
      'nutritionGoal': preferences.nutritionGoal,
      'preferredCuisines': preferences.preferredCuisines,
      'foodsToAvoid': preferences.foodsToAvoid,
      'favoriteFoods': preferences.favoriteFoods,
      'mealFrequency': preferences.mealFrequency,
      'weeklyRotation': preferences.weeklyRotation,
      'remindersEnabled': preferences.remindersEnabled,
      'targetCalories': preferences.targetCalories,
      'targetProtein': preferences.targetProtein,
      'proteinTargets': preferences.proteinTargets,
      'calorieTargets': preferences.calorieTargets,
      'allergies': preferences.allergies,
      'mealTimingPreferences': preferences.mealTimingPreferences,
      'batchCookingPreferences': preferences.batchCookingPreferences,
    };
  }

  /// Convert JSON to DietPlanPreferences
  static DietPlanPreferences _dietPreferencesFromJson(Map<String, dynamic> json) {
    return DietPlanPreferences(
      age: json['age'] as int,
      gender: json['gender'] as String,
      weight: (json['weight'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      fitnessGoal: FitnessGoal.values.firstWhere(
        (e) => e.toString() == 'FitnessGoal.${json['fitnessGoal']}',
        orElse: () => FitnessGoal.maintenance,
      ),
      activityLevel: ActivityLevel.values.firstWhere(
        (e) => e.toString() == 'ActivityLevel.${json['activityLevel']}',
        orElse: () => ActivityLevel.moderatelyActive,
      ),
      dietaryRestrictions: List<String>.from(json['dietaryRestrictions']),
      preferredWorkoutStyles: List<String>.from(json['preferredWorkoutStyles']),
      nutritionGoal: json['nutritionGoal'] as String,
      preferredCuisines: List<String>.from(json['preferredCuisines']),
      foodsToAvoid: List<String>.from(json['foodsToAvoid']),
      favoriteFoods: List<String>.from(json['favoriteFoods']),
      mealFrequency: json['mealFrequency'] as String,
      weeklyRotation: json['weeklyRotation'] as bool,
      remindersEnabled: json['remindersEnabled'] as bool,
      targetCalories: json['targetCalories'] as int,
      targetProtein: json['targetProtein'] as int?,
      proteinTargets: json['proteinTargets'] as Map<String, dynamic>?,
      calorieTargets: json['calorieTargets'] as Map<String, dynamic>?,
      allergies: json['allergies'] as List<Map<String, dynamic>>?,
      mealTimingPreferences: json['mealTimingPreferences'] as Map<String, dynamic>?,
      batchCookingPreferences: json['batchCookingPreferences'] as Map<String, dynamic>?,
    );
  }
} 