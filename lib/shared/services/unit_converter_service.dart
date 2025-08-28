import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

/// Service responsible for converting various units to grams for nutrition calculations
class UnitConverterService {
  static const String _openFoodFactsBaseUrl =
      'https://world.openfoodfacts.org/cgi/search.pl';
  static final _logger = Logger();

  /// Convert various units to grams using USDA portions or Open Food Facts fallback
  static Future<double> convertToGrams(
    double amount,
    String unit,
    String ingredientName,
    List<Map<String, dynamic>>? usdaPortions,
  ) async {
    final unitLower = unit.toLowerCase().trim();

    // Validate input
    if (amount <= 0 || amount > 1000) {
      _logger.w(
          'Invalid amount $amount $unit for $ingredientName, defaulting to 100g');
      return 100.0;
    }

    // Direct gram input
    if (unitLower == 'g' || unitLower == 'gram' || unitLower == 'grams') {
      _logger.i('Direct gram input: $amount g for $ingredientName');
      return amount;
    }

    // Use USDA food portions if available
    if (usdaPortions != null && usdaPortions.isNotEmpty) {
      final usdaGrams = _convertUsingUSDAPortions(
          amount, unitLower, usdaPortions, ingredientName);
      if (usdaGrams != null) {
        return usdaGrams;
      }
    }

    // Fallback to Open Food Facts for portion data
    final fallbackGrams =
        await _getOpenFoodFactsPortion(ingredientName, amount, unit);
    if (fallbackGrams != null) {
      _logger.i(
          'Converted $amount $unit to $fallbackGrams g for $ingredientName using Open Food Facts');
      return fallbackGrams.clamp(0.0, 1000.0);
    }

    // Generic density-based conversion
    return _convertUsingDensity(amount, unitLower, ingredientName);
  }

  /// Convert using USDA food portions
  static double? _convertUsingUSDAPortions(
    double amount,
    String unit,
    List<Map<String, dynamic>> portions,
    String ingredientName,
  ) {
    final portion = portions.firstWhere(
      (p) =>
          p['measureUnit'] != null &&
          p['measureUnit']['name'].toLowerCase() == unit,
      orElse: () => <String, dynamic>{},
    );

    if (portion.isNotEmpty &&
        portion['gramWeight'] != null &&
        portion['gramWeight'] > 0) {
      final grams = amount * portion['gramWeight'].toDouble();
      _logger.i(
          'Converted $amount $unit to $grams g for $ingredientName using USDA portion');
      return grams.clamp(0.0, 1000.0);
    }
    return null;
  }

  /// Fetch portion data from Open Food Facts
  static Future<double?> _getOpenFoodFactsPortion(
      String ingredientName, double amount, String unit) async {
    try {
      final query = _normalizeQuery(ingredientName);
      final response = await http.get(
        Uri.parse(
            '$_openFoodFactsBaseUrl?search_terms=${Uri.encodeComponent(query)}&json=1&page_size=10'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = data['products'] as List?;
        if (products != null && products.isNotEmpty) {
          final product = products.first;
          final servingSize = product['serving_size']?.toString();
          if (servingSize != null && servingSize.contains('g')) {
            final grams = double.tryParse(
                    servingSize.replaceAll(RegExp(r'[^\d.]'), '')) ??
                100.0;
            final multiplier = _estimatePortionMultiplier(unit, product);
            return grams * multiplier * amount;
          }
        }
      }
      return null;
    } catch (e) {
      _logger.e('Open Food Facts portion error for $ingredientName: $e');
      return null;
    }
  }

  /// Convert using density-based estimation
  static double _convertUsingDensity(
      double amount, String unit, String ingredientName) {
    final ingredientLower = _normalizeQuery(ingredientName);
    double density = _estimateDensity(ingredientLower);

    switch (unit) {
      case 'ml':
      case 'milliliter':
      case 'milliliters':
        final grams = amount * density;
        _logger.w(
            'Converted $amount ml to $grams g for $ingredientName using density $density');
        return grams;
      case 'cup':
      case 'cups':
        final grams = amount * density * 240.0; // 240ml per cup
        _logger.w(
            'Using density-based cup conversion ($density * 240g) for $ingredientName: $grams g');
        return grams;
      case 'tbsp':
      case 'tablespoon':
      case 'tablespoons':
        final grams = amount * density * 15.0; // 15ml per tbsp
        _logger.w(
            'Using density-based tbsp conversion ($density * 15g) for $ingredientName: $grams g');
        return grams;
      case 'tsp':
      case 'teaspoon':
      case 'teaspoons':
        final grams = amount * density * 5.0; // 5ml per tsp
        _logger.w(
            'Using density-based tsp conversion ($density * 5g) for $ingredientName: $grams g');
        return grams;
      default:
        _logger.w('Unknown unit $unit for $ingredientName, assuming grams');
        return amount;
    }
  }

  /// Estimate density based on ingredient type
  static double _estimateDensity(String ingredientLower) {
    if (ingredientLower.contains('oat') ||
        ingredientLower.contains('quinoa') ||
        ingredientLower.contains('grain')) {
      return 0.5; // Grains are less dense
    } else if (ingredientLower.contains('lentil') ||
        ingredientLower.contains('bean') ||
        ingredientLower.contains('legume')) {
      return 0.8; // Legumes are moderately dense
    } else if (ingredientLower.contains('oil') ||
        ingredientLower.contains('fat')) {
      return 0.9; // Oils are dense
    } else if (ingredientLower.contains('vegetable') ||
        ingredientLower.contains('fruit')) {
      return 0.2; // Most vegetables/fruits are light
    }
    return 1.0; // Default: 1g/ml
  }

  /// Estimate portion multiplier for Open Food Facts
  static double _estimatePortionMultiplier(
      String unit, Map<String, dynamic> product) {
    final unitLower = unit.toLowerCase();
    switch (unitLower) {
      case 'cup':
      case 'cups':
        return 1.0;
      case 'tbsp':
      case 'tablespoon':
      case 'tablespoons':
        return 0.0625; // 1 tbsp = 1/16 cup
      case 'tsp':
      case 'teaspoon':
      case 'teaspoons':
        return 0.02083; // 1 tsp = 1/48 cup
      case 'ml':
      case 'milliliter':
      case 'milliliters':
        return 0.00417; // 1 ml = 1/240 cup
      default:
        return 1.0;
    }
  }

  /// Normalize query for search
  static String _normalizeQuery(String query) {
    String normalized = query.toLowerCase().trim();
    normalized = normalized
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    return normalized;
  }
}
