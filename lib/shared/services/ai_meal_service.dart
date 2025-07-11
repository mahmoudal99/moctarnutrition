import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/meal_model.dart';

class AIMealService {
  static const String _apiKey = 'YOUR_OPENAI_API_KEY'; // Store this securely
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  /// Generate a personalized meal plan using AI
  static Future<MealPlanModel> generateMealPlan({
    required UserPreferences preferences,
    required int days,
    required int targetCalories,
  }) async {
    try {
      final prompt = _buildMealPlanPrompt(preferences, days, targetCalories);

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a professional nutritionist and meal planner. Generate detailed, personalized meal plans in JSON format.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 4000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return _parseMealPlanFromAI(content, preferences, days, targetCalories);
      } else {
        throw Exception('Failed to generate meal plan: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data if AI fails
      return _generateMockMealPlan(preferences, days, targetCalories);
    }
  }

  /// Build a detailed prompt for the AI
  static String _buildMealPlanPrompt(
    UserPreferences preferences,
    int days,
    int targetCalories,
  ) {
    final fitnessGoal = _getFitnessGoalDescription(preferences.fitnessGoal);
    final activityLevel =
        _getActivityLevelDescription(preferences.activityLevel);
    final restrictions = preferences.dietaryRestrictions.join(', ');
    final workoutStyles = preferences.preferredWorkoutStyles.join(', ');

    return '''
Generate a $days-day personalized meal plan in JSON format with the following requirements:

User Profile:
- Age: ${preferences.age} years
- Gender: ${preferences.gender}
- Weight: ${preferences.weight} kg
- Height: ${preferences.height} cm
- BMI: ${(preferences.weight / ((preferences.height / 100) * (preferences.height / 100))).toStringAsFixed(1)}
- Fitness Goal: $fitnessGoal
- Activity Level: $activityLevel
- Target Calories: $targetCalories per day
- Dietary Restrictions: $restrictions
- Preferred Workout Styles: $workoutStyles

Requirements:
1. Create $days days of meals (breakfast, lunch, dinner, snacks)
2. Each meal should include:
   - Name
   - Description
   - Ingredients with amounts
   - Step-by-step instructions
   - Nutritional info (calories, protein, carbs, fat)
   - Prep time and cook time
   - Servings
   - Cuisine type
   - Tags (vegetarian, vegan, gluten-free, etc.)

3. Ensure the total daily calories match $targetCalories
4. Consider the fitness goal, dietary restrictions, and personal metrics
5. Include variety in cuisines and flavors
6. Make recipes practical and easy to follow
7. Consider age-appropriate nutrition needs
8. Adjust portion sizes based on weight and activity level

Return the response in this exact JSON format:
{
  "mealPlan": {
    "title": "Personalized $days-Day Meal Plan",
    "description": "AI-generated meal plan for $fitnessGoal",
    "startDate": "2024-01-01",
    "endDate": "2024-01-0$days",
    "totalCalories": $targetCalories * $days,
    "totalProtein": 0,
    "totalCarbs": 0,
    "totalFat": 0,
    "dietaryTags": ["$restrictions"],
    "mealDays": [
      {
        "id": "day_1",
        "date": "2024-01-01",
        "totalCalories": $targetCalories,
        "totalProtein": 0,
        "totalCarbs": 0,
        "totalFat": 0,
        "meals": [
          {
            "id": "meal_1",
            "name": "Meal Name",
            "description": "Meal description",
            "type": "breakfast",
            "cuisineType": "american",
            "prepTime": 10,
            "cookTime": 15,
            "servings": 1,
            "ingredients": [
              {
                "name": "Ingredient name",
                "amount": 1.0,
                "unit": "cup",
                "notes": "optional notes"
              }
            ],
            "instructions": [
              "Step 1",
              "Step 2"
            ],
            "nutrition": {
              "calories": 400,
              "protein": 25.0,
              "carbs": 45.0,
              "fat": 15.0,
              "fiber": 8.0,
              "sugar": 12.0,
              "sodium": 500.0
            },
            "tags": ["vegetarian"],
            "isVegetarian": false,
            "isVegan": false,
            "isGlutenFree": false,
            "isDairyFree": false
          }
        ]
      }
    ]
  }
}
''';
  }

  /// Parse AI response into MealPlanModel
  static MealPlanModel _parseMealPlanFromAI(
    String aiResponse,
    UserPreferences preferences,
    int days,
    int targetCalories,
  ) {
    try {
      // Extract JSON from AI response (sometimes it includes markdown)
      final jsonStart = aiResponse.indexOf('{');
      final jsonEnd = aiResponse.lastIndexOf('}') + 1;
      final jsonString = aiResponse.substring(jsonStart, jsonEnd);

      final data = jsonDecode(jsonString);
      final mealPlanData = data['mealPlan'];

      final mealDays = (mealPlanData['mealDays'] as List).map((dayData) {
        // Ensure totalCalories is an int in the day data
        final dayMap = Map<String, dynamic>.from(dayData);
        if (dayMap['totalCalories'] is double) {
          dayMap['totalCalories'] = (dayMap['totalCalories'] as double).toInt();
        }

        // Ensure meal calories are also int
        if (dayMap['meals'] != null) {
          final meals = (dayMap['meals'] as List).map((mealData) {
            final mealMap = Map<String, dynamic>.from(mealData);
            if (mealMap['nutrition'] != null &&
                mealMap['nutrition']['calories'] is double) {
              mealMap['nutrition']['calories'] =
                  (mealMap['nutrition']['calories'] as double).toInt();
            }
            return mealMap;
          }).toList();
          dayMap['meals'] = meals;
        }

        return MealDay.fromJson(dayMap);
      }).toList();

      return MealPlanModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'current_user',
        // Will be set when user auth is implemented
        title: mealPlanData['title'],
        description: mealPlanData['description'],
        startDate: DateTime.parse(mealPlanData['startDate']),
        endDate: DateTime.parse(mealPlanData['endDate']),
        mealDays: mealDays,
        totalCalories: (mealPlanData['totalCalories'] as num).toInt(),
        totalProtein: mealPlanData['totalProtein'].toDouble(),
        totalCarbs: mealPlanData['totalCarbs'].toDouble(),
        totalFat: mealPlanData['totalFat'].toDouble(),
        dietaryTags: List<String>.from(mealPlanData['dietaryTags']),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      // If parsing fails, return mock data
      return _generateMockMealPlan(preferences, days, targetCalories);
    }
  }

  /// Generate mock meal plan as fallback
  static MealPlanModel _generateMockMealPlan(
    UserPreferences preferences,
    int days,
    int targetCalories,
  ) {
    final mealDays = List.generate(days, (index) {
      final date = DateTime.now().add(Duration(days: index));
      return MealDay(
        id: 'day_${index + 1}',
        date: date,
        meals: _generateMockMeals(preferences, targetCalories),
        totalCalories: targetCalories,
        totalProtein: targetCalories * 0.3 / 4,
        // 30% protein
        totalCarbs: targetCalories * 0.4 / 4,
        // 40% carbs
        totalFat: targetCalories * 0.3 / 9, // 30% fat
      );
    });

    return MealPlanModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'current_user',
      title: 'AI-Generated $days-Day Meal Plan',
      description: 'Personalized meal plan based on your preferences',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: days - 1)),
      mealDays: mealDays,
      totalCalories: targetCalories * days,
      totalProtein: targetCalories * days * 0.3 / 4,
      totalCarbs: targetCalories * days * 0.4 / 4,
      totalFat: targetCalories * days * 0.3 / 9,
      dietaryTags: preferences.dietaryRestrictions,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Generate mock meals for fallback
  static List<Meal> _generateMockMeals(
      UserPreferences preferences, int targetCalories) {
    final meals = [
      _createMockMeal(
        'Protein Smoothie Bowl',
        'Nutritious smoothie bowl with berries and granola',
        MealType.breakfast,
        (targetCalories * 0.25).round(),
        preferences,
      ),
      _createMockMeal(
        'Grilled Chicken Salad',
        'Fresh salad with grilled chicken and vegetables',
        MealType.lunch,
        (targetCalories * 0.35).round(),
        preferences,
      ),
      _createMockMeal(
        'Salmon with Quinoa',
        'Baked salmon with quinoa and roasted vegetables',
        MealType.dinner,
        (targetCalories * 0.35).round(),
        preferences,
      ),
      _createMockMeal(
        'Greek Yogurt with Nuts',
        'Protein-rich snack with mixed nuts',
        MealType.snack,
        (targetCalories * 0.05).round(),
        preferences,
      ),
    ];

    return meals;
  }

  /// Create a mock meal
  static Meal _createMockMeal(
    String name,
    String description,
    MealType type,
    int calories,
    UserPreferences preferences,
  ) {
    return Meal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      type: type,
      cuisineType: CuisineType.american,
      ingredients: [
        RecipeIngredient(name: 'Ingredient 1', amount: 1.0, unit: 'cup'),
        RecipeIngredient(name: 'Ingredient 2', amount: 2.0, unit: 'tbsp'),
      ],
      instructions: [
        'Step 1: Prepare ingredients',
        'Step 2: Cook according to recipe',
        'Step 3: Serve and enjoy',
      ],
      prepTime: 10,
      cookTime: 20,
      servings: 1,
      nutrition: NutritionInfo(
        calories: calories,
        protein: calories * 0.3 / 4,
        carbs: calories * 0.4 / 4,
        fat: calories * 0.3 / 9,
        fiber: 5.0,
        sugar: 10.0,
        sodium: 500.0,
      ),
      tags: ['healthy', 'balanced'],
      isVegetarian: preferences.dietaryRestrictions.contains('Vegetarian'),
      isVegan: preferences.dietaryRestrictions.contains('Vegan'),
      isGlutenFree: preferences.dietaryRestrictions.contains('Gluten-Free'),
      isDairyFree: preferences.dietaryRestrictions.contains('Dairy-Free'),
    );
  }

  /// Helper methods for prompt building
  static String _getFitnessGoalDescription(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return 'Weight Loss';
      case FitnessGoal.muscleGain:
        return 'Muscle Building';
      case FitnessGoal.maintenance:
        return 'Maintenance';
      case FitnessGoal.endurance:
        return 'Endurance Training';
      case FitnessGoal.strength:
        return 'Strength Training';
    }
  }

  static String _getActivityLevelDescription(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sedentary (little to no exercise)';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active (light exercise 1-3 days/week)';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active (moderate exercise 3-5 days/week)';
      case ActivityLevel.veryActive:
        return 'Very Active (hard exercise 6-7 days/week)';
      case ActivityLevel.extremelyActive:
        return 'Extremely Active (very hard exercise, physical job)';
    }
  }
}
