import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'config_service.dart';

/// Service responsible for USDA API interactions
class USDAClientService {
  static const String _usdaBaseUrl = 'https://api.nal.usda.gov/fdc/v1';
  static final _logger = Logger();

  static String get _apiKey => ConfigService.usdaApiKey;

  /// Search for a food item in USDA database
  static Future<List<USDASearchResult>> searchFood(String query) async {
    try {
      _logger.i('Searching USDA for: $query');

      final response = await http.get(
        Uri.parse(
            '$_usdaBaseUrl/foods/search?api_key=$_apiKey&query=${Uri.encodeComponent(query)}&pageSize=25&dataType=Foundation,Survey'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final foods = data['foods'] as List;
        final results =
            foods.map((food) => USDASearchResult.fromJson(food)).toList();

        _logger.i('USDA search returned ${results.length} results for: $query');

        if (results.isEmpty) {
          _logger.w('No USDA results for $query, retrying with broad query');
          return await _searchWithBroadQuery(query);
        }

        return results;
      } else {
        _logger.e('USDA API Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      _logger.e('USDA API Search Error: $e');
      return [];
    }
  }

  /// Search with a broader query when initial search fails
  static Future<List<USDASearchResult>> _searchWithBroadQuery(
      String query) async {
    try {
      final broadQuery = query.split(' ').first;
      _logger.i('Retrying USDA search with broad query: $broadQuery');

      final response = await http.get(
        Uri.parse(
            '$_usdaBaseUrl/foods/search?api_key=$_apiKey&query=${Uri.encodeComponent(broadQuery)}&pageSize=25&dataType=Foundation,Survey'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final foods = data['foods'] as List;
        final results =
            foods.map((food) => USDASearchResult.fromJson(food)).toList();

        _logger.i(
            'Broad USDA search returned ${results.length} results for: $broadQuery');
        return results;
      } else {
        _logger.e(
            'USDA API Broad Search Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      _logger.e('USDA API Broad Search Error: $e');
      return [];
    }
  }

  /// Get detailed nutritional information for a specific food
  static Future<USDAFoodDetails?> getFoodDetails(int fdcId) async {
    try {
      _logger.i('Getting USDA food details for FDC ID: $fdcId');

      final response = await http.get(
        Uri.parse('$_usdaBaseUrl/food/$fdcId?api_key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final foodDetails = USDAFoodDetails.fromJson(data);

        _logger.i('Retrieved USDA food details: ${foodDetails.description}');
        return foodDetails;
      } else {
        _logger.e(
            'USDA API Details Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('USDA API Details Error: $e');
      return null;
    }
  }

  /// Test USDA API connectivity
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_usdaBaseUrl/foods/search?api_key=$_apiKey&query=apple&pageSize=1'),
        headers: {'Content-Type': 'application/json'},
      );

      final isConnected = response.statusCode == 200;
      _logger
          .i('USDA API connection test: ${isConnected ? 'SUCCESS' : 'FAILED'}');
      return isConnected;
    } catch (e) {
      _logger.e('USDA API connection test failed: $e');
      return false;
    }
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

  @override
  String toString() {
    return 'USDASearchResult(fdcId: $fdcId, description: $description, brandOwner: $brandOwner, dataType: $dataType)';
  }
}

/// USDA food details model
class USDAFoodDetails {
  final int fdcId;
  final String description;
  final String brandOwner;
  final Map<String, double> nutritionPer100g;
  final List<Map<String, dynamic>> foodPortions;

  USDAFoodDetails({
    required this.fdcId,
    required this.description,
    required this.brandOwner,
    required this.nutritionPer100g,
    required this.foodPortions,
  });

  factory USDAFoodDetails.fromJson(Map<String, dynamic> json) {
    final nutrients = <String, double>{};
    final portions =
        (json['foodPortions'] as List? ?? []).cast<Map<String, dynamic>>();

    if (json['foodNutrients'] != null) {
      final foodNutrients = json['foodNutrients'] as List;
      for (final nutrient in foodNutrients) {
        final nutrientName =
            nutrient['nutrient']?['name']?.toString().toLowerCase() ?? '';
        final value = nutrient['amount']?.toDouble() ?? 0.0;

        // Map USDA nutrient names to our format
        if (nutrientName.contains('energy') ||
            nutrientName.contains('calories') ||
            nutrientName.contains('kcal')) {
          nutrients['calories'] = value;
        } else if (nutrientName.contains('protein')) {
          nutrients['protein'] = value;
        } else if (nutrientName.contains('carbohydrate') ||
            nutrientName.contains('carb') ||
            nutrientName.contains('total carbohydrate')) {
          nutrients['carbs'] = value;
        } else if (nutrientName.contains('total lipid') ||
            nutrientName.contains('fat') ||
            nutrientName.contains('total fat')) {
          nutrients['fat'] = value;
        } else if (nutrientName.contains('fiber') ||
            nutrientName.contains('dietary fiber') ||
            nutrientName.contains('total dietary fiber')) {
          nutrients['fiber'] = value;
        } else if (nutrientName.contains('sugars') ||
            nutrientName.contains('sugar') ||
            nutrientName.contains('total sugars')) {
          nutrients['sugar'] = value;
        } else if (nutrientName.contains('sodium')) {
          nutrients['sodium'] = value;
        }
      }
    }

    return USDAFoodDetails(
      fdcId: json['fdcId'] ?? 0,
      description: json['description'] ?? '',
      brandOwner: json['brandOwner'] ?? '',
      nutritionPer100g: nutrients,
      foodPortions: portions,
    );
  }

  @override
  String toString() {
    return 'USDAFoodDetails(fdcId: $fdcId, description: $description, nutritionPer100g: $nutritionPer100g)';
  }
}
