import 'dart:convert';

/// Utility class for cleaning and fixing JSON responses from AI
class JsonUtils {
  /// Clean and fix common JSON issues from AI responses
  static String cleanAndFixJson(String aiResponse) {
    // Remove markdown code fences if present
    String cleanResponse = aiResponse.trim();
    if (cleanResponse.startsWith('```')) {
      int firstNewline = cleanResponse.indexOf('\n');
      if (firstNewline != -1) {
        cleanResponse = cleanResponse.substring(firstNewline + 1);
      }
      if (cleanResponse.endsWith('```')) {
        cleanResponse = cleanResponse.substring(0, cleanResponse.length - 3);
      }
    }

    // Extract JSON from AI response
    final jsonStart = cleanResponse.indexOf('{');
    final jsonEnd = cleanResponse.lastIndexOf('}') + 1;
    if (jsonStart == -1 || jsonEnd == 0) {
      throw Exception('No JSON found in AI response');
    }

    String jsonString = cleanResponse.substring(jsonStart, jsonEnd);

    // Validate JSON structure
    _validateJsonStructure(jsonString);

    // Remove comments and other non-JSON content
    String cleanedJson = _removeComments(jsonString);

    // Remove empty lines and extra whitespace
    cleanedJson = _removeEmptyLines(cleanedJson);

    // Remove trailing commas before closing brackets/braces
    cleanedJson = _removeTrailingCommas(cleanedJson);

    // Fix common JSON issues from AI responses
    cleanedJson = _fixFractions(cleanedJson);

    return cleanedJson;
  }

  /// Validate that JSON has balanced braces and brackets
  static void _validateJsonStructure(String jsonString) {
    final openBraces = '{'.allMatches(jsonString).length;
    final closeBraces = '}'.allMatches(jsonString).length;
    final openBrackets = '['.allMatches(jsonString).length;
    final closeBrackets = ']'.allMatches(jsonString).length;

    if (openBraces != closeBraces || openBrackets != closeBrackets) {
      print('JSON appears to be truncated. Open braces: $openBraces, Close braces: $closeBraces');
      print('Open brackets: $openBrackets, Close brackets: $closeBrackets');
      throw Exception('AI response was truncated. Please try again.');
    }
  }

  /// Remove single-line and multi-line comments
  static String _removeComments(String jsonString) {
    // Remove single-line comments (// ...)
    String cleaned = jsonString.replaceAll(RegExp(r'//.*$', multiLine: true), '');

    // Remove multi-line comments (/* ... */)
    cleaned = cleaned.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');

    return cleaned;
  }

  /// Remove empty lines and extra whitespace
  static String _removeEmptyLines(String jsonString) {
    return jsonString
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .join('\n');
  }

  /// Remove trailing commas before closing brackets/braces
  static String _removeTrailingCommas(String jsonString) {
    return jsonString.replaceAllMapped(
      RegExp(r',(\s*[}\]])'),
      (match) => match.group(1) ?? '',
    );
  }

  /// Fix fractions like 1/2, 1/4, etc. to decimal values
  static String _fixFractions(String jsonString) {
    // Fix fractions like 1/2, 1/4, etc.
    String fixed = jsonString.replaceAllMapped(
      RegExp(r':\s*(\d+)/(\d+)'),
      (match) {
        final numerator = double.parse(match.group(1) ?? '0');
        final denominator = double.parse(match.group(2) ?? '1');
        final result = numerator / denominator;
        return ': $result';
      },
    );

    // Fix quoted fractions like "1/2"
    fixed = fixed.replaceAllMapped(
      RegExp(r':\s*"(\d+)/(\d+)"'),
      (match) {
        final numerator = double.parse(match.group(1) ?? '0');
        final denominator = double.parse(match.group(2) ?? '1');
        final result = numerator / denominator;
        return ': $result';
      },
    );

    return fixed;
  }

  /// Parse JSON with error handling and logging
  static Map<String, dynamic> parseJson(String jsonString, {String? context}) {
    try {
      final data = jsonDecode(jsonString);
      return Map<String, dynamic>.from(data);
    } catch (e) {
      print('JSON parsing failed${context != null ? ' for $context' : ''}: $e');
      print('JSON string: $jsonString');
      throw Exception('Failed to parse JSON${context != null ? ' for $context' : ''}: $e');
    }
  }

  /// Safely convert numeric values to int
  static int safeToInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Safely convert numeric values to double
  static double safeToDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
} 