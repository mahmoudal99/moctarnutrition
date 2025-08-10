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
                      "required": ["calories", "protein", "carbs", "fat", "fiber", "sugar", "sodium"]
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
    final bmi = (preferences.weight / ((preferences.height / 100) * (preferences.height / 100))).toStringAsFixed(1);

    // Determine required meal types based on meal frequency
    final requiredMeals = _getRequiredMealTypes(preferences.mealFrequency);

    // Check if this day is a cheat day
    final dayOfWeek = _getDayOfWeek(dayDate);
    final isCheatDay = preferences.cheatDay != null && dayOfWeek == preferences.cheatDay;
    final cheatDayInstructions = isCheatDay 
        ? 'CHEAT DAY: Allow slightly more indulgent meals while maintaining nutritional balance.'
        : '';

    return '''
You are a professional nutritionist in Ireland. Generate a meal plan for Day $dayIndex.

**User Profile:**
- Age: ${preferences.age}, Weight: ${preferences.weight}kg, Height: ${preferences.height}cm, BMI: $bmi
- Goal: ${_getFitnessGoalDescription(preferences.fitnessGoal)}, Target: ${preferences.targetCalories} cal/day
- Activity: ${_getActivityLevelDescription(preferences.activityLevel)}
- Restrictions: ${preferences.dietaryRestrictions.join(', ').isEmpty ? 'None' : preferences.dietaryRestrictions.join(', ')}
- Cuisines: ${preferences.preferredCuisines.join(', ').isEmpty ? 'Any' : preferences.preferredCuisines.join(', ')}
- Avoid: ${preferences.foodsToAvoid.join(', ').isEmpty ? 'None' : preferences.foodsToAvoid.join(', ')}

**Requirements:**
- Include exactly ${requiredMeals.length} meals: ${requiredMeals.map((type) => type.name).join(', ')}
- Use precise ingredient names matching USDA database
- Focus on Irish supermarket availability (Lidl, Aldi, Tesco, Spar, SuperValu)
- Each ingredient must include estimated nutrition per specified amount
- Do NOT calculate meal or day totals
${isCheatDay ? '- $cheatDayInstructions' : ''}

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
      context = '\n**Previous Days:** $previousMeals - Ensure variety in ingredients and cuisines.';
    }
    
    return buildSingleDayPrompt(preferences, dayIndex) + context;
  }

  /// Build a compact prompt for multi-day meal plans
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

    // Determine required meal types based on meal frequency
    final requiredMeals = _getRequiredMealTypes(preferences.mealFrequency);

    return '''
You are a professional nutritionist in Ireland. Generate a $days-day meal plan.

**User Profile:**
- Age: ${preferences.age}, Weight: ${preferences.weight}kg, Height: ${preferences.height}cm, BMI: $bmi
- Goal: ${_getFitnessGoalDescription(preferences.fitnessGoal)}, Target: ${preferences.targetCalories} cal/day
- Activity: ${_getActivityLevelDescription(preferences.activityLevel)}
- Restrictions: ${preferences.dietaryRestrictions.join(', ').isEmpty ? 'None' : preferences.dietaryRestrictions.join(', ')}
- Cuisines: ${preferences.preferredCuisines.join(', ').isEmpty ? 'Any' : preferences.preferredCuisines.join(', ')}
- Avoid: ${preferences.foodsToAvoid.join(', ').isEmpty ? 'None' : preferences.foodsToAvoid.join(', ')}
- Cheat Day: ${preferences.cheatDay ?? 'None'}
- Weekly Rotation: ${preferences.weeklyRotation ? 'Yes' : 'No'}

**Requirements:**
- Each day: exactly ${requiredMeals.length} meals (${requiredMeals.map((type) => type.name).join(', ')})
- Use precise ingredient names matching USDA database
- Focus on Irish supermarket availability
- Each ingredient must include estimated nutrition per specified amount
- Do NOT calculate meal, day, or plan totals
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
                            "required": ["calories", "protein", "carbs", "fat", "fiber", "sugar", "sodium"]
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
    
    // Add snacks based on meal frequency string
    if (mealFrequency.contains('snack') || mealFrequency.contains('4') || mealFrequency.contains('5')) {
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
} 