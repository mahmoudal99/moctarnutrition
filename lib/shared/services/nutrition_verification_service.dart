import '../models/meal_model.dart';
import 'usda_api_service.dart';
import 'config_service.dart';

/// Service for verifying nutritional data in meal plans
class NutritionVerificationService {
  /// Verify all ingredients in a meal plan
  static Future<MealPlanVerificationResult> verifyMealPlan(
      MealPlanModel mealPlan) async {
    if (!ConfigService.isUsdaApiEnabled) {
      return MealPlanVerificationResult(
        isVerified: false,
        confidence: 0.0,
        message: 'USDA API not configured',
        verificationDetails: [],
      );
    }

    final verificationDetails = <IngredientVerificationDetail>[];
    int totalIngredients = 0;
    int verifiedIngredients = 0;
    double totalConfidence = 0.0;

    // Verify each meal in the plan
    for (final mealDay in mealPlan.mealDays) {
      for (final meal in mealDay.meals) {
        for (final ingredient in meal.ingredients) {
          totalIngredients++;

          // Extract nutrition data from ingredient if available
          final claimedNutrition = _extractNutritionFromIngredient(ingredient);

          if (claimedNutrition != null) {
            final verification = await USDAApiService.verifyIngredientNutrition(
              ingredient.name,
              ingredient.amount,
              ingredient.unit,
              claimedNutrition,
            );

            verificationDetails.add(IngredientVerificationDetail(
              ingredientName: ingredient.name,
              mealName: meal.name,
              dayIndex: mealDay.id,
              isVerified: verification.isVerified,
              confidence: verification.confidence,
              message: verification.message,
              suggestedCorrection: verification.suggestedCorrection,
              usdaData: verification.usdaData,
              usdaSource: verification.usdaSource,
            ));

            if (verification.isVerified) {
              verifiedIngredients++;
            }
            totalConfidence += verification.confidence;
          } else {
            verificationDetails.add(IngredientVerificationDetail(
              ingredientName: ingredient.name,
              mealName: meal.name,
              dayIndex: mealDay.id,
              isVerified: false,
              confidence: 0.0,
              message: 'No nutritional data available for verification',
              suggestedCorrection: null,
              usdaData: null,
              usdaSource: null,
            ));
          }
        }
      }
    }

    final overallConfidence =
        totalIngredients > 0 ? totalConfidence / totalIngredients : 0.0;
    final verificationRate =
        totalIngredients > 0 ? verifiedIngredients / totalIngredients : 0.0;

    String message;
    if (verificationRate >= 0.8) {
      message =
          'Meal plan verified with ${(overallConfidence * 100).toInt()}% confidence. ${(verificationRate * 100).toInt()}% of ingredients verified.';
    } else if (verificationRate >= 0.6) {
      message =
          'Meal plan mostly verified with ${(overallConfidence * 100).toInt()}% confidence. ${(verificationRate * 100).toInt()}% of ingredients verified. Some adjustments may be needed.';
    } else {
      message =
          'Meal plan verification incomplete. ${(verificationRate * 100).toInt()}% of ingredients verified. Significant adjustments may be needed.';
    }

    return MealPlanVerificationResult(
      isVerified: verificationRate >= 0.7, // 70% threshold
      confidence: overallConfidence,
      message: message,
      verificationDetails: verificationDetails,
    );
  }

  /// Verify a single meal with dietary restriction checking
  static Future<MealVerificationResult> verifyMeal(Meal meal) async {
    if (!ConfigService.isUsdaApiEnabled) {
      return MealVerificationResult(
        isVerified: false,
        confidence: 0.0,
        message: 'USDA API not configured',
        ingredientVerifications: [],
      );
    }

    final ingredientVerifications = <IngredientVerificationDetail>[];
    int totalIngredients = 0;
    int verifiedIngredients = 0;
    double totalConfidence = 0.0;

    // Dietary restriction mappings
    final restrictedIngredients = {
      'Vegan': [
        'meat',
        'fish',
        'dairy',
        'eggs',
        'honey',
        'gelatin',
        'whey',
        'casein'
      ],
      'Vegetarian': ['meat', 'fish', 'gelatin'],
      'Gluten-Free': [
        'wheat',
        'barley',
        'rye',
        'flour',
        'bread',
        'pasta',
        'couscous'
      ],
      'Dairy-Free': [
        'milk',
        'cheese',
        'yogurt',
        'butter',
        'cream',
        'whey',
        'casein'
      ],
      'Nut-Free': [
        'peanuts',
        'almonds',
        'walnuts',
        'cashews',
        'pecans',
        'hazelnuts'
      ],
    };

    for (final ingredient in meal.ingredients) {
      totalIngredients++;

      // Check dietary restrictions first
      String? restrictionViolation;
      RecipeIngredient? suggestedReplacement;

      for (final restriction in meal.dietaryTags ?? []) {
        if (restrictedIngredients[restriction]?.any(
              (r) => ingredient.name.toLowerCase().contains(r),
            ) ==
            true) {
          restrictionViolation = restriction;
          suggestedReplacement =
              _getReplacementIngredient(ingredient.name, restriction);
          break;
        }
      }

      if (restrictionViolation != null) {
        ingredientVerifications.add(IngredientVerificationDetail(
          ingredientName: ingredient.name,
          mealName: meal.name,
          dayIndex: 'single_meal',
          isVerified: false,
          confidence: 0.0,
          message: 'Ingredient violates $restrictionViolation restriction',
          suggestedCorrection: null,
          suggestedReplacement: suggestedReplacement,
          usdaData: null,
          usdaSource: null,
        ));
        continue;
      }

      // Proceed with nutrition verification
      final claimedNutrition = _extractNutritionFromIngredient(ingredient);

      if (claimedNutrition != null) {
        final verification = await USDAApiService.verifyIngredientNutrition(
          ingredient.name,
          ingredient.amount,
          ingredient.unit,
          claimedNutrition,
          dietaryRestrictions: meal.dietaryTags ?? [],
        );

        ingredientVerifications.add(IngredientVerificationDetail(
          ingredientName: ingredient.name,
          mealName: meal.name,
          dayIndex: 'single_meal',
          isVerified: verification.isVerified,
          confidence: verification.confidence,
          message: verification.message,
          suggestedCorrection: verification.suggestedCorrection,
          suggestedReplacement: verification.suggestedReplacement,
          usdaData: verification.usdaData,
          usdaSource: verification.usdaSource,
        ));

        if (verification.isVerified) {
          verifiedIngredients++;
        }
        totalConfidence += verification.confidence;
      } else {
        ingredientVerifications.add(IngredientVerificationDetail(
          ingredientName: ingredient.name,
          mealName: meal.name,
          dayIndex: 'single_meal',
          isVerified: false,
          confidence: 0.0,
          message: 'No nutritional data available for verification',
          suggestedCorrection: null,
          suggestedReplacement: null,
          usdaData: null,
          usdaSource: null,
        ));
      }
    }

    final overallConfidence =
        totalIngredients > 0 ? totalConfidence / totalIngredients : 0.0;
    final verificationRate =
        totalIngredients > 0 ? verifiedIngredients / totalIngredients : 0.0;

    String message;
    if (verificationRate >= 0.8) {
      message =
          'Meal verified with ${(overallConfidence * 100).toInt()}% confidence. ${(verificationRate * 100).toInt()}% of ingredients verified.';
    } else if (verificationRate >= 0.6) {
      message =
          'Meal mostly verified with ${(overallConfidence * 100).toInt()}% confidence. ${(verificationRate * 100).toInt()}% of ingredients verified.';
    } else {
      message =
          'Meal verification incomplete. ${(verificationRate * 100).toInt()}% of ingredients verified.';
    }

    return MealVerificationResult(
      isVerified: verificationRate >= 0.7,
      confidence: overallConfidence,
      message: message,
      ingredientVerifications: ingredientVerifications,
    );
  }

  /// Extract nutrition data from ingredient if available
  static Map<String, double>? _extractNutritionFromIngredient(
      RecipeIngredient ingredient) {
    if (ingredient.nutrition != null) {
      return {
        'calories': ingredient.nutrition!.calories.toDouble(),
        'protein': ingredient.nutrition!.protein,
        'carbs': ingredient.nutrition!.carbs,
        'fat': ingredient.nutrition!.fat,
        'fiber': ingredient.nutrition!.fiber,
        'sugar': ingredient.nutrition!.sugar,
        'sodium': ingredient.nutrition!.sodium,
      };
    }

    return null;
  }

  /// Get replacement ingredient for dietary restriction violations
  static RecipeIngredient? _getReplacementIngredient(
      String ingredientName, String restriction) {
    final replacements = {
      'Vegan': {
        'milk': RecipeIngredient(
          name: 'almond milk',
          amount: 1,
          unit: 'cup',
          nutrition: NutritionInfo(
            calories: 40,
            protein: 1,
            carbs: 2,
            fat: 3,
            fiber: 1,
            sugar: 0,
            sodium: 150,
          ),
        ),
        'cheese': RecipeIngredient(
          name: 'nutritional yeast',
          amount: 2,
          unit: 'tbsp',
          nutrition: NutritionInfo(
            calories: 60,
            protein: 8,
            carbs: 5,
            fat: 1,
            fiber: 4,
            sugar: 0,
            sodium: 5,
          ),
        ),
        'eggs': RecipeIngredient(
          name: 'flax eggs',
          amount: 1,
          unit: 'tbsp',
          nutrition: NutritionInfo(
            calories: 37,
            protein: 1.3,
            carbs: 2,
            fat: 2.9,
            fiber: 1.9,
            sugar: 0.1,
            sodium: 2,
          ),
        ),
      },
      'Gluten-Free': {
        'flour': RecipeIngredient(
          name: 'almond flour',
          amount: 1,
          unit: 'cup',
          nutrition: NutritionInfo(
            calories: 640,
            protein: 24,
            carbs: 24,
            fat: 56,
            fiber: 12,
            sugar: 4,
            sodium: 0,
          ),
        ),
        'bread': RecipeIngredient(
          name: 'gluten-free bread',
          amount: 2,
          unit: 'slices',
          nutrition: NutritionInfo(
            calories: 160,
            protein: 4,
            carbs: 28,
            fat: 4,
            fiber: 2,
            sugar: 2,
            sodium: 300,
          ),
        ),
      },
      'Dairy-Free': {
        'milk': RecipeIngredient(
          name: 'oat milk',
          amount: 1,
          unit: 'cup',
          nutrition: NutritionInfo(
            calories: 120,
            protein: 3,
            carbs: 16,
            fat: 5,
            fiber: 2,
            sugar: 7,
            sodium: 100,
          ),
        ),
        'butter': RecipeIngredient(
          name: 'coconut oil',
          amount: 1,
          unit: 'tbsp',
          nutrition: NutritionInfo(
            calories: 120,
            protein: 0,
            carbs: 0,
            fat: 14,
            fiber: 0,
            sugar: 0,
            sodium: 0,
          ),
        ),
      },
    };

    // Try to find a replacement based on ingredient name
    final ingredientLower = ingredientName.toLowerCase();
    final restrictionReplacements = replacements[restriction];
    if (restrictionReplacements != null) {
      for (final entry in restrictionReplacements.entries) {
        if (ingredientLower.contains(entry.key)) {
          return entry.value;
        }
      }
    }

    return null;
  }

  /// Get verification statistics
  static VerificationStatistics getVerificationStatistics(
      MealPlanVerificationResult result) {
    final totalIngredients = result.verificationDetails.length;
    final verifiedIngredients =
        result.verificationDetails.where((d) => d.isVerified).length;
    final highConfidenceIngredients =
        result.verificationDetails.where((d) => d.confidence >= 0.8).length;
    final lowConfidenceIngredients =
        result.verificationDetails.where((d) => d.confidence < 0.6).length;

    return VerificationStatistics(
      totalIngredients: totalIngredients,
      verifiedIngredients: verifiedIngredients,
      highConfidenceIngredients: highConfidenceIngredients,
      lowConfidenceIngredients: lowConfidenceIngredients,
      verificationRate:
          totalIngredients > 0 ? verifiedIngredients / totalIngredients : 0.0,
      averageConfidence: result.confidence,
    );
  }
}

/// Meal plan verification result
class MealPlanVerificationResult {
  final bool isVerified;
  final double confidence;
  final String message;
  final List<IngredientVerificationDetail> verificationDetails;

  MealPlanVerificationResult({
    required this.isVerified,
    required this.confidence,
    required this.message,
    required this.verificationDetails,
  });
}

/// Meal verification result
class MealVerificationResult {
  final bool isVerified;
  final double confidence;
  final String message;
  final List<IngredientVerificationDetail> ingredientVerifications;

  MealVerificationResult({
    required this.isVerified,
    required this.confidence,
    required this.message,
    required this.ingredientVerifications,
  });
}

/// Ingredient verification detail
class IngredientVerificationDetail {
  final String ingredientName;
  final String mealName;
  final String dayIndex;
  final bool isVerified;
  final double confidence;
  final String message;
  final Map<String, double>? suggestedCorrection;
  final RecipeIngredient?
      suggestedReplacement; // Added for dietary restrictions
  final Map<String, double>? usdaData;
  final String? usdaSource;

  IngredientVerificationDetail({
    required this.ingredientName,
    required this.mealName,
    required this.dayIndex,
    required this.isVerified,
    required this.confidence,
    required this.message,
    this.suggestedCorrection,
    this.suggestedReplacement,
    this.usdaData,
    this.usdaSource,
  });
}

/// Verification statistics
class VerificationStatistics {
  final int totalIngredients;
  final int verifiedIngredients;
  final int highConfidenceIngredients;
  final int lowConfidenceIngredients;
  final double verificationRate;
  final double averageConfidence;

  VerificationStatistics({
    required this.totalIngredients,
    required this.verifiedIngredients,
    required this.highConfidenceIngredients,
    required this.lowConfidenceIngredients,
    required this.verificationRate,
    required this.averageConfidence,
  });
}
