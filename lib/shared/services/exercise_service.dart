import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/workout_model.dart';

class FreeExerciseService {
  static final _logger = Logger();

  static const String _baseUrl =
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main';
  static const String _exercisesUrl = '$_baseUrl/dist/exercises.json';

  /// Get all exercises from the free exercise database
  Future<List<Exercise>> getAllExercises() async {
    try {
      _logger.d('Fetching all exercises from free-exercise-db');

      final response = await http.get(Uri.parse(_exercisesUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final exercises =
            data.map((json) => _mapApiExerciseToExercise(json)).toList();

        _logger.d(
            'Successfully fetched ${exercises.length} exercises from free-exercise-db');
        return exercises;
      } else {
        _logger.e(
            'Failed to fetch exercises: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch exercises: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error fetching exercises: $e');
      throw Exception('Error fetching exercises: $e');
    }
  }

  /// Get exercises by target muscle
  Future<List<Exercise>> getExercisesByTarget(String target) async {
    try {
      _logger.d('Fetching exercises for target muscle: $target');

      final allExercises = await getAllExercises();
      final targetExercises = allExercises.where((exercise) {
        return exercise.muscleGroups.any(
            (muscle) => muscle.toLowerCase().contains(target.toLowerCase()));
      }).toList();

      _logger.d('Found ${targetExercises.length} exercises for target $target');
      return targetExercises;
    } catch (e) {
      _logger.e('Error fetching exercises for target $target: $e');
      throw Exception('Error fetching exercises for target $target: $e');
    }
  }

  /// Get exercises by equipment
  Future<List<Exercise>> getExercisesByEquipment(String equipment) async {
    try {
      _logger.d('Fetching exercises for equipment: $equipment');

      final allExercises = await getAllExercises();
      final equipmentExercises = allExercises.where((exercise) {
        return exercise.equipment
                ?.toLowerCase()
                .contains(equipment.toLowerCase()) ??
            false;
      }).toList();

      _logger.d(
          'Found ${equipmentExercises.length} exercises for equipment $equipment');
      return equipmentExercises;
    } catch (e) {
      _logger.e('Error fetching exercises for equipment $equipment: $e');
      throw Exception('Error fetching exercises for equipment $equipment: $e');
    }
  }

  /// Get all available target muscles
  Future<List<String>> getTargetMuscles() async {
    try {
      _logger.d('Fetching available target muscles');

      final allExercises = await getAllExercises();
      final Set<String> muscles = {};

      for (final exercise in allExercises) {
        muscles.addAll(exercise.muscleGroups);
      }

      final muscleList = muscles.toList()..sort();
      _logger.d('Found ${muscleList.length} target muscles');
      return muscleList;
    } catch (e) {
      _logger.e('Error fetching target muscles: $e');
      throw Exception('Error fetching target muscles: $e');
    }
  }

  /// Get all available equipment
  Future<List<String>> getEquipment() async {
    try {
      _logger.d('Fetching available equipment');

      final allExercises = await getAllExercises();
      final Set<String> equipment = {};

      for (final exercise in allExercises) {
        if (exercise.equipment != null && exercise.equipment!.isNotEmpty) {
          equipment.add(exercise.equipment!);
        }
      }

      final equipmentList = equipment.toList()..sort();
      _logger.d('Found ${equipmentList.length} equipment types');
      return equipmentList;
    } catch (e) {
      _logger.e('Error fetching equipment: $e');
      throw Exception('Error fetching equipment: $e');
    }
  }

  /// Search exercises by name or description
  Future<List<Exercise>> searchExercises(String query) async {
    try {
      _logger.d('Searching exercises with query: $query');

      final allExercises = await getAllExercises();
      final lowercaseQuery = query.toLowerCase();

      final filteredExercises = allExercises.where((exercise) {
        return exercise.name.toLowerCase().contains(lowercaseQuery) ||
            exercise.description.toLowerCase().contains(lowercaseQuery);
      }).toList();

      _logger
          .d('Found ${filteredExercises.length} exercises matching "$query"');
      return filteredExercises;
    } catch (e) {
      _logger.e('Error searching exercises: $e');
      throw Exception('Error searching exercises: $e');
    }
  }

  /// Get exercise by ID
  Future<Exercise?> getExerciseById(String id) async {
    try {
      _logger.d('Fetching exercise by ID: $id');

      final allExercises = await getAllExercises();
      final exercise = allExercises.where((e) => e.id == id).firstOrNull;

      if (exercise != null) {
        _logger.d('Found exercise: ${exercise.name}');
      } else {
        _logger.w('Exercise with ID $id not found');
      }

      return exercise;
    } catch (e) {
      _logger.e('Error fetching exercise $id: $e');
      throw Exception('Error fetching exercise $id: $e');
    }
  }

  /// Get all available primary target muscles (for cleaner filtering)
  Future<List<String>> getPrimaryMuscles() async {
    try {
      _logger.d('Fetching available primary target muscles');

      final allExercises = await getAllExercises();
      final Set<String> muscles = {};

      for (final exercise in allExercises) {
        // Only include primary muscles for cleaner filtering
        if (exercise.muscleGroups.isNotEmpty) {
          muscles.add(exercise.muscleGroups.first);
        }
      }

      final muscleList = muscles.toList()..sort();
      _logger.d('Found ${muscleList.length} primary target muscles');
      return muscleList;
    } catch (e) {
      _logger.e('Error fetching primary target muscles: $e');
      throw Exception('Error fetching primary target muscles: $e');
    }
  }

  /// Map API exercise data to our Exercise model
  Exercise _mapApiExerciseToExercise(Map<String, dynamic> apiData) {
    return Exercise(
      id: apiData['id']?.toString() ?? '',
      name: apiData['name'] ?? '',
      description: apiData['instructions']?.join('\n') ?? '',
      videoUrl: null, // Free exercise DB doesn't provide videos
      imageUrl: _getImageUrl(apiData['id']?.toString(), apiData['images']),
      sets: 3, // Default values since API doesn't provide these
      reps: 12,
      equipment: apiData['equipment'] ?? '',
      muscleGroups: [
        ...(apiData['primaryMuscles'] as List<dynamic>? ?? []).cast<String>(),
        ...(apiData['secondaryMuscles'] as List<dynamic>? ?? []).cast<String>(),
      ],
      order: 0, // Default order
      formCues: apiData['instructions']?.join('\n') ?? '',
    );
  }

  /// Get image URL for exercise
  String? _getImageUrl(String? exerciseId, List<dynamic>? images) {
    if (exerciseId == null || images == null || images.isEmpty) {
      return null;
    }

    // Return the first image URL
    final imagePath = images.first.toString();
    return '$_baseUrl/exercises/$imagePath';
  }
}
