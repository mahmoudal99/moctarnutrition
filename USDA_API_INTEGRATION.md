# USDA API Integration for Nutritional Verification

## Overview

This integration provides nutritional verification for AI-generated meal plans by cross-referencing ingredient data against the USDA FoodData Central database. This ensures accuracy and builds user trust in the nutritional information provided.

## Features

### 🔍 **Ingredient Verification**
- Searches USDA database for precise ingredient names
- Compares AI-generated nutritional data with verified USDA data
- Provides confidence scores and suggested corrections

### 📊 **Nutritional Accuracy**
- Verifies calories, protein, carbs, fat, fiber, sugar, and sodium
- Uses 15% tolerance for acceptable variations
- Calculates overall verification confidence

### 🛡️ **Quality Assurance**
- 70% verification threshold for meal plan approval
- Detailed reporting on verification status
- Graceful handling of missing or unmatched ingredients

## Setup

### 1. Get USDA API Key
1. Visit [USDA FoodData Central](https://fdc.nal.usda.gov/api-key-signup.html)
2. Sign up for a free API key
3. Add to your `.env` file:
```env
USDA_API_KEY=your_api_key_here
```

### 2. Environment Configuration
The system automatically detects if USDA API is enabled:
- If API key is set: Full verification enabled
- If no API key: Verification disabled (graceful fallback)

## Usage

### Basic Verification
```dart
// Verify a complete meal plan
final verification = await NutritionVerificationService.verifyMealPlan(mealPlan);

if (verification.isVerified) {
  print('✅ Meal plan verified: ${verification.message}');
} else {
  print('⚠️ Verification issues: ${verification.message}');
}
```

### Single Meal Verification
```dart
// Verify individual meal
final mealVerification = await NutritionVerificationService.verifyMeal(meal);

print('Confidence: ${(mealVerification.confidence * 100).toInt()}%');
print('Status: ${mealVerification.message}');
```

### Detailed Analysis
```dart
// Get verification statistics
final stats = NutritionVerificationService.getVerificationStatistics(verification);

print('Total ingredients: ${stats.totalIngredients}');
print('Verified: ${stats.verifiedIngredients}');
print('Verification rate: ${(stats.verificationRate * 100).toInt()}%');
```

## Enhanced Prompt System

### Updated AI Prompts
The prompt system now requests detailed ingredient information:

```json
{
  "ingredients": [
    {
      "name": "chicken breast, raw",
      "amount": 150,
      "unit": "g",
      "notes": "skinless, boneless",
      "nutrition": {
        "calories": 247.5,
        "protein": 46.5,
        "carbs": 0.0,
        "fat": 5.4,
        "fiber": 0.0,
        "sugar": 0.0,
        "sodium": 111.0
      }
    }
  ]
}
```

### Ingredient Specifications
- **Precise Names**: "chicken breast, raw" not "chicken"
- **Standardized Units**: grams (g), milliliters (ml), pieces
- **Nutritional Data**: Per-ingredient nutrition for verification
- **USDA Compatibility**: Names match FoodData Central database

## API Services

### USDAApiService
Core service for USDA database interactions:

```dart
// Search for ingredients
final results = await USDAApiService.searchFood('chicken breast');

// Get detailed nutrition
final details = await USDAApiService.getFoodDetails(fdcId);

// Verify ingredient nutrition
final verification = await USDAApiService.verifyIngredientNutrition(
  ingredientName, amount, unit, claimedNutrition
);
```

### NutritionVerificationService
High-level service for meal plan verification:

```dart
// Verify complete meal plans
final result = await NutritionVerificationService.verifyMealPlan(mealPlan);

// Verify individual meals
final mealResult = await NutritionVerificationService.verifyMeal(meal);
```

## Data Models

### RecipeIngredient (Updated)
Now includes nutritional data per ingredient:
```dart
class RecipeIngredient {
  final String name;
  final double amount;
  final String unit;
  final String? notes;
  final NutritionInfo? nutrition; // NEW: Per-ingredient nutrition
}
```

### Verification Results
```dart
class NutritionVerificationResult {
  final bool isVerified;
  final double confidence;
  final String message;
  final Map<String, double>? suggestedCorrection;
  final Map<String, double>? usdaData;
  final String? usdaSource;
}
```

## Performance Considerations

### Caching
- USDA API responses are cached to reduce API calls
- Cache expiration: 24 hours for ingredient data
- Automatic cleanup of expired cache entries

### Rate Limiting
- Respects USDA API rate limits
- Exponential backoff for failed requests
- Graceful degradation when API is unavailable

### Parallel Processing
- Verification can run in parallel for multiple ingredients
- Batch processing for large meal plans
- Progress callbacks for UI feedback

## Error Handling

### API Failures
- Graceful fallback when USDA API is unavailable
- Detailed error messages for debugging
- Retry logic with exponential backoff

### Missing Data
- Handles ingredients not found in USDA database
- Provides alternative suggestions when possible
- Continues verification for other ingredients

### Invalid Data
- Validates nutritional data ranges
- Flags suspicious values for review
- Suggests corrections based on USDA data

## Testing

Run the USDA API tests:
```bash
flutter test test/usda_api_test.dart
```

Tests cover:
- ✅ API connectivity
- ✅ Food search functionality
- ✅ Nutritional verification
- ✅ Unit conversions
- ✅ Error handling

## Benefits

### For Users
- **Trust**: Verified nutritional data from authoritative source
- **Accuracy**: Precise ingredient and nutrition information
- **Transparency**: Detailed verification reports
- **Reliability**: Consistent data quality

### For Developers
- **Quality**: Automated verification reduces manual review
- **Scalability**: Efficient API usage with caching
- **Maintainability**: Clean separation of concerns
- **Extensibility**: Easy to add new verification sources

## Future Enhancements

### Planned Features
- [ ] Multiple database support (FatSecret, MyFoodData)
- [ ] Recipe-level verification
- [ ] User feedback integration
- [ ] Machine learning for ingredient matching
- [ ] Batch verification for large datasets

### Integration Opportunities
- [ ] MyFitnessPal API integration
- [ ] Cronometer data export
- [ ] Nutritionist review workflow
- [ ] Automated meal plan optimization

## Support

For issues or questions:
1. Check USDA API status: https://fdc.nal.usda.gov/api-status.html
2. Review API documentation: https://fdc.nal.usda.gov/api-docs.html
3. Contact development team for app-specific issues

---

**Note**: This integration requires an active internet connection and valid USDA API key for full functionality. The system gracefully degrades when these requirements are not met. 