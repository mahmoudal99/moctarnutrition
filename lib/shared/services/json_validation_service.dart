import 'dart:convert';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import '../models/meal_model.dart';

/// Service for validating JSON responses from AI models
class JSONValidationService {
  static final _logger = Logger();

  /// Validate single day JSON response
  static Map<String, dynamic> validateSingleDayResponse(
    String aiResponse,
    DietPlanPreferences preferences,
    int dayIndex,
  ) {
    try {
      _logger.i('Validating single day response for day $dayIndex');
      
      // Clean and parse JSON
      final cleanedJson = _cleanJsonResponse(aiResponse);
      final data = jsonDecode(cleanedJson);
      
      // Basic structure validation
      if (!data.containsKey('mealDay')) {
        return _createValidationError('Missing mealDay object', aiResponse);
      }
      
      final mealDay = data['mealDay'];
      
      // Required fields validation
      final requiredFields = ['id', 'date', 'meals'];
      for (final field in requiredFields) {
        if (!mealDay.containsKey(field)) {
          return _createValidationError('Missing required field: $field', aiResponse);
        }
      }
      
      // Date validation
      try {
        DateTime.parse(mealDay['date']);
      } catch (e) {
        return _createValidationError('Invalid date format: ${mealDay['date']}', aiResponse);
      }
      
      // Meals validation
      if (mealDay['meals'] is! List) {
        return _createValidationError('meals must be an array', aiResponse);
      }
      
      final meals = mealDay['meals'] as List;
      final requiredMeals = _getRequiredMealTypes(preferences.mealFrequency);
      
      if (meals.length != requiredMeals.length) {
        return _createValidationError(
          'Expected ${requiredMeals.length} meals, got ${meals.length}',
          aiResponse,
        );
      }
      
      // Validate each meal
      final mealTypes = <String>[];
      for (int i = 0; i < meals.length; i++) {
        final meal = meals[i];
        final mealValidation = _validateMeal(meal, i);
        if (!mealValidation['isValid']) {
          return mealValidation;
        }
        mealTypes.add(meal['type']);
      }
      
      // Check required meal types
      final requiredMealTypeNames = requiredMeals.map((t) => t.name).toSet();
      final providedMealTypeNames = mealTypes.toSet();
      
      if (!requiredMealTypeNames.containsAll(providedMealTypeNames)) {
        final missing = requiredMealTypeNames.difference(providedMealTypeNames);
        final extra = providedMealTypeNames.difference(requiredMealTypeNames);
        return _createValidationError(
          'Missing meal types: ${missing.join(', ')}. Extra meal types: ${extra.join(', ')}',
          aiResponse,
        );
      }
      
      _logger.i('✅ Single day validation passed for day $dayIndex');
      return {
        'isValid': true,
        'data': data,
        'message': 'Validation successful',
      };
      
    } catch (e) {
      _logger.e('JSON validation error for day $dayIndex: $e');
      return _createValidationError('JSON parsing failed: $e', aiResponse);
    }
  }

  /// Validate multi-day meal plan JSON response
  static Map<String, dynamic> validateMealPlanResponse(
    String aiResponse,
    DietPlanPreferences preferences,
    int days,
  ) {
    try {
      _logger.i('Validating meal plan response for $days days');
      
      // Clean and parse JSON
      final cleanedJson = _cleanJsonResponse(aiResponse);
      final data = jsonDecode(cleanedJson);
      
      // Basic structure validation
      if (!data.containsKey('mealPlan')) {
        return _createValidationError('Missing mealPlan object', aiResponse);
      }
      
      final mealPlan = data['mealPlan'];
      
      // Required fields validation
      final requiredFields = ['title', 'description', 'startDate', 'endDate', 'dietaryTags', 'mealDays'];
      for (final field in requiredFields) {
        if (!mealPlan.containsKey(field)) {
          return _createValidationError('Missing required field: $field', aiResponse);
        }
      }
      
      // Date validation
      try {
        DateTime.parse(mealPlan['startDate']);
        DateTime.parse(mealPlan['endDate']);
      } catch (e) {
        return _createValidationError('Invalid date format', aiResponse);
      }
      
      // Meal days validation
      if (mealPlan['mealDays'] is! List) {
        return _createValidationError('mealDays must be an array', aiResponse);
      }
      
      final mealDays = mealPlan['mealDays'] as List;
      if (mealDays.length != days) {
        return _createValidationError(
          'Expected $days meal days, got ${mealDays.length}',
          aiResponse,
        );
      }
      
      // Validate each meal day
      for (int i = 0; i < mealDays.length; i++) {
        final mealDay = mealDays[i];
        final dayValidation = validateSingleDayResponse(
          jsonEncode({'mealDay': mealDay}),
          preferences,
          i + 1,
        );
        if (!dayValidation['isValid']) {
          return _createValidationError(
            'Day ${i + 1} validation failed: ${dayValidation['message']}',
            aiResponse,
          );
        }
      }
      
      _logger.i('✅ Meal plan validation passed for $days days');
      return {
        'isValid': true,
        'data': data,
        'message': 'Validation successful',
      };
      
    } catch (e) {
      _logger.e('JSON validation error for meal plan: $e');
      return _createValidationError('JSON parsing failed: $e', aiResponse);
    }
  }

  /// Validate individual meal
  static Map<String, dynamic> _validateMeal(Map<String, dynamic> meal, int mealIndex) {
    final requiredFields = [
      'id', 'name', 'description', 'type', 'cuisineType', 
      'prepTime', 'cookTime', 'servings', 'ingredients', 
      'instructions', 'tags', 'isVegetarian', 'isVegan', 
      'isGlutenFree', 'isDairyFree'
    ];
    
    for (final field in requiredFields) {
      if (!meal.containsKey(field)) {
        return _createValidationError(
          'Meal $mealIndex missing required field: $field',
          jsonEncode(meal),
        );
      }
    }
    
    // Type validation
    final validTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
    if (!validTypes.contains(meal['type'])) {
      return _createValidationError(
        'Meal $mealIndex has invalid type: ${meal['type']}',
        jsonEncode(meal),
      );
    }
    
    // Ingredients validation
    if (meal['ingredients'] is! List) {
      return _createValidationError(
        'Meal $mealIndex ingredients must be an array',
        jsonEncode(meal),
      );
    }
    
    final ingredients = meal['ingredients'] as List;
    if (ingredients.isEmpty) {
      return _createValidationError(
        'Meal $mealIndex must have at least one ingredient',
        jsonEncode(meal),
      );
    }
    
    // Validate each ingredient
    for (int i = 0; i < ingredients.length; i++) {
      final ingredient = ingredients[i];
      final ingredientValidation = _validateIngredient(ingredient, i);
      if (!ingredientValidation['isValid']) {
        return _createValidationError(
          'Meal $mealIndex ingredient $i validation failed: ${ingredientValidation['message']}',
          jsonEncode(meal),
        );
      }
    }
    
    return {
      'isValid': true,
      'message': 'Meal validation successful',
    };
  }

  /// Validate individual ingredient
  static Map<String, dynamic> _validateIngredient(Map<String, dynamic> ingredient, int ingredientIndex) {
    final requiredFields = ['name', 'amount', 'unit', 'nutrition'];
    
    for (final field in requiredFields) {
      if (!ingredient.containsKey(field)) {
        return _createValidationError(
          'Ingredient $ingredientIndex missing required field: $field',
          jsonEncode(ingredient),
        );
      }
    }
    
    // Amount validation
    if (ingredient['amount'] is! num || ingredient['amount'] <= 0) {
      return _createValidationError(
        'Ingredient $ingredientIndex amount must be a positive number',
        jsonEncode(ingredient),
      );
    }
    
    // Nutrition validation
    if (ingredient['nutrition'] is! Map) {
      return _createValidationError(
        'Ingredient $ingredientIndex nutrition must be an object',
        jsonEncode(ingredient),
      );
    }
    
    final nutrition = ingredient['nutrition'] as Map<String, dynamic>;
    
    // Only require essential nutrition fields
    final requiredNutrition = ['calories', 'protein', 'carbs', 'fat'];
    
    for (final nutrient in requiredNutrition) {
      if (!nutrition.containsKey(nutrient)) {
        return _createValidationError(
          'Ingredient $ingredientIndex nutrition missing essential field: $nutrient',
          jsonEncode(ingredient),
        );
      }
      if (nutrition[nutrient] is! num) {
        return _createValidationError(
          'Ingredient $ingredientIndex nutrition $nutrient must be a number',
          jsonEncode(ingredient),
        );
      }
    }
    
    // Add default values for optional nutrition fields if missing
    final optionalNutrition = ['fiber', 'sugar', 'sodium'];
    for (final nutrient in optionalNutrition) {
      if (!nutrition.containsKey(nutrient)) {
        nutrition[nutrient] = 0.0; // Default to 0 for missing optional fields
      } else if (nutrition[nutrient] is! num) {
        nutrition[nutrient] = 0.0; // Default to 0 for invalid values
      }
    }
    
    return {
      'isValid': true,
      'message': 'Ingredient validation successful',
    };
  }

  /// Clean JSON response by removing markdown and extracting JSON
  static String _cleanJsonResponse(String response) {
    // Remove markdown code blocks
    String cleaned = response.replaceAll(RegExp(r'```json\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'```\s*'), '');
    
    // Remove any leading/trailing whitespace
    cleaned = cleaned.trim();
    
    // Find JSON object boundaries
    final jsonStart = cleaned.indexOf('{');
    final jsonEnd = cleaned.lastIndexOf('}');
    
    if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
      throw Exception('No valid JSON object found in response');
    }
    
    return cleaned.substring(jsonStart, jsonEnd + 1);
  }

  /// Create validation error response
  static Map<String, dynamic> _createValidationError(String message, String originalResponse) {
    return {
      'isValid': false,
      'message': message,
      'originalResponse': originalResponse,
      'data': null,
    };
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

  /// Get validation summary for debugging
  static Map<String, dynamic> getValidationSummary(Map<String, dynamic> validationResult) {
    if (validationResult['isValid'] == true) {
      return {
        'status': '✅ Valid',
        'message': validationResult['message'],
        'dataSize': validationResult['data']?.toString().length ?? 0,
      };
    } else {
      return {
        'status': '❌ Invalid',
        'message': validationResult['message'],
        'originalResponseLength': validationResult['originalResponse']?.toString().length ?? 0,
      };
    }
  }
} 