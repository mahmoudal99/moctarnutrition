import 'package:cloud_firestore/cloud_firestore.dart';
import 'workout_model.dart';

enum WorkoutPlanType {
  strength,
  bodybuilding,
  cardio,
  hiit,
  running,
  ai_generated
}

enum WorkoutPlanApprovalStatus {
  pending,
  approved,
  rejected
}

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
  final WorkoutPlanApprovalStatus approvalStatus;
  final String? approvedBy; // Trainer ID who approved
  final DateTime? approvedAt;
  final String? rejectionReason;
  final String? approvedByTrainerName;

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
    this.approvalStatus = WorkoutPlanApprovalStatus.pending,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.approvedByTrainerName,
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
      createdAt: _extractDateTimeFromField(json['createdAt']),
      updatedAt: _extractDateTimeFromField(json['updatedAt']),
      isActive: json['isActive'] as bool? ?? true,
      approvalStatus: WorkoutPlanApprovalStatus.values.firstWhere(
        (e) => e.toString() == 'WorkoutPlanApprovalStatus.${json['approvalStatus']}',
        orElse: () => WorkoutPlanApprovalStatus.pending,
      ),
      approvedBy: json['approvedBy'] as String?,
      approvedAt: json['approvedAt'] != null ? _extractDateTimeFromField(json['approvedAt']) : null,
      rejectionReason: json['rejectionReason'] as String?,
      approvedByTrainerName: json['approvedByTrainerName'] as String?,
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
      'approvalStatus': approvalStatus.toString().split('.').last,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'approvedByTrainerName': approvedByTrainerName,
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
    WorkoutPlanApprovalStatus? approvalStatus,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    String? approvedByTrainerName,
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
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvedByTrainerName: approvedByTrainerName ?? this.approvedByTrainerName,
    );
  }

  // Helper getters for approval status
  bool get isApproved => approvalStatus == WorkoutPlanApprovalStatus.approved;
  bool get isPending => approvalStatus == WorkoutPlanApprovalStatus.pending;
  bool get isRejected => approvalStatus == WorkoutPlanApprovalStatus.rejected;

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
