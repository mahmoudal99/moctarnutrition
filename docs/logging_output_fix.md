# Logging Output Options

## The Problem
The logs were showing ANSI escape codes (`\^[[38;5;12m`) which made them messy and hard to read in Flutter's console output.

## The Solution
I've fixed the logging service to disable colors in Flutter environments, which eliminates the ANSI escape codes.

## Available Logging Options

### 1. Standard Logging (Recommended)
```dart
LoggingService.instance.i('This is a clean info message');
LoggingService.auth.i('Authentication event');
LoggingService.meal.i('Meal operation');
```

**Output:**
```
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
│ 💡 This is a clean info message
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
```

### 2. Simple Logging (Minimal Output)
```dart
LoggingService.simple.i('Simple message');
```

**Output:**
```
I: Simple message
```

### 3. Category-Specific Logging
```dart
LoggingService.auth.i('User signed in');
LoggingService.network.i('API call completed');
LoggingService.meal.i('Meal plan generated');
LoggingService.workout.i('Workout completed');
LoggingService.performance.i('Operation took 150ms');
```

## What Changed
- ✅ **Disabled colors** in PrettyPrinter to eliminate ANSI escape codes
- ✅ **Kept emojis** for visual distinction between log types
- ✅ **Maintained structured format** with boxes and timestamps
- ✅ **Added simple logger option** for minimal output

## Benefits
- **Clean output**: No more ANSI escape codes cluttering the console
- **Readable logs**: Clear, structured format that's easy to scan
- **Visual distinction**: Emojis help identify different types of logs
- **Flexible options**: Choose between detailed or minimal output

## Usage Examples

### For Development
```dart
// Detailed logging with context
LoggingService.logAuthEvent('User signed in', userId: 'user123');
LoggingService.logMealOperation('Meal consumed', mealName: 'Breakfast');
LoggingService.logError('API failed', error: exception, context: 'UserService');
```

### For Production
```dart
// Simple logging
LoggingService.simple.i('User action completed');
LoggingService.simple.e('Error occurred');
```

The logging system now provides clean, readable output without the messy ANSI escape codes!
