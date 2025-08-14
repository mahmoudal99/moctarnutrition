import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import '../models/meal_model.dart';

/// Service for caching meal plans to avoid redundant API calls
class CacheService {
  static final _logger = Logger();
  static final Map<String, CachedMealPlan> _cache = {};
  static const int _maxCacheSize = 50; // Maximum number of cached plans
  static const Duration _cacheExpiry = Duration(hours: 24); // Cache for 24 hours

  /// Generate a unique cache key based on preferences and days
  static String _generateCacheKey(DietPlanPreferences preferences, int days) {
    final data = {
      'days': days,
      'age': preferences.age,
      'gender': preferences.gender,
      'weight': preferences.weight,
      'height': preferences.height,
      'fitnessGoal': preferences.fitnessGoal.name,
      'activityLevel': preferences.activityLevel.name,
      'targetCalories': preferences.targetCalories,
      'targetProtein': preferences.targetProtein,
      'dietaryRestrictions': preferences.dietaryRestrictions.toList()..sort(),
      'preferredCuisines': preferences.preferredCuisines.toList()..sort(),
      'foodsToAvoid': preferences.foodsToAvoid.toList()..sort(),
      'favoriteFoods': preferences.favoriteFoods.toList()..sort(),
      'mealFrequency': preferences.mealFrequency,
      'nutritionGoal': preferences.nutritionGoal,
      'weeklyRotation': preferences.weeklyRotation,
      'remindersEnabled': preferences.remindersEnabled,
      'allergies': preferences.allergies?.map((a) => a['name']).toList()?..sort(),
      'mealTiming': preferences.mealTimingPreferences,
      'batchCooking': preferences.batchCookingPreferences,
    };

    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if a meal plan exists in cache
  static CachedMealPlan? getCachedMealPlan(DietPlanPreferences preferences, int days) {
    final cacheKey = _generateCacheKey(preferences, days);
    final cached = _cache[cacheKey];

    if (cached != null) {
      // Check if cache has expired
      if (DateTime.now().difference(cached.timestamp) > _cacheExpiry) {
        _cache.remove(cacheKey);
        return null;
      }
      
      _logger.i('Cache hit: Found meal plan for $days days');
      return cached;
    }

    _logger.d('Cache miss: No meal plan found for $days days');
    return null;
  }

  /// Store a meal plan in cache
  static void cacheMealPlan(DietPlanPreferences preferences, int days, MealPlanModel mealPlan) {
    final cacheKey = _generateCacheKey(preferences, days);
    
    // Remove oldest entries if cache is full
    if (_cache.length >= _maxCacheSize) {
      _cleanupCache();
    }

    _cache[cacheKey] = CachedMealPlan(
      mealPlan: mealPlan,
      timestamp: DateTime.now(),
      preferences: preferences,
      days: days,
    );

    _logger.i('Cached meal plan for $days days (cache size: ${_cache.length})');
  }

  /// Remove expired entries from cache
  static void _cleanupCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cache.entries) {
      if (now.difference(entry.value.timestamp) > _cacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
    }

    // If still too many entries, remove oldest ones
    if (_cache.length >= _maxCacheSize) {
      final sortedEntries = _cache.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
      
      final toRemove = sortedEntries.take(_cache.length - _maxCacheSize + 1);
      for (final entry in toRemove) {
        _cache.remove(entry.key);
      }
    }

    _logger.i('Cache cleanup: Removed ${expiredKeys.length} expired entries');
  }

  /// Clear all cached meal plans
  static void clearCache() {
    _cache.clear();
    _logger.i('Cache cleared');
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    int expiredCount = 0;
    int validCount = 0;

    for (final entry in _cache.values) {
      if (now.difference(entry.timestamp) > _cacheExpiry) {
        expiredCount++;
      } else {
        validCount++;
      }
    }

    return {
      'totalEntries': _cache.length,
      'validEntries': validCount,
      'expiredEntries': expiredCount,
      'maxCacheSize': _maxCacheSize,
      'cacheExpiry': _cacheExpiry.inHours,
    };
  }

  /// Check if cache is enabled (for feature toggling)
  static bool get isEnabled => true;
}

/// Cached meal plan data structure
class CachedMealPlan {
  final MealPlanModel mealPlan;
  final DateTime timestamp;
  final DietPlanPreferences preferences;
  final int days;

  CachedMealPlan({
    required this.mealPlan,
    required this.timestamp,
    required this.preferences,
    required this.days,
  });
} 