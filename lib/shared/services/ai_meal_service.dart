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
  /// Generate a single day meal plan
  static Future<MealDay> _generateSingleDay(
    DietPlanPreferences preferences,
    int dayIndex,
  ) async {
    final dayPrompt = PromptService.buildSingleDayPrompt(preferences, dayIndex);

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

      return ParserService.parseSingleDayFromAI(content, preferences, dayIndex);
    } else {
      print(
          'API Error for day $dayIndex: ${response.statusCode} - ${response.body}');
      throw Exception(
          'Failed to generate day $dayIndex: ${response.statusCode}');
    }
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

      // Determine optimal batch size for parallel processing
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
        final batchSize = batchEnd - batchStart + 1;
        int batchCompletedDays = 0;
        
        for (int dayIndex = batchStart; dayIndex <= batchEnd; dayIndex++) {
          futures.add(_generateSingleDay(preferences, dayIndex).then((mealDay) {
            // Report individual day completion
            batchCompletedDays++;
            final totalCompleted = mealDays.length + batchCompletedDays;
            onProgress?.call(totalCompleted, days);
            return mealDay;
          }));
        }

        // Wait for all days in the batch to complete
        final batchResults = await Future.wait(futures);
        mealDays.addAll(batchResults);

        // Small delay between batches to be respectful to the API
        if (batchEnd < days) {
          await Future.delayed(Duration(milliseconds: 500));
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
        totalCalories: preferences.targetCalories * days,
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
      throw Exception('Failed to generate meal plan: $e');
    }
  }

  /// Calculate optimal batch size for parallel processing
  static int _calculateOptimalBatchSize(int totalDays) {
    // Conservative approach: limit parallel requests to avoid rate limits
    if (totalDays <= 7) return totalDays; // Small plans: process all at once
    if (totalDays <= 14) return 5; // Medium plans: batches of 5
    return 3; // Large plans: smaller batches to be safe
  }

  /// Generate a 1-day preview meal plan (for preview step)
  static Future<Map<String, List<String>>> generatePreviewDay({
    required DietPlanPreferences preferences,
  }) async {
    try {
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
}
