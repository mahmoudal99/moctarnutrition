import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized logging service for Moctar Nutrition app
/// Provides environment-aware logging with different configurations for debug/production
class LoggingService {
  static Logger? _instance;
  static Logger? _performanceLogger;
  static Logger? _networkLogger;
  static Logger? _authLogger;
  static Logger? _mealLogger;
  static Logger? _workoutLogger;

  /// Simple logger for minimal output (no boxes, no stack traces)
  static Logger get simple {
    return Logger(
      printer: SimplePrinter(
        printTime: true,
        colors: false,
      ),
      level: kDebugMode ? Level.debug : Level.warning,
    );
  }

  /// Main application logger
  static Logger get instance {
    _instance ??= _createLogger(
      name: 'MoctarNutrition',
      level: kDebugMode ? Level.debug : Level.warning,
    );
    return _instance!;
  }

  /// Performance monitoring logger
  static Logger get performance {
    _performanceLogger ??= _createLogger(
      name: 'Performance',
      level: kDebugMode ? Level.debug : Level.info,
    );
    return _performanceLogger!;
  }

  /// Network operations logger
  static Logger get network {
    _networkLogger ??= _createLogger(
      name: 'Network',
      level: kDebugMode ? Level.debug : Level.warning,
    );
    return _networkLogger!;
  }

  /// Authentication operations logger
  static Logger get auth {
    _authLogger ??= _createLogger(
      name: 'Auth',
      level: kDebugMode ? Level.debug : Level.warning,
    );
    return _authLogger!;
  }

  /// Meal planning and nutrition logger
  static Logger get meal {
    _mealLogger ??= _createLogger(
      name: 'Meal',
      level: kDebugMode ? Level.debug : Level.info,
    );
    return _mealLogger!;
  }

  /// Workout operations logger
  static Logger get workout {
    _workoutLogger ??= _createLogger(
      name: 'Workout',
      level: kDebugMode ? Level.debug : Level.info,
    );
    return _workoutLogger!;
  }

  /// Create a logger instance with environment-aware configuration
  static Logger _createLogger({
    required String name,
    required Level level,
    bool useMinimalFormat = false,
  }) {
    if (kDebugMode) {
      if (useMinimalFormat) {
        // Debug mode: Minimal format for cleaner output
        return Logger(
          printer: SimplePrinter(
            printTime: true,
            colors: false,
          ),
          level: level,
          filter: _CustomLogFilter(name),
        );
      } else {
        // Debug mode: Rich logging without ANSI colors (Flutter-friendly)
        return Logger(
          printer: PrettyPrinter(
            methodCount: 2, // Number of method calls to display
            errorMethodCount: 8, // Number of method calls if stacktrace is provided
            lineLength: 120, // Width of the output
            colors: false, // Disable colors to avoid ANSI escape codes in Flutter
            printEmojis: true, // Print an emoji for each log message
            dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart, // Use new format instead of printTime
            noBoxingByDefault: false, // Enable boxing by default
          ),
          level: level,
          filter: _CustomLogFilter(name),
        );
      }
    } else {
      // Production mode: Simple, minimal logging
      return Logger(
        printer: SimplePrinter(
          printTime: true,
          colors: false,
        ),
        level: level,
        filter: _CustomLogFilter(name),
      );
    }
  }

  /// Log app startup information
  static void logAppStart() {
    instance.i('🚀 Moctar Nutrition app starting...');
    instance.d('Debug mode: $kDebugMode');
    instance.d('Platform: ${defaultTargetPlatform.name}');
  }

  /// Log app shutdown information
  static void logAppShutdown() {
    instance.i('👋 Moctar Nutrition app shutting down...');
  }

  /// Log feature usage for analytics
  static void logFeatureUsage(String feature, {Map<String, dynamic>? metadata}) {
    instance.i('📊 Feature used: $feature', error: metadata);
  }

  /// Log user action for analytics
  static void logUserAction(String action, {Map<String, dynamic>? metadata}) {
    instance.i('👤 User action: $action', error: metadata);
  }

  /// Log error with context
  static void logError(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    final errorContext = context != null ? '[$context] ' : '';
    instance.e(
      '$errorContext$message',
      error: error,
      stackTrace: stackTrace,
    );
    
    if (metadata != null) {
      instance.d('Error metadata: $metadata');
    }
  }

  /// Log API call
  static void logApiCall(
    String method,
    String url, {
    int? statusCode,
    Duration? duration,
    Map<String, dynamic>? requestData,
    Map<String, dynamic>? responseData,
  }) {
    final statusEmoji = _getStatusEmoji(statusCode);
    final durationStr = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
    
    network.i('$statusEmoji $method $url$durationStr');
    
    if (requestData != null && kDebugMode) {
      network.d('Request data: $requestData');
    }
    
    if (responseData != null && kDebugMode) {
      network.d('Response data: $responseData');
    }
  }

  /// Log performance metrics
  static void logPerformance(
    String operation, {
    required Duration duration,
    Map<String, dynamic>? metadata,
  }) {
    final emoji = duration.inMilliseconds > 1000 ? '🐌' : '⚡';
    performance.i('$emoji $operation: ${duration.inMilliseconds}ms');
    
    if (metadata != null && kDebugMode) {
      performance.d('Performance metadata: $metadata');
    }
  }

  /// Log meal-related operations
  static void logMealOperation(
    String operation, {
    String? mealName,
    Map<String, dynamic>? nutritionData,
    Map<String, dynamic>? metadata,
  }) {
    final mealInfo = mealName != null ? ' "$mealName"' : '';
    meal.i('🍽️ $operation$mealInfo');
    
    if (nutritionData != null && kDebugMode) {
      meal.d('Nutrition data: $nutritionData');
    }
    
    if (metadata != null && kDebugMode) {
      meal.d('Meal metadata: $metadata');
    }
  }

  /// Log workout-related operations
  static void logWorkoutOperation(
    String operation, {
    String? workoutName,
    Map<String, dynamic>? exerciseData,
    Map<String, dynamic>? metadata,
  }) {
    final workoutInfo = workoutName != null ? ' "$workoutName"' : '';
    workout.i('💪 $operation$workoutInfo');
    
    if (exerciseData != null && kDebugMode) {
      workout.d('Exercise data: $exerciseData');
    }
    
    if (metadata != null && kDebugMode) {
      workout.d('Workout metadata: $metadata');
    }
  }

  /// Log authentication events
  static void logAuthEvent(
    String event, {
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    final userInfo = userId != null ? ' (User: $userId)' : '';
    auth.i('🔐 $event$userInfo');
    
    if (metadata != null && kDebugMode) {
      auth.d('Auth metadata: $metadata');
    }
  }

  /// Get emoji for HTTP status codes
  static String _getStatusEmoji(int? statusCode) {
    if (statusCode == null) return '❓';
    if (statusCode >= 200 && statusCode < 300) return '✅';
    if (statusCode >= 300 && statusCode < 400) return '🔄';
    if (statusCode >= 400 && statusCode < 500) return '⚠️';
    if (statusCode >= 500) return '❌';
    return '❓';
  }

  /// Dispose all logger instances
  static void dispose() {
    _instance = null;
    _performanceLogger = null;
    _networkLogger = null;
    _authLogger = null;
    _mealLogger = null;
    _workoutLogger = null;
  }
}

/// Custom log filter to add category names to log messages
class _CustomLogFilter extends LogFilter {
  final String category;

  _CustomLogFilter(this.category);

  @override
  bool shouldLog(LogEvent event) {
    return true; // Let the Logger handle level filtering
  }
}

/// Performance measurement utility
class PerformanceTimer {
  final String operation;
  final DateTime _startTime;
  final Map<String, dynamic>? _metadata;

  PerformanceTimer(this.operation, {Map<String, dynamic>? metadata})
      : _startTime = DateTime.now(),
        _metadata = metadata;

  /// End the timer and log the performance
  void end() {
    final duration = DateTime.now().difference(_startTime);
    LoggingService.logPerformance(operation, duration: duration, metadata: _metadata);
  }
}

/// Extension to easily start performance timers
extension PerformanceLogging on String {
  PerformanceTimer startTimer({Map<String, dynamic>? metadata}) {
    return PerformanceTimer(this, metadata: metadata);
  }
}
