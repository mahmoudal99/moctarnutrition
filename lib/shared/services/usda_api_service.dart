// Re-export types for backward compatibility
export 'usda_client_service.dart' show USDASearchResult, USDAFoodDetails;
export 'nutrition_comparison_service.dart' show NutritionComparison;
export 'nutrition_verification_service.dart' show NutritionVerificationResult, MealVerificationResult, IngredientVerificationDetail;

import 'package:logger/logger.dart';
import 'ingredient_name_mapper_service.dart';
import 'nutrition_verification_service.dart';
import 'usda_client_service.dart';

/// Service for verifying nutritional data against USDA FoodData Central API with Open Food Facts pre-lookup
/// This is now a wrapper around the new microservices architecture
class USDAApiService {
  static final _logger = Logger();

  /// Search for a food item in USDA database (delegated to USDAClientService)
  static Future<List<USDASearchResult>> searchFood(String query) async {
    // This is now handled by USDAClientService
    _logger.w('searchFood is deprecated. Use USDAClientService.searchFood instead.');
    return USDAClientService.searchFood(query);
  }

  /// Get detailed nutritional information for a specific food (delegated to USDAClientService)
  static Future<USDAFoodDetails?> getFoodDetails(int fdcId) async {
    // This is now handled by USDAClientService
    _logger.w('getFoodDetails is deprecated. Use USDAClientService.getFoodDetails instead.');
    return USDAClientService.getFoodDetails(fdcId);
  }

  /// Verify ingredient nutritional data against USDA database (delegated to NutritionVerificationService)
  static Future<NutritionVerificationResult> verifyIngredientNutrition(
    String ingredientName,
    double amount,
    String unit,
    Map<String, double> claimedNutrition, {
    List<String> dietaryRestrictions = const [],
    String preparationState = 'unspecified',
  }) async {
    // This is now handled by NutritionVerificationService
    return NutritionVerificationService.verifyIngredientNutrition(
      ingredientName,
      amount,
      unit,
      claimedNutrition,
      dietaryRestrictions: dietaryRestrictions,
      preparationState: preparationState,
    );
  }

  /// Test USDA API connectivity (delegated to USDAClientService)
  static Future<bool> testConnection() async {
    return USDAClientService.testConnection();
  }

  /// Clear all caches across microservices
  static void clearAllCaches() {
    IngredientNameMapperService.clearCache();
    NutritionVerificationService.clearCache();
    _logger.i('All caches cleared across microservices');
  }

  /// Get cache statistics from all microservices
  static Map<String, dynamic> getAllCacheStats() {
    return {
      'nameMapper': IngredientNameMapperService.getCacheStats(),
      'nutritionVerification': NutritionVerificationService.getCacheStats(),
    };
  }
} 