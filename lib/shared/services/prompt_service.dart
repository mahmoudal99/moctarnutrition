import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/meal_model.dart';

/// Service for generating AI prompts for meal plan generation
class PromptService {
  /// Build a prompt for generating a single day
  static String buildSingleDayPrompt(
    DietPlanPreferences preferences,
    int dayIndex,
  ) {
    final dayDate = DateTime.now().add(Duration(days: dayIndex - 1));
    final formattedDate = DateFormat('yyyy-MM-dd').format(dayDate);
    final bmi = (preferences.weight / ((preferences.height / 100) * (preferences.height / 100))).toStringAsFixed(1);

    return '''
You are a professional nutritionist. Generate a meal plan for Day $dayIndex in JSON format, strictly adhering to the user's dietary restrictions and preferences.

### User Profile
- Age: ${preferences.age} years
- Gender: ${preferences.gender}
- Weight: ${preferences.weight} kg
- Height: ${preferences.height} cm
- BMI: $bmi
- Fitness Goal: ${_getFitnessGoalDescription(preferences.fitnessGoal)}
- Activity Level: ${_getActivityLevelDescription(preferences.activityLevel)}
- Nutrition Goal: ${preferences.nutritionGoal}
- Target Calories: ${preferences.targetCalories}/day

### Nutrition Preferences
- Preferred Cuisines: ${preferences.preferredCuisines.join(', ').isEmpty ? 'Any' : preferences.preferredCuisines.join(', ')}
- Favorite Foods: ${preferences.favoriteFoods.join(', ').isEmpty ? 'None' : preferences.favoriteFoods.join(', ')}
- Foods to Avoid: ${preferences.foodsToAvoid.join(', ').isEmpty ? 'None' : preferences.foodsToAvoid.join(', ')}
- Meal Frequency: ${preferences.mealFrequency} meals/day

### Dietary Restrictions (CRITICAL)
- Restrictions: ${preferences.dietaryRestrictions.join(', ').isEmpty ? 'None' : preferences.dietaryRestrictions.join(', ')}
- Rules:
  - Vegan: No animal products (meat, fish, dairy, eggs, honey).
  - Vegetarian: No meat or fish; dairy and eggs allowed.
  - Gluten-Free: No wheat, barley, rye, or gluten-containing ingredients.
  - Dairy-Free: No milk, cheese, yogurt, or dairy products.
- ALWAYS respect these restrictions. Double-check all ingredients.

### Requirements
- Generate ${preferences.mealFrequency} meals (e.g., breakfast, lunch, dinner, snacks) for Day $dayIndex.
- Total daily calories: ${preferences.targetCalories}.
- Each meal must include:
  - Name: Unique and descriptive.
  - Description: Brief, appealing summary.
  - Ingredients: Detailed list with precise names, amounts, units, and nutritional data per ingredient.
  - Instructions: Clear, step-by-step, practical for home cooking.
  - Nutrition: Calories, protein, carbs, fat, fiber, sugar, sodium (calculated from ingredients).
  - Prep Time, Cook Time: In minutes.
  - Servings: 1.
  - Cuisine Type: From preferred cuisines or varied.
  - Tags: e.g., vegetarian, vegan, gluten-free, based on meal content.
  - Flags: isVegetarian, isVegan, isGlutenFree, isDairyFree (true/false).

### Ingredient Specifications (CRITICAL FOR VERIFICATION)
- Use precise ingredient names that match USDA FoodData Central database:
  - Examples: "chicken breast, raw" not "chicken", "almond flour" not "flour"
  - Include preparation state: "cooked", "raw", "skinless", "boneless"
  - Specify variety: "brown rice" not "rice", "extra virgin olive oil" not "oil"
- Standardize units for consistency:
  - Weight: grams (g) for solids, milliliters (ml) for liquids
  - Count: pieces for whole items (e.g., "1 egg", "2 slices bread")
  - Volume: cups, tablespoons, teaspoons (specify if packed/level)
- Each ingredient must include nutritional data per specified amount:
  - Calories, protein (g), carbs (g), fat (g), fiber (g), sugar (g), sodium (mg)
  - Base calculations on USDA FoodData Central or similar verified sources
  - Account for preparation method (cooked vs raw, etc.)

### Nutrition Guidelines
- Balance macronutrients based on fitness goal:
  - Weight Loss: ~40% carbs, 30% protein, 30% fat.
  - Muscle Gain: ~40% carbs, 35% protein, 25% fat.
  - Maintenance: ~50% carbs, 25% protein, 25% fat.
  - Endurance: ~55% carbs, 20% protein, 25% fat.
  - Strength: ~45% carbs, 30% protein, 25% fat.
- Nutrition ranges per meal:
  - Protein: 10-40g (higher for main meals, lower for snacks)
  - Carbs: 20-80g (higher for breakfast/lunch, moderate for dinner)
  - Fat: 5-30g (distribute evenly across meals)
  - Fiber: 2-10g (aim for 25-35g total daily)
  - Sugar: <10g per meal (natural sugars preferred)
  - Sodium: <800mg per meal (aim for <2300mg daily)
- Ensure variety in flavors, cuisines, and ingredients.
- Adjust portions for weight, activity level, and fitness goal.
- Meals must be practical, using common ingredients and simple techniques.

### JSON Format
{
  "mealDay": {
    "id": "day_$dayIndex",
    "date": "$formattedDate",
    "totalCalories": ${preferences.targetCalories},
    "totalProtein": <sum of meal proteins>,
    "totalCarbs": <sum of meal carbs>,
    "totalFat": <sum of meal fats>,
    "meals": [
      {
        "id": "meal_<unique_id>",
        "name": "<meal_name>",
        "description": "<meal_description>",
        "type": "<breakfast|lunch|dinner|snack>",
        "cuisineType": "<cuisine>",
        "prepTime": <minutes>,
        "cookTime": <minutes>,
        "servings": 1,
        "ingredients": [
          {
            "name": "<precise_ingredient_name>",
            "amount": <amount>,
            "unit": "<unit>",
            "notes": "<preparation_notes>",
            "nutrition": {
              "calories": <calories_per_amount>,
              "protein": <protein_g_per_amount>,
              "carbs": <carbs_g_per_amount>,
              "fat": <fat_g_per_amount>,
              "fiber": <fiber_g_per_amount>,
              "sugar": <sugar_g_per_amount>,
              "sodium": <sodium_mg_per_amount>
            }
          }
        ],
        "instructions": ["<step1>", "<step2>"],
        "nutrition": {
          "calories": <calories>,
          "protein": <grams>,
          "carbs": <grams>,
          "fat": <grams>,
          "fiber": <grams>,
          "sugar": <grams>,
          "sodium": <milligrams>
        },
        "tags": ["<tag1>", "<tag2>"],
        "isVegetarian": <true|false>,
        "isVegan": <true|false>,
        "isGlutenFree": <true|false>,
        "isDairyFree": <true|false>
      }
    ]
  }
}
''';
  }

  /// Build a single day prompt with context from previous days
  static String buildSingleDayPromptWithContext(
    DietPlanPreferences preferences,
    int dayIndex,
    List<MealDay>? previousDays,
  ) {
    String context = '';
    if (previousDays != null && previousDays.isNotEmpty) {
      final previousMeals = previousDays
          .map((day) => day.meals.map((m) => m.name).join(', '))
          .join('; ');
      context = '\n\n### Previous Days Context\n- Previous days\' main dishes: $previousMeals\n- Avoid repeating these dishes. Ensure variety in ingredients, cooking methods, and cuisines.';
    }
    
    return buildSingleDayPrompt(preferences, dayIndex) + context;
  }

  /// Build a detailed prompt for the AI
  static String buildMealPlanPrompt(
    DietPlanPreferences preferences,
    int days,
  ) {
    final bmi = (preferences.weight / ((preferences.height / 100) * (preferences.height / 100))).toStringAsFixed(1);
    
    // Calculate proper dates
    final startDate = DateTime.now();
    final endDate = startDate.add(Duration(days: days - 1));
    final formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
    final formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);

    return '''
You are a professional nutritionist. Generate a $days-day personalized meal plan in JSON format, strictly adhering to the user's dietary restrictions and preferences.

### User Profile
- Age: ${preferences.age} years
- Gender: ${preferences.gender}
- Weight: ${preferences.weight} kg
- Height: ${preferences.height} cm
- BMI: $bmi
- Fitness Goal: ${_getFitnessGoalDescription(preferences.fitnessGoal)}
- Activity Level: ${_getActivityLevelDescription(preferences.activityLevel)}
- Nutrition Goal: ${preferences.nutritionGoal}
- Target Calories: ${preferences.targetCalories}/day

### Nutrition Preferences
- Preferred Cuisines: ${preferences.preferredCuisines.join(', ').isEmpty ? 'Any' : preferences.preferredCuisines.join(', ')}
- Favorite Foods: ${preferences.favoriteFoods.join(', ').isEmpty ? 'None' : preferences.favoriteFoods.join(', ')}
- Foods to Avoid: ${preferences.foodsToAvoid.join(', ').isEmpty ? 'None' : preferences.foodsToAvoid.join(', ')}
- Meal Frequency: ${preferences.mealFrequency} meals/day
- Cheat Day: ${preferences.cheatDay ?? 'None'}
- Weekly Rotation: ${preferences.weeklyRotation ? 'Yes' : 'No'}

### Dietary Restrictions (CRITICAL)
- Restrictions: ${preferences.dietaryRestrictions.join(', ').isEmpty ? 'None' : preferences.dietaryRestrictions.join(', ')}
- Rules:
  - Vegan: No animal products (meat, fish, dairy, eggs, honey).
  - Vegetarian: No meat or fish; dairy and eggs allowed.
  - Gluten-Free: No wheat, barley, rye, or gluten-containing ingredients.
  - Dairy-Free: No milk, cheese, yogurt, or dairy products.
- ALWAYS respect these restrictions. Double-check all ingredients.

### Requirements
- Generate $days days of ${preferences.mealFrequency} meals each (breakfast, lunch, dinner, snacks).
- Total daily calories: ${preferences.targetCalories}.
- Cheat Day: ${preferences.cheatDay != null ? 'On ${preferences.cheatDay}, allow for slightly more indulgent meals while maintaining nutritional balance. Include favorite foods and comfort dishes.' : 'No cheat day specified - maintain consistent healthy eating throughout the week.'}
- Each meal must include:
  - Name: Unique and descriptive.
  - Description: Brief, appealing summary.
  - Ingredients: Detailed list with precise names, amounts, units, and nutritional data per ingredient.
  - Instructions: Clear, step-by-step, practical for home cooking.
  - Nutrition: Calories, protein, carbs, fat, fiber, sugar, sodium (calculated from ingredients).
  - Prep Time, Cook Time: In minutes.
  - Servings: 1.
  - Cuisine Type: From preferred cuisines or varied.
  - Tags: e.g., vegetarian, vegan, gluten-free, based on meal content.
  - Flags: isVegetarian, isVegan, isGlutenFree, isDairyFree (true/false).

### Ingredient Specifications (CRITICAL FOR VERIFICATION)
- Use precise ingredient names that match USDA FoodData Central database:
  - Examples: "chicken breast, raw" not "chicken", "almond flour" not "flour"
  - Include preparation state: "cooked", "raw", "skinless", "boneless"
  - Specify variety: "brown rice" not "rice", "extra virgin olive oil" not "oil"
- Standardize units for consistency:
  - Weight: grams (g) for solids, milliliters (ml) for liquids
  - Count: pieces for whole items (e.g., "1 egg", "2 slices bread")
  - Volume: cups, tablespoons, teaspoons (specify if packed/level)
- Each ingredient must include nutritional data per specified amount:
  - Calories, protein (g), carbs (g), fat (g), fiber (g), sugar (g), sodium (mg)
  - Base calculations on USDA FoodData Central or similar verified sources
  - Account for preparation method (cooked vs raw, etc.)

### Nutrition Guidelines
- Balance macronutrients based on fitness goal:
  - Weight Loss: ~40% carbs, 30% protein, 30% fat.
  - Muscle Gain: ~40% carbs, 35% protein, 25% fat.
  - Maintenance: ~50% carbs, 25% protein, 25% fat.
  - Endurance: ~55% carbs, 20% protein, 25% fat.
  - Strength: ~45% carbs, 30% protein, 25% fat.
- Nutrition ranges per meal:
  - Protein: 10-40g (higher for main meals, lower for snacks)
  - Carbs: 20-80g (higher for breakfast/lunch, moderate for dinner)
  - Fat: 5-30g (distribute evenly across meals)
  - Fiber: 2-10g (aim for 25-35g total daily)
  - Sugar: <10g per meal (natural sugars preferred)
  - Sodium: <800mg per meal (aim for <2300mg daily)
- Ensure variety in flavors, cuisines, and ingredients across days.
- Adjust portions for weight, activity level, and fitness goal.
- Meals must be practical, using common ingredients and simple techniques.
- If weekly rotation is enabled, make each day unique; otherwise, repeat the same day.

### JSON Format
{
  "mealPlan": {
    "title": "Personalized $days-Day Meal Plan",
    "description": "AI-generated meal plan for ${_getFitnessGoalDescription(preferences.fitnessGoal)} and ${preferences.nutritionGoal}",
    "startDate": "$formattedStartDate",
    "endDate": "$formattedEndDate",
    "totalCalories": ${preferences.targetCalories * days},
    "totalProtein": <sum of all meal proteins>,
    "totalCarbs": <sum of all meal carbs>,
    "totalFat": <sum of all meal fats>,
    "dietaryTags": ["${preferences.dietaryRestrictions.join('", "')}"],
    "mealDays": [
      {
        "id": "day_1",
        "date": "$formattedStartDate",
        "totalCalories": ${preferences.targetCalories},
        "totalProtein": <sum of day 1 meal proteins>,
        "totalCarbs": <sum of day 1 meal carbs>,
        "totalFat": <sum of day 1 meal fats>,
        "meals": [
          {
            "id": "meal_<unique_id>",
            "name": "<meal_name>",
            "description": "<meal_description>",
            "type": "<breakfast|lunch|dinner|snack>",
            "cuisineType": "<cuisine>",
            "prepTime": <minutes>,
            "cookTime": <minutes>,
            "servings": 1,
            "ingredients": [
              {
                "name": "<precise_ingredient_name>",
                "amount": <amount>,
                "unit": "<unit>",
                "notes": "<preparation_notes>",
                "nutrition": {
                  "calories": <calories_per_amount>,
                  "protein": <protein_g_per_amount>,
                  "carbs": <carbs_g_per_amount>,
                  "fat": <fat_g_per_amount>,
                  "fiber": <fiber_g_per_amount>,
                  "sugar": <sugar_g_per_amount>,
                  "sodium": <sodium_mg_per_amount>
                }
              }
            ],
            "instructions": ["<step1>", "<step2>"],
            "nutrition": {
              "calories": <calories>,
              "protein": <grams>,
              "carbs": <grams>,
              "fat": <grams>,
              "fiber": <grams>,
              "sugar": <grams>,
              "sodium": <milligrams>
            },
            "tags": ["<tag1>", "<tag2>"],
            "isVegetarian": <true|false>,
            "isVegan": <true|false>,
            "isGlutenFree": <true|false>,
            "isDairyFree": <true|false>
          }
        ]
      }
    ]
  }
}
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