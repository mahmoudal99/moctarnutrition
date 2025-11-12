import 'package:cloud_firestore/cloud_firestore.dart';

enum WorkoutDifficulty { beginner, intermediate, advanced }

enum WorkoutCategory { strength, cardio, flexibility, hiit, yoga, pilates }

class WorkoutModel {
  final String id;
  final String title;
  final String description;
  final String trainerId;
  final String trainerName;
  final String? trainerPhotoUrl;
  final WorkoutDifficulty difficulty;
  final WorkoutCategory category;
  final int estimatedDuration; // in minutes
  final List<Exercise> exercises;
  final String? videoUrl;
  final String? thumbnailUrl;
  final List<String> tags;
  final bool isPremium;
  final int viewCount;
  final double rating;
  final int ratingCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkoutModel({
    required this.id,
    required this.title,
    required this.description,
    required this.trainerId,
    required this.trainerName,
    this.trainerPhotoUrl,
    required this.difficulty,
    required this.category,
    required this.estimatedDuration,
    required this.exercises,
    this.videoUrl,
    this.thumbnailUrl,
    required this.tags,
    this.isPremium = false,
    this.viewCount = 0,
    this.rating = 0.0,
    this.ratingCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkoutModel.fromJson(Map<String, dynamic> json) {
    return WorkoutModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      trainerId: json['trainerId'] as String,
      trainerName: json['trainerName'] as String,
      trainerPhotoUrl: json['trainerPhotoUrl'] as String?,
      difficulty: WorkoutDifficulty.values.firstWhere(
        (e) => e.toString() == 'WorkoutDifficulty.${json['difficulty']}',
        orElse: () => WorkoutDifficulty.beginner,
      ),
      category: WorkoutCategory.values.firstWhere(
        (e) => e.toString() == 'WorkoutCategory.${json['category']}',
        orElse: () => WorkoutCategory.strength,
      ),
      estimatedDuration: json['estimatedDuration'] as int,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      videoUrl: json['videoUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      isPremium: json['isPremium'] as bool? ?? false,
      viewCount: json['viewCount'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['ratingCount'] as int? ?? 0,
      createdAt: _extractDateTimeFromField(json['createdAt']),
      updatedAt: _extractDateTimeFromField(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'trainerId': trainerId,
      'trainerName': trainerName,
      'trainerPhotoUrl': trainerPhotoUrl,
      'difficulty': difficulty.toString().split('.').last,
      'category': category.toString().split('.').last,
      'estimatedDuration': estimatedDuration,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'tags': tags,
      'isPremium': isPremium,
      'viewCount': viewCount,
      'rating': rating,
      'ratingCount': ratingCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  WorkoutModel copyWith({
    String? id,
    String? title,
    String? description,
    String? trainerId,
    String? trainerName,
    String? trainerPhotoUrl,
    WorkoutDifficulty? difficulty,
    WorkoutCategory? category,
    int? estimatedDuration,
    List<Exercise>? exercises,
    String? videoUrl,
    String? thumbnailUrl,
    List<String>? tags,
    bool? isPremium,
    int? viewCount,
    double? rating,
    int? ratingCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      trainerId: trainerId ?? this.trainerId,
      trainerName: trainerName ?? this.trainerName,
      trainerPhotoUrl: trainerPhotoUrl ?? this.trainerPhotoUrl,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      exercises: exercises ?? this.exercises,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      tags: tags ?? this.tags,
      isPremium: isPremium ?? this.isPremium,
      viewCount: viewCount ?? this.viewCount,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Helper method to extract DateTime from field that might be Timestamp or String
  static DateTime _extractDateTimeFromField(dynamic field) {
    if (field is Timestamp) {
      return field.toDate();
    } else if (field is String) {
      return DateTime.parse(field);
    } else {
      throw Exception('Invalid date field type: ${field.runtimeType}');
    }
  }
}

class Exercise {
  final String id;
  final String name;
  final String description;
  final String? videoUrl;
  final String? imageUrl;
  final int sets;
  final int reps;
  final String? tempo; // e.g., "2-0-2-0" for eccentric-pause-concentric-pause
  final int? duration; // in seconds
  final int? restTime; // in seconds
  final String? equipment;
  final List<String> muscleGroups;
  final int order;
  final String? formCues; // Specific form instructions and cues

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    this.videoUrl,
    this.imageUrl,
    required this.sets,
    required this.reps,
    this.tempo,
    this.duration,
    this.restTime,
    this.equipment,
    required this.muscleGroups,
    required this.order,
    this.formCues,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      videoUrl: json['videoUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      sets: json['sets'] as int,
      reps: json['reps'] as int,
      tempo: json['tempo'] as String?,
      duration: json['duration'] as int?,
      restTime: json['restTime'] as int?,
      equipment: json['equipment'] as String?,
      muscleGroups: List<String>.from(json['muscleGroups'] ?? []),
      order: json['order'] as int,
      formCues: json['formCues'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
      'sets': sets,
      'reps': reps,
      'tempo': tempo,
      'duration': duration,
      'restTime': restTime,
      'equipment': equipment,
      'muscleGroups': muscleGroups,
      'order': order,
      'formCues': formCues,
    };
  }
}
