import 'package:flutter_test/flutter_test.dart';
import 'package:champions_gym_app/shared/services/usda_api_service.dart';
import 'package:champions_gym_app/shared/services/unit_converter_service.dart';

void main() {
  group('USDA API Service Tests', () {
    test('should search for food items', () async {
      final results = await USDAApiService.searchFood('chicken breast');

      expect(results, isA<List<USDASearchResult>>());
      expect(results.isNotEmpty, isTrue);

      if (results.isNotEmpty) {
        final firstResult = results.first;
        expect(firstResult.fdcId, isA<int>());
        expect(firstResult.description, isA<String>());
        expect(firstResult.description.isNotEmpty, isTrue);
      }
    });

    test('should get food details', () async {
      // First search for a food item
      final searchResults = await USDAApiService.searchFood('apple');

      if (searchResults.isNotEmpty) {
        final foodDetails =
            await USDAApiService.getFoodDetails(searchResults.first.fdcId);

        expect(foodDetails, isA<USDAFoodDetails>());
        expect(foodDetails!.fdcId, equals(searchResults.first.fdcId));
        expect(foodDetails.description.isNotEmpty, isTrue);
        expect(foodDetails.nutritionPer100g, isA<Map<String, double>>());
      }
    });

    test('should verify ingredient nutrition', () async {
      final claimedNutrition = {
        'calories': 165.0,
        'protein': 31.0,
        'carbs': 0.0,
        'fat': 3.6,
        'fiber': 0.0,
        'sugar': 0.0,
        'sodium': 74.0,
      };

      final result = await USDAApiService.verifyIngredientNutrition(
        'chicken breast, raw',
        100.0,
        'g',
        claimedNutrition,
      );

      expect(result, isA<NutritionVerificationResult>());
      expect(result.isVerified, isA<bool>());
      expect(result.confidence, isA<double>());
      expect(result.message, isA<String>());
      expect(result.message.isNotEmpty, isTrue);
    });

    test('should handle unit conversions correctly', () async {
      // Test gram conversion
      final gramsResult = await UnitConverterService.convertToGrams(
          100, 'g', 'test ingredient', null);
      expect(gramsResult, equals(100.0));

      // Test cup conversion (approximate)
      final cupResult =
          await UnitConverterService.convertToGrams(1, 'cup', 'water', null);
      expect(cupResult, greaterThan(200.0)); // Should be around 240g

      // Test tablespoon conversion (approximate)
      final tbspResult =
          await UnitConverterService.convertToGrams(1, 'tbsp', 'water', null);
      expect(tbspResult, greaterThan(10.0)); // Should be around 15g

      // Test teaspoon conversion (approximate)
      final tspResult =
          await UnitConverterService.convertToGrams(1, 'tsp', 'water', null);
      expect(tspResult, greaterThan(3.0)); // Should be around 5g
    });

    test('should test API connectivity', () async {
      final isConnected = await USDAApiService.testConnection();
      expect(isConnected, isA<bool>());
    });
  });
}
