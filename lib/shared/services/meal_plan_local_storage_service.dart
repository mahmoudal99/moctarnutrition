import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../models/meal_model.dart';

class MealPlanLocalStorageService {
  static final _logger = Logger();
  static const String _mealPlanKey = 'meal_plan';
  static const String _lastUpdatedKey = 'meal_plan_last_updated';
  static const String _userIdKey = 'meal_plan_user_id';

  /// Save meal plan to local storage
  static Future<void> saveMealPlan(MealPlanModel mealPlan) async {
    try {
      _logger.d('Saving meal plan to local storage: ${mealPlan.id}');

      final prefs = await SharedPreferences.getInstance();
      final mealPlanJson = jsonEncode(mealPlan.toJson());

      await prefs.setString(_mealPlanKey, mealPlanJson);
      await prefs.setString(_lastUpdatedKey, DateTime.now().toIso8601String());
      await prefs.setString(_userIdKey, mealPlan.userId);

      _logger.i('Meal plan saved to local storage successfully');
    } catch (e) {
      _logger.e('Failed to save meal plan to local storage: $e');
      rethrow;
    }
  }

  /// Load meal plan from local storage
  static Future<MealPlanModel?> loadMealPlan(String userId) async {
    try {
      _logger.d('Loading meal plan from local storage for user: $userId');

      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString(_userIdKey);

      // Check if the stored plan is for the current user
      if (storedUserId != userId) {
        _logger.d('Stored meal plan is for different user, clearing cache');
        await clearMealPlan();
        return null;
      }

      final mealPlanJson = prefs.getString(_mealPlanKey);
      if (mealPlanJson == null) {
        _logger.d('No meal plan found in local storage');
        return null;
      }

      final mealPlanData = jsonDecode(mealPlanJson) as Map<String, dynamic>;
      final mealPlan = MealPlanModel.fromJson(mealPlanData);

      _logger.i('Meal plan loaded from local storage: ${mealPlan.id}');
      return mealPlan;
    } catch (e) {
      _logger.e('Failed to load meal plan from local storage: $e');
      return null;
    }
  }

  /// Check if local meal plan is fresh (less than 24 hours old)
  static Future<bool> isMealPlanFresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdatedString = prefs.getString(_lastUpdatedKey);

      if (lastUpdatedString == null) return false;

      final lastUpdated = DateTime.parse(lastUpdatedString);
      final now = DateTime.now();
      final difference = now.difference(lastUpdated);

      // Consider fresh if less than 24 hours old
      return difference.inHours < 24;
    } catch (e) {
      _logger.e('Failed to check meal plan freshness: $e');
      return false;
    }
  }

  /// Clear meal plan from local storage
  static Future<void> clearMealPlan() async {
    try {
      _logger.d('Clearing meal plan from local storage');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_mealPlanKey);
      await prefs.remove(_lastUpdatedKey);
      await prefs.remove(_userIdKey);

      _logger.i('Meal plan cleared from local storage');
    } catch (e) {
      _logger.e('Failed to clear meal plan from local storage: $e');
    }
  }

  /// Get last updated timestamp
  static Future<DateTime?> getLastUpdated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdatedString = prefs.getString(_lastUpdatedKey);

      if (lastUpdatedString == null) return null;

      return DateTime.parse(lastUpdatedString);
    } catch (e) {
      _logger.e('Failed to get last updated timestamp: $e');
      return null;
    }
  }
}
