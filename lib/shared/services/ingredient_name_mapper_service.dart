import 'package:logger/logger.dart';

/// Service responsible for mapping AI-generated ingredient names to USDA-compatible search terms
class IngredientNameMapperService {
  static final _logger = Logger();
  static final _nameMappingCache = <String, String>{};

  /// Map AI-generated ingredient name to USDA-compatible search term
  /// For now, just return the original name - USDA can handle most ingredient names directly
  static Future<String> mapToUSDASearchTerm(String aiGeneratedName) async {
    // Check cache first
    if (_nameMappingCache.containsKey(aiGeneratedName)) {
      _logger.i(
          'Using cached name mapping: $aiGeneratedName -> ${_nameMappingCache[aiGeneratedName]}');
      return _nameMappingCache[aiGeneratedName]!;
    }

    // For now, just return the original name - USDA can handle most ingredient names
    final searchTerm = aiGeneratedName.trim();

    // Cache the result
    _nameMappingCache[aiGeneratedName] = searchTerm;

    _logger.i('Mapped $aiGeneratedName to USDA search term: $searchTerm');
    return searchTerm;
  }

  /// Clear the name mapping cache
  static void clearCache() {
    _nameMappingCache.clear();
    _logger.i('Name mapping cache cleared');
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _nameMappingCache.length,
      'cachedMappings': _nameMappingCache.keys.toList(),
    };
  }
}
