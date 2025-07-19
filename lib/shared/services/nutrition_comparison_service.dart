import 'package:logger/logger.dart';

/// Service responsible for comparing nutrition data and calculating confidence scores
class NutritionComparisonService {
  static final _logger = Logger();

  /// Compare claimed vs expected nutrition and return comparison result
  static NutritionComparison compareNutrition(
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
    final isWithinTolerance = toleranceConfidence >= 0.7;
    final usdaDataQuality = expected.values.where((v) => v > 0).length / expected.length;
    final confidence = usdaDataQuality * 0.8 + toleranceConfidence * 0.2;

    String message;
    if (isWithinTolerance) {
      message = 'Nutrition data verified with ${(toleranceConfidence * 100).toInt()}% tolerance match';
    } else {
      message = 'Nutrition data may need adjustment. ${(toleranceConfidence * 100).toInt()}% of nutrients within tolerance.';
    }

    _logger.i('Nutrition comparison: $toleranceConfidence tolerance, $confidence confidence, ${corrections.length} corrections needed');

    return NutritionComparison(
      isWithinTolerance: isWithinTolerance,
      confidence: confidence,
      message: message,
      suggestedCorrection: corrections.isNotEmpty ? corrections : null,
    );
  }

  /// Calculate nutrition for a specific amount
  static Map<String, double> calculateNutritionForAmount(
    Map<String, double> nutritionPer100g,
    double amountInGrams,
    String unit,
  ) {
    final multiplier = amountInGrams / 100.0;
    return {
      'calories': ((nutritionPer100g['calories'] ?? 0.0) * multiplier).clamp(0.0, 1000.0),
      'protein': ((nutritionPer100g['protein'] ?? 0.0) * multiplier).clamp(0.0, 200.0),
      'carbs': ((nutritionPer100g['carbs'] ?? 0.0) * multiplier).clamp(0.0, 300.0),
      'fat': ((nutritionPer100g['fat'] ?? 0.0) * multiplier).clamp(0.0, 100.0),
      'fiber': ((nutritionPer100g['fiber'] ?? 0.0) * multiplier).clamp(0.0, 50.0),
      'sugar': ((nutritionPer100g['sugar'] ?? 0.0) * multiplier).clamp(0.0, 100.0),
      'sodium': ((nutritionPer100g['sodium'] ?? 0.0) * multiplier).clamp(0.0, 2000.0),
    };
  }

  /// Validate nutrition data for reasonableness
  static bool validateNutritionData(Map<String, double> nutrition, String ingredientName) {
    final calories = nutrition['calories'] ?? 0.0;
    final protein = nutrition['protein'] ?? 0.0;
    final carbs = nutrition['carbs'] ?? 0.0;
    final fat = nutrition['fat'] ?? 0.0;

    // Basic sanity checks
    if (calories < 0 || calories > 1000) {
      _logger.w('Invalid calories for $ingredientName: $calories');
      return false;
    }

    if (protein < 0 || protein > 200) {
      _logger.w('Invalid protein for $ingredientName: $protein');
      return false;
    }

    if (carbs < 0 || carbs > 300) {
      _logger.w('Invalid carbs for $ingredientName: $carbs');
      return false;
    }

    if (fat < 0 || fat > 100) {
      _logger.w('Invalid fat for $ingredientName: $fat');
      return false;
    }

    // Check if macronutrients add up reasonably
    final calculatedCalories = (protein * 4) + (carbs * 4) + (fat * 9);
    final calorieDiff = (calories - calculatedCalories).abs();
    
    if (calorieDiff > calories * 0.3) { // 30% tolerance
      _logger.w('Calorie mismatch for $ingredientName: claimed $calories, calculated $calculatedCalories');
      return false;
    }

    return true;
  }

  /// Get nutrition summary for debugging
  static Map<String, dynamic> getNutritionSummary(Map<String, double> nutrition) {
    return {
      'calories': nutrition['calories'] ?? 0.0,
      'protein': nutrition['protein'] ?? 0.0,
      'carbs': nutrition['carbs'] ?? 0.0,
      'fat': nutrition['fat'] ?? 0.0,
      'fiber': nutrition['fiber'] ?? 0.0,
      'sugar': nutrition['sugar'] ?? 0.0,
      'sodium': nutrition['sodium'] ?? 0.0,
      'totalMacros': (nutrition['protein'] ?? 0.0) + (nutrition['carbs'] ?? 0.0) + (nutrition['fat'] ?? 0.0),
    };
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

  @override
  String toString() {
    return 'NutritionComparison(isWithinTolerance: $isWithinTolerance, confidence: $confidence, message: $message, corrections: ${suggestedCorrection?.length ?? 0})';
  }
} 