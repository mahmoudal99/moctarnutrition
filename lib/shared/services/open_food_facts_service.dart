import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for Open Food Facts API integration
/// Used to normalize GPT-generated ingredient names to USDA-compatible terms
class OpenFoodFactsService {
  static const String _baseUrl =
      'https://world.openfoodfacts.org/cgi/search.pl';

  /// Search for food items and normalize ingredient names
  static Future<OpenFoodFactsResult?> searchAndNormalize(
      String ingredientName) async {
    try {
      print('🔍 Open Food Facts: Searching for "$ingredientName"');

      final response = await http.get(
        Uri.parse(
            '$_baseUrl?search_terms=${Uri.encodeComponent(ingredientName)}&json=1&page_size=5'),
        headers: {'User-Agent': 'ChampionsGym/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseSearchResults(data, ingredientName);
      } else {
        print('❌ Open Food Facts API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Open Food Facts search error: $e');
      return null;
    }
  }

  /// Parse search results and find best match
  static OpenFoodFactsResult? _parseSearchResults(
      Map<String, dynamic> data, String originalQuery) {
    final products = data['products'] as List?;
    if (products == null || products.isEmpty) {
      print('⚠️ Open Food Facts: No products found for "$originalQuery"');
      return null;
    }

    print(
        '📋 Open Food Facts: Found ${products.length} products for "$originalQuery"');

    // Find best match based on relevance and data quality
    OpenFoodFactsProduct? bestMatch;
    double bestScore = -1;

    for (final product in products) {
      final score = _calculateRelevanceScore(product, originalQuery);
      if (score > bestScore) {
        bestScore = score;
        bestMatch = OpenFoodFactsProduct.fromJson(product);
      }
    }

    if (bestMatch != null) {
      print(
          '🎯 Open Food Facts: Best match for "$originalQuery" -> "${bestMatch.productName}" (score: $bestScore)');

      return OpenFoodFactsResult(
        originalQuery: originalQuery,
        normalizedName: _normalizeProductName(bestMatch.productName),
        product: bestMatch,
        confidence: bestScore / 100, // Normalize to 0-1 range
      );
    }

    return null;
  }

  /// Calculate relevance score for a product
  static double _calculateRelevanceScore(
      Map<String, dynamic> product, String originalQuery) {
    double score = 0;
    final productName =
        (product['product_name'] ?? '').toString().toLowerCase();
    final categories = (product['categories'] ?? '').toString().toLowerCase();
    final originalLower = originalQuery.toLowerCase();

    // Exact name match (highest priority)
    if (productName.contains(originalLower) ||
        originalLower.contains(productName)) {
      score += 50;
    }

    // Partial word matches
    final originalWords =
        originalLower.split(RegExp(r'[,\s]+')).where((w) => w.isNotEmpty);
    for (final word in originalWords) {
      if (productName.contains(word)) {
        score += 20;
      }
      if (categories.contains(word)) {
        score += 10;
      }
    }

    // Data quality bonus
    final nutriments = product['nutriments'] as Map<String, dynamic>?;
    if (nutriments != null) {
      final hasCalories = nutriments['energy-kcal_100g'] != null;
      final hasProtein = nutriments['proteins_100g'] != null;
      final hasCarbs = nutriments['carbohydrates_100g'] != null;
      final hasFat = nutriments['fat_100g'] != null;

      if (hasCalories) score += 5;
      if (hasProtein) score += 5;
      if (hasCarbs) score += 5;
      if (hasFat) score += 5;
    }

    // Prefer raw ingredients over processed foods
    if (productName.contains('raw') || productName.contains('fresh')) {
      score += 10;
    }
    if (productName.contains('processed') || productName.contains('canned')) {
      score -= 10;
    }

    return score;
  }

  /// Normalize product name for USDA search
  static String _normalizeProductName(String productName) {
    // Remove common qualifiers that might not be in USDA
    String normalized = productName.toLowerCase();

    // Remove brand names and qualifiers
    final qualifiersToRemove = [
      'organic',
      'gluten free',
      'non-gmo',
      'natural',
      'fresh',
      'raw',
      'whole grain',
      'whole wheat',
      'extra virgin',
      'pure',
      'la choy',
      'gerble',
      'galettes',
      'sudoises',
      'chocolat',
      'cookie',
      '132g',
      '47oz',
      '15 fl oz',
      '15 oz',
      'light',
      'super firm',
      'cubed',
      'sprouted'
    ];

    for (final qualifier in qualifiersToRemove) {
      normalized = normalized.replaceAll(qualifier, '').trim();
    }

    // Clean up extra spaces and punctuation
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    normalized = normalized.replaceAll(RegExp(r'[^\w\s]'), '');

    // Extract core ingredient names
    final coreIngredients = _extractCoreIngredient(normalized);

    return coreIngredients.trim();
  }

  /// Extract core ingredient name from product name
  static String _extractCoreIngredient(String productName) {
    // Common ingredient keywords to prioritize
    final ingredientKeywords = [
      'oat',
      'oats',
      'tofu',
      'spinach',
      'soy sauce',
      'sesame',
      'seed',
      'lentil',
      'almond',
      'blueberry',
      'chicken',
      'rice',
      'quinoa'
    ];

    final words = productName.split(' ');
    final coreWords = <String>[];

    for (final word in words) {
      if (word.isNotEmpty &&
          ingredientKeywords.any((keyword) => word.contains(keyword))) {
        coreWords.add(word);
      }
    }

    if (coreWords.isNotEmpty) {
      return coreWords.join(' ');
    }

    // Fallback: return first few meaningful words
    return words.take(3).where((w) => w.length > 2).join(' ');
  }

  /// Get fallback nutrition data when USDA fails
  static Map<String, double>? getFallbackNutrition(
      OpenFoodFactsProduct product) {
    final nutriments = product.nutriments;
    if (nutriments == null) return null;

    final nutrition = <String, double>{};

    // Map Open Food Facts nutrients to our format
    if (nutriments['energy-kcal_100g'] != null) {
      nutrition['calories'] = nutriments['energy-kcal_100g'].toDouble();
    }
    if (nutriments['proteins_100g'] != null) {
      nutrition['protein'] = nutriments['proteins_100g'].toDouble();
    }
    if (nutriments['carbohydrates_100g'] != null) {
      nutrition['carbs'] = nutriments['carbohydrates_100g'].toDouble();
    }
    if (nutriments['fat_100g'] != null) {
      nutrition['fat'] = nutriments['fat_100g'].toDouble();
    }
    if (nutriments['fiber_100g'] != null) {
      nutrition['fiber'] = nutriments['fiber_100g'].toDouble();
    }
    if (nutriments['sugars_100g'] != null) {
      nutrition['sugar'] = nutriments['sugars_100g'].toDouble();
    }
    if (nutriments['sodium_100g'] != null) {
      nutrition['sodium'] = nutriments['sodium_100g'].toDouble();
    }

    return nutrition.isNotEmpty ? nutrition : null;
  }
}

/// Result from Open Food Facts search and normalization
class OpenFoodFactsResult {
  final String originalQuery;
  final String normalizedName;
  final OpenFoodFactsProduct product;
  final double confidence;

  OpenFoodFactsResult({
    required this.originalQuery,
    required this.normalizedName,
    required this.product,
    required this.confidence,
  });
}

/// Open Food Facts product model
class OpenFoodFactsProduct {
  final String productName;
  final String? categories;
  final Map<String, dynamic>? nutriments;
  final String? servingSize;

  OpenFoodFactsProduct({
    required this.productName,
    this.categories,
    this.nutriments,
    this.servingSize,
  });

  factory OpenFoodFactsProduct.fromJson(Map<String, dynamic> json) {
    return OpenFoodFactsProduct(
      productName: json['product_name'] ?? '',
      categories: json['categories'],
      nutriments: json['nutriments'] as Map<String, dynamic>?,
      servingSize: json['serving_size'],
    );
  }
}
