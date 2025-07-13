import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/meal_model.dart';

class AIMealService {
  static const String _apiKey = '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'; // Store this securely
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  /// Generate a personalized meal plan using AI
  static Future<MealPlanModel> generateMealPlan({
    required DietPlanPreferences preferences,
    required int days,
  }) async {
    try {
      final prompt = _buildMealPlanPrompt(preferences, days);

      final requestBody = {
        'model': 'gpt-3.5-turbo', // Use cheaper model for testing
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a professional nutritionist and meal planner. Generate detailed, personalized meal plans in JSON format. ALWAYS respect dietary restrictions - this is the most critical requirement. Never include foods that violate the user\'s dietary restrictions.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.7,
        'max_tokens': 4096, // Maximum allowed for GPT-3.5-turbo
      };
      
      print('Making API request to OpenAI...');
      print('Request body: ${jsonEncode(requestBody)}');
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        print('AI Response received successfully');
        print('AI Content length: ${content.length}');
        return _parseMealPlanFromAI(content, preferences, days);
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to generate meal plan: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('AI Service Error: $e');
      
      // If it's a truncation error and we're trying more than 3 days, try with fewer days
      if (e.toString().contains('truncated') && days > 3) {
        print('Attempting to generate a shorter meal plan with ${days - 1} days...');
        try {
          return await generateMealPlan(preferences: preferences, days: days - 1);
        } catch (retryError) {
          print('Retry also failed: $retryError');
        }
      }
      
      throw Exception('Failed to generate meal plan: $e');
    }
  }

  /// Build a detailed prompt for the AI
  static String _buildMealPlanPrompt(
    DietPlanPreferences preferences,
    int days,
  ) {
    final fitnessGoal = _getFitnessGoalDescription(preferences.fitnessGoal);
    final activityLevel = _getActivityLevelDescription(preferences.activityLevel);
    final restrictions = preferences.dietaryRestrictions.join(', ');
    final workoutStyles = preferences.preferredWorkoutStyles.join(', ');
    final cuisines = preferences.preferredCuisines.join(', ');
    final avoid = preferences.foodsToAvoid.join(', ');
    final favorites = preferences.favoriteFoods.join(', ');
    final mealFrequency = preferences.mealFrequency;
    final nutritionGoal = preferences.nutritionGoal;
    final weeklyRotation = preferences.weeklyRotation ? 'Yes' : 'No';
    final reminders = preferences.remindersEnabled ? 'Yes' : 'No';
    final targetCalories = preferences.targetCalories;

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
- Nutrition Goal: $nutritionGoal
- Target Calories: $targetCalories per day
- Dietary Restrictions: $restrictions
- Preferred Workout Styles: $workoutStyles

Nutrition Preferences:
- Preferred Cuisines: $cuisines
- Foods to Avoid: $avoid
- Favorite Foods: $favorites

Meal Prep Preferences:
- Meal Frequency: $mealFrequency
- Weekly Rotation: $weeklyRotation
- Reminders Enabled: $reminders

CRITICAL DIETARY RESTRICTIONS:
- The user has the following dietary restrictions: $restrictions
- If the user is Vegan: DO NOT include any animal products (meat, fish, dairy, eggs, honey)
- If the user is Vegetarian: DO NOT include any meat or fish, but dairy and eggs are allowed
- If the user is Gluten-Free: DO NOT include wheat, barley, rye, or any gluten-containing ingredients
- If the user is Dairy-Free: DO NOT include milk, cheese, yogurt, or any dairy products
- ALWAYS respect these restrictions - this is the most important requirement

Requirements:
1. Create $days days of meals (breakfast, lunch, dinner, snacks)
2. Each meal should include:
   - Name
   - Description
   - Ingredients with amounts
   - Step-by-step instructions
   - Nutritional info (calories, protein, carbs, fat, fiber, sugar, sodium)
   - Prep time and cook time
   - Servings
   - Cuisine type
   - Tags (vegetarian, vegan, gluten-free, etc.)
   - Meal type (breakfast, lunch, dinner, snack)

3. Ensure the total daily calories match $targetCalories
4. Consider the fitness goal, nutrition goal, dietary restrictions, and personal metrics
5. Include variety in cuisines and flavors
6. Make recipes practical and easy to follow
7. Consider age-appropriate nutrition needs
8. Adjust portion sizes based on weight and activity level
9. Use the user's meal frequency and preferences for meal timing
10. If weekly rotation is Yes, make each day unique; if No, repeat the same day
11. CRITICAL: Double-check that ALL meals respect the dietary restrictions

Return the response in this exact JSON format, but replace all placeholder values with actual meal data:

{
  "mealPlan": {
    "title": "Personalized $days-Day Meal Plan",
    "description": "AI-generated meal plan for $fitnessGoal and $nutritionGoal",
    "startDate": "2024-01-01",
    "endDate": "2024-01-0$days",
    "totalCalories": $targetCalories * $days,
    "totalProtein": [CALCULATE_TOTAL_PROTEIN_FROM_ALL_MEALS],
    "totalCarbs": [CALCULATE_TOTAL_CARBS_FROM_ALL_MEALS],
    "totalFat": [CALCULATE_TOTAL_FAT_FROM_ALL_MEALS],
    "dietaryTags": ["$restrictions"],
    "mealDays": [
      {
        "id": "day_1",
        "date": "2024-01-01",
        "totalCalories": $targetCalories,
        "totalProtein": [CALCULATE_DAY_PROTEIN_FROM_MEALS],
        "totalCarbs": [CALCULATE_DAY_CARBS_FROM_MEALS],
        "totalFat": [CALCULATE_DAY_FAT_FROM_MEALS],
        "meals": [
          {
            "id": "meal_1",
            "name": "[ACTUAL_MEAL_NAME]",
            "description": "[ACTUAL_MEAL_DESCRIPTION]",
            "type": "breakfast",
            "cuisineType": "[ACTUAL_CUISINE]",
            "prepTime": [ACTUAL_PREP_TIME],
            "cookTime": [ACTUAL_COOK_TIME],
            "servings": 1,
            "ingredients": [
              {
                "name": "[ACTUAL_INGREDIENT_NAME]",
                "amount": [ACTUAL_AMOUNT],
                "unit": "[ACTUAL_UNIT]",
                "notes": "[OPTIONAL_NOTES]"
              }
            ],
            "instructions": [
              "[ACTUAL_STEP_1]",
              "[ACTUAL_STEP_2]"
            ],
            "nutrition": {
              "calories": [ACTUAL_CALORIES],
              "protein": [ACTUAL_PROTEIN],
              "carbs": [ACTUAL_CARBS],
              "fat": [ACTUAL_FAT],
              "fiber": [ACTUAL_FIBER],
              "sugar": [ACTUAL_SUGAR],
              "sodium": [ACTUAL_SODIUM]
            },
            "tags": ["[ACTUAL_TAGS]"],
            "isVegetarian": [TRUE_OR_FALSE_BASED_ON_MEAL],
            "isVegan": [TRUE_OR_FALSE_BASED_ON_MEAL],
            "isGlutenFree": [TRUE_OR_FALSE_BASED_ON_MEAL],
            "isDairyFree": [TRUE_OR_FALSE_BASED_ON_MEAL]
          }
        ]
      }
    ]
  }
}

IMPORTANT: 
- Replace ALL placeholder values in [BRACKETS] with actual data
- Calculate nutrition totals by summing all meals
- Generate unique meal names for each meal
- Ensure all nutrition values are realistic numbers, not 0
- Create $days days of meals, not just one day
''';
  }

  /// Parse AI response into MealPlanModel
  static MealPlanModel _parseMealPlanFromAI(
    String aiResponse,
    DietPlanPreferences preferences,
    int days,
  ) {
    try {
      print('Parsing AI response...');
      print('AI Response length:  [33m${aiResponse.length} [0m');
      print('AI Response preview:  [36m${aiResponse.substring(0, aiResponse.length > 200 ? 200 : aiResponse.length)}... [0m');
      
      // Remove markdown code fences if present
      String cleanResponse = aiResponse.trim();
      if (cleanResponse.startsWith('```')) {
        int firstNewline = cleanResponse.indexOf('\n');
        if (firstNewline != -1) {
          cleanResponse = cleanResponse.substring(firstNewline + 1);
        }
        if (cleanResponse.endsWith('```')) {
          cleanResponse = cleanResponse.substring(0, cleanResponse.length - 3);
        }
      }
      
      // Extract JSON from AI response (sometimes it includes markdown)
      final jsonStart = cleanResponse.indexOf('{');
      final jsonEnd = cleanResponse.lastIndexOf('}') + 1;
      if (jsonStart == -1 || jsonEnd == 0) {
        print('No JSON found in AI response');
        throw Exception('No JSON found in AI response');
      }
      
      // Check if the JSON appears to be truncated
      final jsonString = cleanResponse.substring(jsonStart, jsonEnd);
      final openBraces = '{'.allMatches(jsonString).length;
      final closeBraces = '}'.allMatches(jsonString).length;
      final openBrackets = '['.allMatches(jsonString).length;
      final closeBrackets = ']'.allMatches(jsonString).length;
      
      if (openBraces != closeBraces || openBrackets != closeBrackets) {
        print('JSON appears to be truncated. Open braces: $openBraces, Close braces: $closeBraces');
        print('Open brackets: $openBrackets, Close brackets: $closeBrackets');
        throw Exception('AI response was truncated. Please try again with a shorter meal plan or contact support.');
      }
      
      // Remove comments and other non-JSON content
      String cleanedJson = jsonString;
      
      // Remove single-line comments (// ...)
      cleanedJson = cleanedJson.replaceAll(RegExp(r'//.*$', multiLine: true), '');
      
      // Remove multi-line comments (/* ... */)
      cleanedJson = cleanedJson.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
      
      // Remove empty lines and extra whitespace
      cleanedJson = cleanedJson.split('\n')
          .where((line) => line.trim().isNotEmpty)
          .join('\n');
      
      // Remove trailing commas before closing brackets/braces
      cleanedJson = cleanedJson.replaceAllMapped(
        RegExp(r',(\s*[}\]])'),
        (match) => match.group(1) ?? '',
      );
      print('Extracted JSON: $jsonString');
      print('Cleaned JSON: $cleanedJson');
      
      // Fix common JSON issues from AI responses
      String fixedJsonString = cleanedJson;
      
      // Fix fractions like 1/2, 1/4, etc.
      fixedJsonString = fixedJsonString.replaceAllMapped(
        RegExp(r':\s*(\d+)/(\d+)'),
        (match) {
          final numerator = double.parse(match.group(1) ?? '0');
          final denominator = double.parse(match.group(2) ?? '1');
          final result = numerator / denominator;
          return ': $result';
        },
      );
      
      // Fix quoted fractions like "1/2"
      fixedJsonString = fixedJsonString.replaceAllMapped(
        RegExp(r':\s*"(\d+)/(\d+)"'),
        (match) {
          final numerator = double.parse(match.group(1) ?? '0');
          final denominator = double.parse(match.group(2) ?? '1');
          final result = numerator / denominator;
          return ': $result';
        },
      );
      
      print('Fixed JSON: $fixedJsonString');
      final data = jsonDecode(fixedJsonString);
      final mealPlanData = data['mealPlan'];
      final mealDays = (mealPlanData['mealDays'] as List).map((dayData) {
        final dayMap = Map<String, dynamic>.from(dayData);
        if (dayMap['totalCalories'] is double) {
          dayMap['totalCalories'] = (dayMap['totalCalories'] as double).toInt();
        }
        
        // Calculate nutrition totals from meals if they're missing or 0
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
          
          // Calculate day totals from meals
          double dayProtein = 0;
          double dayCarbs = 0;
          double dayFat = 0;
          
          for (final meal in meals) {
            if (meal['nutrition'] != null) {
              final nutrition = meal['nutrition'] as Map<String, dynamic>;
              dayProtein += (nutrition['protein'] as num?)?.toDouble() ?? 0;
              dayCarbs += (nutrition['carbs'] as num?)?.toDouble() ?? 0;
              dayFat += (nutrition['fat'] as num?)?.toDouble() ?? 0;
            }
          }
          
          // Update day totals if they're missing or 0
          if ((dayMap['totalProtein'] as num?)?.toDouble() == 0 || dayMap['totalProtein'] == null) {
            dayMap['totalProtein'] = dayProtein;
          }
          if ((dayMap['totalCarbs'] as num?)?.toDouble() == 0 || dayMap['totalCarbs'] == null) {
            dayMap['totalCarbs'] = dayCarbs;
          }
          if ((dayMap['totalFat'] as num?)?.toDouble() == 0 || dayMap['totalFat'] == null) {
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
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'current_user',
        title: mealPlanData['title'],
        description: mealPlanData['description'],
        startDate: DateTime.parse(mealPlanData['startDate']),
        endDate: DateTime.parse(mealPlanData['endDate']),
        mealDays: mealDays,
        totalCalories: (mealPlanData['totalCalories'] as num).toInt(),
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
  static MealPlanModel _generateMockMealPlan(
    DietPlanPreferences preferences,
    int days,
  ) {
    print('Generating mock meal plan as fallback');
    final mealDays = List.generate(days, (index) {
      final date = DateTime.now().add(Duration(days: index));
      // Use different seed for each day to get varied meals
      final daySeed = DateTime.now().millisecondsSinceEpoch + index;
      return MealDay(
        id: 'day_${index + 1}',
        date: date,
        meals: _generateMockMeals(preferences, daySeed),
        totalCalories: preferences.targetCalories,
        totalProtein: preferences.targetCalories * 0.3 / 4,
        // 30% protein
        totalCarbs: preferences.targetCalories * 0.4 / 4,
        // 40% carbs
        totalFat: preferences.targetCalories * 0.3 / 9, // 30% fat
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
      totalCalories: preferences.targetCalories * days,
      totalProtein: preferences.targetCalories * days * 0.3 / 4,
      totalCarbs: preferences.targetCalories * days * 0.4 / 4,
      totalFat: preferences.targetCalories * days * 0.3 / 9,
      dietaryTags: preferences.dietaryRestrictions,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Generate mock meals for fallback
  static List<Meal> _generateMockMeals(
      DietPlanPreferences preferences, [int? seed]) {
    // Create varied meal options based on preferences
    final isVegan = preferences.dietaryRestrictions.contains('Vegan');
    final isVegetarian = preferences.dietaryRestrictions.contains('Vegetarian');
    
    final breakfastOptions = isVegan ? [
      ('Oatmeal with Berries', 'Steel-cut oats topped with fresh berries and maple syrup'),
      ('Vegan Protein Smoothie Bowl', 'Plant-based smoothie bowl with berries and granola'),
      ('Avocado Toast', 'Whole grain toast with avocado and microgreens'),
      ('Vegan Breakfast Burrito', 'Tofu scramble with black beans and salsa in a whole wheat tortilla'),
      ('Chia Pudding', 'Chia seeds soaked in almond milk with fresh fruits'),
    ] : isVegetarian ? [
      ('Oatmeal with Berries', 'Steel-cut oats topped with fresh berries and honey'),
      ('Greek Yogurt Parfait', 'Greek yogurt layered with granola and mixed berries'),
      ('Protein Smoothie Bowl', 'Nutritious smoothie bowl with berries and granola'),
      ('Avocado Toast', 'Whole grain toast with avocado, eggs, and microgreens'),
      ('Breakfast Burrito', 'Scrambled eggs with black beans and salsa in a whole wheat tortilla'),
    ] : [
      ('Oatmeal with Berries', 'Steel-cut oats topped with fresh berries and honey'),
      ('Greek Yogurt Parfait', 'Greek yogurt layered with granola and mixed berries'),
      ('Protein Smoothie Bowl', 'Nutritious smoothie bowl with berries and granola'),
      ('Avocado Toast', 'Whole grain toast with avocado, eggs, and microgreens'),
      ('Breakfast Burrito', 'Scrambled eggs with black beans and salsa in a whole wheat tortilla'),
    ];
    
    final lunchOptions = isVegan ? [
      ('Quinoa Buddha Bowl', 'Quinoa bowl with roasted vegetables and tahini dressing'),
      ('Lentil Soup', 'Hearty lentil soup with vegetables and herbs'),
      ('Mediterranean Plate', 'Hummus, falafel, and fresh vegetables'),
      ('Vegan Wrap', 'Chickpea and avocado wrap with mixed greens'),
      ('Vegan Buddha Bowl', 'Brown rice with tofu, vegetables, and peanut sauce'),
    ] : isVegetarian ? [
      ('Quinoa Buddha Bowl', 'Quinoa bowl with roasted vegetables and tahini dressing'),
      ('Lentil Soup', 'Hearty lentil soup with vegetables and herbs'),
      ('Mediterranean Plate', 'Hummus, falafel, and fresh vegetables'),
      ('Vegetarian Wrap', 'Cheese and avocado wrap with mixed greens'),
      ('Vegetarian Buddha Bowl', 'Brown rice with eggs, vegetables, and peanut sauce'),
    ] : [
      ('Grilled Chicken Salad', 'Fresh salad with grilled chicken and vegetables'),
      ('Quinoa Buddha Bowl', 'Quinoa bowl with roasted vegetables and tahini dressing'),
      ('Turkey Wrap', 'Turkey and avocado wrap with mixed greens'),
      ('Lentil Soup', 'Hearty lentil soup with vegetables and herbs'),
      ('Mediterranean Plate', 'Hummus, falafel, and fresh vegetables'),
    ];
    
    final dinnerOptions = isVegan ? [
      ('Vegan Pasta', 'Whole wheat pasta with tomato sauce and vegetables'),
      ('Tofu Stir-Fry', 'Stir-fried tofu with broccoli and brown rice'),
      ('Vegan Buddha Bowl', 'Quinoa with roasted vegetables and tahini dressing'),
      ('Lentil Curry', 'Spiced lentil curry with brown rice'),
      ('Vegan Tacos', 'Black bean and vegetable tacos with avocado'),
    ] : isVegetarian ? [
      ('Vegetarian Pasta', 'Whole wheat pasta with tomato sauce and vegetables'),
      ('Eggplant Parmesan', 'Baked eggplant with marinara and cheese'),
      ('Vegetarian Buddha Bowl', 'Quinoa with roasted vegetables and tahini dressing'),
      ('Lentil Curry', 'Spiced lentil curry with brown rice'),
      ('Vegetarian Tacos', 'Black bean and vegetable tacos with cheese'),
    ] : [
      ('Salmon with Quinoa', 'Baked salmon with quinoa and roasted vegetables'),
      ('Lean Beef Stir-Fry', 'Stir-fried beef with broccoli and brown rice'),
      ('Vegetarian Pasta', 'Whole wheat pasta with tomato sauce and vegetables'),
      ('Grilled Shrimp Skewers', 'Grilled shrimp with couscous and vegetables'),
      ('Chicken Breast with Sweet Potato', 'Grilled chicken with roasted sweet potato'),
    ];
    
    final snackOptions = isVegan ? [
      ('Vegan Yogurt with Nuts', 'Plant-based yogurt with mixed nuts'),
      ('Apple with Almond Butter', 'Fresh apple slices with almond butter'),
      ('Vegan Protein Bar', 'Homemade protein bar with nuts and dried fruit'),
      ('Hummus with Carrots', 'Fresh carrot sticks with hummus'),
      ('Mixed Nuts', 'Assorted nuts and dried fruits'),
    ] : [
      ('Greek Yogurt with Nuts', 'Protein-rich snack with mixed nuts'),
      ('Apple with Almond Butter', 'Fresh apple slices with almond butter'),
      ('Protein Bar', 'Homemade protein bar with nuts and dried fruit'),
      ('Hummus with Carrots', 'Fresh carrot sticks with hummus'),
      ('Mixed Nuts', 'Assorted nuts and dried fruits'),
    ];
    
    // Select random meals based on preferences
    final random = seed ?? DateTime.now().millisecondsSinceEpoch;
    final breakfast = breakfastOptions[random % breakfastOptions.length];
    final lunch = lunchOptions[random % lunchOptions.length];
    final dinner = dinnerOptions[random % dinnerOptions.length];
    final snack = snackOptions[random % snackOptions.length];
    
    final meals = [
      _createMockMeal(
        breakfast.$1,
        breakfast.$2,
        MealType.breakfast,
        (preferences.targetCalories * 0.25).round(),
        preferences,
      ),
      _createMockMeal(
        lunch.$1,
        lunch.$2,
        MealType.lunch,
        (preferences.targetCalories * 0.35).round(),
        preferences,
      ),
      _createMockMeal(
        dinner.$1,
        dinner.$2,
        MealType.dinner,
        (preferences.targetCalories * 0.35).round(),
        preferences,
      ),
      _createMockMeal(
        snack.$1,
        snack.$2,
        MealType.snack,
        (preferences.targetCalories * 0.05).round(),
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
    DietPlanPreferences preferences,
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

  static String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
 