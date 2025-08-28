import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../models/meal_model.dart';

/// Service responsible for tracking daily consumption data separately from meal plan templates
/// This ensures each calendar day has unique consumption tracking
class DailyConsumptionService {
  static final _logger = Logger();
  static const String _consumptionKeyPrefix = 'daily_consumption_';

  /// Save consumption data for a specific date
  static Future<void> saveDailyConsumption(
    String userId,
    DateTime date,
    Map<String, bool> mealConsumption,
    Map<String, double> nutritionData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey = _getDateKey(date);
      final key = '$_consumptionKeyPrefix${userId}_$dateKey';

      final consumptionData = {
        'date': date.toIso8601String(),
        'mealConsumption': mealConsumption,
        'nutritionData': nutritionData,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      final jsonData = jsonEncode(consumptionData);
      await prefs.setString(key, jsonData);

      _logger.d(
          'Saved consumption data for $dateKey: ${consumptionData['nutritionData']}');
    } catch (e) {
      _logger.e(
          'Failed to save consumption data for ${date.toIso8601String()}: $e');
      rethrow;
    }
  }

  /// Load consumption data for a specific date
  static Future<Map<String, dynamic>?> loadDailyConsumption(
    String userId,
    DateTime date,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey = _getDateKey(date);
      final key = '$_consumptionKeyPrefix${userId}_$dateKey';

      final jsonData = prefs.getString(key);
      if (jsonData == null) return null;

      final consumptionData = jsonDecode(jsonData) as Map<String, dynamic>;
      _logger.d(
          'Loaded consumption data for $dateKey: ${consumptionData['nutritionData']}');

      return consumptionData;
    } catch (e) {
      _logger.e(
          'Failed to load consumption data for ${date.toIso8601String()}: $e');
      return null;
    }
  }

  /// Update meal consumption for a specific date
  static Future<void> updateMealConsumption(
    String userId,
    DateTime date,
    String mealId,
    bool isConsumed,
  ) async {
    try {
      // Load existing consumption data
      final existingData = await loadDailyConsumption(userId, date);
      Map<String, bool> mealConsumption = {};
      Map<String, double> nutritionData = {
        'consumedCalories': 0.0,
        'consumedProtein': 0.0,
        'consumedCarbs': 0.0,
        'consumedFat': 0.0,
      };

      if (existingData != null) {
        mealConsumption =
            Map<String, bool>.from(existingData['mealConsumption'] ?? {});
        nutritionData =
            Map<String, double>.from(existingData['nutritionData'] ?? {});
      }

      // Use the original meal ID (without date suffix) for consistency
      final originalMealId =
          mealId.split('_').first; // Remove date suffix if present
      mealConsumption[originalMealId] = isConsumed;

      // Recalculate nutrition data based on current meal consumption
      nutritionData =
          await _recalculateNutritionData(userId, date, mealConsumption);

      // Save updated data
      await saveDailyConsumption(userId, date, mealConsumption, nutritionData);

      _logger.d(
          'Updated meal consumption for $originalMealId on ${date.toIso8601String()}: $isConsumed');
      _logger.d('Updated nutrition data: $nutritionData');
    } catch (e) {
      _logger.e('Failed to update meal consumption: $e');
      rethrow;
    }
  }

  /// Recalculate nutrition data based on meal consumption
  static Future<Map<String, double>> _recalculateNutritionData(
      String userId, DateTime date, Map<String, bool> mealConsumption) async {
    try {
      double totalCalories = 0.0;
      double totalProtein = 0.0;
      double totalCarbs = 0.0;
      double totalFats = 0.0;

      // Get the meal plan for this user to calculate nutrition
      // This is a simplified approach - you might need to implement this based on your meal plan structure
      final mealPlan = await _getUserMealPlan(userId);

      if (mealPlan != null) {
        // Calculate nutrition from consumed meals
        for (final entry in mealConsumption.entries) {
          final mealId = entry.key;
          final isConsumed = entry.value;

          if (isConsumed) {
            // Find the meal in the meal plan and add its nutrition
            final meal = _findMealInPlan(mealPlan, mealId);
            if (meal != null) {
              totalCalories += meal.nutrition.calories;
              totalProtein += meal.nutrition.protein;
              totalCarbs += meal.nutrition.carbs;
              totalFats += meal.nutrition.fat;
            }
          }
        }
      }

      return {
        'consumedCalories': totalCalories,
        'consumedProtein': totalProtein,
        'consumedCarbs': totalCarbs,
        'consumedFat': totalFats,
      };
    } catch (e) {
      _logger.w('Error recalculating nutrition data: $e');
      return {
        'consumedCalories': 0.0,
        'consumedProtein': 0.0,
        'consumedCarbs': 0.0,
        'consumedFat': 0.0,
      };
    }
  }

  /// Get user's meal plan (placeholder - implement based on your structure)
  static Future<dynamic> _getUserMealPlan(String userId) async {
    try {
      // Import and implement based on your meal plan service
      // For now, return null to use fallback approach
      return null;
    } catch (e) {
      _logger.w('Could not load meal plan for user $userId: $e');
      return null;
    }
  }

  /// Find meal in meal plan (placeholder - implement based on your structure)
  static dynamic _findMealInPlan(dynamic mealPlan, String mealId) {
    try {
      // Implement based on your meal plan structure
      // For now, return null
      return null;
    } catch (e) {
      _logger.w('Error finding meal in plan: $e');
      return null;
    }
  }

  /// Get consumption summary for a specific date
  static Future<Map<String, dynamic>?> getDailyConsumptionSummary(
    String userId,
    DateTime date,
  ) async {
    try {
      final consumptionData = await loadDailyConsumption(userId, date);
      if (consumptionData == null) return null;

      final mealConsumption =
          Map<String, bool>.from(consumptionData['mealConsumption'] ?? {});
      final nutritionData =
          Map<String, double>.from(consumptionData['nutritionData'] ?? {});

      return {
        'date': date,
        'mealConsumption': mealConsumption,
        'consumedCalories': nutritionData['consumedCalories'] ?? 0.0,
        'consumedProtein': nutritionData['consumedProtein'] ?? 0.0,
        'consumedCarbs': nutritionData['consumedCarbs'] ?? 0.0,
        'consumedFat': nutritionData['consumedFat'] ?? 0.0,
      };
    } catch (e) {
      _logger.e('Failed to get consumption summary: $e');
      return null;
    }
  }

  /// Clear consumption data for a specific date
  static Future<void> clearDailyConsumption(
    String userId,
    DateTime date,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey = _getDateKey(date);
      final key = '$_consumptionKeyPrefix${userId}_$dateKey';

      await prefs.remove(key);
      _logger.d('Cleared consumption data for $dateKey');
    } catch (e) {
      _logger.e('Failed to clear consumption data: $e');
      rethrow;
    }
  }

  /// Get a unique key for a date (YYYY-MM-DD format)
  static String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
