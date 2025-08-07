import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

/// Service for managing environment-specific configurations
class ConfigService {
  static final _logger = Logger();
  static const String _defaultOpenAIUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _defaultModel = 'gpt-4o-mini'; // Changed from 'gpt-4o' to use 2.5M free tokens/day
  static const double _defaultTemperature = 0.7;
  static const int _defaultMaxTokens = 4000;

  /// Get OpenAI API key from environment variables
  static String get openAIApiKey {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_openai_api_key_here') {
      throw Exception('OPENAI_API_KEY not found or not configured. '
          'Please copy .env.example to .env and set your actual OpenAI API key.');
    }
    
    // Log the first and last few characters of the API key for debugging
    final maskedKey = '${apiKey.substring(0, 10)}...${apiKey.substring(apiKey.length - 10)}';
    _logger.i('ConfigService: Using OpenAI API key: $maskedKey');
    
    return apiKey;
  }

  /// Get OpenAI base URL (configurable for different environments)
  static String get openAIBaseUrl {
    return dotenv.env['OPENAI_BASE_URL'] ?? _defaultOpenAIUrl;
  }

  /// Get OpenAI model name (configurable for different environments)
  static String get openAIModel {
    return dotenv.env['OPENAI_MODEL'] ?? _defaultModel;
  }

  /// Get OpenAI temperature setting
  static double get openAITemperature {
    final temp = dotenv.env['OPENAI_TEMPERATURE'];
    if (temp != null) {
      return double.tryParse(temp) ?? _defaultTemperature;
    }
    return _defaultTemperature;
  }

  /// Get OpenAI max tokens setting
  static int get openAIMaxTokens {
    final tokens = dotenv.env['OPENAI_MAX_TOKENS'];
    if (tokens != null) {
      return int.tryParse(tokens) ?? _defaultMaxTokens;
    }
    return _defaultMaxTokens;
  }

  /// Get environment name (development, staging, production)
  static String get environment {
    return dotenv.env['ENVIRONMENT'] ?? 'development';
  }

  /// Check if running in development mode
  static bool get isDevelopment => environment == 'development';

  /// Check if running in production mode
  static bool get isProduction => environment == 'production';

  /// Check if running in staging mode
  static bool get isStaging => environment == 'staging';

  /// Get app version from environment
  static String get appVersion {
    return dotenv.env['APP_VERSION'] ?? '1.0.0';
  }

  /// Get build number from environment
  static String get buildNumber {
    return dotenv.env['BUILD_NUMBER'] ?? '1';
  }

  /// Get USDA API key from environment variables
  static String get usdaApiKey {
    return dotenv.env['USDA_API_KEY'] ?? 'DEMO_KEY';
  }

  /// Check if USDA API is enabled
  static bool get isUsdaApiEnabled {
    final key = usdaApiKey;
    return key.isNotEmpty && key != 'DEMO_KEY';
  }

  /// Validate that all required environment variables are set
  static void validateEnvironment() {
    final requiredVars = ['OPENAI_API_KEY'];
    final missingVars = <String>[];
    _logger.d(dotenv.env);
    for (final varName in requiredVars) {
      final value = dotenv.env[varName];
      if (value == null || value.isEmpty || value == 'your_openai_api_key_here') {
        missingVars.add(varName);
      }
    }

    if (missingVars.isNotEmpty) {
      throw Exception('Missing or invalid required environment variables: ${missingVars.join(', ')}. '
          'Please copy .env.example to .env and configure your API key.');
    }
  }

  /// Check if environment is properly configured
  static bool get isConfigured {
    try {
      validateEnvironment();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get configuration summary for debugging (without sensitive data)
  static Map<String, dynamic> getConfigSummary() {
    return {
      'environment': environment,
      'openAIBaseUrl': openAIBaseUrl,
      'openAIModel': openAIModel,
      'openAITemperature': openAITemperature,
      'openAIMaxTokens': openAIMaxTokens,
      'appVersion': appVersion,
      'buildNumber': buildNumber,
      'hasApiKey': openAIApiKey.isNotEmpty,
    };
  }
} 