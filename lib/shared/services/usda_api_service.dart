import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config_service.dart';
import '../models/meal_model.dart';

/// Service for verifying nutritional data against USDA FoodData Central API
class USDAApiService {
  static const String _baseUrl = 'https://api.nal.usda.gov/fdc/v1';
  
  static String get _apiKey => ConfigService.usdaApiKey;
  
  /// Search for a food item in USDA database
  static Future<List<USDASearchResult>> searchFood(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/foods/search?api_key=$_apiKey&query=${Uri.encodeComponent(query)}&pageSize=25'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final foods = data['foods'] as List;
        
        return foods.map((food) => USDASearchResult.fromJson(food)).toList();
      } else {
        print('USDA API Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('USDA API Search Error: $e');
      return [];
    }
  }

  /// Get detailed nutritional information for a specific food
  static Future<USDAFoodDetails?> getFoodDetails(int fdcId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/food/$fdcId?api_key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return USDAFoodDetails.fromJson(data);
      } else {
        print('USDA API Details Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('USDA API Details Error: $e');
      return null;
    }
  }

  /// Verify ingredient nutritional data against USDA database
  static Future<NutritionVerificationResult> verifyIngredientNutrition(
    String ingredientName,
    double amount,
    String unit,
    Map<String, double> claimedNutrition, {
    List<String> dietaryRestrictions = const [],
  }) async {
    try {
      // Search for the ingredient
      final searchResults = await searchFood(ingredientName);
      
      if (searchResults.isEmpty) {
              return NutritionVerificationResult(
        isVerified: false,
        confidence: 0.0,
        message: 'Ingredient not found in USDA database',
        suggestedCorrection: null,
        suggestedReplacement: null,
      );
      }

      // Get the best match (first result)
      final bestMatch = searchResults.first;
      final foodDetails = await getFoodDetails(bestMatch.fdcId);
      
      if (foodDetails == null) {
              return NutritionVerificationResult(
        isVerified: false,
        confidence: 0.0,
        message: 'Could not retrieve nutritional details',
        suggestedCorrection: null,
        suggestedReplacement: null,
      );
      }

      // Calculate expected nutrition based on amount
      final expectedNutrition = _calculateNutritionForAmount(
        foodDetails.nutritionPer100g,
        amount,
        unit,
      );

      // Compare claimed vs expected nutrition
      final verification = _compareNutrition(claimedNutrition, expectedNutrition);
      
      return NutritionVerificationResult(
        isVerified: verification.isWithinTolerance,
        confidence: verification.confidence,
        message: verification.message,
        suggestedCorrection: verification.suggestedCorrection,
        suggestedReplacement: null,
        usdaData: expectedNutrition,
        usdaSource: foodDetails.description,
      );
    } catch (e) {
      print('Nutrition verification error: $e');
      return NutritionVerificationResult(
        isVerified: false,
        confidence: 0.0,
        message: 'Verification failed: $e',
        suggestedCorrection: null,
        suggestedReplacement: null,
      );
    }
  }

  /// Calculate nutrition for a specific amount
  static Map<String, double> _calculateNutritionForAmount(
    Map<String, double> nutritionPer100g,
    double amount,
    String unit,
  ) {
    // Convert to grams if needed
    double amountInGrams = _convertToGrams(amount, unit);
    
    // Calculate nutrition for the specified amount
    final multiplier = amountInGrams / 100.0;
    
    return {
      'calories': (nutritionPer100g['calories'] ?? 0) * multiplier,
      'protein': (nutritionPer100g['protein'] ?? 0) * multiplier,
      'carbs': (nutritionPer100g['carbs'] ?? 0) * multiplier,
      'fat': (nutritionPer100g['fat'] ?? 0) * multiplier,
      'fiber': (nutritionPer100g['fiber'] ?? 0) * multiplier,
      'sugar': (nutritionPer100g['sugar'] ?? 0) * multiplier,
      'sodium': (nutritionPer100g['sodium'] ?? 0) * multiplier,
    };
  }

  /// Convert various units to grams
  static double _convertToGrams(double amount, String unit) {
    switch (unit.toLowerCase()) {
      case 'g':
      case 'gram':
      case 'grams':
        return amount;
      case 'ml':
      case 'milliliter':
      case 'milliliters':
        return amount; // Approximate 1:1 for most liquids
      case 'cup':
      case 'cups':
        return amount * 240; // Approximate grams per cup
      case 'tbsp':
      case 'tablespoon':
      case 'tablespoons':
        return amount * 15; // Approximate grams per tablespoon
      case 'tsp':
      case 'teaspoon':
      case 'teaspoons':
        return amount * 5; // Approximate grams per teaspoon
      default:
        return amount; // Default to grams
    }
  }

  /// Compare claimed vs expected nutrition
  static NutritionComparison _compareNutrition(
    Map<String, double> claimed,
    Map<String, double> expected,
  ) {
    const tolerance = 0.15; // 15% tolerance
    int matches = 0;
    int totalNutrients = 0;
    final corrections = <String, double>{};
    
    for (final nutrient in ['calories', 'protein', 'carbs', 'fat']) {
      if (claimed.containsKey(nutrient) && expected.containsKey(nutrient)) {
        totalNutrients++;
        final claimedValue = claimed[nutrient]!;
        final expectedValue = expected[nutrient]!;
        
        if (expectedValue > 0) {
          final difference = (claimedValue - expectedValue).abs() / expectedValue;
          if (difference <= tolerance) {
            matches++;
          } else {
            corrections[nutrient] = expectedValue;
          }
        }
      }
    }
    
    final toleranceConfidence = totalNutrients > 0 ? matches / totalNutrients : 0.0;
    final isWithinTolerance = toleranceConfidence >= 0.7; // 70% of nutrients within tolerance
    
    // Calculate confidence based on USDA data quality and availability
    // High confidence if we have good USDA data, regardless of tolerance
    final usdaDataQuality = expected.values.where((v) => v > 0).length / expected.length;
    final confidence = usdaDataQuality * 0.8 + toleranceConfidence * 0.2; // Weight USDA data quality more heavily
    
    String message;
    if (isWithinTolerance) {
      message = 'Nutrition data verified with ${(toleranceConfidence * 100).toInt()}% tolerance match';
    } else {
      message = 'Nutrition data may need adjustment. ${(toleranceConfidence * 100).toInt()}% of nutrients within tolerance.';
    }
    
    return NutritionComparison(
      isWithinTolerance: isWithinTolerance,
      confidence: confidence,
      message: message,
      suggestedCorrection: corrections.isNotEmpty ? corrections : null,
    );
  }
}

/// USDA search result model
class USDASearchResult {
  final int fdcId;
  final String description;
  final String brandOwner;
  final String dataType;

  USDASearchResult({
    required this.fdcId,
    required this.description,
    required this.brandOwner,
    required this.dataType,
  });

  factory USDASearchResult.fromJson(Map<String, dynamic> json) {
    return USDASearchResult(
      fdcId: json['fdcId'] ?? 0,
      description: json['description'] ?? '',
      brandOwner: json['brandOwner'] ?? '',
      dataType: json['dataType'] ?? '',
    );
  }
}

/// USDA food details model
class USDAFoodDetails {
  final int fdcId;
  final String description;
  final String brandOwner;
  final Map<String, double> nutritionPer100g;

  USDAFoodDetails({
    required this.fdcId,
    required this.description,
    required this.brandOwner,
    required this.nutritionPer100g,
  });

  factory USDAFoodDetails.fromJson(Map<String, dynamic> json) {
    final nutrients = <String, double>{};
    
    if (json['foodNutrients'] != null) {
      final foodNutrients = json['foodNutrients'] as List;
      
      for (final nutrient in foodNutrients) {
        final nutrientName = nutrient['nutrient']?['name']?.toString().toLowerCase() ?? '';
        final value = nutrient['amount']?.toDouble() ?? 0.0;
        
        // Map USDA nutrient names to our format
        if (nutrientName.contains('protein')) {
          nutrients['protein'] = value;
        } else if (nutrientName.contains('carbohydrate')) {
          nutrients['carbs'] = value;
        } else if (nutrientName.contains('total lipid')) {
          nutrients['fat'] = value;
        } else if (nutrientName.contains('fiber')) {
          nutrients['fiber'] = value;
        } else if (nutrientName.contains('sugars')) {
          nutrients['sugar'] = value;
        } else if (nutrientName.contains('sodium')) {
          nutrients['sodium'] = value;
        } else if (nutrientName.contains('energy')) {
          nutrients['calories'] = value;
        }
      }
    }
    
    return USDAFoodDetails(
      fdcId: json['fdcId'] ?? 0,
      description: json['description'] ?? '',
      brandOwner: json['brandOwner'] ?? '',
      nutritionPer100g: nutrients,
    );
  }
}

/// Nutrition comparison result
class NutritionComparison {
  final bool isWithinTolerance;
  final double confidence;
  final String message;
  final Map<String, double>? suggestedCorrection;

  NutritionComparison({
    required this.isWithinTolerance,
    required this.confidence,
    required this.message,
    this.suggestedCorrection,
  });
}

/// Nutrition verification result
class NutritionVerificationResult {
  final bool isVerified;
  final double confidence;
  final String message;
  final Map<String, double>? suggestedCorrection;
  final RecipeIngredient? suggestedReplacement; // Added for dietary restrictions
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
} 