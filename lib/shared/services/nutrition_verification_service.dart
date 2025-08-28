import 'package:logger/logger.dart';
import '../models/meal_model.dart';
import 'ingredient_name_mapper_service.dart';
import 'usda_client_service.dart';
import 'unit_converter_service.dart';
import 'nutrition_comparison_service.dart';

/// Main service that orchestrates nutrition verification using microservices
class NutritionVerificationService {
  static final _logger = Logger();
  static final _nutritionCache = <String, Map<String, double>>{};

  /// Verify ingredient nutritional data against USDA database
  static Future<NutritionVerificationResult> verifyIngredientNutrition(
    String ingredientName,
    double amount,
    String unit,
    Map<String, double> claimedNutrition, {
    List<String> dietaryRestrictions = const [],
    String preparationState = 'unspecified',
  }) async {
    try {
      _logger.i(
          'Starting nutrition verification for $ingredientName: $amount $unit');

      // Validate input
      if (amount <= 0 || amount > 1000) {
        _logger.w(
            'Invalid amount $amount for $ingredientName, defaulting to 100g');
        amount = 100.0;
        unit = 'grams';
      }

      // Check dietary restrictions
      final restrictionCheck =
          await _checkDietaryRestrictions(ingredientName, dietaryRestrictions);
      if (restrictionCheck != null) {
        return restrictionCheck;
      }

      // Check cache
      final cacheKey = '$ingredientName-$amount-$unit-$preparationState';
      if (_nutritionCache.containsKey(cacheKey)) {
        _logger.i('Using cached nutrition data for $ingredientName');
        final usdaData = _nutritionCache[cacheKey]!;
        final comparison = NutritionComparisonService.compareNutrition(
            claimedNutrition, usdaData);
        return NutritionVerificationResult(
          isVerified: comparison.isWithinTolerance,
          confidence: comparison.confidence,
          message: comparison.message,
          suggestedCorrection: comparison.suggestedCorrection,
          suggestedReplacement: null,
          usdaData: usdaData,
          usdaSource: 'USDA FoodData Central (Cached)',
        );
      }

      // Step 1: Map ingredient name to USDA-compatible search term
      final usdaSearchTerm =
          await IngredientNameMapperService.mapToUSDASearchTerm(ingredientName);
      _logger
          .i('Mapped "$ingredientName" to USDA search term: "$usdaSearchTerm"');

      // Step 2: Search USDA with the mapped name
      final searchResults = await USDAClientService.searchFood(usdaSearchTerm);
      if (searchResults.isEmpty) {
        _logger.w(
            'No USDA data found for $usdaSearchTerm, attempting Open Food Facts fallback');
        final fallbackNutrition =
            await _getOpenFoodFactsNutrition(ingredientName, amount, unit);
        return NutritionVerificationResult(
          isVerified: false,
          confidence: 0.0,
          message: 'Ingredient not found in USDA database',
          suggestedCorrection: fallbackNutrition,
          suggestedReplacement: null,
          usdaData: null,
          usdaSource: null,
        );
      }

      // Step 3: Select best match from USDA results
      final bestMatch = _selectBestMatch(searchResults, usdaSearchTerm);
      _logger.i('Selected best USDA match: ${bestMatch.description}');

      // Step 4: Get detailed nutrition data from USDA
      final foodDetails =
          await USDAClientService.getFoodDetails(bestMatch.fdcId);
      if (foodDetails == null) {
        _logger.w(
            'Could not retrieve details for $usdaSearchTerm (FDC ID: ${bestMatch.fdcId})');
        final fallbackNutrition =
            await _getOpenFoodFactsNutrition(ingredientName, amount, unit);
        return NutritionVerificationResult(
          isVerified: false,
          confidence: 0.0,
          message: 'Could not retrieve nutritional details',
          suggestedCorrection: fallbackNutrition,
          suggestedReplacement: null,
          usdaData: null,
          usdaSource: null,
        );
      }

      // Step 5: Convert amount to grams
      final amountInGrams = await UnitConverterService.convertToGrams(
        amount,
        unit,
        ingredientName,
        foodDetails.foodPortions,
      );

      // Step 6: Calculate expected nutrition for the amount
      final expectedNutrition =
          NutritionComparisonService.calculateNutritionForAmount(
        foodDetails.nutritionPer100g,
        amountInGrams,
        unit,
      );

      // Step 7: Validate nutrition data
      if (!NutritionComparisonService.validateNutritionData(
          expectedNutrition, ingredientName)) {
        _logger.w('Invalid nutrition data for $ingredientName, using fallback');
        final fallbackNutrition =
            await _getOpenFoodFactsNutrition(ingredientName, amount, unit);
        return NutritionVerificationResult(
          isVerified: false,
          confidence: 0.0,
          message: 'Invalid nutrition data from USDA',
          suggestedCorrection: fallbackNutrition,
          suggestedReplacement: null,
          usdaData: expectedNutrition,
          usdaSource: foodDetails.description,
        );
      }

      // Step 8: Cache the result
      _nutritionCache[cacheKey] = expectedNutrition;

      // Step 9: Compare claimed vs expected nutrition
      final comparison = NutritionComparisonService.compareNutrition(
          claimedNutrition, expectedNutrition);

      // Step 10: Sanity check for unreasonable values
      if (comparison.suggestedCorrection != null) {
        final calorieDiff =
            ((comparison.suggestedCorrection!['calories'] ?? 0.0) -
                    (claimedNutrition['calories'] ?? 0.0))
                .abs();
        if (calorieDiff > (claimedNutrition['calories'] ?? 100.0) * 0.5 ||
            comparison.confidence < 0.8) {
          _logger.w(
              'Rejected correction for $ingredientName: large discrepancy or low confidence (${comparison.confidence})');
          return NutritionVerificationResult(
            isVerified: false,
            confidence: comparison.confidence,
            message:
                'Unreasonable correction or low confidence. Manual review required.',
            suggestedCorrection: null,
            suggestedReplacement: null,
            usdaData: expectedNutrition,
            usdaSource: foodDetails.description,
          );
        }
      }

      _logger.i(
          'Verified $ingredientName: $amount $unit, USDA match: ${foodDetails.description}, Confidence: ${comparison.confidence}');

      return NutritionVerificationResult(
        isVerified: comparison.isWithinTolerance,
        confidence: comparison.confidence,
        message: comparison.message,
        suggestedCorrection: comparison.suggestedCorrection,
        suggestedReplacement: null,
        usdaData: expectedNutrition,
        usdaSource: foodDetails.description,
      );
    } catch (e) {
      _logger.e('Nutrition verification error for $ingredientName: $e');
      final fallbackNutrition =
          await _getOpenFoodFactsNutrition(ingredientName, amount, unit);
      return NutritionVerificationResult(
        isVerified: false,
        confidence: 0.0,
        message: 'Verification failed: $e',
        suggestedCorrection: fallbackNutrition,
        suggestedReplacement: null,
        usdaData: null,
        usdaSource: null,
      );
    }
  }

  /// Verify a single meal with dietary restriction checking
  static Future<MealVerificationResult> verifyMeal(Meal meal) async {
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
              await _getReplacementIngredient(ingredient.name, restriction);
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
        final verification = await verifyIngredientNutrition(
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

  /// Select the best USDA search result
  static USDASearchResult _selectBestMatch(
      List<USDASearchResult> results, String query) {
    final queryLower = query.toLowerCase();
    return results.reduce((a, b) {
      int scoreA = 0;
      int scoreB = 0;

      // Prioritize Foundation or Survey foods
      if (a.dataType == 'Foundation' || a.dataType == 'Survey') scoreA += 20;
      if (b.dataType == 'Foundation' || b.dataType == 'Survey') scoreB += 20;

      // Prioritize exact or close name matches
      final aMatchScore =
          _calculateMatchScore(queryLower, a.description.toLowerCase());
      final bMatchScore =
          _calculateMatchScore(queryLower, b.description.toLowerCase());
      scoreA += aMatchScore;
      scoreB += bMatchScore;

      // Prefer non-branded items
      if (a.brandOwner.isEmpty) scoreA += 10;
      if (b.brandOwner.isEmpty) scoreB += 10;

      // Match preparation state
      if (queryLower.contains('cooked') &&
          a.description.toLowerCase().contains('cooked')) scoreA += 15;
      if (queryLower.contains('cooked') &&
          b.description.toLowerCase().contains('cooked')) scoreB += 15;
      if (queryLower.contains('raw') &&
          a.description.toLowerCase().contains('raw')) scoreA += 15;
      if (queryLower.contains('raw') &&
          b.description.toLowerCase().contains('raw')) scoreB += 15;

      // Penalize processed foods
      if (a.description.toLowerCase().contains('instant') ||
          a.description.toLowerCase().contains('flavored')) scoreA -= 10;
      if (b.description.toLowerCase().contains('instant') ||
          b.description.toLowerCase().contains('flavored')) scoreB -= 10;

      // Specific ingredient matching - heavily penalize wrong categories
      if (queryLower.contains('sesame') &&
          !a.description.toLowerCase().contains('sesame')) scoreA -= 50;
      if (queryLower.contains('sesame') &&
          !b.description.toLowerCase().contains('sesame')) scoreB -= 50;
      if (queryLower.contains('oat') &&
          !a.description.toLowerCase().contains('oat')) scoreA -= 50;
      if (queryLower.contains('oat') &&
          !b.description.toLowerCase().contains('oat')) scoreB -= 50;
      if (queryLower.contains('tofu') &&
          !a.description.toLowerCase().contains('tofu')) scoreA -= 50;
      if (queryLower.contains('tofu') &&
          !b.description.toLowerCase().contains('tofu')) scoreB -= 50;

      _logger.i(
          'Match scores for $query: ${a.description} ($scoreA) vs ${b.description} ($scoreB)');
      return scoreA >= scoreB ? a : b;
    });
  }

  /// Calculate match score for ingredient name using word overlap
  static int _calculateMatchScore(String query, String description) {
    int score = 0;
    final queryWords = query.split(' ').map((w) => w.trim()).toList();
    final descWords =
        description.split(' ').map((w) => w.trim().toLowerCase()).toList();

    for (final word in queryWords) {
      if (descWords.contains(word.toLowerCase())) {
        score += 15; // Exact word match
      } else if (descWords.any((dw) =>
          dw.contains(word.toLowerCase()) || word.toLowerCase().contains(dw))) {
        score += 7; // Partial match
      }
    }
    return score;
  }

  /// Check dietary restrictions and suggest replacements
  static Future<NutritionVerificationResult?> _checkDietaryRestrictions(
    String ingredientName,
    List<String> dietaryRestrictions,
  ) async {
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

    for (final restriction in dietaryRestrictions) {
      if (restrictedIngredients[restriction]
              ?.any((r) => ingredientName.toLowerCase().contains(r)) ==
          true) {
        final replacement =
            await _getReplacementIngredient(ingredientName, restriction);
        return NutritionVerificationResult(
          isVerified: false,
          confidence: 0.0,
          message: 'Ingredient violates $restriction restriction',
          suggestedCorrection: null,
          suggestedReplacement: replacement,
          usdaData: null,
          usdaSource: null,
        );
      }
    }
    return null;
  }

  /// Get replacement ingredient for dietary restrictions
  static Future<RecipeIngredient?> _getReplacementIngredient(
      String ingredientName, String restriction) async {
    // Use Open Food Facts to find suitable replacements
    final replacementQueries = {
      'Vegan': {
        'milk': ['almond milk', 'soy milk', 'oat milk'],
        'cheese': ['nutritional yeast', 'vegan cheese'],
        'eggs': ['flax eggs', 'chia eggs', 'banana'],
      },
      'Gluten-Free': {
        'oats': ['gluten-free oats', 'quinoa', 'buckwheat'],
        'wheat': ['rice', 'quinoa', 'buckwheat'],
      },
      'Dairy-Free': {
        'milk': ['almond milk', 'soy milk', 'oat milk'],
        'cheese': ['nutritional yeast', 'dairy-free cheese'],
      },
    };

    final ingredientLower = ingredientName.toLowerCase();
    final restrictionReplacements = replacementQueries[restriction];
    if (restrictionReplacements != null) {
      for (final entry in restrictionReplacements.entries) {
        if (ingredientLower.contains(entry.key)) {
          // Try to find nutrition data for the replacement
          for (final replacement in entry.value) {
            final nutrition =
                await _getOpenFoodFactsNutrition(replacement, 100, 'grams');
            if (nutrition != null) {
              return RecipeIngredient(
                name: replacement,
                amount: 100,
                unit: 'grams',
                nutrition: NutritionInfo(
                  calories: nutrition['calories'] ?? 0.0,
                  protein: nutrition['protein'] ?? 0.0,
                  carbs: nutrition['carbs'] ?? 0.0,
                  fat: nutrition['fat'] ?? 0.0,
                  fiber: nutrition['fiber'] ?? 0.0,
                  sugar: nutrition['sugar'] ?? 0.0,
                  sodium: nutrition['sodium'] ?? 0.0,
                ),
              );
            }
          }
        }
      }
    }
    return null;
  }

  /// Fetch fallback nutrition from Open Food Facts
  static Future<Map<String, double>?> _getOpenFoodFactsNutrition(
      String ingredientName, double amount, String unit) async {
    // This would be implemented in a separate OpenFoodFactsService
    // For now, return null to indicate no fallback data
    _logger.w('Open Food Facts fallback not implemented for $ingredientName');
    return null;
  }

  /// Clear the nutrition cache
  static void clearCache() {
    _nutritionCache.clear();
    _logger.i('Nutrition cache cleared');
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _nutritionCache.length,
      'cachedItems': _nutritionCache.keys.toList(),
    };
  }
}

/// Nutrition verification result
class NutritionVerificationResult {
  final bool isVerified;
  final double confidence;
  final String message;
  final Map<String, double>? suggestedCorrection;
  final RecipeIngredient? suggestedReplacement;
  final Map<String, double>? usdaData;
  final String? usdaSource;

  NutritionVerificationResult({
    required this.isVerified,
    required this.confidence,
    required this.message,
    this.suggestedCorrection,
    this.suggestedReplacement,
    this.usdaData,
    this.usdaSource,
  });

  @override
  String toString() {
    return 'NutritionVerificationResult(isVerified: $isVerified, confidence: $confidence, message: $message)';
  }
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
  final RecipeIngredient? suggestedReplacement;
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
