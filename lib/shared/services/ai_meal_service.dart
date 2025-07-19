import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/meal_model.dart';
import 'prompt_service.dart';
import 'parser_service.dart';
import 'mock_data_service.dart';
import 'config_service.dart';

class AIMealService {

  /// Generate a personalized meal plan using AI
  static Future<MealPlanModel> generateMealPlan({
    required DietPlanPreferences preferences,
    required int days,
    Function(int completedDays, int totalDays)? onProgress,
  }) async {
    try {
      print('Generating $days-day meal plan using chunking approach...');
      
      // Generate each day individually to avoid truncation
      final List<MealDay> mealDays = [];
      
      for (int dayIndex = 1; dayIndex <= days; dayIndex++) {
        print('Generating day $dayIndex of $days...');
        
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
          'max_tokens': ConfigService.openAIMaxTokens, // Reduced since we're only generating one day
        };
        
        final response = await http.post(
          Uri.parse(ConfigService.openAIBaseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${ConfigService.openAIApiKey}',
          },
          body: jsonEncode(requestBody),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = data['choices'][0]['message']['content'];
          print('Day $dayIndex response received successfully');
          
          final mealDay = ParserService.parseSingleDayFromAI(content, preferences, dayIndex);
          mealDays.add(mealDay);
          
          // Report progress after each day is completed
          onProgress?.call(dayIndex, days);
        } else {
          print('API Error for day $dayIndex: ${response.statusCode} - ${response.body}');
          throw Exception('Failed to generate day $dayIndex: ${response.statusCode}');
        }
      }
      
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
      
    } catch (e) {
      print('AI Service Error: $e');
      throw Exception('Failed to generate meal plan: $e');
    }
  }

  /// Generate a 1-day preview meal plan (for preview step)
  static Future<Map<String, List<String>>> generatePreviewDay({
    required DietPlanPreferences preferences,
  }) async {
    try {
      final previewPlan = await generateMealPlan(preferences: preferences, days: 1);
      // Convert the first day to a simple map for preview UI
      final day = previewPlan.mealDays.first;
      final Map<String, List<String>> preview = {};
      for (final meal in day.meals) {
        preview[capitalize(meal.type.name)] = [meal.name, ...meal.ingredients.map((i) => i.name)];
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
  static String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
 