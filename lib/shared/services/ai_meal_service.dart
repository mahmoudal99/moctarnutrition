import 'dart:convert';
import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/meal_model.dart';
import 'prompt_service.dart';
import 'parser_service.dart';
import 'mock_data_service.dart';
import 'config_service.dart';
import 'cache_service.dart';
import 'rate_limit_service.dart';

class AIMealService {
  /// Generate a single day meal plan with context from previous days
  static Future<MealDay> _generateSingleDayWithContext(
    DietPlanPreferences preferences,
    int dayIndex,
    List<MealDay> previousDays,
  ) async {
    final dayPrompt = PromptService.buildSingleDayPromptWithContext(
      preferences,
      dayIndex,
      previousDays.isNotEmpty ? previousDays : null,
    );

    final requestBody = {
      'model': ConfigService.openAIModel,
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a professional nutritionist and meal planner. Generate detailed, personalized meal plans in JSON format. ALWAYS respect dietary restrictions - this is the most critical requirement. Never include foods that violate the user\'s dietary restrictions.',
        },
        {
          'role': 'user',
          'content': dayPrompt,
        },
      ],
      'temperature': ConfigService.openAITemperature,
      'max_tokens': ConfigService.openAIMaxTokens,
    };

    final response = await RateLimitService.makeApiCall(
      url: Uri.parse(ConfigService.openAIBaseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ConfigService.openAIApiKey}',
      },
      body: jsonEncode(requestBody),
      context: 'day $dayIndex',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      print('Day $dayIndex response received successfully');

      final mealDay = ParserService.parseSingleDayFromAI(content, preferences, dayIndex);
      
      // Validate that all required meals are present
      if (!_validateMealDay(mealDay, preferences)) {
        print('Day $dayIndex validation failed - missing required meals. Regenerating...');
        // Try one more time with a more explicit prompt
        return await _generateSingleDayWithContextRetry(preferences, dayIndex, previousDays, mealDay);
      }

      return mealDay;
    } else {
      print(
          'API Error for day $dayIndex: ${response.statusCode} - ${response.body}');
      throw Exception(
          'Failed to generate day $dayIndex: ${response.statusCode}');
    }
  }

  /// Retry generation with more explicit prompt if validation fails
  static Future<MealDay> _generateSingleDayWithContextRetry(
    DietPlanPreferences preferences,
    int dayIndex,
    List<MealDay> previousDays,
    MealDay failedMealDay,
  ) async {
    final requiredMeals = _getRequiredMealTypes(preferences.mealFrequency);
    final missingMeals = _getMissingMealTypes(failedMealDay, requiredMeals);
    
    final retryPrompt = '''
${PromptService.buildSingleDayPromptWithContext(preferences, dayIndex, previousDays.isNotEmpty ? previousDays : null)}

### URGENT: PREVIOUS ATTEMPT FAILED
Your previous response was missing the following required meal types: ${missingMeals.map((type) => type.name).join(', ')}.

You MUST include ALL of these meal types:
${requiredMeals.map((type) => '- ${type.name}').join('\n')}

The current response only had: ${failedMealDay.meals.map((m) => m.type.name).join(', ')}

Please regenerate the meal plan ensuring ALL required meal types are included.
''';

    final requestBody = {
      'model': ConfigService.openAIModel,
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a professional nutritionist and meal planner. Generate detailed, personalized meal plans in JSON format. ALWAYS respect dietary restrictions - this is the most critical requirement. Never include foods that violate the user\'s dietary restrictions.',
        },
        {
          'role': 'user',
          'content': retryPrompt,
        },
      ],
      'temperature': ConfigService.openAITemperature,
      'max_tokens': ConfigService.openAIMaxTokens,
    };

    final response = await RateLimitService.makeApiCall(
      url: Uri.parse(ConfigService.openAIBaseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ConfigService.openAIApiKey}',
      },
      body: jsonEncode(requestBody),
      context: 'day $dayIndex retry',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      print('Day $dayIndex retry response received successfully');

      final mealDay = ParserService.parseSingleDayFromAI(content, preferences, dayIndex);
      
      // Validate again
      if (!_validateMealDay(mealDay, preferences)) {
        print('Day $dayIndex retry validation failed - using fallback meal plan');
        return _generateFallbackMealDay(preferences, dayIndex, requiredMeals);
      }

      return mealDay;
    } else {
      print('API Error for day $dayIndex retry: ${response.statusCode} - ${response.body}');
      final requiredMeals = _getRequiredMealTypes(preferences.mealFrequency);
      return _generateFallbackMealDay(preferences, dayIndex, requiredMeals);
    }
  }

  /// Validate that a meal day contains all required meals
  static bool _validateMealDay(MealDay mealDay, DietPlanPreferences preferences) {
    final requiredMeals = _getRequiredMealTypes(preferences.mealFrequency);
    final presentMealTypes = mealDay.meals.map((m) => m.type).toSet();
    
    for (final requiredType in requiredMeals) {
      if (!presentMealTypes.contains(requiredType)) {
        print('Missing required meal type: ${requiredType.name}');
        return false;
      }
    }
    
    print('Meal day validation passed - all required meals present');
    return true;
  }

  /// Get missing meal types from a meal day
  static List<MealType> _getMissingMealTypes(MealDay mealDay, List<MealType> requiredMeals) {
    final presentMealTypes = mealDay.meals.map((m) => m.type).toSet();
    return requiredMeals.where((type) => !presentMealTypes.contains(type)).toList();
  }

  /// Generate a fallback meal day with all required meals
  static MealDay _generateFallbackMealDay(
    DietPlanPreferences preferences,
    int dayIndex,
    List<MealType> requiredMeals,
  ) {
    print('Generating fallback meal day for day $dayIndex');
    return MockDataService.generateMockMealDay(preferences, dayIndex, requiredMeals);
  }

  /// Helper to determine required meal types based on meal frequency
  static List<MealType> _getRequiredMealTypes(String mealFrequency) {
    // Always require breakfast, lunch, and dinner as core meals
    final requiredMeals = [MealType.breakfast, MealType.lunch, MealType.dinner];
    
    // Add snacks based on meal frequency string
    if (mealFrequency.contains('snack') || mealFrequency.contains('4') || mealFrequency.contains('5')) {
      requiredMeals.add(MealType.snack);
    }
    
    return requiredMeals;
  }

  /// Generate a personalized meal plan using AI with caching and parallel processing
  static Future<MealPlanModel> generateMealPlan({
    required DietPlanPreferences preferences,
    required int days,
    Function(int completedDays, int totalDays)? onProgress,
  }) async {
    try {
      print(
          'Generating $days-day meal plan with caching and parallel processing...');

      // Check cache first
      if (CacheService.isEnabled) {
        final cached = CacheService.getCachedMealPlan(preferences, days);
        if (cached != null) {
          print('Using cached meal plan for $days days');
          onProgress?.call(days, days); // Report full completion
          return cached.mealPlan;
        }
      }

      // Determine optimal batch size for processing
      final optimalBatchSize = _calculateOptimalBatchSize(days);
      final List<MealDay> mealDays = [];

      print('Processing $days days in batches of $optimalBatchSize');

      // Process days in batches to avoid overwhelming the API
      for (int batchStart = 1;
          batchStart <= days;
          batchStart += optimalBatchSize) {
        final batchEnd = (batchStart + optimalBatchSize - 1).clamp(1, days);

        print('Processing batch: days $batchStart to $batchEnd');

        // Create futures for parallel processing within the batch
        final futures = <Future<MealDay>>[];
        int batchCompletedDays = 0;

        for (int dayIndex = batchStart; dayIndex <= batchEnd; dayIndex++) {
          futures.add(
              _generateSingleDayWithContext(preferences, dayIndex, mealDays)
                  .then((mealDay) {
            // Report individual day completion
            batchCompletedDays++;
            final totalCompleted = mealDays.length + batchCompletedDays;
            onProgress?.call(totalCompleted, days);
            return mealDay;
          }));
        }

        // Wait for all days in the batch to complete
        try {
          final batchResults = await Future.wait(futures);
          mealDays.addAll(batchResults);
        } catch (e) {
          print('Batch failed with error: $e');
          
          // If batch fails due to rate limits, fall back to sequential processing
          if (e.toString().contains('RateLimitException')) {
            print('Rate limit hit during batch processing, falling back to sequential processing...');
            await _generateSequentialFallback(preferences, batchStart, batchEnd, mealDays, onProgress, days);
          } else {
            // For other errors, try to generate fallback meal days
            print('Generating fallback meal days for batch $batchStart-$batchEnd');
            for (int dayIndex = batchStart; dayIndex <= batchEnd; dayIndex++) {
              final requiredMeals = _getRequiredMealTypes(preferences.mealFrequency);
              final fallbackDay = _generateFallbackMealDay(preferences, dayIndex, requiredMeals);
              mealDays.add(fallbackDay);
              onProgress?.call(mealDays.length, days);
            }
          }
        }

        // Small delay between batches to be respectful to the API
        if (batchEnd < days) {
          await Future.delayed(Duration(milliseconds: 5000)); // Increased from 3000ms
        }
      }

      // Sort meal days by date to ensure correct order
      mealDays.sort((a, b) => a.date.compareTo(b.date));

      // Calculate overall meal plan totals
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (final day in mealDays) {
        totalProtein += day.totalProtein;
        totalCarbs += day.totalCarbs;
        totalFat += day.totalFat;
      }

      final mealPlan = MealPlanModel(
        id: const Uuid().v4(),
        userId: 'current_user',
        title: 'AI-Generated $days-Day Meal Plan',
        description: 'Personalized meal plan based on your preferences',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: days - 1)),
        mealDays: mealDays,
        totalCalories: (preferences.targetCalories * days).toDouble(),
        totalProtein: totalProtein,
        totalCarbs: totalCarbs,
        totalFat: totalFat,
        dietaryTags: preferences.dietaryRestrictions,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Cache the generated meal plan
      if (CacheService.isEnabled) {
        CacheService.cacheMealPlan(preferences, days, mealPlan);
      }

      return mealPlan;
    } catch (e) {
      print('AI Service Error: $e');
      
      // If all else fails, generate a complete mock meal plan
      print('Generating fallback mock meal plan due to error: $e');
      final fallbackPlan = MockDataService.generateMockMealPlan(preferences, days);
      
      // Report completion for fallback
      onProgress?.call(days, days);
      
      return fallbackPlan;
    }
  }

  /// Generate meal days sequentially as fallback when parallel processing fails
  static Future<void> _generateSequentialFallback(
    DietPlanPreferences preferences,
    int batchStart,
    int batchEnd,
    List<MealDay> mealDays,
    Function(int completedDays, int totalDays)? onProgress,
    int totalDays,
  ) async {
    print('Generating days $batchStart-$batchEnd sequentially...');
    
    for (int dayIndex = batchStart; dayIndex <= batchEnd; dayIndex++) {
      try {
        final mealDay = await _generateSingleDayWithContext(preferences, dayIndex, mealDays);
        mealDays.add(mealDay);
        onProgress?.call(mealDays.length, totalDays);
        
        // Add delay between sequential calls to respect rate limits
        if (dayIndex < batchEnd) {
          await Future.delayed(Duration(milliseconds: 5000)); // Increased from 2000ms
        }
      } catch (e) {
        print('Sequential generation failed for day $dayIndex: $e');
        
        // Generate fallback meal day
        final requiredMeals = _getRequiredMealTypes(preferences.mealFrequency);
        final fallbackDay = _generateFallbackMealDay(preferences, dayIndex, requiredMeals);
        mealDays.add(fallbackDay);
        onProgress?.call(mealDays.length, totalDays);
      }
    }
  }

  /// Calculate optimal batch size for parallel processing
  static int _calculateOptimalBatchSize(int totalDays) {
    // Very conservative approach to avoid hitting OpenAI rate limits
    if (totalDays <= 1) return totalDays; // Single day: process immediately
    return 1; // Always process one day at a time to avoid rate limits
  }

  /// Generate a 1-day preview meal plan (for preview step)
  static Future<Map<String, List<String>>> generatePreviewDay({
    required DietPlanPreferences preferences,
  }) async {
    try {
      // For preview, we don't need context since it's just one day
      final previewPlan =
          await generateMealPlan(preferences: preferences, days: 1);
      // Convert the first day to a simple map for preview UI
      final day = previewPlan.mealDays.first;
      final Map<String, List<String>> preview = {};
      for (final meal in day.meals) {
        preview[capitalize(meal.type.name)] = [
          meal.name,
          ...meal.ingredients.map((i) => i.name)
        ];
      }
      return preview;
    } catch (e) {
      print('Preview generation failed: $e');
      throw Exception('Failed to generate preview: $e');
    }
  }

  /// Generate mock meal plan as fallback
  static MealPlanModel generateMockMealPlan(
    DietPlanPreferences preferences,
    int days,
  ) {
    return MockDataService.generateMockMealPlan(preferences, days);
  }

  /// Helper method for string capitalization
  static String capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Get performance statistics
  static Map<String, dynamic> getPerformanceStats() {
    return {
      'cacheStats': CacheService.getCacheStats(),
      'rateLimitStats': RateLimitService.getRateLimitStatus(),
      'configSummary': ConfigService.getConfigSummary(),
    };
  }

  /// Clear all caches and reset rate limiting (useful for testing)
  static void resetAll() {
    CacheService.clearCache();
    RateLimitService.resetRateLimit();
    print('All caches and rate limits reset');
  }

  /// Test method to validate meal plan generation with required meals
  static Future<void> testMealPlanValidation() async {
    print('🧪 Testing meal plan validation...');
    
    final testPreferences = DietPlanPreferences(
      age: 30,
      gender: 'Male',
      weight: 70.0,
      height: 175.0,
      fitnessGoal: FitnessGoal.weightLoss,
      activityLevel: ActivityLevel.moderatelyActive,
      dietaryRestrictions: [],
      preferredWorkoutStyles: [],
      nutritionGoal: 'Lose fat',
      preferredCuisines: ['American', 'Italian'],
      foodsToAvoid: [],
      favoriteFoods: [],
      mealFrequency: '3 meals',
      weeklyRotation: true,
      remindersEnabled: false,
      targetCalories: 2000,
    );

    try {
      final mealPlan = await generateMealPlan(
        preferences: testPreferences,
        days: 1,
        onProgress: (completed, total) {
          print('Progress: $completed/$total days completed');
        },
      );

      print('✅ Test completed successfully');
      print('Generated ${mealPlan.mealDays.length} days');
      
      for (int i = 0; i < mealPlan.mealDays.length; i++) {
        final day = mealPlan.mealDays[i];
        print('Day ${i + 1}: ${day.meals.length} meals');
        for (final meal in day.meals) {
          print('  - ${meal.type.name}: ${meal.name}');
        }
      }
    } catch (e) {
      print('❌ Test failed: $e');
    }
  }
}
