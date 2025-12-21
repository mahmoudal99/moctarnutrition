import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/meal_model.dart';

/// Service for generating AI prompts for meal plan generation
class PromptService {
  /// Compact JSON schema for meal plan generation
  static const String _jsonSchema = '''
{
  "type": "object",
  "properties": {
    "mealDay": {
      "type": "object",
      "properties": {
        "id": {"type": "string"},
        "date": {"type": "string", "format": "date"},
        "meals": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "id": {"type": "string"},
              "name": {"type": "string"},
              "description": {"type": "string"},
              "type": {"type": "string", "enum": ["breakfast", "lunch", "dinner", "snack"]},
              "cuisineType": {"type": "string"},
              "prepTime": {"type": "integer"},
              "cookTime": {"type": "integer"},
              "servings": {"type": "integer"},
              "ingredients": {
                "type": "array",
                "items": {
                  "type": "object",
                  "properties": {
                    "name": {"type": "string"},
                    "amount": {"type": "number"},
                    "unit": {"type": "string"},
                    "notes": {"type": "string"},
                    "nutrition": {
                      "type": "object",
                      "properties": {
                        "calories": {"type": "number"},
                        "protein": {"type": "number"},
                        "carbs": {"type": "number"},
                        "fat": {"type": "number"},
                        "fiber": {"type": "number"},
                        "sugar": {"type": "number"},
                        "sodium": {"type": "number"}
                      },
                      "required": ["calories", "protein", "carbs", "fat"]
                    }
                  },
                  "required": ["name", "amount", "unit", "nutrition"]
                }
              },
              "instructions": {"type": "array", "items": {"type": "string"}},
              "tags": {"type": "array", "items": {"type": "string"}},
              "isVegetarian": {"type": "boolean"},
              "isVegan": {"type": "boolean"},
              "isGlutenFree": {"type": "boolean"},
              "isDairyFree": {"type": "boolean"}
            },
            "required": ["id", "name", "description", "type", "cuisineType", "prepTime", "cookTime", "servings", "ingredients", "instructions", "tags", "isVegetarian", "isVegan", "isGlutenFree", "isDairyFree"]
          }
        }
      },
      "required": ["id", "date", "meals"]
    }
  },
  "required": ["mealDay"]
}
''';

  /// Build a compact prompt for generating a single day
  static String buildSingleDayPrompt(
    DietPlanPreferences preferences,
    int dayIndex,
  ) {
    final dayDate = DateTime.now().add(Duration(days: dayIndex - 1));
    final formattedDate = DateFormat('yyyy-MM-dd').format(dayDate);
    final bmi = (preferences.weight /
            ((preferences.height / 100) * (preferences.height / 100)))
        .toStringAsFixed(1);

    // Determine required meal types based on meal frequency
    final requiredMeals = _getRequiredMealTypes(preferences.mealFrequency);

    // Check if this day is a cheat day
    final dayOfWeek = _getDayOfWeek(dayDate);
    final isCheatDay =
        preferences.cheatDay != null && dayOfWeek == preferences.cheatDay;
    final cheatDayInstructions = isCheatDay
        ? 'CHEAT DAY: Allow slightly more indulgent meals while maintaining nutritional balance.'
        : '';

    return '''
You are a professional nutritionist in Ireland. Generate a meal plan for Day $dayIndex.

**User Profile:**
- Age: ${preferences.age}, Weight: ${preferences.weight}kg, Height: ${preferences.height}cm, BMI: $bmi
- Goal: ${_getFitnessGoalDescription(preferences.fitnessGoal)}
- Activity: ${_getActivityLevelDescription(preferences.activityLevel)}
- Restrictions: ${preferences.dietaryRestrictions.join(', ').isEmpty ? 'None' : preferences.dietaryRestrictions.join(', ')}
- Cuisines: ${preferences.preferredCuisines.join(', ').isEmpty ? 'Any' : preferences.preferredCuisines.join(', ')}
- Avoid: ${preferences.foodsToAvoid.join(', ').isEmpty ? 'None' : preferences.foodsToAvoid.join(', ')}

**Allergies & Intolerances (CRITICAL - NEVER INCLUDE THESE):**
${_getAllergiesInfo(preferences)}

**Meal Timing & Frequency:**
${_getMealTimingInfo(preferences)}

**Batch Cooking Preferences:**
${_getBatchCookingInfo(preferences)}

**Nutrition Targets (CRITICAL - MUST BE RESPECTED):**
- Daily Calories: ${preferences.targetCalories} calories (MUST match within ±5%)
- Daily Protein: ${preferences.targetProtein ?? 'Not specified'} grams (MUST be met)
- Protein Distribution: ${_getProteinDistributionInfo(preferences)}
- Macronutrient Breakdown: ${_getMacroBreakdownInfo(preferences)}

**Requirements:**
- Include exactly ${requiredMeals.length} meals: ${requiredMeals.map((type) => type.name).join(', ')}
- Use precise ingredient names matching USDA database
- Focus on Irish supermarket availability (Lidl, Aldi, Tesco, Spar, SuperValu)
- Each ingredient must include estimated nutrition per specified amount
- **CRITICAL**: Total daily calories MUST equal ${preferences.targetCalories} ±5%
- **CRITICAL**: Total daily protein MUST equal ${preferences.targetProtein ?? 'target'} grams
- **CRITICAL**: NEVER include any ingredients from the allergies list
- Distribute calories and protein across meals as follows:
  - Breakfast: 20-25% of daily calories and protein
  - Lunch: 30-35% of daily calories and protein  
  - Dinner: 30-35% of daily calories and protein
  - Snacks (if any): 10-15% of daily calories and protein
- Each meal's ingredient calories and protein must sum closely to the meal's allocated amounts
- Prioritize protein-rich ingredients to meet the daily protein target
- Ensure macronutrient balance aligns with the calculated targets
- Consider batch cooking preferences when designing recipes
- Avoid arbitrary splits; use the exact nutrition targets provided

**One-Shot Example:**

**Input:** 30-year-old male, 80kg, 180cm, weight loss goal, 2000 cal/day, moderately active, no restrictions, prefers Irish/Italian cuisine, avoids processed foods, 3 meals + 1 snack

**Calorie Distribution Target:** Breakfast ~500 cal (25%), Lunch ~650 cal (32.5%), Dinner ~650 cal (32.5%), Snack ~200 cal (10%)

**Output:**
```json
{
  "mealDay": {
    "id": "day-1",
    "date": "2024-01-15",
    "meals": [
      {
        "id": "breakfast-1",
        "name": "Irish Oatmeal with Berries, Nuts, and Greek Yogurt",
        "description": "Hearty Irish steel-cut oats with fresh berries, mixed nuts, and protein-rich Greek yogurt",
        "type": "breakfast",
        "cuisineType": "irish",
        "prepTime": 10,
        "cookTime": 20,
        "servings": 1,
        "ingredients": [
          {
            "name": "steel cut oats",
            "amount": 60,
            "unit": "g",
            "notes": "Irish steel-cut oats",
            "nutrition": {
              "calories": 216,
              "protein": 7,
              "carbs": 38,
              "fat": 4,
              "fiber": 5,
              "sugar": 1,
              "sodium": 0
            }
          },
          {
            "name": "mixed berries",
            "amount": 100,
            "unit": "g",
            "notes": "Fresh strawberries, blueberries, raspberries",
            "nutrition": {
              "calories": 60,
              "protein": 1,
              "carbs": 15,
              "fat": 0,
              "fiber": 4,
              "sugar": 10,
              "sodium": 0
            }
          },
          {
            "name": "mixed nuts",
            "amount": 25,
            "unit": "g",
            "notes": "Almonds, walnuts, hazelnuts",
            "nutrition": {
              "calories": 150,
              "protein": 5,
              "carbs": 5,
              "fat": 14,
              "fiber": 3,
              "sugar": 1,
              "sodium": 0
            }
          },
          {
            "name": "greek yogurt",
            "amount": 100,
            "unit": "g",
            "notes": "Plain Greek yogurt",
            "nutrition": {
              "calories": 59,
              "protein": 10,
              "carbs": 3,
              "fat": 0,
              "fiber": 0,
              "sugar": 3,
              "sodium": 36
            }
          },
          {
            "name": "honey",
            "amount": 10,
            "unit": "g",
            "notes": "Natural honey for sweetness",
            "nutrition": {
              "calories": 30,
              "protein": 0,
              "carbs": 8,
              "fat": 0,
              "fiber": 0,
              "sugar": 8,
              "sodium": 0
            }
          }
        ],
        "instructions": [
          "Bring 240ml water to boil in a saucepan",
          "Add steel-cut oats and reduce heat to low",
          "Simmer for 15-20 minutes, stirring occasionally",
          "Top with fresh berries, mixed nuts, Greek yogurt, and honey",
          "Serve hot"
        ],
        "tags": ["breakfast", "healthy", "fiber-rich", "protein"],
        "isVegetarian": true,
        "isVegan": false,
        "isGlutenFree": false,
        "isDairyFree": false
      },
      {
        "id": "lunch-1",
        "name": "Grilled Chicken Salad with Irish Cheddar and Quinoa",
        "description": "Fresh mixed greens with grilled chicken breast, Irish cheddar, and protein-rich quinoa",
        "type": "lunch",
        "cuisineType": "irish",
        "prepTime": 15,
        "cookTime": 15,
        "servings": 1,
        "ingredients": [
          {
            "name": "chicken breast",
            "amount": 150,
            "unit": "g",
            "notes": "Skinless, boneless chicken breast",
            "nutrition": {
              "calories": 250,
              "protein": 45,
              "carbs": 0,
              "fat": 5,
              "fiber": 0,
              "sugar": 0,
              "sodium": 100
            }
          },
          {
            "name": "quinoa",
            "amount": 60,
            "unit": "g",
            "notes": "Cooked quinoa",
            "nutrition": {
              "calories": 222,
              "protein": 8,
              "carbs": 40,
              "fat": 4,
              "fiber": 5,
              "sugar": 1,
              "sodium": 10
            }
          },
          {
            "name": "mixed salad greens",
            "amount": 80,
            "unit": "g",
            "notes": "Lettuce, spinach, rocket",
            "nutrition": {
              "calories": 20,
              "protein": 3,
              "carbs": 4,
              "fat": 0,
              "fiber": 3,
              "sugar": 1,
              "sodium": 13
            }
          },
          {
            "name": "irish cheddar cheese",
            "amount": 30,
            "unit": "g",
            "notes": "Mature Irish cheddar",
            "nutrition": {
              "calories": 120,
              "protein": 8,
              "carbs": 0,
              "fat": 10,
              "fiber": 0,
              "sugar": 0,
              "sodium": 200
            }
          },
          {
            "name": "olive oil",
            "amount": 15,
            "unit": "ml",
            "notes": "Extra virgin olive oil for dressing",
            "nutrition": {
              "calories": 135,
              "protein": 0,
              "carbs": 0,
              "fat": 15,
              "fiber": 0,
              "sugar": 0,
              "sodium": 0
            }
          }
        ],
        "instructions": [
          "Cook quinoa according to package instructions",
          "Season chicken breast with salt and pepper",
          "Grill chicken for 6-7 minutes per side until cooked through",
          "Wash and prepare mixed greens",
          "Slice Irish cheddar into small cubes",
          "Combine greens, quinoa, cheese, and sliced chicken",
          "Drizzle with olive oil and serve"
        ],
        "tags": ["lunch", "protein-rich", "quinoa", "balanced"],
        "isVegetarian": false,
        "isVegan": false,
        "isGlutenFree": true,
        "isDairyFree": false
      },
      {
        "id": "dinner-1",
        "name": "Baked Salmon with Roasted Vegetables and Brown Rice",
        "description": "Atlantic salmon with seasonal Irish vegetables and whole grain brown rice",
        "type": "dinner",
        "cuisineType": "irish",
        "prepTime": 15,
        "cookTime": 30,
        "servings": 1,
        "ingredients": [
          {
            "name": "atlantic salmon fillet",
            "amount": 180,
            "unit": "g",
            "notes": "Fresh Atlantic salmon",
            "nutrition": {
              "calories": 336,
              "protein": 41,
              "carbs": 0,
              "fat": 19,
              "fiber": 0,
              "sugar": 0,
              "sodium": 72
            }
          },
          {
            "name": "brown rice",
            "amount": 80,
            "unit": "g",
            "notes": "Cooked brown rice",
            "nutrition": {
              "calories": 296,
              "protein": 6,
              "carbs": 62,
              "fat": 2,
              "fiber": 3,
              "sugar": 1,
              "sodium": 5
            }
          },
          {
            "name": "carrots",
            "amount": 100,
            "unit": "g",
            "notes": "Fresh Irish carrots",
            "nutrition": {
              "calories": 40,
              "protein": 1,
              "carbs": 9,
              "fat": 0,
              "fiber": 3,
              "sugar": 5,
              "sodium": 30
            }
          },
          {
            "name": "broccoli",
            "amount": 100,
            "unit": "g",
            "notes": "Fresh broccoli florets",
            "nutrition": {
              "calories": 35,
              "protein": 3,
              "carbs": 7,
              "fat": 0,
              "fiber": 3,
              "sugar": 2,
              "sodium": 30
            }
          },
          {
            "name": "olive oil",
            "amount": 10,
            "unit": "ml",
            "notes": "For roasting vegetables",
            "nutrition": {
              "calories": 90,
              "protein": 0,
              "carbs": 0,
              "fat": 10,
              "fiber": 0,
              "sugar": 0,
              "sodium": 0
            }
          }
        ],
        "instructions": [
          "Cook brown rice according to package instructions",
          "Preheat oven to 200°C",
          "Cut carrots and broccoli into uniform pieces",
          "Toss vegetables with olive oil, salt, and pepper",
          "Place salmon on a baking sheet",
          "Arrange vegetables around salmon",
          "Bake for 20-25 minutes until salmon is flaky",
          "Serve salmon and vegetables over brown rice"
        ],
        "tags": ["dinner", "omega-3", "vegetables", "whole-grain"],
        "isVegetarian": false,
        "isVegan": false,
        "isGlutenFree": true,
        "isDairyFree": true
      },
      {
        "id": "snack-1",
        "name": "Apple with Almond Butter and Greek Yogurt",
        "description": "Fresh Irish apple with natural almond butter and protein-rich Greek yogurt",
        "type": "snack",
        "cuisineType": "irish",
        "prepTime": 5,
        "cookTime": 0,
        "servings": 1,
        "ingredients": [
          {
            "name": "apple",
            "amount": 150,
            "unit": "g",
            "notes": "Fresh Irish apple",
            "nutrition": {
              "calories": 80,
              "protein": 0,
              "carbs": 20,
              "fat": 0,
              "fiber": 4,
              "sugar": 15,
              "sodium": 0
            }
          },
          {
            "name": "almond butter",
            "amount": 20,
            "unit": "g",
            "notes": "Natural almond butter",
            "nutrition": {
              "calories": 120,
              "protein": 4,
              "carbs": 4,
              "fat": 11,
              "fiber": 2,
              "sugar": 1,
              "sodium": 0
            }
          },
          {
            "name": "greek yogurt",
            "amount": 50,
            "unit": "g",
            "notes": "Plain Greek yogurt",
            "nutrition": {
              "calories": 30,
              "protein": 5,
              "carbs": 2,
              "fat": 0,
              "fiber": 0,
              "sugar": 2,
              "sodium": 18
            }
          }
        ],
        "instructions": [
          "Wash and slice apple into wedges",
          "Serve with almond butter and Greek yogurt",
          "Enjoy as a healthy protein-rich snack"
        ],
        "tags": ["snack", "fiber", "healthy fats", "protein"],
        "isVegetarian": true,
        "isVegan": false,
        "isGlutenFree": true,
        "isDairyFree": false
      }
    ]
  }
}
```

$cheatDayInstructions

**JSON Schema:**
$_jsonSchema

Respond with JSON only. No commentary.
''';
  }

  /// Build a compact prompt for generating a single day with context
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
      context =
          '\n**Previous Days:** $previousMeals - Ensure variety in ingredients and cuisines.';
    }

    return buildSingleDayPrompt(preferences, dayIndex) + context;
  }

  /// Build a compact prompt for multi-day meal plans
  static String buildMealPlanPrompt(
    DietPlanPreferences preferences,
    int days,
  ) {
    final bmi = (preferences.weight /
            ((preferences.height / 100) * (preferences.height / 100)))
        .toStringAsFixed(1);

    // Calculate proper dates
    final startDate = DateTime.now();
    final endDate = startDate.add(Duration(days: days - 1));
    final formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
    final formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);

    // Determine required meal types based on meal frequency
    final requiredMeals = _getRequiredMealTypes(preferences.mealFrequency);

    return '''
You are a professional nutritionist in Ireland. Generate a $days-day meal plan.

**User Profile:**
- Age: ${preferences.age}, Weight: ${preferences.weight}kg, Height: ${preferences.height}cm, BMI: $bmi
- Goal: ${_getFitnessGoalDescription(preferences.fitnessGoal)}
- Activity: ${_getActivityLevelDescription(preferences.activityLevel)}
- Restrictions: ${preferences.dietaryRestrictions.join(', ').isEmpty ? 'None' : preferences.dietaryRestrictions.join(', ')}
- Cuisines: ${preferences.preferredCuisines.join(', ').isEmpty ? 'Any' : preferences.preferredCuisines.join(', ')}
- Avoid: ${preferences.foodsToAvoid.join(', ').isEmpty ? 'None' : preferences.foodsToAvoid.join(', ')}
- Cheat Day: ${preferences.cheatDay ?? 'None'}
- Weekly Rotation: ${preferences.weeklyRotation ? 'Yes' : 'No'}

**Allergies & Intolerances (CRITICAL - NEVER INCLUDE THESE):**
${_getAllergiesInfo(preferences)}

**Meal Timing & Frequency:**
${_getMealTimingInfo(preferences)}

**Batch Cooking Preferences:**
${_getBatchCookingInfo(preferences)}

**Nutrition Targets (CRITICAL - MUST BE RESPECTED):**
- Daily Calories: ${preferences.targetCalories} calories (MUST match within ±5%)
- Daily Protein: ${preferences.targetProtein ?? 'Not specified'} grams (MUST be met)
- Protein Distribution: ${_getProteinDistributionInfo(preferences)}
- Macronutrient Breakdown: ${_getMacroBreakdownInfo(preferences)}

**Requirements:**
- Each day: exactly ${requiredMeals.length} meals (${requiredMeals.map((type) => type.name).join(', ')})
- Use precise ingredient names matching USDA database
- Focus on Irish supermarket availability
- Each ingredient must include estimated nutrition per specified amount
- **CRITICAL**: Each day's total calories MUST equal ${preferences.targetCalories} ±5%
- **CRITICAL**: Each day's total protein MUST equal ${preferences.targetProtein ?? 'target'} grams
- **CRITICAL**: NEVER include any ingredients from the allergies list
- Distribute calories and protein across meals as follows:
  - Breakfast: 20-25% of daily calories and protein
  - Lunch: 30-35% of daily calories and protein  
  - Dinner: 30-35% of daily calories and protein
  - Snacks (if any): 10-15% of daily calories and protein
- Each meal's ingredient calories and protein must sum closely to the meal's allocated amounts
- Prioritize protein-rich ingredients to meet the daily protein target
- Ensure macronutrient balance aligns with the calculated targets
- Consider batch cooking preferences when designing recipes
- Avoid arbitrary splits; use the exact nutrition targets provided
- ${preferences.weeklyRotation ? 'Make each day unique' : 'Repeat same day structure'}

**JSON Schema:**
{
  "type": "object",
  "properties": {
    "mealPlan": {
      "type": "object",
      "properties": {
        "title": {"type": "string"},
        "description": {"type": "string"},
        "startDate": {"type": "string", "format": "date"},
        "endDate": {"type": "string", "format": "date"},
        "dietaryTags": {"type": "array", "items": {"type": "string"}},
        "mealDays": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "id": {"type": "string"},
              "date": {"type": "string", "format": "date"},
              "meals": {
                "type": "array",
                "items": {
                  "type": "object",
                  "properties": {
                    "id": {"type": "string"},
                    "name": {"type": "string"},
                    "description": {"type": "string"},
                    "type": {"type": "string", "enum": ["breakfast", "lunch", "dinner", "snack"]},
                    "cuisineType": {"type": "string"},
                    "prepTime": {"type": "integer"},
                    "cookTime": {"type": "integer"},
                    "servings": {"type": "integer"},
                    "ingredients": {
                      "type": "array",
                      "items": {
                        "type": "object",
                        "properties": {
                          "name": {"type": "string"},
                          "amount": {"type": "number"},
                          "unit": {"type": "string"},
                          "notes": {"type": "string"},
                          "nutrition": {
                            "type": "object",
                            "properties": {
                              "calories": {"type": "number"},
                              "protein": {"type": "number"},
                              "carbs": {"type": "number"},
                              "fat": {"type": "number"},
                              "fiber": {"type": "number"},
                              "sugar": {"type": "number"},
                              "sodium": {"type": "number"}
                            },
                            "required": ["calories", "protein", "carbs", "fat"]
                          }
                        },
                        "required": ["name", "amount", "unit", "nutrition"]
                      }
                    },
                    "instructions": {"type": "array", "items": {"type": "string"}},
                    "tags": {"type": "array", "items": {"type": "string"}},
                    "isVegetarian": {"type": "boolean"},
                    "isVegan": {"type": "boolean"},
                    "isGlutenFree": {"type": "boolean"},
                    "isDairyFree": {"type": "boolean"}
                  },
                  "required": ["id", "name", "description", "type", "cuisineType", "prepTime", "cookTime", "servings", "ingredients", "instructions", "tags", "isVegetarian", "isVegan", "isGlutenFree", "isDairyFree"]
                }
              }
            },
            "required": ["id", "date", "meals"]
          }
        }
      },
      "required": ["title", "description", "startDate", "endDate", "dietaryTags", "mealDays"]
    }
  },
  "required": ["mealPlan"]
}

Respond with JSON only. No commentary.
''';
  }

  /// Helper methods for prompt building
  static String _getFitnessGoalDescription(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return 'Weight Loss';
      case FitnessGoal.weightGain:
        return 'Weight Gain';
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
        return 'Sedentary';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
      case ActivityLevel.extremelyActive:
        return 'Extremely Active';
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

  /// Helper to get the day of the week for a given date
  static String _getDayOfWeek(DateTime date) {
    switch (date.weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  /// Helper to get protein distribution information
  static String _getProteinDistributionInfo(DietPlanPreferences preferences) {
    if (preferences.proteinTargets == null) {
      return 'Not specified';
    }

    final mealDistribution =
        preferences.proteinTargets!['mealDistribution'] as List<dynamic>?;
    if (mealDistribution == null || mealDistribution.isEmpty) {
      return 'Not specified';
    }

    final distribution = mealDistribution.map((meal) {
      final name = meal['mealName'] ?? 'Unknown';
      final protein = meal['proteinGrams'] ?? 0;
      return '$name: ${protein}g';
    }).join(', ');

    return distribution;
  }

  /// Helper to get macro breakdown information
  static String _getMacroBreakdownInfo(DietPlanPreferences preferences) {
    if (preferences.calorieTargets == null) {
      return 'Not specified';
    }

    final macros =
        preferences.calorieTargets!['macros'] as Map<String, dynamic>?;
    if (macros == null) {
      return 'Not specified';
    }

    final protein = macros['protein'] as Map<String, dynamic>?;
    final carbs = macros['carbs'] as Map<String, dynamic>?;
    final fat = macros['fat'] as Map<String, dynamic>?;

    if (protein == null || carbs == null || fat == null) {
      return 'Not specified';
    }

    return 'Protein: ${protein['grams']}g (${protein['percentage']}%), Carbs: ${carbs['grams']}g (${carbs['percentage']}%), Fat: ${fat['grams']}g (${fat['percentage']}%)';
  }

  /// Helper to get allergies information
  static String _getAllergiesInfo(DietPlanPreferences preferences) {
    if (preferences.allergies == null || preferences.allergies!.isEmpty) {
      return 'None specified';
    }

    final allergyList = preferences.allergies!.map((allergy) {
      final name = allergy['name'] as String? ?? 'Unknown';
      final severity = allergy['severity'] as String? ?? 'mild';
      final notes = allergy['notes'] as String?;

      String info = '$name ($severity)';
      if (notes != null && notes.isNotEmpty) {
        info += ' - $notes';
      }
      return info;
    }).join(', ');

    return allergyList;
  }

  /// Helper to get meal timing information
  static String _getMealTimingInfo(DietPlanPreferences preferences) {
    if (preferences.mealTimingPreferences == null) {
      return 'Not specified';
    }

    final timing = preferences.mealTimingPreferences!;
    final mealFrequency = timing['mealFrequency'] as String? ?? 'Not specified';
    final fastingType = timing['fastingType'] as String?;
    final breakfastTime = timing['breakfastTime'] as String?;
    final lunchTime = timing['lunchTime'] as String?;
    final dinnerTime = timing['dinnerTime'] as String?;
    final snackTimes = timing['snackTimes'] as List<dynamic>?;
    final customNotes = timing['customNotes'] as String?;

    final List<String> info = [];
    info.add('Frequency: $mealFrequency');

    if (fastingType != null && fastingType != 'none') {
      info.add('Fasting: $fastingType');
    }

    if (breakfastTime != null) {
      info.add('Breakfast: $breakfastTime');
    }
    if (lunchTime != null) {
      info.add('Lunch: $lunchTime');
    }
    if (dinnerTime != null) {
      info.add('Dinner: $dinnerTime');
    }
    if (snackTimes != null && snackTimes.isNotEmpty) {
      info.add('Snacks: ${snackTimes.join(', ')}');
    }
    if (customNotes != null && customNotes.isNotEmpty) {
      info.add('Notes: $customNotes');
    }

    return info.join(', ');
  }

  /// Helper to get batch cooking information
  static String _getBatchCookingInfo(DietPlanPreferences preferences) {
    if (preferences.batchCookingPreferences == null) {
      return 'Not specified';
    }

    final batchCooking = preferences.batchCookingPreferences!;
    final frequency = batchCooking['frequency'] as String? ?? 'Not specified';
    final batchSize = batchCooking['batchSize'] as String? ?? 'Not specified';
    final preferLeftovers = batchCooking['preferLeftovers'] as bool? ?? true;
    final customNotes = batchCooking['customNotes'] as String?;

    final List<String> info = [];
    info.add('Frequency: $frequency');
    info.add('Batch Size: $batchSize');
    info.add('Leftovers: ${preferLeftovers ? 'Yes' : 'No'}');

    if (customNotes != null && customNotes.isNotEmpty) {
      info.add('Notes: $customNotes');
    }

    return info.join(', ');
  }
}
