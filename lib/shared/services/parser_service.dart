import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/meal_model.dart';
import 'json_utils.dart';

/// Service for parsing AI responses into meal plan models
class ParserService {
  /// Parse single day AI response into MealDay
  static MealDay parseSingleDayFromAI(
    String aiResponse,
    DietPlanPreferences preferences,
    int dayIndex,
  ) {
    try {
      print('Parsing single day AI response for day $dayIndex...');
      print('AI Response length: ${aiResponse.length}');
      print('AI Response preview: ${aiResponse.substring(0, aiResponse.length > 200 ? 200 : aiResponse.length)}...');

      // Clean and fix the JSON
      final cleanedJson = JsonUtils.cleanAndFixJson(aiResponse);
      final data = JsonUtils.parseJson(cleanedJson, context: 'day $dayIndex');
      final mealDayData = data['mealDay'];

      // Generate unique IDs for the meal day and meals
      mealDayData['id'] = const Uuid().v4();

      // Calculate nutrition totals from meals if they're missing or 0
      if (mealDayData['meals'] != null) {
        final meals = (mealDayData['meals'] as List).map((mealData) {
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
        mealDayData['meals'] = meals;

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
        if (JsonUtils.safeToDouble(mealDayData['totalProtein']) == 0 || mealDayData['totalProtein'] == null) {
          mealDayData['totalProtein'] = dayProtein;
        }
        if (JsonUtils.safeToDouble(mealDayData['totalCarbs']) == 0 || mealDayData['totalCarbs'] == null) {
          mealDayData['totalCarbs'] = dayCarbs;
        }
        if (JsonUtils.safeToDouble(mealDayData['totalFat']) == 0 || mealDayData['totalFat'] == null) {
          mealDayData['totalFat'] = dayFat;
        }
      }

      return MealDay.fromJson(mealDayData);
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
        totalCalories: JsonUtils.safeToInt(mealPlanData['totalCalories']),
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
} 