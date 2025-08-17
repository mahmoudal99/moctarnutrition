import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_model.dart';

class ExerciseLocalStorageService {
  static const String _exercisesKey = 'exercises_cache';
  static const String _muscleGroupsKey = 'muscle_groups_cache';
  static const String _lastUpdatedKey = 'exercises_last_updated';

  /// Save exercises to local storage
  Future<void> saveExercises(List<Exercise> exercises) async {
    final prefs = await SharedPreferences.getInstance();
    final exercisesJson = exercises.map((e) => e.toJson()).toList();
    await prefs.setString(_exercisesKey, jsonEncode(exercisesJson));
    await prefs.setString(_lastUpdatedKey, DateTime.now().toIso8601String());
  }

  /// Load exercises from local storage
  Future<List<Exercise>> loadExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final exercisesJson = prefs.getString(_exercisesKey);
    if (exercisesJson == null) return [];
    
    final List<dynamic> exercisesList = jsonDecode(exercisesJson);
    return exercisesList.map((json) => Exercise.fromJson(json)).toList();
  }

  /// Save muscle groups to local storage
  Future<void> saveMuscleGroups(List<String> muscleGroups) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_muscleGroupsKey, muscleGroups);
  }

  /// Load muscle groups from local storage
  Future<List<String>> loadMuscleGroups() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_muscleGroupsKey) ?? [];
  }

  /// Get last update time
  Future<DateTime?> getLastUpdated() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdatedString = prefs.getString(_lastUpdatedKey);
    if (lastUpdatedString == null) return null;
    return DateTime.parse(lastUpdatedString);
  }

  /// Check if cache is stale (older than 24 hours)
  Future<bool> isCacheStale() async {
    final lastUpdated = await getLastUpdated();
    if (lastUpdated == null) return true;
    
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    return difference.inHours > 24;
  }

  /// Clear all exercise data from local storage
  Future<void> clearExercises() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_exercisesKey);
    await prefs.remove(_muscleGroupsKey);
    await prefs.remove(_lastUpdatedKey);
  }
} 