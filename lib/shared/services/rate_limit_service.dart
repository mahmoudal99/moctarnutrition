import 'dart:async';
import 'dart:math';
import 'package:retry/retry.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Added for jsonDecode

/// Service for handling API rate limits and retries
class RateLimitService {
  static const int _maxRetries = 2; // Reduced from 3
  static const Duration _baseDelay =
      Duration(seconds: 5); // Increased from 2 seconds
  static const Duration _maxDelay =
      Duration(seconds: 30); // Increased from 15 seconds
  static const double _randomizationFactor = 0.25;

  // Track API calls to respect rate limits
  static final List<DateTime> _apiCallTimes = [];
  static const int _maxCallsPerMinute =
      10; // Reduced from 20 to be very conservative
  static const Duration _rateLimitWindow = Duration(minutes: 1);

  /// Initialize the rate limit service (call this on app startup)
  static void initialize() {
    print('RateLimitService: Initializing and clearing any stale data');
    _apiCallTimes.clear();
  }

  /// Make an API call with retry logic and rate limiting
  static Future<http.Response> makeApiCall({
    required Uri url,
    required Map<String, String> headers,
    required String body,
    String? context,
  }) async {
    // Disable internal rate limiting - let OpenAI handle it
    // await _checkRateLimit();

    return retry(
      () async {
        print('Making API call${context != null ? ' for $context' : ''}...');
        final response = await http.post(url, headers: headers, body: body);

        print(
            'API response status: ${response.statusCode}${context != null ? ' for $context' : ''}');

        // Handle rate limit errors
        if (response.statusCode == 429) {
          // Check if it's actually a quota error
          if (response.body.contains('insufficient_quota') ||
              response.body.contains('exceeded your current quota')) {
            print(
                'OpenAI quota exceeded${context != null ? ' for $context' : ''}');
            throw QuotaExceededException(
                'OpenAI quota exceeded - please check your billing');
          }

          print(
              'OpenAI rate limit hit${context != null ? ' for $context' : ''}, retrying...');
          print('Response body: ${response.body}');
          // Add extra delay for OpenAI rate limits
          await Future.delayed(Duration(seconds: 10));
          throw RateLimitException('OpenAI rate limit exceeded');
        }

        // Handle authentication errors
        if (response.statusCode == 401) {
          if (response.body.contains('Incorrect API key provided')) {
            print('Invalid API key${context != null ? ' for $context' : ''}');
            throw AuthenticationException(
                'Invalid API key - please check your configuration');
          } else if (response.body
              .contains('must be a member of an organization')) {
            print(
                'Organization membership required${context != null ? ' for $context' : ''}');
            throw AuthenticationException(
                'Organization membership required - contact OpenAI support');
          } else {
            print(
                'Authentication error${context != null ? ' for $context' : ''}');
            throw AuthenticationException(
                'Authentication failed - please check your API key');
          }
        }

        // Handle forbidden errors
        if (response.statusCode == 403) {
          if (response.body.contains('not supported')) {
            print(
                'Region not supported${context != null ? ' for $context' : ''}');
            throw RegionNotSupportedException(
                'Your region is not supported by OpenAI');
          } else {
            print('Forbidden error${context != null ? ' for $context' : ''}');
            throw ForbiddenException(
                'Access forbidden - please check your account permissions');
          }
        }

        // Handle server overload errors
        if (response.statusCode == 503) {
          if (response.body.contains('overloaded')) {
            print(
                'OpenAI servers overloaded${context != null ? ' for $context' : ''}, retrying...');
            await Future.delayed(
                const Duration(seconds: 30)); // Longer delay for server issues
            throw ServerOverloadedException(
                'OpenAI servers are overloaded - please try again later');
          } else if (response.body.contains('Slow Down')) {
            print(
                'Rate too high${context != null ? ' for $context' : ''}, retrying...');
            await Future.delayed(const Duration(
                seconds: 60)); // Much longer delay for rate issues
            throw SlowDownException('Request rate too high - please slow down');
          } else {
            print(
                'Server error 503${context != null ? ' for $context' : ''}, retrying...');
            await Future.delayed(Duration(seconds: 15));
            throw ServerException('Server error 503 - please try again later');
          }
        }

        // Handle other retryable errors
        if (response.statusCode >= 500) {
          print(
              'Server error ${response.statusCode}${context != null ? ' for $context' : ''}, retrying...');
          throw ServerException('Server error: ${response.statusCode}');
        }

        // Handle other errors
        if (response.statusCode != 200) {
          print(
              'API error ${response.statusCode}${context != null ? ' for $context' : ''}: ${response.body}');
          throw Exception(
              'API error: ${response.statusCode} - ${response.body}');
        }

        print('API call successful${context != null ? ' for $context' : ''}');
        
        // Track token usage for free token monitoring
        _trackTokenUsage(response, context);
        
        return response;
      },
      maxAttempts: _maxRetries,
      delayFactor: _baseDelay,
      randomizationFactor: _randomizationFactor,
      maxDelay: _maxDelay,
      onRetry: (e) {
        print(
            'Retrying API call${context != null ? ' for $context' : ''} due to: $e');
      },
    );
  }

  /// Check if we're within rate limits
  static Future<void> _checkRateLimit() async {
    final now = DateTime.now();

    // Remove old API call times (older than 1 minute)
    _apiCallTimes
        .removeWhere((time) => now.difference(time) > _rateLimitWindow);

    // Debug logging
    print(
        'Rate limit check: ${_apiCallTimes.length} calls in last minute, max: $_maxCallsPerMinute');

    // If we have no recent calls, we're definitely not rate limited
    if (_apiCallTimes.isEmpty) {
      print('Rate limit: No recent calls, proceeding with API call');
      _apiCallTimes.add(now);
      return;
    }

    // Check if we're at the limit
    if (_apiCallTimes.length >= _maxCallsPerMinute) {
      final oldestCall = _apiCallTimes.first;
      final timeToWait = _rateLimitWindow - now.difference(oldestCall);

      if (timeToWait.isNegative == false) {
        print(
            'Rate limit: Waiting ${timeToWait.inSeconds} seconds before next API call');
        await Future.delayed(timeToWait);
      }
    }

    // Add extra delay if we're approaching the limit
    if (_apiCallTimes.length >= _maxCallsPerMinute * 0.8) {
      print('Rate limit: Approaching limit, adding extra delay');
      await Future.delayed(Duration(milliseconds: 500));
    }

    // Record this API call
    _apiCallTimes.add(now);
    print(
        'Rate limit: Recorded API call, total in window: ${_apiCallTimes.length}');
  }

  /// Get current rate limit status
  static Map<String, dynamic> getRateLimitStatus() {
    final now = DateTime.now();
    final recentCalls = _apiCallTimes
        .where((time) => now.difference(time) <= _rateLimitWindow)
        .length;

    return {
      'callsInLastMinute': recentCalls,
      'maxCallsPerMinute': _maxCallsPerMinute,
      'remainingCalls': _maxCallsPerMinute - recentCalls,
      'rateLimitWindow': _rateLimitWindow.inSeconds,
    };
  }

  /// Reset rate limit tracking (useful for testing)
  static void resetRateLimit() {
    _apiCallTimes.clear();
  }

  /// Track token usage for free token monitoring
  static void _trackTokenUsage(http.Response response, String? context) {
    try {
      // Parse usage from response headers
      final usageHeader = response.headers['x-usage'];
      if (usageHeader != null) {
        final usage = jsonDecode(usageHeader);
        final promptTokens = usage['prompt_tokens'] ?? 0;
        final completionTokens = usage['completion_tokens'] ?? 0;
        final totalTokens = usage['total_tokens'] ?? 0;
        
        print('Token usage${context != null ? ' for $context' : ''}:');
        print('  - Prompt tokens: $promptTokens');
        print('  - Completion tokens: $completionTokens');
        print('  - Total tokens: $totalTokens');
        
        // Calculate remaining free tokens (2.5M for GPT-4o-mini)
        final dailyTokensUsed = _getDailyTokenUsage();
        final remainingFreeTokens = 2500000 - dailyTokensUsed;
        
        print('  - Daily tokens used: $dailyTokensUsed');
        print('  - Remaining free tokens: $remainingFreeTokens');
        
        if (remainingFreeTokens < 100000) {
          print('⚠️ WARNING: Low free token balance remaining!');
        }
      }
    } catch (e) {
      print('Error tracking token usage: $e');
    }
  }

  /// Get total tokens used today
  static int _getDailyTokenUsage() {
    // This would ideally be stored in a database or cache
    // For now, we'll return a placeholder
    return 0; // TODO: Implement actual daily token tracking
  }

  /// Calculate exponential backoff delay
  static Duration _calculateBackoffDelay(int attempt) {
    final delay = _baseDelay * pow(2, attempt - 1);
    final jitter = delay.inMilliseconds * _randomizationFactor;
    final finalDelay = delay.inMilliseconds + Random().nextInt(jitter.toInt());

    return Duration(
        milliseconds: finalDelay.clamp(0, _maxDelay.inMilliseconds));
  }
}

/// Custom exceptions for better error handling
class RateLimitException implements Exception {
  final String message;

  RateLimitException(this.message);

  @override
  String toString() => 'RateLimitException: $message';
}

class QuotaExceededException implements Exception {
  final String message;

  QuotaExceededException(this.message);

  @override
  String toString() => 'QuotaExceededException: $message';
}

class AuthenticationException implements Exception {
  final String message;

  AuthenticationException(this.message);

  @override
  String toString() => 'AuthenticationException: $message';
}

class RegionNotSupportedException implements Exception {
  final String message;

  RegionNotSupportedException(this.message);

  @override
  String toString() => 'RegionNotSupportedException: $message';
}

class ForbiddenException implements Exception {
  final String message;

  ForbiddenException(this.message);

  @override
  String toString() => 'ForbiddenException: $message';
}

class ServerOverloadedException implements Exception {
  final String message;

  ServerOverloadedException(this.message);

  @override
  String toString() => 'ServerOverloadedException: $message';
}

class SlowDownException implements Exception {
  final String message;

  SlowDownException(this.message);

  @override
  String toString() => 'SlowDownException: $message';
}

class ServerException implements Exception {
  final String message;

  ServerException(this.message);

  @override
  String toString() => 'ServerException: $message';
}
