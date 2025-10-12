# Logging Migration Guide

This guide helps you migrate from the old logging patterns to the new centralized `LoggingService`.

## Quick Migration Steps

### 1. Update Imports
```dart
// OLD
import 'package:logger/logger.dart';

// NEW
import 'logging_service.dart';
```

### 2. Replace Logger Instances
```dart
// OLD
class MyService {
  static final _logger = Logger();
}

// NEW
class MyService {
  // Remove logger instance - use LoggingService directly
}
```

### 3. Update Logging Calls

#### Basic Logging
```dart
// OLD
_logger.d('Debug message');
_logger.i('Info message');
_logger.w('Warning message');
_logger.e('Error message');

// NEW
LoggingService.instance.d('Debug message');
LoggingService.instance.i('Info message');
LoggingService.instance.w('Warning message');
LoggingService.instance.e('Error message');
```

#### Structured Logging
```dart
// OLD
_logger.i('User signed in: $userId');

// NEW
LoggingService.logAuthEvent('User signed in', userId: userId);

// OLD
_logger.i('Meal consumed: ${meal.name}');

// NEW
LoggingService.logMealOperation('Meal consumed', mealName: meal.name);

// OLD
_logger.i('Workout completed: ${workout.name}');

// NEW
LoggingService.logWorkoutOperation('Workout completed', workoutName: workout.name);
```

#### Error Logging
```dart
// OLD
_logger.e('API call failed: $error');

// NEW
LoggingService.logError(
  'API call failed',
  error: error,
  context: 'API',
  metadata: {'endpoint': '/api/users'},
);
```

#### Performance Logging
```dart
// OLD
final stopwatch = Stopwatch()..start();
// ... do work ...
_logger.i('Operation took ${stopwatch.elapsedMilliseconds}ms');

// NEW
final timer = 'Database query'.startTimer();
// ... do work ...
timer.end();
```

#### Network Logging
```dart
// OLD
_logger.i('GET /api/users - 200 OK');

// NEW
LoggingService.logApiCall(
  'GET',
  '/api/users',
  statusCode: 200,
  duration: Duration(milliseconds: 150),
);
```

## Category-Specific Loggers

Use category-specific loggers for better organization:

```dart
// Authentication
LoggingService.auth.i('User authentication successful');

// Network operations
LoggingService.network.d('Request headers: $headers');

// Meal planning
LoggingService.meal.i('Meal plan generated successfully');

// Workouts
LoggingService.workout.d('Exercise data loaded');

// Performance monitoring
LoggingService.performance.i('Database query optimized');
```

## Best Practices

### 1. Use Structured Logging
- Prefer `logAuthEvent()`, `logMealOperation()`, etc. over generic logging
- Include relevant metadata for better debugging

### 2. Environment-Aware Logging
- Debug logs are automatically filtered in production
- Use appropriate log levels for different environments

### 3. Performance Monitoring
- Use `PerformanceTimer` for measuring operation duration
- Log performance metrics for optimization

### 4. Error Context
- Always include context when logging errors
- Provide metadata for better error tracking

### 5. User Actions
- Log user actions for analytics and debugging
- Use `logUserAction()` for user interactions

## Migration Checklist

- [ ] Update imports from `package:logger/logger.dart` to `logging_service.dart`
- [ ] Remove `static final _logger = Logger();` declarations
- [ ] Replace `_logger.d/i/w/e()` calls with `LoggingService.instance.d/i/w/e()`
- [ ] Use structured logging methods where appropriate
- [ ] Add performance timers for long-running operations
- [ ] Include metadata in error logs
- [ ] Test logging in both debug and release modes

## Examples

### Before (Old Pattern)
```dart
class UserService {
  static final _logger = Logger();
  
  static Future<User> createUser(String email) async {
    try {
      _logger.i('Creating user with email: $email');
      // ... create user logic
      _logger.i('User created successfully');
      return user;
    } catch (e) {
      _logger.e('Failed to create user: $e');
      rethrow;
    }
  }
}
```

### After (New Pattern)
```dart
class UserService {
  static Future<User> createUser(String email) async {
    final timer = 'User creation'.startTimer();
    try {
      LoggingService.logAuthEvent(
        'User creation started',
        metadata: {'email': email},
      );
      // ... create user logic
      LoggingService.logAuthEvent(
        'User created successfully',
        metadata: {'userId': user.id, 'email': email},
      );
      return user;
    } catch (e) {
      LoggingService.logError(
        'Failed to create user',
        error: e,
        context: 'UserService',
        metadata: {'email': email},
      );
      rethrow;
    } finally {
      timer.end();
    }
  }
}
```

This migration provides better structured logging, performance monitoring, and environment-aware configuration.
