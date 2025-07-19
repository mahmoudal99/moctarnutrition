import 'package:intl/intl.dart';
import '../models/user_model.dart';

/// Service for generating AI prompts for meal plan generation
class PromptService {
  /// Build a prompt for generating a single day
  static String buildSingleDayPrompt(
    DietPlanPreferences preferences,
    int dayIndex,
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

    // Calculate the date for this day
    final dayDate = DateTime.now().add(Duration(days: dayIndex - 1));
    final formattedDate = DateFormat('yyyy-MM-dd').format(dayDate);

    return '''
Generate Day $dayIndex of a personalized meal plan in JSON format with the following requirements:

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
1. Create Day $dayIndex with meals (breakfast, lunch, dinner, snacks)
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
10. CRITICAL: Double-check that ALL meals respect the dietary restrictions

Return the response in this exact JSON format, but replace all placeholder values with actual meal data:

{
  "mealDay": {
    "id": "day_$dayIndex",
    "date": "$formattedDate",
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
}

IMPORTANT: 
- Replace ALL placeholder values in [BRACKETS] with actual data
- Calculate nutrition totals by summing all meals
- Generate unique meal names for each meal
- Ensure all nutrition values are realistic numbers, not 0
- Create Day $dayIndex with breakfast, lunch, dinner, and snacks
''';
  }

  /// Build a detailed prompt for the AI
  static String buildMealPlanPrompt(
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

    // Calculate proper dates
    final startDate = DateTime.now();
    final endDate = startDate.add(Duration(days: days - 1));
    final formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
    final formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);

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
    "startDate": "$formattedStartDate",
    "endDate": "$formattedEndDate",
    "totalCalories": $targetCalories * $days,
    "totalProtein": [CALCULATE_TOTAL_PROTEIN_FROM_ALL_MEALS],
    "totalCarbs": [CALCULATE_TOTAL_CARBS_FROM_ALL_MEALS],
    "totalFat": [CALCULATE_TOTAL_FAT_FROM_ALL_MEALS],
    "dietaryTags": ["$restrictions"],
    "mealDays": [
      {
        "id": "day_1",
        "date": "$formattedStartDate",
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