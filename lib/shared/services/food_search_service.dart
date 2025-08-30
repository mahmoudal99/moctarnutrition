import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:logger/logger.dart';
import '../models/meal_model.dart';

/// Service for searching foods using Open Food Facts API
class FoodSearchService {
  static final _logger = Logger();

  /// Initialize the Open Food Facts configuration
  static void initialize() {
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'Moctar Nutrition',
      url: 'https://moctarnutrition.com',
    );
    OpenFoodAPIConfiguration.globalLanguages = [OpenFoodFactsLanguage.ENGLISH];
    OpenFoodAPIConfiguration.globalCountry = OpenFoodFactsCountry.IRELAND;

    _logger.i('Open Food Facts API initialized');
  }

  /// Search for foods by name
  static Future<List<FoodProduct>> searchFoods(String query) async {
    try {
      _logger.i('Searching for foods with query: $query');

      final configuration = ProductSearchQueryConfiguration(
        parametersList: [
          SearchTerms(terms: [query]),
        ],
        language: OpenFoodFactsLanguage.ENGLISH,
        country: OpenFoodFactsCountry.IRELAND,
        fields: [
          ProductField.BARCODE,
          ProductField.NAME,
          ProductField.BRANDS,
          ProductField.IMAGE_FRONT_URL,
          ProductField.NUTRIMENTS,
          ProductField.SERVING_SIZE,
          ProductField.ALLERGENS,
          ProductField.INGREDIENTS_TEXT,
          ProductField.NUTRISCORE,
        ],
        version: ProductQueryVersion.v3,
      );

      final searchResult = await OpenFoodAPIClient.searchProducts(
        User(userId: '', password: ''), // Anonymous user
        configuration,
      );

      if (searchResult.products == null) {
        _logger.w('No products found for query: $query');
        return [];
      }

      final products = searchResult.products!;
      _logger.i('Found ${products.length} products for query: $query');

      return products.map((product) => _convertToFoodProduct(product)).toList();
    } catch (e) {
      _logger.e('Error searching foods: $e');
      return [];
    }
  }

  /// Get product by barcode
  static Future<FoodProduct?> getProductByBarcode(String barcode) async {
    try {
      _logger.i('Getting product by barcode: $barcode');

      final configuration = ProductQueryConfiguration(
        barcode,
        language: OpenFoodFactsLanguage.ENGLISH,
        country: OpenFoodFactsCountry.IRELAND,
        fields: [
          ProductField.BARCODE,
          ProductField.NAME,
          ProductField.BRANDS,
          ProductField.IMAGE_FRONT_URL,
          ProductField.NUTRIMENTS,
          ProductField.SERVING_SIZE,
          ProductField.ALLERGENS,
          ProductField.INGREDIENTS_TEXT,
          ProductField.NUTRISCORE,
        ],
        version: ProductQueryVersion.v3,
      );

      final productResult = await OpenFoodAPIClient.getProductV3(configuration);
      final product = productResult.product;

      if (product == null) {
        _logger.w('No product found for barcode: $barcode');
        return null;
      }

      _logger.i('Found product: ${product.productName}');
      return _convertToFoodProduct(product);
    } catch (e) {
      _logger.e('Error getting product by barcode: $e');
      return null;
    }
  }

  /// Convert Open Food Facts product to app's FoodProduct model
  static FoodProduct _convertToFoodProduct(Product product) {
    final nutriments = product.nutriments;

    return FoodProduct(
      id: product.barcode ?? '',
      name: product.productName ?? 'Unknown Product',
      brand: product.brands ?? '',
      barcode: product.barcode ?? '',
      imageUrl: product.imageFrontUrl,
      nutrition: NutritionInfo(
        calories: nutriments
                ?.getValue(Nutrient.energyKCal, PerSize.oneHundredGrams)
                ?.toDouble() ??
            0.0,
        protein: nutriments
                ?.getValue(Nutrient.proteins, PerSize.oneHundredGrams)
                ?.toDouble() ??
            0.0,
        carbs: nutriments
                ?.getValue(Nutrient.carbohydrates, PerSize.oneHundredGrams)
                ?.toDouble() ??
            0.0,
        fat: nutriments
                ?.getValue(Nutrient.fat, PerSize.oneHundredGrams)
                ?.toDouble() ??
            0.0,
        fiber: nutriments
                ?.getValue(Nutrient.fiber, PerSize.oneHundredGrams)
                ?.toDouble() ??
            0.0,
        sugar: nutriments
                ?.getValue(Nutrient.sugars, PerSize.oneHundredGrams)
                ?.toDouble() ??
            0.0,
        sodium: nutriments
                ?.getValue(Nutrient.sodium, PerSize.oneHundredGrams)
                ?.toDouble() ??
            0.0,
      ),
      servingSize: product.servingSize ?? '100g',
      allergens: product.allergens?.names ?? [],
      ingredients: product.ingredientsText ?? '',
      nutriscore: product.nutriscore,
      ecoscore: product.ecoscoreGrade,
    );
  }
}

/// Model for food products from Open Food Facts
class FoodProduct {
  final String id;
  final String name;
  final String brand;
  final String barcode;
  final String? imageUrl;
  final NutritionInfo nutrition;
  final String servingSize;
  final List<String> allergens;
  final String ingredients;
  final String? nutriscore;
  final String? ecoscore;

  FoodProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.barcode,
    this.imageUrl,
    required this.nutrition,
    required this.servingSize,
    required this.allergens,
    required this.ingredients,
    this.nutriscore,
    this.ecoscore,
  });

  /// Convert to app's Meal model for adding to daily intake
  Meal toMeal(MealType type) {
    return Meal(
      id: id,
      name: name,
      description: '${brand.isNotEmpty ? '$brand - ' : ''}$ingredients',
      type: type,
      cuisineType: CuisineType.other,
      imageUrl: imageUrl,
      ingredients: [
        RecipeIngredient(
          name: name,
          amount: 1.0,
          unit: servingSize,
          notes: 'From Open Food Facts',
          nutrition: nutrition,
        ),
      ],
      instructions: ['Ready to eat'],
      prepTime: 0,
      cookTime: 0,
      servings: 1,
      nutrition: nutrition,
      tags: ['open-food-facts', 'barcode: $barcode'],
      dietaryTags: allergens,
      isVegetarian:
          !allergens.any((a) => a.contains('meat') || a.contains('fish')),
      isVegan: !allergens.any((a) =>
          a.contains('meat') ||
          a.contains('fish') ||
          a.contains('dairy') ||
          a.contains('egg')),
      isGlutenFree: !allergens.any((a) => a.contains('gluten')),
      isDairyFree:
          !allergens.any((a) => a.contains('dairy') || a.contains('milk')),
    );
  }
}
