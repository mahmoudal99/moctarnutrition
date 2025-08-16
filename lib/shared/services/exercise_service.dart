import '../models/workout_model.dart';

class ExerciseService {
  static final ExerciseService _instance = ExerciseService._internal();
  factory ExerciseService() => _instance;
  ExerciseService._internal();

  // Exercise library data
  static const Map<String, Map<String, dynamic>> _exerciseLibrary = {
    // Chest exercises
    'chest_press': {
      'name': 'Chest Press',
      'description': 'Classic chest exercise using dumbbells or barbell',
      'sets': 3,
      'reps': 12,
      'muscleGroups': ['chest', 'triceps', 'shoulders'],
      'equipment': 'Dumbbells/Barbell',
    },
    'push_ups': {
      'name': 'Push-ups',
      'description': 'Bodyweight chest exercise',
      'sets': 3,
      'reps': 15,
      'muscleGroups': ['chest', 'triceps', 'shoulders'],
      'equipment': 'Bodyweight',
    },
    'incline_press': {
      'name': 'Incline Press',
      'description': 'Upper chest focus exercise',
      'sets': 3,
      'reps': 10,
      'muscleGroups': ['chest', 'triceps', 'shoulders'],
      'equipment': 'Dumbbells/Barbell',
    },
    'dumbbell_flyes': {
      'name': 'Dumbbell Flyes',
      'description': 'Isolation exercise for chest',
      'sets': 3,
      'reps': 12,
      'muscleGroups': ['chest'],
      'equipment': 'Dumbbells',
    },
    
    // Back exercises
    'pull_ups': {
      'name': 'Pull-ups',
      'description': 'Upper body pulling exercise',
      'sets': 3,
      'reps': 8,
      'muscleGroups': ['back', 'biceps'],
      'equipment': 'Pull-up bar',
    },
    'barbell_rows': {
      'name': 'Barbell Rows',
      'description': 'Compound back exercise',
      'sets': 3,
      'reps': 12,
      'muscleGroups': ['back', 'biceps'],
      'equipment': 'Barbell',
    },
    'lat_pulldowns': {
      'name': 'Lat Pulldowns',
      'description': 'Machine-based back exercise',
      'sets': 3,
      'reps': 12,
      'muscleGroups': ['back', 'biceps'],
      'equipment': 'Cable machine',
    },
    
    // Leg exercises
    'squats': {
      'name': 'Squats',
      'description': 'Compound leg exercise',
      'sets': 3,
      'reps': 15,
      'muscleGroups': ['legs', 'glutes'],
      'equipment': 'Bodyweight/Barbell',
    },
    'deadlifts': {
      'name': 'Deadlifts',
      'description': 'Posterior chain exercise',
      'sets': 3,
      'reps': 8,
      'muscleGroups': ['legs', 'back', 'glutes'],
      'equipment': 'Barbell',
    },
    'lunges': {
      'name': 'Lunges',
      'description': 'Unilateral leg exercise',
      'sets': 3,
      'reps': 12,
      'muscleGroups': ['legs', 'glutes'],
      'equipment': 'Bodyweight/Dumbbells',
    },
    
    // Shoulder exercises
    'shoulder_press': {
      'name': 'Shoulder Press',
      'description': 'Overhead pressing movement',
      'sets': 3,
      'reps': 10,
      'muscleGroups': ['shoulders', 'triceps'],
      'equipment': 'Dumbbells/Barbell',
    },
    'lateral_raises': {
      'name': 'Lateral Raises',
      'description': 'Isolation exercise for lateral deltoids',
      'sets': 3,
      'reps': 15,
      'muscleGroups': ['shoulders'],
      'equipment': 'Dumbbells',
    },
    
    // Arm exercises
    'bicep_curls': {
      'name': 'Bicep Curls',
      'description': 'Isolation exercise for biceps',
      'sets': 3,
      'reps': 12,
      'muscleGroups': ['biceps'],
      'equipment': 'Dumbbells/Barbell',
    },
    'tricep_dips': {
      'name': 'Tricep Dips',
      'description': 'Bodyweight tricep exercise',
      'sets': 3,
      'reps': 12,
      'muscleGroups': ['triceps'],
      'equipment': 'Dip bars',
    },
    
    // Core exercises
    'plank': {
      'name': 'Plank',
      'description': 'Core stability exercise',
      'sets': 3,
      'reps': 0,
      'duration': 60,
      'muscleGroups': ['core'],
      'equipment': 'Bodyweight',
    },
    'crunches': {
      'name': 'Crunches',
      'description': 'Abdominal exercise',
      'sets': 3,
      'reps': 20,
      'muscleGroups': ['core'],
      'equipment': 'Bodyweight',
    },
  };

  /// Get all available exercises
  List<Exercise> getAllExercises() {
    return _exerciseLibrary.entries.map((entry) {
      final data = entry.value;
      return Exercise(
        id: entry.key,
        name: data['name'] as String,
        description: data['description'] as String,
        sets: data['sets'] as int,
        reps: data['reps'] as int,
        duration: data['duration'] as int?,
        equipment: data['equipment'] as String?,
        muscleGroups: List<String>.from(data['muscleGroups'] as List),
        order: 1,
      );
    }).toList();
  }

  /// Get exercises filtered by muscle group
  List<Exercise> getExercisesByMuscleGroup(String muscleGroup) {
    return getAllExercises().where((exercise) {
      return exercise.muscleGroups.contains(muscleGroup);
    }).toList();
  }

  /// Search exercises by name or description
  List<Exercise> searchExercises(String query) {
    final lowercaseQuery = query.toLowerCase();
    return getAllExercises().where((exercise) {
      return exercise.name.toLowerCase().contains(lowercaseQuery) ||
             exercise.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Get all available muscle groups
  List<String> getAvailableMuscleGroups() {
    final allGroups = <String>{};
    for (final exercise in getAllExercises()) {
      allGroups.addAll(exercise.muscleGroups);
    }
    return allGroups.toList()..sort();
  }

  /// Get exercise by ID
  Exercise? getExerciseById(String id) {
    final data = _exerciseLibrary[id];
    if (data == null) return null;
    
    return Exercise(
      id: id,
      name: data['name'] as String,
      description: data['description'] as String,
      sets: data['sets'] as int,
      reps: data['reps'] as int,
      duration: data['duration'] as int?,
      equipment: data['equipment'] as String?,
      muscleGroups: List<String>.from(data['muscleGroups'] as List),
      order: 1,
    );
  }

  /// Filter exercises by multiple criteria
  List<Exercise> filterExercises({
    String? searchQuery,
    String? muscleGroup,
  }) {
    List<Exercise> exercises = getAllExercises();

    // Filter by search query
    if (searchQuery != null && searchQuery.isNotEmpty) {
      exercises = exercises.where((exercise) {
        final lowercaseQuery = searchQuery.toLowerCase();
        return exercise.name.toLowerCase().contains(lowercaseQuery) ||
               exercise.description.toLowerCase().contains(lowercaseQuery);
      }).toList();
    }

    // Filter by muscle group
    if (muscleGroup != null && muscleGroup.isNotEmpty) {
      exercises = exercises.where((exercise) {
        return exercise.muscleGroups.contains(muscleGroup);
      }).toList();
    }

    return exercises;
  }
} 