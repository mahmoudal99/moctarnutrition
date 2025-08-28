import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/checkin_model.dart';
import '../models/meal_model.dart';
import '../models/user_model.dart';
import 'streak_service.dart';
import 'daily_consumption_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';

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
      final moodData = checkins
          .where((c) => c.energyLevel != null && c.motivationLevel != null)
          .toList();
      MoodStats? moodStats;
      if (moodData.isNotEmpty) {
        final energyLevels = moodData.map((c) => c.energyLevel!).toList();
        final motivationLevels =
            moodData.map((c) => c.motivationLevel!).toList();

        moodStats = MoodStats(
          averageEnergy:
              energyLevels.reduce((a, b) => a + b) / energyLevels.length,
          averageMotivation: motivationLevels.reduce((a, b) => a + b) /
              motivationLevels.length,
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

  /// Get overview data for the overview tab
  static Future<OverviewData> getOverviewData(String userId,
      {UserModel? userModel}) async {
    try {
      _logger.d(
          'getOverviewData called with userId: $userId, userModel: ${userModel?.id ?? 'null'}');

      // Always get current streak regardless of checkins
      final currentStreak = await StreakService.getCurrentStreak(userId);
      final streakStats = await StreakService.getStreakStats(userId);
      _logger.d('Streak data - current: $currentStreak, stats: $streakStats');

      final checkins = await getUserCheckins(userId);
      _logger.d('Found ${checkins.length} checkins');

      WeightProgressData? weightProgress;

      // Always create weight progress data using user preferences
      if (userModel != null) {
        final startWeight = userModel.preferences.weight;
        final goalWeight = userModel.preferences.desiredWeight;

        // Get current weight from check-ins if available, otherwise use starting weight
        double currentWeight = startWeight;
        if (checkins.isNotEmpty) {
          final weightData = checkins.where((c) => c.weight != null).toList();
          _logger.d('Found ${weightData.length} weight data points');

          if (weightData.isNotEmpty) {
            currentWeight = weightData.last.weight!;
            _logger.d('Using check-in weight: $currentWeight');
          } else {
            _logger.d(
                'No check-in weight data, using onboarding weight: $currentWeight');
          }
        } else {
          _logger.d('No check-ins, using onboarding weight: $currentWeight');
        }

        _logger.d(
            'Weight progress - current: $currentWeight, start: $startWeight, goal: $goalWeight');

        weightProgress = WeightProgressData(
          currentWeight: currentWeight,
          startWeight: startWeight,
          goalWeight: goalWeight,
          progressPercentage:
              _calculateWeightProgress(startWeight, currentWeight, goalWeight),
          dataPoints: checkins.isNotEmpty
              ? checkins
                  .where((c) => c.weight != null)
                  .map((c) => WeightDataPoint(
                        date: c.weekStartDate,
                        weight: c.weight!,
                        weekRange: c.weekRange,
                      ))
                  .toList()
              : [],
        );
      }

      // Get daily calories data for the current week
      final dailyCalories = await _getDailyCaloriesDataForWeek(userId);
      _logger.d('Daily calories data loaded');

      // Get BMI data from user preferences
      final bmiData = _getBMIDataFromUser(userModel);
      _logger.d('BMI data created: ${bmiData.currentBMI}');

      return OverviewData(
        streak: StreakData(
          currentStreak: currentStreak,
          isActive: streakStats['isStreakActive'] ?? false,
          lastCompletedDate: streakStats['lastCompletedDate'],
        ),
        weightProgress: weightProgress,
        dailyCalories: dailyCalories,
        bmiData: bmiData,
      );
    } catch (e) {
      _logger.e('Error getting overview data: $e');
      return OverviewData.empty();
    }
  }

  /// Get daily calories data for the current week
  static Future<DailyCaloriesData> _getDailyCaloriesDataForWeek(
      String userId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(
          now.year, now.month, now.day); // Get today's date without time

      _logger.d(
          'ProgressService - Getting daily calories for week starting: ${today.toIso8601String()}');
      _logger.d('ProgressService - User ID: $userId');
      _logger.d('ProgressService - Today is: ${today.toIso8601String()}');

      final dailyData = <DailyCaloriesPoint>[];

      // Get consumption data for TODAY and the last 6 days (7 days total)
      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));

        try {
          _logger.d(
              'ProgressService - Checking date: ${date.toIso8601String()} (weekday: ${date.weekday})');

          // Use the SAME LOGIC as home screen - call with the actual date
          final consumptionData =
              await DailyConsumptionService.getDailyConsumptionSummary(
                  userId, date);

          if (consumptionData != null) {
            _logger.d(
                'ProgressService - Found data for ${date.toIso8601String()}: ${consumptionData['consumedCalories']} calories');
            dailyData.add(DailyCaloriesPoint(
              date: date,
              totalCalories: consumptionData['consumedCalories'] ?? 0.0,
              protein: consumptionData['consumedProtein'] ?? 0.0,
              carbs: consumptionData['consumedCarbs'] ?? 0.0,
              fats: consumptionData['consumedFat'] ?? 0.0,
            ));
          } else {
            _logger.d(
                'ProgressService - NO DATA found for ${date.toIso8601String()}');
            // No consumption data for this day
            dailyData.add(DailyCaloriesPoint(
              date: date,
              totalCalories: 0.0,
              protein: 0.0,
              carbs: 0.0,
              fats: 0.0,
            ));
          }
        } catch (e) {
          _logger.w(
              'Error getting consumption data for ${date.toIso8601String()}: $e');
          // Add empty data for this day
          dailyData.add(DailyCaloriesPoint(
            date: date,
            totalCalories: 0.0,
            protein: 0.0,
            carbs: 0.0,
            fats: 0.0,
          ));
        }
      }

      final weeklyTotal =
          dailyData.fold(0.0, (sum, day) => sum + day.totalCalories);

      return DailyCaloriesData(
        dailyData: dailyData,
        weeklyTotal: weeklyTotal,
        weeklyAverage: weeklyTotal / 7,
      );
    } catch (e) {
      _logger.e('Error getting daily calories data: $e');
      return DailyCaloriesData.empty();
    }
  }

  /// Get BMI data from user preferences
  static BMIData _getBMIDataFromUser(UserModel? userModel) {
    _logger.d(
        '_getBMIDataFromUser called with userModel: ${userModel?.id ?? 'null'}');

    if (userModel == null) {
      _logger.w('UserModel is null, returning empty BMI data');
      return BMIData.empty();
    }

    final preferences = userModel.preferences;
    _logger.d(
        'User preferences - weight: ${preferences.weight}, height: ${preferences.height}');

    final height = preferences.height;
    final currentWeight = preferences.weight;

    if (height <= 0 || currentWeight <= 0) {
      _logger.w(
          'Invalid height or weight - height: $height, weight: $currentWeight');
      return BMIData.empty();
    }

    // Use the BMI calculation that already exists in your system
    final bmi = currentWeight / ((height / 100) * (height / 100));
    final bmiCategory = _getBMICategory(bmi);

    _logger.d('Calculated BMI: $bmi, category: $bmiCategory');

    return BMIData(
      currentBMI: bmi,
      bmiCategory: bmiCategory,
      weight: currentWeight,
      height: height,
      isHealthy: bmiCategory == BMICategory.healthy,
    );
  }

  /// Calculate weight progress percentage
  static double _calculateWeightProgress(
      double start, double current, double goal) {
    if (start == goal) return 100.0;

    final totalChange = (goal - start).abs();
    final currentChange = (current - start).abs();

    if (totalChange == 0) return 100.0;

    final progress = (currentChange / totalChange) * 100;
    return progress.clamp(0.0, 100.0);
  }

  /// Get BMI category
  static BMICategory _getBMICategory(double bmi) {
    if (bmi < 18.5) return BMICategory.underweight;
    if (bmi < 25) return BMICategory.healthy;
    if (bmi < 30) return BMICategory.overweight;
    return BMICategory.obese;
  }

  /// Check if two dates are the same day
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
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
    return type
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}

/// Data classes for the overview tab
class OverviewData {
  final StreakData streak;
  final WeightProgressData? weightProgress;
  final DailyCaloriesData dailyCalories;
  final BMIData bmiData;

  OverviewData({
    required this.streak,
    this.weightProgress,
    required this.dailyCalories,
    required this.bmiData,
  });

  factory OverviewData.empty() {
    return OverviewData(
      streak: StreakData.empty(),
      dailyCalories: DailyCaloriesData.empty(),
      bmiData: BMIData.empty(),
    );
  }
}

class StreakData {
  final int currentStreak;
  final bool isActive;
  final DateTime? lastCompletedDate;

  StreakData({
    required this.currentStreak,
    required this.isActive,
    this.lastCompletedDate,
  });

  factory StreakData.empty() {
    return StreakData(
      currentStreak: 0,
      isActive: false,
    );
  }
}

class WeightProgressData {
  final double currentWeight;
  final double startWeight;
  final double goalWeight;
  final double progressPercentage;
  final List<WeightDataPoint> dataPoints;

  WeightProgressData({
    required this.currentWeight,
    required this.startWeight,
    required this.goalWeight,
    required this.progressPercentage,
    required this.dataPoints,
  });

  double get weightChange => currentWeight - startWeight;
  double get weightToGoal => goalWeight - currentWeight;
  bool get isOnTrack =>
      (goalWeight > startWeight && currentWeight <= goalWeight) ||
      (goalWeight < startWeight && currentWeight >= goalWeight);
}

class DailyCaloriesPoint {
  final DateTime date;
  final double totalCalories;
  final double protein;
  final double carbs;
  final double fats;

  DailyCaloriesPoint({
    required this.date,
    required this.totalCalories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  double get proteinCalories => protein * 4;
  double get carbsCalories => carbs * 4;
  double get fatsCalories => fats * 9;
}

class DailyCaloriesData {
  final List<DailyCaloriesPoint> dailyData;
  final double weeklyTotal;
  final double weeklyAverage;

  DailyCaloriesData({
    required this.dailyData,
    required this.weeklyTotal,
    required this.weeklyAverage,
  });

  factory DailyCaloriesData.empty() {
    return DailyCaloriesData(
      dailyData: [],
      weeklyTotal: 0.0,
      weeklyAverage: 0.0,
    );
  }
}

enum BMICategory { underweight, healthy, overweight, obese }

class BMIData {
  final double currentBMI;
  final BMICategory bmiCategory;
  final double weight;
  final double height;
  final bool isHealthy;

  BMIData({
    required this.currentBMI,
    required this.bmiCategory,
    required this.weight,
    required this.height,
    required this.isHealthy,
  });

  factory BMIData.empty() {
    return BMIData(
      currentBMI: 0.0,
      bmiCategory: BMICategory.healthy,
      weight: 0.0,
      height: 0.0,
      isHealthy: true,
    );
  }

  String get categoryText {
    switch (bmiCategory) {
      case BMICategory.underweight:
        return 'Underweight';
      case BMICategory.healthy:
        return 'Healthy';
      case BMICategory.overweight:
        return 'Overweight';
      case BMICategory.obese:
        return 'Obese';
    }
  }

  Color get categoryColor {
    switch (bmiCategory) {
      case BMICategory.underweight:
        return Colors.blue;
      case BMICategory.healthy:
        return Colors.green;
      case BMICategory.overweight:
        return Colors.orange;
      case BMICategory.obese:
        return Colors.red;
    }
  }
}
