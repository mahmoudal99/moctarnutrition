import 'dart:convert';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import '../models/meal_model.dart';
import 'prompt_service.dart';
import 'parser_service.dart';
import 'json_validation_service.dart';

import 'config_service.dart';
import 'cache_service.dart';
import 'rate_limit_service.dart';

// Import ValidationException from parser service
import 'parser_service.dart' show ValidationException;

class AIMealService {
  static final _logger = Logger();

  /// Generate a single day meal plan with context from previous days
  static Future<MealDay> _generateSingleDayWithContext(
    DietPlanPreferences preferences,
    int dayIndex,
    List<MealDay> previousDays,
    Function(int completedMeals)? onDayProgress,
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
      _logger.i('Day $dayIndex response received successfully');

      try {
        // Parse the AI response (validation happens inside the parser)
        final mealDay = await ParserService.parseSingleDayFromAI(
          content,
          preferences,
          dayIndex,
        );

        // Update progress for all meals in this day
        onDayProgress?.call(mealDay.meals.length);

        return mealDay;
      } catch (e) {
        if (e is ValidationException) {
          _logger.w(
              'Day $dayIndex validation failed: ${e.message}. Regenerating...');
          return await _generateSingleDayWithContextRetry(
            preferences,
            dayIndex,
            previousDays,
            null,
            onDayProgress,
          );
        }
        rethrow;
      }
    } else {
      _logger.e(
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
    MealDay? failedMealDay,
    Function(int completedMeals)? onDayProgress,
  ) async {
    final requiredMeals = _getRequiredMealTypes(preferences.mealFrequency);

    final retryPrompt = '''
${PromptService.buildSingleDayPromptWithContext(preferences, dayIndex, previousDays.isNotEmpty ? previousDays : null)}

### URGENT: PREVIOUS ATTEMPT FAILED
Your previous response had validation errors. Please ensure:

1. You include exactly ${requiredMeals.length} meals: ${requiredMeals.map((type) => type.name).join(', ')}
2. All required fields are present in the JSON structure
3. All ingredient nutrition data is provided
4. No meal or day totals are calculated

Please regenerate the meal plan following the JSON schema exactly.
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
      _logger.i('Day $dayIndex retry response received successfully');

      try {
        // Parse the AI response (validation happens inside the parser)
        final mealDay = await ParserService.parseSingleDayFromAI(
          content,
          preferences,
          dayIndex,
        );

        // Update progress for all meals in this day
        onDayProgress?.call(mealDay.meals.length);

        return mealDay;
      } catch (e) {
        if (e is ValidationException) {
          _logger.e('Day $dayIndex retry validation failed: ${e.message}');
          throw Exception(
              'AI validation failed for day $dayIndex: ${e.message}');
        }
        rethrow;
      }
    } else {
      _logger.e(
          'API Error for day $dayIndex retry: ${response.statusCode} - ${response.body}');
      throw Exception(
          'API retry failed for day $dayIndex: ${response.statusCode}');
    }
  }

  /// Helper to determine required meal types based on meal frequency
  static List<MealType> _getRequiredMealTypes(String mealFrequency) {
    // Always require breakfast, lunch, and dinner as core meals
    final requiredMeals = [MealType.breakfast, MealType.lunch, MealType.dinner];

    // Add snacks based on meal frequency string (case-insensitive)
    if (mealFrequency.toLowerCase().contains('snack') ||
        mealFrequency.contains('4') ||
        mealFrequency.contains('5')) {
      requiredMeals.add(MealType.snack);
    }

    return requiredMeals;
  }

  /// Helper to get expected calorie distribution for meal types
  static Map<MealType, double> _getCalorieDistribution(
      String mealFrequency, int targetCalories) {
    final distribution = <MealType, double>{};
    final hasSnacks = mealFrequency.toLowerCase().contains('snack') ||
        mealFrequency.contains('4') ||
        mealFrequency.contains('5');

    if (hasSnacks) {
      // With snacks: Breakfast 25%, Lunch 30%, Dinner 35%, Snacks 10%
      distribution[MealType.breakfast] = targetCalories * 0.25;
      distribution[MealType.lunch] = targetCalories * 0.30;
      distribution[MealType.dinner] = targetCalories * 0.35;
      distribution[MealType.snack] = targetCalories * 0.10;
    } else {
      // Without snacks: Breakfast 30%, Lunch 35%, Dinner 35%
      distribution[MealType.breakfast] = targetCalories * 0.30;
      distribution[MealType.lunch] = targetCalories * 0.35;
      distribution[MealType.dinner] = targetCalories * 0.35;
    }

    return distribution;
  }

  /// Check if there are enough free tokens remaining for meal plan generation
  static bool _hasEnoughFreeTokens(int days) {
    // Estimate tokens needed: ~1,400 tokens per day based on your usage data
    final estimatedTokensNeeded = days * 1400;

    // Get remaining free tokens (2.5M for GPT-4o-mini)
    const remainingFreeTokens = 2500000; // TODO: Get actual remaining tokens

    final hasEnough = remainingFreeTokens >= estimatedTokensNeeded;

    _logger.d(
        'Token check: Need ~$estimatedTokensNeeded tokens, have ~$remainingFreeTokens remaining');
    _logger.d('Has enough free tokens: $hasEnough');

    return hasEnough;
  }

  /// Generate a personalized meal plan using AI with caching and parallel processing
  static Future<MealPlanModel> generateMealPlan({
    required DietPlanPreferences preferences,
    required int days,
    Function(int completedMeals, int totalMeals)? onProgress,
  }) async {
    try {
      _logger.i(
          'Generating $days-day meal plan with caching and parallel processing...');

      // Check cache first
      if (CacheService.isEnabled) {
        final cached = CacheService.getCachedMealPlan(preferences, days);
        if (cached != null) {
          _logger.i('Using cached meal plan for $days days');
          // Calculate total meals for cached plan
          final totalMeals = cached.mealPlan.mealDays
              .fold<int>(0, (sum, day) => sum + day.meals.length);
          onProgress?.call(totalMeals, totalMeals); // Report full completion
          return cached.mealPlan;
        }
      }

      // Check if we have enough free tokens remaining
      if (!_hasEnoughFreeTokens(days)) {
        throw Exception(
            'Insufficient free tokens remaining for $days-day meal plan');
      }

      // Calculate total meals expected
      final requiredMeals = _getRequiredMealTypes(preferences.mealFrequency);
      final totalMeals = days * requiredMeals.length;
      int completedMeals = 0;

      // Determine optimal batch size for processing
      final optimalBatchSize = _calculateOptimalBatchSize(days);
      final List<MealDay> mealDays = [];

      _logger.i(
          'Processing $days days in batches of $optimalBatchSize (total meals: $totalMeals)');

      // Process days in batches to avoid overwhelming the API
      for (int batchStart = 1;
          batchStart <= days;
          batchStart += optimalBatchSize) {
        final batchEnd = (batchStart + optimalBatchSize - 1).clamp(1, days);

        _logger.d('Processing batch: days $batchStart to $batchEnd');

        // Create futures for parallel processing within the batch
        final futures = <Future<MealDay>>[];

        for (int dayIndex = batchStart; dayIndex <= batchEnd; dayIndex++) {
          futures.add(_generateSingleDayWithContext(
            preferences,
            dayIndex,
            mealDays,
            (dayCompletedMeals) {
              // Update progress as meals are completed within each day
              completedMeals += dayCompletedMeals;
              onProgress?.call(completedMeals, totalMeals);
            },
          ));
        }

        // Wait for all days in the batch to complete
        try {
          final batchResults = await Future.wait(futures);
          mealDays.addAll(batchResults);

          // Update progress after batch completion
          _logger.i('Batch completed: ${mealDays.length}/$days days total');
        } catch (e) {
          _logger.e('Batch failed with error: $e');

          // If batch fails due to rate limits or validation errors, fall back to sequential processing
          if (e.toString().contains('RateLimitException') ||
              e.toString().contains('ValidationException') ||
              e.toString().contains('JSON validation failed')) {
            _logger.w(
                'Batch processing failed, falling back to sequential processing...');
            await _generateSequentialFallback(preferences, batchStart, batchEnd,
                mealDays, onProgress, totalMeals, completedMeals);
          } else {
            // For other errors, throw exception for testing
            _logger.e(
                'Batch processing failed for batch $batchStart-$batchEnd - throwing exception for testing');
            throw Exception('Batch processing failed: $e');
          }
        }

        // Small delay between batches to be respectful to the API
        if (batchEnd < days) {
          await Future.delayed(
              const Duration(milliseconds: 1000)); // Reduced for faster processing
        }
      }

      // Sort meal days by date to ensure correct order
      mealDays.sort((a, b) => a.date.compareTo(b.date));

      // Calculate overall meal plan totals
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;
      double totalCalories = 0;

      for (final day in mealDays) {
        totalProtein += day.totalProtein;
        totalCarbs += day.totalCarbs;
        totalFat += day.totalFat;
        totalCalories += day.totalCalories;
      }

      // Validate that the generated calories match the target
      final targetTotalCalories = preferences.targetCalories * days;
      final calorieDiff = (totalCalories - targetTotalCalories).abs();
      final caloriePercentDiff = (calorieDiff / targetTotalCalories) * 100;

      if (caloriePercentDiff > 5) {
        _logger.w(
            '⚠️ WARNING: Generated meal plan calories (${totalCalories.toStringAsFixed(0)}) differ by ${caloriePercentDiff.toStringAsFixed(1)}% from target (${targetTotalCalories.toStringAsFixed(0)})');
        _logger.w(
            'This exceeds the ±5% tolerance. Consider regenerating the meal plan.');
      } else {
        _logger.i(
            '✅ Generated meal plan calories (${totalCalories.toStringAsFixed(0)}) are within ±5% of target (${targetTotalCalories.toStringAsFixed(0)})');
      }

      final mealPlan = MealPlanModel(
        id: const Uuid().v4(),
        userId: 'current_user',
        title: 'AI-Generated $days-Day Meal Plan',
        description: 'Personalized meal plan based on your preferences',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: days - 1)),
        mealDays: mealDays,
        totalCalories:
            totalCalories, // Use actual calculated calories instead of target
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

      // Final progress update
      _logger.i(
          'Progress: $totalMeals/$totalMeals meals completed - Meal plan generation finished!');
      onProgress?.call(totalMeals, totalMeals);

      return mealPlan;
    } catch (e) {
      _logger.e('AI Service Error: $e');
      throw Exception('Meal plan generation failed: $e');
    }
  }

  /// Generate meal days sequentially as fallback when parallel processing fails
  static Future<void> _generateSequentialFallback(
    DietPlanPreferences preferences,
    int batchStart,
    int batchEnd,
    List<MealDay> mealDays,
    Function(int completedMeals, int totalMeals)? onProgress,
    int totalMeals,
    int completedMeals,
  ) async {
    _logger.i('Generating days $batchStart-$batchEnd sequentially...');

    int failedDays = 0;
    final int totalDaysInBatch = batchEnd - batchStart + 1;

    for (int dayIndex = batchStart; dayIndex <= batchEnd; dayIndex++) {
      try {
        final mealDay = await _generateSingleDayWithContext(
            preferences, dayIndex, mealDays, (dayCompletedMeals) {
          // Update progress for sequential fallback
          completedMeals += dayCompletedMeals;
          onProgress?.call(completedMeals, totalMeals);
        });
        mealDays.add(mealDay);

        // Add delay between sequential calls to respect rate limits
        if (dayIndex < batchEnd) {
          await Future.delayed(
              const Duration(milliseconds: 1000)); // Reduced for faster processing
        }
      } catch (e) {
        failedDays++;
        _logger.e('Sequential generation failed for day $dayIndex: $e');

        // If all days in the batch failed, throw an exception
        if (failedDays >= totalDaysInBatch) {
          throw Exception('All days in batch $batchStart-$batchEnd failed: $e');
        }

        // Otherwise, continue with the next day
        _logger.w('Continuing with remaining days in batch...');
      }
    }
  }

  /// Calculate optimal batch size for parallel processing
  static int _calculateOptimalBatchSize(int totalDays) {
    // Restore concurrent processing for better performance
    if (totalDays <= 1) return totalDays; // Single day: process immediately
    if (totalDays <= 3) return totalDays; // Small plans: process all at once
    if (totalDays <= 7) return 3; // Medium plans: process in batches of 3
    return 4; // Large plans: process in batches of 4
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
      _logger.e('Preview generation failed: $e');
      throw Exception('Failed to generate preview: $e');
    }
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
    _logger.i('All caches and rate limits reset');
  }

  /// Test method to validate meal plan generation with required meals
  static Future<void> testMealPlanValidation() async {
    _logger.i('🧪 Testing meal plan validation...');

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
        onProgress: (completedMeals, totalMeals) {
          _logger.d('Progress: $completedMeals/$totalMeals meals completed');
        },
      );

      _logger.i('✅ Test completed successfully');
      _logger.i('Generated ${mealPlan.mealDays.length} days');

      for (int i = 0; i < mealPlan.mealDays.length; i++) {
        final day = mealPlan.mealDays[i];
        _logger.i('Day ${i + 1}: ${day.meals.length} meals');
        for (final meal in day.meals) {
          _logger.d('  - ${meal.type.name}: ${meal.name}');
        }
      }
    } catch (e) {
      _logger.e('❌ Test failed: $e');
    }
  }
}
