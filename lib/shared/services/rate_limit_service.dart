import 'dart:async';
import 'dart:math';
import 'package:retry/retry.dart';
import 'package:http/http.dart' as http;

/// Service for handling API rate limits and retries
class RateLimitService {
  static const int _maxRetries = 3;
  static const Duration _baseDelay = Duration(seconds: 1);
  static const Duration _maxDelay = Duration(seconds: 10);
  static const double _randomizationFactor = 0.25;
  
  // Track API calls to respect rate limits
  static final List<DateTime> _apiCallTimes = [];
  static const int _maxCallsPerMinute = 50; // Conservative limit
  static const Duration _rateLimitWindow = Duration(minutes: 1);

  /// Make an API call with retry logic and rate limiting
  static Future<http.Response> makeApiCall({
    required Uri url,
    required Map<String, String> headers,
    required String body,
    String? context,
  }) async {
    // Check rate limit before making call
    await _checkRateLimit();

    return retry(
      () async {
        final response = await http.post(url, headers: headers, body: body);
        
        // Handle rate limit errors
        if (response.statusCode == 429) {
          print('Rate limit hit${context != null ? ' for $context' : ''}, retrying...');
          throw RateLimitException('Rate limit exceeded');
        }
        
        // Handle other retryable errors
        if (response.statusCode >= 500) {
          print('Server error ${response.statusCode}${context != null ? ' for $context' : ''}, retrying...');
          throw ServerException('Server error: ${response.statusCode}');
        }
        
        return response;
      },
      maxAttempts: _maxRetries,
      delayFactor: _baseDelay,
      randomizationFactor: _randomizationFactor,
      maxDelay: _maxDelay,
      onRetry: (e) {
        print('Retrying API call${context != null ? ' for $context' : ''} due to: $e');
      },
    );
  }

  /// Check if we're within rate limits
  static Future<void> _checkRateLimit() async {
    final now = DateTime.now();
    
    // Remove old API call times
    _apiCallTimes.removeWhere((time) => now.difference(time) > _rateLimitWindow);
    
    // Check if we're at the limit
    if (_apiCallTimes.length >= _maxCallsPerMinute) {
      final oldestCall = _apiCallTimes.first;
      final timeToWait = _rateLimitWindow - now.difference(oldestCall);
      
      if (timeToWait.isNegative == false) {
        print('Rate limit: Waiting ${timeToWait.inSeconds} seconds before next API call');
        await Future.delayed(timeToWait);
      }
    }
    
    // Record this API call
    _apiCallTimes.add(now);
  }

  /// Get current rate limit status
  static Map<String, dynamic> getRateLimitStatus() {
    final now = DateTime.now();
    final recentCalls = _apiCallTimes.where(
      (time) => now.difference(time) <= _rateLimitWindow
    ).length;
    
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

  /// Calculate exponential backoff delay
  static Duration _calculateBackoffDelay(int attempt) {
    final delay = _baseDelay * pow(2, attempt - 1);
    final jitter = delay.inMilliseconds * _randomizationFactor;
    final finalDelay = delay.inMilliseconds + Random().nextInt(jitter.toInt());
    
    return Duration(milliseconds: finalDelay.clamp(0, _maxDelay.inMilliseconds));
  }
}

/// Custom exceptions for better error handling
class RateLimitException implements Exception {
  final String message;
  RateLimitException(this.message);
  
  @override
  String toString() => 'RateLimitException: $message';
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);
  
  @override
  String toString() => 'ServerException: $message';
} 