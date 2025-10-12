import 'package:flutter/material.dart';
import '../shared/services/logging_service.dart';

/// Example demonstrating the new LoggingService features
/// This file shows how to use structured logging throughout your app
class LoggingExampleService {
  
  /// Example of basic logging
  static void demonstrateBasicLogging() {
    LoggingService.instance.d('This is a debug message');
    LoggingService.instance.i('This is an info message');
    LoggingService.instance.w('This is a warning message');
    LoggingService.instance.e('This is an error message');
  }

  /// Example of structured authentication logging
  static void demonstrateAuthLogging() {
    // Log authentication events with context
    LoggingService.logAuthEvent(
      'User login attempt',
      metadata: {
        'method': 'email',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Use category-specific logger
    LoggingService.auth.i('Authentication successful');
    LoggingService.auth.w('Invalid credentials provided');
  }

  /// Example of meal-related logging
  static void demonstrateMealLogging() {
    // Log meal operations with nutrition data
    LoggingService.logMealOperation(
      'Meal plan generated',
      mealName: 'Breakfast Bowl',
      nutritionData: {
        'calories': 450,
        'protein': 25.5,
        'carbs': 35.2,
        'fat': 18.3,
      },
      metadata: {
        'userId': 'user123',
        'planType': 'weight_loss',
      },
    );

    // Use category-specific logger
    LoggingService.meal.d('Meal preferences updated');
  }

  /// Example of workout logging
  static void demonstrateWorkoutLogging() {
    // Log workout operations with exercise data
    LoggingService.logWorkoutOperation(
      'Workout completed',
      workoutName: 'Upper Body Strength',
      exerciseData: {
        'exercises': 6,
        'totalSets': 18,
        'duration': '45 minutes',
      },
      metadata: {
        'userId': 'user123',
        'difficulty': 'intermediate',
      },
    );

    // Use category-specific logger
    LoggingService.workout.i('Exercise form validated');
  }

  /// Example of network/API logging
  static void demonstrateNetworkLogging() {
    // Log API calls with timing and status
    LoggingService.logApiCall(
      'POST',
      '/api/meal-plans',
      statusCode: 201,
      duration: Duration(milliseconds: 250),
      requestData: {
        'userId': 'user123',
        'preferences': ['vegetarian', 'low_carb'],
      },
      responseData: {
        'planId': 'plan456',
        'meals': 21,
      },
    );

    // Use category-specific logger
    LoggingService.network.d('Request headers: {Authorization: Bearer token}');
  }

  /// Example of performance logging
  static void demonstratePerformanceLogging() {
    // Method 1: Using PerformanceTimer extension
    final timer = 'Database query'.startTimer(metadata: {
      'table': 'users',
      'operation': 'SELECT',
    });
    
    // Simulate some work
    Future.delayed(Duration(milliseconds: 100), () {
      timer.end(); // This will automatically log the performance
    });

    // Method 2: Manual performance logging
    final startTime = DateTime.now();
    // ... do some work ...
    final duration = DateTime.now().difference(startTime);
    LoggingService.logPerformance(
      'Image processing',
      duration: duration,
      metadata: {
        'imageSize': '2.5MB',
        'format': 'JPEG',
        'operations': ['resize', 'compress'],
      },
    );
  }

  /// Example of error logging with context
  static void demonstrateErrorLogging() {
    try {
      // Simulate an error
      throw Exception('Database connection failed');
    } catch (e, stackTrace) {
      LoggingService.logError(
        'Failed to fetch user data',
        error: e,
        stackTrace: stackTrace,
        context: 'UserService.fetchUser',
        metadata: {
          'userId': 'user123',
          'endpoint': '/api/users/user123',
          'retryCount': 3,
        },
      );
    }
  }

  /// Example of user action logging for analytics
  static void demonstrateUserActionLogging() {
    // Log user interactions for analytics
    LoggingService.logUserAction(
      'meal_plan_viewed',
      metadata: {
        'planId': 'plan456',
        'viewDuration': '2m 30s',
        'scrollDepth': 0.8,
      },
    );

    LoggingService.logFeatureUsage(
      'meal_prep_export',
      metadata: {
        'format': 'PDF',
        'mealCount': 7,
        'userId': 'user123',
      },
    );
  }

  /// Example of category-specific logging
  static void demonstrateCategoryLogging() {
    // Each category has its own logger with appropriate levels
    LoggingService.auth.d('Debug auth info');
    LoggingService.network.i('Network status update');
    LoggingService.meal.w('Meal preference warning');
    LoggingService.workout.e('Workout error occurred');
    LoggingService.performance.i('Performance metric recorded');
  }

  /// Example of app lifecycle logging
  static void demonstrateAppLifecycleLogging() {
    // These are typically called in main.dart
    LoggingService.logAppStart();
    
    // ... app initialization ...
    
    // Log app shutdown (if needed)
    LoggingService.logAppShutdown();
  }

  /// Example of conditional logging based on environment
  static void demonstrateEnvironmentAwareLogging() {
    // Debug logs are automatically filtered in production
    LoggingService.instance.d('This will only show in debug mode');
    
    // Info logs show in both debug and production
    LoggingService.instance.i('This will show in both environments');
    
    // Warning and error logs always show
    LoggingService.instance.w('This will always show');
    LoggingService.instance.e('This will always show');
  }

  /// Example of logging in a Flutter widget
  static Widget createExampleWidget() {
    return Builder(
      builder: (context) {
        // Log widget build
        LoggingService.instance.d('ExampleWidget built');
        
        return ElevatedButton(
          onPressed: () {
            // Log user interaction
            LoggingService.logUserAction(
              'example_button_pressed',
              metadata: {'widget': 'ExampleWidget'},
            );
            
            // Log feature usage
            LoggingService.logFeatureUsage(
              'example_feature',
              metadata: {'context': 'demo'},
            );
          },
          child: Text('Example Button'),
        );
      },
    );
  }
}

/// Example of how to use logging in a service class
class ExampleService {
  static Future<void> performOperation() async {
    final timer = 'ExampleService.performOperation'.startTimer();
    
    try {
      LoggingService.instance.i('Starting operation');
      
      // Simulate some work
      await Future.delayed(Duration(milliseconds: 500));
      
      LoggingService.instance.i('Operation completed successfully');
      
    } catch (e, stackTrace) {
      LoggingService.logError(
        'Operation failed',
        error: e,
        stackTrace: stackTrace,
        context: 'ExampleService.performOperation',
      );
      rethrow;
    } finally {
      timer.end();
    }
  }
}

/// Example of logging in a provider/state management
class ExampleProvider extends ChangeNotifier {
  void updateState() {
    LoggingService.instance.d('ExampleProvider state updated');
    notifyListeners();
  }
  
  void handleError(dynamic error) {
    LoggingService.logError(
      'Provider error',
      error: error,
      context: 'ExampleProvider',
    );
  }
}
