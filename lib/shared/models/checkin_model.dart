import 'package:cloud_firestore/cloud_firestore.dart';

enum CheckinStatus { pending, completed, missed }

class CheckinModel {
  final String id;
  final String userId;
  final DateTime weekStartDate; // Monday of the week
  final String? photoUrl;
  final String? photoThumbnailUrl;
  final String? notes;
  final CheckinStatus status;
  final DateTime? submittedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Progress tracking fields
  final double? weight; // in kg
  final double? bodyFatPercentage;
  final double? muscleMass; // in kg
  final Map<String, double>? measurements; // chest, waist, arms, etc.
  final String? mood; // how user feels about their progress
  final int? energyLevel; // 1-10 scale
  final int? motivationLevel; // 1-10 scale

  CheckinModel({
    required this.id,
    required this.userId,
    required this.weekStartDate,
    this.photoUrl,
    this.photoThumbnailUrl,
    this.notes,
    this.status = CheckinStatus.pending,
    this.submittedAt,
    required this.createdAt,
    required this.updatedAt,
    this.weight,
    this.bodyFatPercentage,
    this.muscleMass,
    this.measurements,
    this.mood,
    this.energyLevel,
    this.motivationLevel,
  });

  factory CheckinModel.fromJson(Map<String, dynamic> json) {
    return CheckinModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      weekStartDate: (json['weekStartDate'] as Timestamp).toDate(),
      photoUrl: json['photoUrl'] as String?,
      photoThumbnailUrl: json['photoThumbnailUrl'] as String?,
      notes: json['notes'] as String?,
      status: CheckinStatus.values.firstWhere(
        (e) => e.toString() == 'CheckinStatus.${json['status']}',
        orElse: () => CheckinStatus.pending,
      ),
      submittedAt: json['submittedAt'] != null 
          ? (json['submittedAt'] as Timestamp).toDate() 
          : null,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      weight: (json['weight'] as num?)?.toDouble(),
      bodyFatPercentage: (json['bodyFatPercentage'] as num?)?.toDouble(),
      muscleMass: (json['muscleMass'] as num?)?.toDouble(),
      measurements: json['measurements'] != null 
          ? Map<String, double>.from(json['measurements'])
          : null,
      mood: json['mood'] as String?,
      energyLevel: json['energyLevel'] as int?,
      motivationLevel: json['motivationLevel'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'weekStartDate': Timestamp.fromDate(weekStartDate),
      'photoUrl': photoUrl,
      'photoThumbnailUrl': photoThumbnailUrl,
      'notes': notes,
      'status': status.toString().split('.').last,
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'weight': weight,
      'bodyFatPercentage': bodyFatPercentage,
      'muscleMass': muscleMass,
      'measurements': measurements,
      'mood': mood,
      'energyLevel': energyLevel,
      'motivationLevel': motivationLevel,
    };
  }

  CheckinModel copyWith({
    String? id,
    String? userId,
    DateTime? weekStartDate,
    String? photoUrl,
    String? photoThumbnailUrl,
    String? notes,
    CheckinStatus? status,
    DateTime? submittedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? weight,
    double? bodyFatPercentage,
    double? muscleMass,
    Map<String, double>? measurements,
    String? mood,
    int? energyLevel,
    int? motivationLevel,
  }) {
    return CheckinModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      photoUrl: photoUrl ?? this.photoUrl,
      photoThumbnailUrl: photoThumbnailUrl ?? this.photoThumbnailUrl,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      weight: weight ?? this.weight,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      muscleMass: muscleMass ?? this.muscleMass,
      measurements: measurements ?? this.measurements,
      mood: mood ?? this.mood,
      energyLevel: energyLevel ?? this.energyLevel,
      motivationLevel: motivationLevel ?? this.motivationLevel,
    );
  }

  /// Get the week number for this check-in
  int get weekNumber {
    final yearStart = DateTime(weekStartDate.year, 1, 1);
    final daysSinceYearStart = weekStartDate.difference(yearStart).inDays;
    return ((daysSinceYearStart + yearStart.weekday - 1) / 7).ceil();
  }

  /// Get the formatted week range (e.g., "Jan 1-7")
  String get weekRange {
    final endDate = weekStartDate.add(const Duration(days: 6));
    final startMonth = _getMonthAbbreviation(weekStartDate.month);
    final endMonth = _getMonthAbbreviation(endDate.month);
    
    if (startMonth == endMonth) {
      return '$startMonth ${weekStartDate.day}-${endDate.day}';
    } else {
      return '$startMonth ${weekStartDate.day} - $endMonth ${endDate.day}';
    }
  }

  /// Get the formatted week range with year (e.g., "Jan 1-7, 2024")
  String get weekRangeWithYear {
    final endDate = weekStartDate.add(const Duration(days: 6));
    final startMonth = _getMonthAbbreviation(weekStartDate.month);
    final endMonth = _getMonthAbbreviation(endDate.month);
    
    if (startMonth == endMonth) {
      return '$startMonth ${weekStartDate.day}-${endDate.day}, ${weekStartDate.year}';
    } else {
      return '$startMonth ${weekStartDate.day} - $endMonth ${endDate.day}, ${weekStartDate.year}';
    }
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  /// Check if this check-in is for the current week
  bool get isCurrentWeek {
    final now = DateTime.now();
    final currentWeekStart = _getWeekStart(now);
    return weekStartDate.isAtSameMomentAs(currentWeekStart);
  }

  /// Check if this check-in is overdue (past the current week)
  bool get isOverdue {
    final now = DateTime.now();
    final currentWeekStart = _getWeekStart(now);
    return weekStartDate.isBefore(currentWeekStart);
  }

  /// Get the number of days until the check-in is due
  int get daysUntilDue {
    final now = DateTime.now();
    final currentWeekStart = _getWeekStart(now);
    final nextWeekStart = currentWeekStart.add(const Duration(days: 7));
    return nextWeekStart.difference(now).inDays;
  }

  /// Get the number of days since the check-in was submitted
  int get daysSinceSubmitted {
    if (submittedAt == null) return 0;
    return DateTime.now().difference(submittedAt!).inDays;
  }

  /// Static method to get the start of a week (Monday)
  static DateTime _getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return date.subtract(Duration(days: daysFromMonday));
  }

  /// Create a check-in for the current week
  static CheckinModel createForCurrentWeek(String userId) {
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);
    
    return CheckinModel(
      id: '', // Will be set by Firestore
      userId: userId,
      weekStartDate: weekStart,
      status: CheckinStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a check-in for a specific week
  static CheckinModel createForWeek(String userId, DateTime weekStart) {
    final now = DateTime.now();
    
    return CheckinModel(
      id: '', // Will be set by Firestore
      userId: userId,
      weekStartDate: weekStart,
      status: CheckinStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
  }
}

/// Model for check-in progress summary
class CheckinProgressSummary {
  final int totalCheckins;
  final int completedCheckins;
  final int missedCheckins;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCheckinDate;
  final DateTime? nextCheckinDate;
  final double? averageWeight;
  final double? averageBodyFat;
  final double? averageEnergyLevel;
  final double? averageMotivationLevel;

  CheckinProgressSummary({
    required this.totalCheckins,
    required this.completedCheckins,
    required this.missedCheckins,
    required this.currentStreak,
    required this.longestStreak,
    this.lastCheckinDate,
    this.nextCheckinDate,
    this.averageWeight,
    this.averageBodyFat,
    this.averageEnergyLevel,
    this.averageMotivationLevel,
  });

  double get completionRate => totalCheckins > 0 ? completedCheckins / totalCheckins : 0.0;
  bool get isOnTrack => currentStreak > 0;
  int get daysUntilNextCheckin {
    if (nextCheckinDate == null) return 0;
    return nextCheckinDate!.difference(DateTime.now()).inDays;
  }
} 