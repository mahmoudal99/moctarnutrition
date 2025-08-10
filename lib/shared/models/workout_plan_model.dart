import 'workout_model.dart';

enum WorkoutPlanType { strength, bodybuilding, cardio, hiit, running }

class WorkoutPlanModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final WorkoutPlanType type;
  final List<DailyWorkout> dailyWorkouts;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  WorkoutPlanModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    required this.dailyWorkouts,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory WorkoutPlanModel.fromJson(Map<String, dynamic> json) {
    return WorkoutPlanModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: WorkoutPlanType.values.firstWhere(
        (e) => e.toString() == 'WorkoutPlanType.${json['type']}',
        orElse: () => WorkoutPlanType.strength,
      ),
      dailyWorkouts: (json['dailyWorkouts'] as List<dynamic>)
          .map((e) => DailyWorkout.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'dailyWorkouts': dailyWorkouts.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  WorkoutPlanModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    WorkoutPlanType? type,
    List<DailyWorkout>? dailyWorkouts,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return WorkoutPlanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      dailyWorkouts: dailyWorkouts ?? this.dailyWorkouts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class DailyWorkout {
  final String id;
  final String dayName; // e.g., "Monday", "Tuesday"
  final String title;
  final String description;
  final List<WorkoutModel> workouts;
  final int estimatedDuration; // in minutes
  final String? restDay; // null if not a rest day, otherwise reason for rest

  DailyWorkout({
    required this.id,
    required this.dayName,
    required this.title,
    required this.description,
    required this.workouts,
    required this.estimatedDuration,
    this.restDay,
  });

  factory DailyWorkout.fromJson(Map<String, dynamic> json) {
    return DailyWorkout(
      id: json['id'] as String,
      dayName: json['dayName'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      workouts: (json['workouts'] as List<dynamic>)
          .map((e) => WorkoutModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      estimatedDuration: json['estimatedDuration'] as int,
      restDay: json['restDay'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayName': dayName,
      'title': title,
      'description': description,
      'workouts': workouts.map((e) => e.toJson()).toList(),
      'estimatedDuration': estimatedDuration,
      'restDay': restDay,
    };
  }

  bool get isRestDay => restDay != null;
} 