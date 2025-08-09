import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/checkin_model.dart';

class ProgressService {
  static final _firestore = FirebaseFirestore.instance;
  static final _checkinsCollection = _firestore.collection('checkins');
  static final _logger = Logger();

  /// Get all completed check-ins for a user, ordered by date
  static Future<List<CheckinModel>> getUserCheckins(String userId) async {
    try {
      final querySnapshot = await _checkinsCollection
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .orderBy('weekStartDate', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return CheckinModel.fromJson(data);
      }).toList();
    } catch (e) {
      _logger.e('Error getting user check-ins: $e');
      rethrow;
    }
  }

  /// Get weight progress data points
  static Future<List<WeightDataPoint>> getWeightProgress(String userId) async {
    try {
      final checkins = await getUserCheckins(userId);
      
      return checkins
          .where((checkin) => checkin.weight != null)
          .map((checkin) => WeightDataPoint(
                date: checkin.weekStartDate,
                weight: checkin.weight!,
                weekRange: checkin.weekRange,
              ))
          .toList();
    } catch (e) {
      _logger.e('Error getting weight progress: $e');
      rethrow;
    }
  }

  /// Get mood progress data points
  static Future<List<MoodDataPoint>> getMoodProgress(String userId) async {
    try {
      final checkins = await getUserCheckins(userId);
      
      return checkins
          .where((checkin) => checkin.mood != null)
          .map((checkin) => MoodDataPoint(
                date: checkin.weekStartDate,
                mood: checkin.mood!,
                energyLevel: checkin.energyLevel,
                motivationLevel: checkin.motivationLevel,
                weekRange: checkin.weekRange,
              ))
          .toList();
    } catch (e) {
      _logger.e('Error getting mood progress: $e');
      rethrow;
    }
  }

  /// Get measurements progress for a specific measurement type
  static Future<List<MeasurementDataPoint>> getMeasurementProgress(
      String userId, String measurementType) async {
    try {
      final checkins = await getUserCheckins(userId);
      
      return checkins
          .where((checkin) => 
              checkin.measurements != null && 
              checkin.measurements!.containsKey(measurementType))
          .map((checkin) => MeasurementDataPoint(
                date: checkin.weekStartDate,
                value: checkin.measurements![measurementType]!,
                measurementType: measurementType,
                weekRange: checkin.weekRange,
              ))
          .toList();
    } catch (e) {
      _logger.e('Error getting measurement progress: $e');
      rethrow;
    }
  }

  /// Get all measurement types that the user has tracked
  static Future<List<String>> getUserMeasurementTypes(String userId) async {
    try {
      final checkins = await getUserCheckins(userId);
      final measurementTypes = <String>{};
      
      for (final checkin in checkins) {
        if (checkin.measurements != null) {
          measurementTypes.addAll(checkin.measurements!.keys);
        }
      }
      
      return measurementTypes.toList()..sort();
    } catch (e) {
      _logger.e('Error getting measurement types: $e');
      rethrow;
    }
  }

  /// Get progress summary statistics
  static Future<ProgressSummary> getProgressSummary(String userId) async {
    try {
      final checkins = await getUserCheckins(userId);
      
      if (checkins.isEmpty) {
        return ProgressSummary.empty();
      }

      // Weight statistics
      final weightData = checkins.where((c) => c.weight != null).toList();
      WeightStats? weightStats;
      if (weightData.isNotEmpty) {
        final weights = weightData.map((c) => c.weight!).toList();
        final currentWeight = weights.last;
        final startWeight = weights.first;
        final weightChange = currentWeight - startWeight;
        final averageWeight = weights.reduce((a, b) => a + b) / weights.length;
        
        weightStats = WeightStats(
          current: currentWeight,
          start: startWeight,
          change: weightChange,
          average: averageWeight,
          dataPoints: weightData.length,
        );
      }

      // Mood statistics
      final moodData = checkins.where((c) => c.energyLevel != null && c.motivationLevel != null).toList();
      MoodStats? moodStats;
      if (moodData.isNotEmpty) {
        final energyLevels = moodData.map((c) => c.energyLevel!).toList();
        final motivationLevels = moodData.map((c) => c.motivationLevel!).toList();
        
        moodStats = MoodStats(
          averageEnergy: energyLevels.reduce((a, b) => a + b) / energyLevels.length,
          averageMotivation: motivationLevels.reduce((a, b) => a + b) / motivationLevels.length,
          currentEnergy: energyLevels.last.toDouble(),
          currentMotivation: motivationLevels.last.toDouble(),
          dataPoints: moodData.length,
        );
      }

      // Measurement statistics
      final measurementTypes = await getUserMeasurementTypes(userId);
      final measurementStats = <String, MeasurementStats>{};
      
      for (final type in measurementTypes) {
        final typeData = checkins
            .where((c) => c.measurements?.containsKey(type) == true)
            .toList();
        
        if (typeData.isNotEmpty) {
          final values = typeData.map((c) => c.measurements![type]!).toList();
          final current = values.last;
          final start = values.first;
          final change = current - start;
          final average = values.reduce((a, b) => a + b) / values.length;
          
          measurementStats[type] = MeasurementStats(
            type: type,
            current: current,
            start: start,
            change: change,
            average: average,
            dataPoints: values.length,
          );
        }
      }

      return ProgressSummary(
        totalCheckins: checkins.length,
        firstCheckinDate: checkins.first.weekStartDate,
        lastCheckinDate: checkins.last.weekStartDate,
        weightStats: weightStats,
        moodStats: moodStats,
        measurementStats: measurementStats,
      );
    } catch (e) {
      _logger.e('Error getting progress summary: $e');
      rethrow;
    }
  }
}

/// Data classes for progress tracking
class WeightDataPoint {
  final DateTime date;
  final double weight;
  final String weekRange;

  WeightDataPoint({
    required this.date,
    required this.weight,
    required this.weekRange,
  });
}

class MoodDataPoint {
  final DateTime date;
  final String mood;
  final int? energyLevel;
  final int? motivationLevel;
  final String weekRange;

  MoodDataPoint({
    required this.date,
    required this.mood,
    this.energyLevel,
    this.motivationLevel,
    required this.weekRange,
  });
}

class MeasurementDataPoint {
  final DateTime date;
  final double value;
  final String measurementType;
  final String weekRange;

  MeasurementDataPoint({
    required this.date,
    required this.value,
    required this.measurementType,
    required this.weekRange,
  });
}

class ProgressSummary {
  final int totalCheckins;
  final DateTime? firstCheckinDate;
  final DateTime? lastCheckinDate;
  final WeightStats? weightStats;
  final MoodStats? moodStats;
  final Map<String, MeasurementStats> measurementStats;

  ProgressSummary({
    required this.totalCheckins,
    this.firstCheckinDate,
    this.lastCheckinDate,
    this.weightStats,
    this.moodStats,
    this.measurementStats = const {},
  });

  factory ProgressSummary.empty() {
    return ProgressSummary(
      totalCheckins: 0,
      measurementStats: {},
    );
  }

  int get trackingWeeks {
    if (firstCheckinDate == null || lastCheckinDate == null) return 0;
    return lastCheckinDate!.difference(firstCheckinDate!).inDays ~/ 7 + 1;
  }
}

class WeightStats {
  final double current;
  final double start;
  final double change;
  final double average;
  final int dataPoints;

  WeightStats({
    required this.current,
    required this.start,
    required this.change,
    required this.average,
    required this.dataPoints,
  });

  String get changeText {
    if (change == 0) return 'No change';
    final symbol = change > 0 ? '+' : '';
    return '$symbol${change.toStringAsFixed(1)} kg';
  }

  bool get hasProgress => dataPoints > 1;
}

class MoodStats {
  final double averageEnergy;
  final double averageMotivation;
  final double currentEnergy;
  final double currentMotivation;
  final int dataPoints;

  MoodStats({
    required this.averageEnergy,
    required this.averageMotivation,
    required this.currentEnergy,
    required this.currentMotivation,
    required this.dataPoints,
  });

  double get overallMoodScore => (averageEnergy + averageMotivation) / 2;
  double get currentMoodScore => (currentEnergy + currentMotivation) / 2;
  
  String get moodTrend {
    if (dataPoints < 2) return 'Not enough data';
    final currentScore = currentMoodScore;
    final avgScore = overallMoodScore;
    
    if (currentScore > avgScore + 0.5) return 'Improving';
    if (currentScore < avgScore - 0.5) return 'Declining';
    return 'Stable';
  }
}

class MeasurementStats {
  final String type;
  final double current;
  final double start;
  final double change;
  final double average;
  final int dataPoints;

  MeasurementStats({
    required this.type,
    required this.current,
    required this.start,
    required this.change,
    required this.average,
    required this.dataPoints,
  });

  String get changeText {
    if (change == 0) return 'No change';
    final symbol = change > 0 ? '+' : '';
    return '$symbol${change.toStringAsFixed(1)} cm';
  }

  bool get hasProgress => dataPoints > 1;
  
  String get formattedType {
    return type.split('_').map((word) => 
        word[0].toUpperCase() + word.substring(1).toLowerCase()
    ).join(' ');
  }
}