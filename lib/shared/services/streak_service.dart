import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

/// Service responsible for tracking meal completion streaks
/// A streak is maintained as long as you complete/track your meals for the day
class StreakService {
  static final _logger = Logger();
  static const String _streakKeyPrefix = 'meal_streak_';

  /// Get the current streak for a user
  static Future<int> getCurrentStreak(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_streakKeyPrefix$userId';

      final streakData = prefs.getString(key);
      if (streakData == null) return 0;

      final data = jsonDecode(streakData) as Map<String, dynamic>;
      final lastCompletedDate =
          DateTime.parse(data['lastCompletedDate'] as String);
      final streakCount = data['streakCount'] as int;

      // Check if the last completed date was yesterday (to maintain streak)
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1);

      // If last completed was yesterday, streak continues
      if (_isSameDay(lastCompletedDate, yesterday)) {
        return streakCount;
      }

      // If last completed was today, streak continues
      if (_isSameDay(lastCompletedDate, now)) {
        return streakCount;
      }

      // If last completed was before yesterday, streak is broken
      return 0;
    } catch (e) {
      _logger.e('Failed to get current streak: $e');
      return 0;
    }
  }

  /// Update streak when meals are completed for today
  static Future<int> updateStreak(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_streakKeyPrefix$userId';

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get current streak data
      final streakData = prefs.getString(key);
      int currentStreak = 0;
      DateTime? lastCompletedDate;

      if (streakData != null) {
        final data = jsonDecode(streakData) as Map<String, dynamic>;
        currentStreak = data['streakCount'] as int;
        lastCompletedDate = DateTime.parse(data['lastCompletedDate'] as String);
      }

      // Check if we already completed today
      if (lastCompletedDate != null && _isSameDay(lastCompletedDate, today)) {
        // Already completed today, return current streak
        return currentStreak;
      }

      // Check if this continues the streak (completed yesterday)
      final yesterday = DateTime(today.year, today.month, today.day - 1);
      if (lastCompletedDate != null &&
          _isSameDay(lastCompletedDate, yesterday)) {
        // Continue streak
        currentStreak++;
      } else if (lastCompletedDate == null ||
          !_isSameDay(lastCompletedDate, today)) {
        // Start new streak or continue if completed today
        if (lastCompletedDate == null ||
            !_isSameDay(lastCompletedDate, today)) {
          currentStreak = 1;
        }
      }

      // Save updated streak data
      final newStreakData = {
        'streakCount': currentStreak,
        'lastCompletedDate': today.toIso8601String(),
        'lastUpdated': now.toIso8601String(),
      };

      await prefs.setString(key, jsonEncode(newStreakData));

      _logger.d('Updated streak for user $userId: $currentStreak days');
      return currentStreak;
    } catch (e) {
      _logger.e('Failed to update streak: $e');
      return 0;
    }
  }

  /// Check if a date is the same day (ignoring time)
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Reset streak for a user (useful for testing or manual reset)
  static Future<void> resetStreak(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_streakKeyPrefix$userId';
      await prefs.remove(key);
      _logger.d('Reset streak for user $userId');
    } catch (e) {
      _logger.e('Failed to reset streak: $e');
    }
  }

  /// Get streak statistics for a user
  static Future<Map<String, dynamic>> getStreakStats(String userId) async {
    try {
      final currentStreak = await getCurrentStreak(userId);
      final prefs = await SharedPreferences.getInstance();
      final key = '$_streakKeyPrefix$userId';

      final streakData = prefs.getString(key);
      DateTime? lastCompletedDate;

      if (streakData != null) {
        final data = jsonDecode(streakData) as Map<String, dynamic>;
        lastCompletedDate = DateTime.parse(data['lastCompletedDate'] as String);
      }

      return {
        'currentStreak': currentStreak,
        'lastCompletedDate': lastCompletedDate,
        'isStreakActive': currentStreak > 0,
      };
    } catch (e) {
      _logger.e('Failed to get streak stats: $e');
      return {
        'currentStreak': 0,
        'lastCompletedDate': null,
        'isStreakActive': false,
      };
    }
  }

  /// Increment streak when meals are completed for today
  static Future<int> incrementStreak(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_streakKeyPrefix$userId';

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get current streak data
      final streakData = prefs.getString(key);
      int currentStreak = 0;
      DateTime? lastCompletedDate;

      if (streakData != null) {
        final data = jsonDecode(streakData) as Map<String, dynamic>;
        currentStreak = data['streakCount'] as int;
        lastCompletedDate = DateTime.parse(data['lastCompletedDate'] as String);
      }

      // Check if we already completed today
      if (lastCompletedDate != null && _isSameDay(lastCompletedDate, today)) {
        // Already completed today, return current streak
        return currentStreak;
      }

      // Check if this continues the streak (completed yesterday)
      final yesterday = DateTime(today.year, today.month, today.day - 1);
      if (lastCompletedDate != null &&
          _isSameDay(lastCompletedDate, yesterday)) {
        // Continue streak
        currentStreak++;
      } else if (lastCompletedDate == null ||
          !_isSameDay(lastCompletedDate, today)) {
        // Start new streak or continue if completed today
        if (lastCompletedDate == null ||
            !_isSameDay(lastCompletedDate, today)) {
          currentStreak = 1;
        }
      }

      // Save updated streak data
      final newStreakData = {
        'streakCount': currentStreak,
        'lastCompletedDate': today.toIso8601String(),
        'lastUpdated': now.toIso8601String(),
      };

      await prefs.setString(key, jsonEncode(newStreakData));

      _logger.d('Incremented streak for user $userId: $currentStreak days');
      return currentStreak;
    } catch (e) {
      _logger.e('Failed to increment streak: $e');
      return 0;
    }
  }
}
