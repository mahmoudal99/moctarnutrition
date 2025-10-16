import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../../features/onboarding/presentation/steps/onboarding_meal_timing_step.dart';
import '../models/meal_model.dart';
import '../models/user_model.dart';
import 'config_service.dart';

/// Service for generating meal plans using the backend endpoint
class BackendMealService {
  static final _logger = Logger();
  static const String _backendBaseUrl = 'https://moctarnutrition-admin-dashboard.vercel.app';

  /// Generate a meal plan using the backend API
  static Future<MealPlanModel> generateMealPlan({
    required DietPlanPreferences preferences,
    required int days,
    required String userId,
    Function(int completedMeals, int totalMeals)? onProgress,
  }) async {
    try {
      _logger.i('Generating $days-day meal plan via backend API...');
      
      // Report initial progress
      onProgress?.call(0, days);

      // Map DietPlanPreferences to backend format
      final requestBody = _mapPreferencesToBackendFormat(preferences, days);

      final url = '$_backendBaseUrl/api/generate-meal-plan';
      _logger.d('Sending request to backend URL: $url');
      _logger.d('Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      _logger.d('Backend response status: ${response.statusCode}');
      _logger.d('Backend response body: ${response.body}');
      
      // Debug the raw response structure
      if (response.statusCode == 200) {
        final rawData = jsonDecode(response.body);
        if (rawData['mealPlan'] != null) {
          final mealPlan = rawData['mealPlan'];
          if (mealPlan['mealDays'] != null && mealPlan['mealDays'].isNotEmpty) {
            final firstDay = mealPlan['mealDays'][0];
            if (firstDay['meals'] != null && firstDay['meals'].isNotEmpty) {
              final firstMeal = firstDay['meals'][0];
            }
          }
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Backend meal plan generated successfully');
        
        // Report completion
        onProgress?.call(days, days);
        
        // Parse the response into MealPlanModel
        return _parseBackendResponse(data, preferences, days, userId);
      } else {
        _logger.e('Backend API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to generate meal plan: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logger.e('Error generating meal plan via backend: $e');
      throw Exception('Meal plan generation failed: $e');
    }
  }

  /// Map DietPlanPreferences to backend API format
  static Map<String, dynamic> _mapPreferencesToBackendFormat(
    DietPlanPreferences preferences,
    int days,
  ) {
    // Convert string meal frequency to enum
    final mealFrequencyEnum = _stringToMealFrequency(preferences.mealFrequency);
    
    // Determine meals per day based on meal frequency
    final mealsPerDay = _getMealsPerDay(mealFrequencyEnum);
    
    // Determine if snacks are included
    final includeSnacks = _shouldIncludeSnacks(mealFrequencyEnum);

    return {
      'preferences': {
        'duration': days,
        'mealsPerDay': mealsPerDay,
        'includeSnacks': includeSnacks,
        'considerAllergies': preferences.allergies?.isNotEmpty ?? false,
        'considerDietaryRestrictions': preferences.dietaryRestrictions.isNotEmpty,
        'useUserPreferences': true,
      },
      'userPreferences': {
        // Physical metrics
        'height': preferences.height,
        'weight': preferences.weight,
        'age': preferences.age,
        'gender': preferences.gender.toString().split('.').last,
        'activityLevel': preferences.activityLevel.toString().split('.').last,
        
        // Dietary preferences
        'allergies': preferences.allergies,
        'dietaryRestrictions': preferences.dietaryRestrictions,
        'favoriteFoods': preferences.favoriteFoods,
        'foodsToAvoid': preferences.foodsToAvoid,
        'preferredCuisines': preferences.preferredCuisines,
        
        // Nutrition targets
        'targetCalories': preferences.targetCalories,
        'calorieTargets': preferences.calorieTargets,
        'proteinTargets': preferences.proteinTargets,
        
        // Fitness goals
        'fitnessGoal': preferences.fitnessGoal.toString().split('.').last,
        'desiredWeight': preferences.weight, // Use current weight as desired weight fallback
        
        // Meal timing
        'mealTimingPreferences': {
          'mealFrequency': _mapMealFrequencyToString(mealFrequencyEnum),
          'mealTimingPreferences': preferences.mealTimingPreferences,
          'batchCookingPreferences': preferences.batchCookingPreferences,
        }
      }
    };
  }

  /// Get number of meals per day from meal frequency
  static int _getMealsPerDay(MealFrequency frequency) {
    switch (frequency) {
      case MealFrequency.threeMeals:
      case MealFrequency.threeMealsOneSnack:
        return 3;
      case MealFrequency.fourMeals:
      case MealFrequency.fourMealsOneSnack:
        return 4;
      case MealFrequency.fiveMeals:
      case MealFrequency.fiveMealsOneSnack:
        return 5;
      case MealFrequency.intermittentFasting:
        return 2; // Typically 2 meals for IF
      case MealFrequency.custom:
        return 3; // Default fallback
      default:
        return 3;
    }
  }

  /// Determine if snacks should be included based on meal frequency
  static bool _shouldIncludeSnacks(MealFrequency frequency) {
    switch (frequency) {
      case MealFrequency.threeMealsOneSnack:
      case MealFrequency.fourMealsOneSnack:
      case MealFrequency.fiveMealsOneSnack:
        return true;
      case MealFrequency.threeMeals:
      case MealFrequency.fourMeals:
      case MealFrequency.fiveMeals:
      case MealFrequency.intermittentFasting:
      case MealFrequency.custom:
      default:
        return false;
    }
  }

  /// Parse backend response into MealPlanModel
  static MealPlanModel _parseBackendResponse(
    Map<String, dynamic> data,
    DietPlanPreferences preferences,
    int days,
    String userId,
  ) {
    try {
      _logger.i('Parsing backend response into MealPlanModel');
      
      final mealPlanData = data['mealPlan'];
      if (mealPlanData == null) {
        throw Exception('Invalid response format: missing mealPlan data');
      }

      // Debug the API response structure

      final nutritionSummary = mealPlanData['nutritionSummary']?['dailyAverage'];
      
      final mealPlanJson = {
        'id': const Uuid().v4(),
        'userId': userId,
        'title': mealPlanData['title'] ?? 'AI-Generated $days-Day Meal Plan',
        'description': mealPlanData['description'] ?? 'Personalized meal plan generated via backend API',
        'startDate': mealPlanData['startDate'] ?? DateTime.now().toIso8601String(),
        'endDate': mealPlanData['endDate'] ?? DateTime.now().add(Duration(days: days - 1)).toIso8601String(),
        'mealDays': _parseMealDays(mealPlanData['mealDays'] ?? []),
        'totalCalories': nutritionSummary?['calories'] ?? preferences.targetCalories,
        'totalProtein': nutritionSummary?['protein'] ?? preferences.targetProtein,
        'totalCarbs': nutritionSummary?['carbs'] ?? 0,
        'totalFat': nutritionSummary?['fat'] ?? 0,
        'dietaryTags': mealPlanData['dietaryTags'] ?? preferences.dietaryRestrictions,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      return MealPlanModel.fromJson(mealPlanJson);
    } catch (e) {
      _logger.e('Error parsing backend response: $e');
      throw Exception('Failed to parse backend response: $e');
    }
  }

  /// Parse meal days from backend response
  static List<Map<String, dynamic>> _parseMealDays(List<dynamic> mealDaysData) {
    _logger.d('Parsing ${mealDaysData.length} meal days from backend response');
    
    return mealDaysData.map((dayData) {
      final dayMap = dayData as Map<String, dynamic>;
      final totalNutrition = dayMap['totalNutrition'] ?? {};
      
      return {
        'id': dayMap['id'] ?? const Uuid().v4(),
        'date': dayMap['date'] ?? DateTime.now().toIso8601String(),
        'totalCalories': totalNutrition['calories'] ?? 0,
        'totalProtein': totalNutrition['protein'] ?? 0,
        'totalCarbs': totalNutrition['carbs'] ?? 0,
        'totalFat': totalNutrition['fat'] ?? 0,
        'meals': _parseMeals(dayMap['meals'] ?? []),
      };
    }).toList();
  }

  /// Parse meals from backend response
  static List<Map<String, dynamic>> _parseMeals(List<dynamic> mealsData) {
    return mealsData.map((mealData) {
      final mealMap = mealData as Map<String, dynamic>;
      final totalNutrition = mealMap['totalNutrition'] ?? {};
      final ingredients = mealMap['ingredients'] ?? [];
      
      return {
        'id': mealMap['id'] ?? const Uuid().v4(),
        'name': mealMap['name'] ?? 'Unknown Meal',
        'description': mealMap['description'] ?? '',
        'type': _mapMealType(mealMap['type'] ?? 'breakfast'),
        'cuisineType': mealMap['cuisineType'] ?? '',
        'prepTime': mealMap['prepTime'] ?? 0,
        'cookTime': mealMap['cookTime'] ?? 0,
        'servings': mealMap['servings'] ?? 1,
        'ingredients': _parseIngredients(ingredients),
        'instructions': List<String>.from(mealMap['instructions'] ?? []),
        'prepNotes': List<String>.from(mealMap['prepNotes'] ?? []),
        'storageInstructions': mealMap['storageInstructions'] ?? '',
        'tags': List<String>.from(mealMap['tags'] ?? []),
        'nutrition': {
          'calories': totalNutrition['calories'] ?? 0,
          'protein': totalNutrition['protein'] ?? 0,
          'carbs': totalNutrition['carbs'] ?? 0,
          'fat': totalNutrition['fat'] ?? 0,
          'fiber': 0,
          'sugar': 0,
          'sodium': 0,
        },
        'isVegetarian': mealMap['isVegetarian'] ?? false,
        'isVegan': mealMap['isVegan'] ?? false,
        'isGlutenFree': mealMap['isGlutenFree'] ?? false,
        'isDairyFree': mealMap['isDairyFree'] ?? false,
        'imageUrl': null,
        'videoUrl': null,
        'dietaryTags': List<String>.from(mealMap['tags'] ?? []),
        'rating': 0.0,
        'ratingCount': 0,
        'isConsumed': false,
      };
    }).toList();
  }

  /// Parse ingredients from backend response
  static List<Map<String, dynamic>> _parseIngredients(List<dynamic> ingredientsData) {
    return ingredientsData.map((ingredientData) {
      final ingredientMap = ingredientData as Map<String, dynamic>;
      final nutrition = ingredientMap['nutrition'] ?? {};
      
      return {
        'name': ingredientMap['name'] ?? 'Unknown Ingredient',
        'amount': ingredientMap['amount'] ?? 0,
        'unit': ingredientMap['unit'] ?? 'g',
        'notes': ingredientMap['notes'] ?? '',
        'substitutes': List<String>.from(ingredientMap['substitutes'] ?? []),
        'calories': nutrition['calories'] ?? 0,
        'protein': nutrition['protein'] ?? 0,
        'carbs': nutrition['carbs'] ?? 0,
        'fat': nutrition['fat'] ?? 0,
        'fiber': nutrition['fiber'] ?? 0,
        'sugar': nutrition['sugar'] ?? 0,
        'sodium': nutrition['sodium'] ?? 0,
      };
    }).toList();
  }

  /// Map meal type string to MealType enum
  static String _mapMealType(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return 'breakfast';
      case 'lunch':
        return 'lunch';
      case 'dinner':
        return 'dinner';
      case 'snack':
        return 'snack';
      default:
        return 'breakfast';
    }
  }

  /// Convert string meal frequency to MealFrequency enum
  static MealFrequency _stringToMealFrequency(String mealFrequency) {
    // Handle different string formats that might come from the UI
    switch (mealFrequency.toLowerCase()) {
      case '3 meals':
      case 'threemeals':
      case 'three meals':
        return MealFrequency.threeMeals;
      case '3 meals + 1 snack':
      case '3 meals + one snack':
      case 'threemealsonesnack':
      case 'three meals one snack':
        return MealFrequency.threeMealsOneSnack;
      case '4 meals':
      case 'fourmeals':
      case 'four meals':
        return MealFrequency.fourMeals;
      case '4 meals + 1 snack':
      case '4 meals + one snack':
      case 'fourmealsonesnack':
      case 'four meals one snack':
        return MealFrequency.fourMealsOneSnack;
      case '5 meals':
      case 'fivemeals':
      case 'five meals':
        return MealFrequency.fiveMeals;
      case '5 meals + 1 snack':
      case '5 meals + one snack':
      case 'fivemealsonesnack':
      case 'five meals one snack':
        return MealFrequency.fiveMealsOneSnack;
      case 'intermittent fasting':
      case 'intermittentfasting':
      case '16:8 fasting':
      case 'if':
        return MealFrequency.intermittentFasting;
      case 'custom':
        return MealFrequency.custom;
      default:
        return MealFrequency.threeMeals; // Default fallback
    }
  }

  /// Map MealFrequency enum to string for backend API
  static String _mapMealFrequencyToString(MealFrequency frequency) {
    switch (frequency) {
      case MealFrequency.threeMeals:
        return 'threeMeals';
      case MealFrequency.threeMealsOneSnack:
        return 'threeMealsOneSnack';
      case MealFrequency.fourMeals:
        return 'fourMeals';
      case MealFrequency.fourMealsOneSnack:
        return 'fourMealsOneSnack';
      case MealFrequency.fiveMeals:
        return 'fiveMeals';
      case MealFrequency.fiveMealsOneSnack:
        return 'fiveMealsOneSnack';
      case MealFrequency.intermittentFasting:
        return 'intermittentFasting';
      case MealFrequency.custom:
        return 'custom';
      default:
        return 'threeMeals';
    }
  }
}
