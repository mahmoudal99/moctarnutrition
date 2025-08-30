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
        final response = await http.post(url, headers: headers, body: body);


        // Handle rate limit errors
        if (response.statusCode == 429) {
          // Check if it's actually a quota error
          if (response.body.contains('insufficient_quota') ||
              response.body.contains('exceeded your current quota')) {
            throw QuotaExceededException(
                'OpenAI quota exceeded - please check your billing');
          }

          // Add extra delay for OpenAI rate limits
          await Future.delayed(const Duration(seconds: 10));
          throw RateLimitException('OpenAI rate limit exceeded');
        }

        // Handle authentication errors
        if (response.statusCode == 401) {
          if (response.body.contains('Incorrect API key provided')) {
            throw AuthenticationException(
                'Invalid API key - please check your configuration');
          } else if (response.body
              .contains('must be a member of an organization')) {
            throw AuthenticationException(
                'Organization membership required - contact OpenAI support');
          } else {
            throw AuthenticationException(
                'Authentication failed - please check your API key');
          }
        }

        // Handle forbidden errors
        if (response.statusCode == 403) {
          if (response.body.contains('not supported')) {
            throw RegionNotSupportedException(
                'Your region is not supported by OpenAI');
          } else {
            throw ForbiddenException(
                'Access forbidden - please check your account permissions');
          }
        }

        // Handle server overload errors
        if (response.statusCode == 503) {
          if (response.body.contains('overloaded')) {
            await Future.delayed(
                const Duration(seconds: 30)); // Longer delay for server issues
            throw ServerOverloadedException(
                'OpenAI servers are overloaded - please try again later');
          } else if (response.body.contains('Slow Down')) {
            await Future.delayed(const Duration(
                seconds: 60)); // Much longer delay for rate issues
            throw SlowDownException('Request rate too high - please slow down');
          } else {
            await Future.delayed(const Duration(seconds: 15));
            throw ServerException('Server error 503 - please try again later');
          }
        }

        // Handle other retryable errors
        if (response.statusCode >= 500) {
          throw ServerException('Server error: ${response.statusCode}');
        }

        // Handle other errors
        if (response.statusCode != 200) {
          throw Exception(
              'API error: ${response.statusCode} - ${response.body}');
        }


        // Track token usage for free token monitoring
        _trackTokenUsage(response, context);

        return response;
      },
      maxAttempts: _maxRetries,
      delayFactor: _baseDelay,
      randomizationFactor: _randomizationFactor,
      maxDelay: _maxDelay,
      onRetry: (e) {
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

    // If we have no recent calls, we're definitely not rate limited
    if (_apiCallTimes.isEmpty) {
      _apiCallTimes.add(now);
      return;
    }

    // Check if we're at the limit
    if (_apiCallTimes.length >= _maxCallsPerMinute) {
      final oldestCall = _apiCallTimes.first;
      final timeToWait = _rateLimitWindow - now.difference(oldestCall);

      if (timeToWait.isNegative == false) {
        await Future.delayed(timeToWait);
      }
    }

    // Add extra delay if we're approaching the limit
    if (_apiCallTimes.length >= _maxCallsPerMinute * 0.8) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Record this API call
    _apiCallTimes.add(now);
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
        final completionTokens = usage['completion_tokens'] ?? 0;
        final totalTokens = usage['total_tokens'] ?? 0;


        // Calculate remaining free tokens (2.5M for GPT-4o-mini)
        final dailyTokensUsed = _getDailyTokenUsage();
        final remainingFreeTokens = 2500000 - dailyTokensUsed;


        if (remainingFreeTokens < 100000) {
        }
      }
    } catch (e) {
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
