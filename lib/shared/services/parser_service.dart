import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/meal_model.dart';
import 'json_utils.dart';
import 'nutrition_calculation_service.dart';
import 'json_validation_service.dart';

/// Custom exception for validation failures
class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  
  @override
  String toString() => 'ValidationException: $message';
}

/// Service for parsing AI responses into meal plan models
class ParserService {
  /// Parse single day AI response into MealDay
  static Future<MealDay> parseSingleDayFromAI(
    String aiResponse,
    DietPlanPreferences preferences,
    int dayIndex,
  ) async {
    try {
      print('Parsing single day AI response for day $dayIndex...');
      print('AI Response length: ${aiResponse.length}');
      print('AI Response preview: ${aiResponse.substring(0, aiResponse.length > 200 ? 200 : aiResponse.length)}...');
      
      // Debug: Print the full AI response for debugging
      print('FULL AI RESPONSE FOR DAY $dayIndex:');
      print(aiResponse);

      // Validate the JSON response first
      final validationResult = JSONValidationService.validateSingleDayResponse(
        aiResponse,
        preferences,
        dayIndex,
      );

      if (!validationResult['isValid']) {
        throw ValidationException('JSON validation failed: ${validationResult['message']}');
      }

      // Use the validated data
      final data = validationResult['data'];
      final mealDayData = data['mealDay'];
      
      // Debug: Check ingredients in parsed data
      if (mealDayData['meals'] != null) {
        final meals = mealDayData['meals'] as List;
        print('PARSED MEALS FOR DAY $dayIndex:');
        for (int i = 0; i < meals.length; i++) {
          final meal = meals[i];
          print('  Meal ${i + 1}: ${meal['name']} (${meal['type']})');
          if (meal['ingredients'] != null) {
            final ingredients = meal['ingredients'] as List;
            print('    Ingredients:');
            for (int j = 0; j < ingredients.length; j++) {
              final ingredient = ingredients[j];
              print('      ${j + 1}. ${ingredient['name']} - ${ingredient['amount']} ${ingredient['unit']}');
            }
          }
        }
      }

      // Generate unique IDs for the meal day and meals
      mealDayData['id'] = const Uuid().v4();

      // Process meals and generate unique IDs
      if (mealDayData['meals'] != null) {
        final meals = (mealDayData['meals'] as List).map((mealData) {
          final mealMap = Map<String, dynamic>.from(mealData);
          // Generate unique ID for each meal
          mealMap['id'] = const Uuid().v4();
          
          // Remove any model-provided meal nutrition (we'll calculate it ourselves)
          mealMap.remove('nutrition');
          
          return mealMap;
        }).toList();
        mealDayData['meals'] = meals;

        // Remove any model-provided day totals (we'll calculate them ourselves)
        mealDayData.remove('totalCalories');
        mealDayData.remove('totalProtein');
        mealDayData.remove('totalCarbs');
        mealDayData.remove('totalFat');

        // Validate meal types
        _validateMealTypes(meals, preferences, dayIndex);
      }

      final mealDay = MealDay.fromJson(mealDayData);
      
      // Apply calculated nutrition to all meals and the meal day
      _applyCalculatedNutrition(mealDay);
      
      return mealDay;
    } catch (e) {
      print('JSON parsing failed for day $dayIndex: $e');
      throw Exception('Failed to parse AI response for day $dayIndex: $e');
    }
  }

  /// Parse AI response into MealPlanModel
  static MealPlanModel parseMealPlanFromAI(
    String aiResponse,
    DietPlanPreferences preferences,
    int days,
  ) {
    try {
      print('Parsing AI response...');
      print('AI Response length: ${aiResponse.length}');
      print('AI Response preview: ${aiResponse.substring(0, aiResponse.length > 200 ? 200 : aiResponse.length)}...');

      // Clean and fix the JSON
      final cleanedJson = JsonUtils.cleanAndFixJson(aiResponse);
      final data = JsonUtils.parseJson(cleanedJson, context: 'meal plan');
      final mealPlanData = data['mealPlan'];

      final mealDays = (mealPlanData['mealDays'] as List).map((dayData) {
        final dayMap = Map<String, dynamic>.from(dayData);
        // Generate unique ID for the meal day
        dayMap['id'] = const Uuid().v4();
        if (dayMap['totalCalories'] is double) {
          dayMap['totalCalories'] = (dayMap['totalCalories'] as double).toInt();
        }

        // Calculate nutrition totals from meals if they're missing or 0
        if (dayMap['meals'] != null) {
          final meals = (dayMap['meals'] as List).map((mealData) {
            final mealMap = Map<String, dynamic>.from(mealData);
            // Generate unique ID for each meal
            mealMap['id'] = const Uuid().v4();
            if (mealMap['nutrition'] != null &&
                mealMap['nutrition']['calories'] is double) {
              mealMap['nutrition']['calories'] =
                  (mealMap['nutrition']['calories'] as double).toInt();
            }
            return mealMap;
          }).toList();
          dayMap['meals'] = meals;

          // Calculate day totals from meals
          double dayProtein = 0;
          double dayCarbs = 0;
          double dayFat = 0;

          for (final meal in meals) {
            if (meal['nutrition'] != null) {
              final nutrition = meal['nutrition'] as Map<String, dynamic>;
              dayProtein += JsonUtils.safeToDouble(nutrition['protein']);
              dayCarbs += JsonUtils.safeToDouble(nutrition['carbs']);
              dayFat += JsonUtils.safeToDouble(nutrition['fat']);
            }
          }

          // Update day totals if they're missing or 0
          if (JsonUtils.safeToDouble(dayMap['totalProtein']) == 0 || dayMap['totalProtein'] == null) {
            dayMap['totalProtein'] = dayProtein;
          }
          if (JsonUtils.safeToDouble(dayMap['totalCarbs']) == 0 || dayMap['totalCarbs'] == null) {
            dayMap['totalCarbs'] = dayCarbs;
          }
          if (JsonUtils.safeToDouble(dayMap['totalFat']) == 0 || dayMap['totalFat'] == null) {
            dayMap['totalFat'] = dayFat;
          }
        }

        return MealDay.fromJson(dayMap);
      }).toList();

      // Calculate overall meal plan totals
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (final day in mealDays) {
        totalProtein += day.totalProtein;
        totalCarbs += day.totalCarbs;
        totalFat += day.totalFat;
      }

      return MealPlanModel(
        id: const Uuid().v4(),
        userId: 'current_user',
        title: mealPlanData['title'],
        description: mealPlanData['description'],
        startDate: DateTime.parse(mealPlanData['startDate']),
        endDate: DateTime.parse(mealPlanData['endDate']),
        mealDays: mealDays,
        totalCalories: JsonUtils.safeToDouble(mealPlanData['totalCalories']),
        totalProtein: totalProtein,
        totalCarbs: totalCarbs,
        totalFat: totalFat,
        dietaryTags: List<String>.from(mealPlanData['dietaryTags']),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('JSON parsing failed: $e');
      throw Exception('Failed to parse AI response: $e');
    }
  }

  /// Validate that all required meal types are present
  static void _validateMealTypes(
    List<Map<String, dynamic>> meals,
    DietPlanPreferences preferences,
    int dayIndex,
  ) {
    final requiredMeals = _getRequiredMealTypes(preferences.mealFrequency);
    final presentMealTypes = meals.map((m) => m['type'] as String).toSet();
    
    final missingMeals = <String>[];
    for (final requiredType in requiredMeals) {
      if (!presentMealTypes.contains(requiredType.name)) {
        missingMeals.add(requiredType.name);
      }
    }
    
    if (missingMeals.isNotEmpty) {
      print('⚠️ WARNING: Day $dayIndex is missing required meal types: ${missingMeals.join(', ')}');
      print('Present meals: ${presentMealTypes.join(', ')}');
      print('Required meals: ${requiredMeals.map((t) => t.name).join(', ')}');
    } else {
      print('✅ Day $dayIndex validation passed - all required meals present');
    }
  }

  /// Helper to determine required meal types based on meal frequency
  static List<MealType> _getRequiredMealTypes(String mealFrequency) {
    // Always require breakfast, lunch, and dinner as core meals
    final requiredMeals = [MealType.breakfast, MealType.lunch, MealType.dinner];
    
    // Add snacks based on meal frequency string (case-insensitive)
    if (mealFrequency.toLowerCase().contains('snack') || mealFrequency.contains('4') || mealFrequency.contains('5')) {
      requiredMeals.add(MealType.snack);
    }
    
    return requiredMeals;
  }

  /// Apply calculated nutrition to a meal day and all its meals
  static void _applyCalculatedNutrition(MealDay mealDay) {
    try {
      // Calculate nutrition for each meal
      for (final meal in mealDay.meals) {
        NutritionCalculationService.applyCalculatedNutritionToMeal(meal);
      }
      
      // Calculate nutrition for the meal day
      NutritionCalculationService.applyCalculatedNutritionToMealDay(mealDay);
      
      print('✅ Applied calculated nutrition to meal day ${mealDay.date}');
    } catch (e) {
      print('❌ Error applying calculated nutrition: $e');
      // Continue without failing the entire parsing process
    }
  }
} 