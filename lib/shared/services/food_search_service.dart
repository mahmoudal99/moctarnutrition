import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
      // Ensure the service is initialized
      if (OpenFoodAPIConfiguration.userAgent == null) {
        initialize();
      }
      
      _logger.i('Searching for foods with query: $query');

      // Split query into individual terms for better search
      final searchTerms = query.toLowerCase().split(' ').where((term) => term.isNotEmpty).toList();
      
      final configuration = ProductSearchQueryConfiguration(
        parametersList: [
          SearchTerms(terms: searchTerms),
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
          ProductField.CATEGORIES,
          ProductField.LABELS,
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

      var products = searchResult.products!;
      _logger.i('Found ${products.length} products for query: $query');

      // If we don't get enough results, try a broader search
      if (products.length < 10 && searchTerms.length > 1) {
        _logger.i('Trying broader search with fewer terms');
        
        // Try searching with just the first term
        final broaderConfiguration = ProductSearchQueryConfiguration(
          parametersList: [
            SearchTerms(terms: [searchTerms.first]),
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
            ProductField.CATEGORIES,
            ProductField.LABELS,
          ],
          version: ProductQueryVersion.v3,
        );

        try {
          final broaderResult = await OpenFoodAPIClient.searchProducts(
            User(userId: '', password: ''),
            broaderConfiguration,
          );
          
          if (broaderResult.products != null && broaderResult.products!.isNotEmpty) {
            _logger.i('Broader search found ${broaderResult.products!.length} additional products');
            // Combine results, avoiding duplicates
            final existingBarcodes = products.map((p) => p.barcode).toSet();
            final additionalProducts = broaderResult.products!
                .where((p) => !existingBarcodes.contains(p.barcode))
                .toList();
            products = [...products, ...additionalProducts];
          }
        } catch (e) {
          _logger.w('Broader search failed: $e');
        }
      }

      _logger.i('Total products found: ${products.length}');
      
      // Convert all API results to FoodProduct objects first
      final List<FoodProduct> allFoodProducts = products.map((product) => _convertToFoodProduct(product)).toList();
      
      // If we still don't have enough results, try web search fallback
      if (allFoodProducts.length < 20) {
        _logger.i('Trying web search fallback for more results');
        try {
          final webResults = await _searchViaWebFallback(query);
          if (webResults.isNotEmpty) {
            _logger.i('Web fallback found ${webResults.length} additional products');
            // Combine results, avoiding duplicates
            final existingBarcodes = allFoodProducts.map((p) => p.barcode).toSet();
            final additionalProducts = webResults
                .where((p) => !existingBarcodes.contains(p.barcode))
                .toList();
            allFoodProducts.addAll(additionalProducts);
            _logger.i('Combined total: ${allFoodProducts.length} products');
          }
        } catch (e) {
          _logger.w('Web fallback failed: $e');
        }
      }
      
      return allFoodProducts;
    } catch (e) {
      _logger.e('Error searching foods: $e');
      return [];
    }
  }

  /// Web search fallback to get more comprehensive results
  static Future<List<FoodProduct>> _searchViaWebFallback(String query) async {
    try {
      String url;
      
      // Check if this is a barcode search (numeric) or text search
      if (RegExp(r'^\d+$').hasMatch(query)) {
        // Barcode search - use direct product lookup
        url = 'https://world.openfoodfacts.org/api/v0/product/$query.json';
        _logger.i('Web fallback: Barcode search for $query');
      } else {
        // Text search
        final encodedQuery = Uri.encodeComponent(query);
        url = 'https://world.openfoodfacts.org/cgi/search.pl?search_terms=$encodedQuery&search_simple=1&action=process&json=1';
        _logger.i('Web fallback: Text search for $query');
      }
      
      _logger.i('Web fallback URL: $url');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 1) {
          // Single product response (barcode search)
          _logger.i('Web fallback: Single product found');
          final foodProduct = _convertFromWebData(data['product']);
          return foodProduct != null ? [foodProduct] : [];
        } else if (data['products'] != null) {
          // Multiple products response (text search)
          final products = data['products'] as List;
          _logger.i('Web fallback returned ${products.length} products');
          
          final List<FoodProduct> foodProducts = [];
          for (final productData in products.take(50)) { // Limit to first 50
            try {
              final foodProduct = _convertFromWebData(productData);
              if (foodProduct != null) {
                foodProducts.add(foodProduct);
              }
            } catch (e) {
              _logger.w('Error converting web product: $e');
            }
          }
          
          return foodProducts;
        }
      }
      
      return [];
    } catch (e) {
      _logger.e('Web fallback error: $e');
      return [];
    }
  }

  /// Convert web search data to FoodProduct
  static FoodProduct? _convertFromWebData(Map<String, dynamic> productData) {
    try {
      final barcode = productData['code']?.toString() ?? '';
      final productName = productData['product_name']?.toString() ?? 'Unknown Product';
      final brands = productData['brands']?.toString() ?? '';
      
      // Extract nutrition data
      final nutriments = productData['nutriments'] as Map<String, dynamic>?;
      final nutrition = NutritionInfo(
        calories: _extractNutrient(nutriments, 'energy-kcal_100g') ?? 0.0,
        protein: _extractNutrient(nutriments, 'proteins_100g') ?? 0.0,
        carbs: _extractNutrient(nutriments, 'carbohydrates_100g') ?? 0.0,
        fat: _extractNutrient(nutriments, 'fat_100g') ?? 0.0,
        fiber: _extractNutrient(nutriments, 'fiber_100g') ?? 0.0,
        sugar: _extractNutrient(nutriments, 'sugars_100g') ?? 0.0,
        sodium: _extractNutrient(nutriments, 'salt_100g') ?? 0.0,
      );
      
      return FoodProduct(
        id: barcode,
        name: productName,
        brand: brands,
        barcode: barcode,
        imageUrl: productData['image_front_url']?.toString(),
        nutrition: nutrition,
        servingSize: productData['serving_size']?.toString() ?? '100g',
        allergens: _extractList(productData['allergens_tags']),
        ingredients: productData['ingredients_text']?.toString() ?? '',
        nutriscore: productData['nutriscore_grade']?.toString(),
        ecoscore: productData['ecoscore_grade']?.toString(),
      );
    } catch (e) {
      _logger.w('Error converting web product data: $e');
      return null;
    }
  }

  /// Extract nutrient value from nutriments data
  static double? _extractNutrient(Map<String, dynamic>? nutriments, String key) {
    if (nutriments == null) return null;
    final value = nutriments[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Extract list from dynamic data
  static List<String> _extractList(dynamic data) {
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Get product by barcode
  static Future<FoodProduct?> getProductByBarcode(String barcode) async {
    try {
      // Ensure the service is initialized
      if (OpenFoodAPIConfiguration.userAgent == null) {
        initialize();
      }
      
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

      _logger.i('API configuration created for barcode: $barcode');
      
      final productResult = await OpenFoodAPIClient.getProductV3(configuration);
      _logger.i('API response received: ${productResult.status}');
      
      final product = productResult.product;

      if (product == null) {
        _logger.w('No product found for barcode: $barcode');
        _logger.w('API status: ${productResult.status}');
        
        // If API lookup failed, try web search fallback for this barcode
        if (productResult.status == 0) { // failure status
          _logger.i('API lookup failed, trying web search fallback for barcode: $barcode');
          try {
            final webResults = await _searchViaWebFallback(barcode);
            if (webResults.isNotEmpty) {
              // Find the product with matching barcode
              final matchingProduct = webResults.firstWhere(
                (p) => p.barcode == barcode,
                orElse: () => webResults.first,
              );
              
              if (matchingProduct.barcode == barcode) {
                _logger.i('Found product via web fallback: ${matchingProduct.name}');
                return matchingProduct;
              }
            }
          } catch (e) {
            _logger.w('Web fallback for barcode failed: $e');
          }
        }
        
        return null;
      }

      _logger.i('Found product: ${product.productName}');
      _logger.i('Product barcode: ${product.barcode}');
      _logger.i('Product brand: ${product.brands}');
      return _convertToFoodProduct(product);
    } catch (e, stackTrace) {
      _logger.e('Error getting product by barcode: $e');
      _logger.e('Stack trace: $stackTrace');
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
