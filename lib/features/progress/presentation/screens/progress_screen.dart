import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/meal_plan_provider.dart';
import '../../../../shared/services/progress_service.dart';
import '../../../../shared/services/daily_consumption_service.dart';
import '../../../../shared/services/streak_service.dart';
import '../../../../shared/models/meal_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/progress_service.dart';
import '../widgets/weight_tab.dart';
import '../widgets/mood_tab.dart';
import '../widgets/measurements_tab.dart';
import '../widgets/overview_tab.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _overviewScrollController;
  Future<ProgressSummary>? _progressSummaryFuture;
  Future<List<WeightDataPoint>>? _weightDataFuture;
  Future<List<MoodDataPoint>>? _moodDataFuture;
  Future<List<String>>? _measurementTypesFuture;
  Map<String, Future<List<MeasurementDataPoint>>> _measurementDataFutures = {};
  Future<OverviewData>? _overviewDataFuture;
  int _selectedWeekOffset =
      0; // 0 = this week, 1 = last week, 2 = 2 weeks ago, 3 = 3 weeks ago

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _overviewScrollController = ScrollController();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when dependencies change (e.g., returning from meal prep screen)
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _overviewScrollController.dispose();
    super.dispose();
  }

  void _loadData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userModel?.id;
    final userModel = authProvider.userModel;

    if (userId != null) {
      setState(() {
        _progressSummaryFuture = ProgressService.getProgressSummary(userId);
        _weightDataFuture = ProgressService.getWeightProgress(userId);
        _moodDataFuture = ProgressService.getMoodProgress(userId);
        _measurementTypesFuture =
            ProgressService.getUserMeasurementTypes(userId);
        _overviewDataFuture = _getOverviewDataWithMealPlan(userId, userModel);
      });

      // Load measurement data for each type
      _measurementTypesFuture?.then((types) {
        final futures = <String, Future<List<MeasurementDataPoint>>>{};
        for (final type in types) {
          futures[type] = ProgressService.getMeasurementProgress(userId, type);
        }
        setState(() {
          _measurementDataFutures = futures;
        });
      });
    }
  }

  /// Get overview data using the SAME LOGIC as home screen
  Future<OverviewData> _getOverviewDataWithMealPlan(
      String userId, UserModel? userModel) async {
    try {
      final mealPlanProvider =
          Provider.of<MealPlanProvider>(context, listen: false);
      final mealPlan = mealPlanProvider.mealPlan;

      if (mealPlan == null) {
        return OverviewData.empty();
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Calculate the start date for the selected week
      // Get the Monday of the current week
      final currentWeekMonday =
          today.subtract(Duration(days: today.weekday - 1));

      // Go back by the selected week offset to get the target week's Monday
      final targetWeekMonday =
          currentWeekMonday.subtract(Duration(days: _selectedWeekOffset * 7));

      final dailyData = <DailyCaloriesPoint>[];

      // Get data for the selected week (7 days total)
      for (int i = 0; i < 7; i++) {
        final date = targetWeekMonday.add(Duration(days: i));
        final weekdayIndex = date.weekday - 1; // Monday = 0, Sunday = 6

        if (weekdayIndex >= 0 && weekdayIndex < mealPlan.mealDays.length) {
          final templateMealDay = mealPlan.mealDays[weekdayIndex];

          // Create meal day for this date (same as home screen)
          final mealDay = MealDay(
            id: '${templateMealDay.id}_${date.toIso8601String()}',
            date: date,
            meals:
                templateMealDay.meals.map((meal) => meal.copyWith()).toList(),
            totalCalories: templateMealDay.totalCalories,
            totalProtein: templateMealDay.totalProtein,
            totalCarbs: templateMealDay.totalCarbs,
            totalFat: templateMealDay.totalFat,
          );

          // Load consumption data for this date (same as home screen)
          final consumptionData =
              await DailyConsumptionService.getDailyConsumptionSummary(
                  userId, date);

          if (consumptionData != null) {
            final mealConsumption = Map<String, bool>.from(
                consumptionData['mealConsumption'] ?? {});

            // Apply consumption data to meals (same as home screen)
            for (final meal in mealDay.meals) {
              if (mealConsumption.containsKey(meal.id)) {
                meal.isConsumed = mealConsumption[meal.id]!;
              } else {
                meal.isConsumed = false;
              }
            }

            // Calculate consumed nutrition (same as home screen)
            mealDay.calculateConsumedNutrition();

            dailyData.add(DailyCaloriesPoint(
              date: date,
              totalCalories: mealDay.consumedCalories,
              protein: mealDay.consumedProtein,
              carbs: mealDay.consumedCarbs,
              fats: mealDay.consumedFat,
            ));
          } else {
            // No consumption data, all meals not consumed
            for (final meal in mealDay.meals) {
              meal.isConsumed = false;
            }
            mealDay.calculateConsumedNutrition();

            dailyData.add(DailyCaloriesPoint(
              date: date,
              totalCalories: mealDay.consumedCalories,
              protein: mealDay.consumedProtein,
              carbs: mealDay.consumedCarbs,
              fats: mealDay.consumedFat,
            ));
          }
        } else {
          // No meal plan for this weekday
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

      // Get streak data
      final streakData = await StreakService.getCurrentStreak(userId);
      final streak = StreakData(
        currentStreak: streakData,
        isActive: streakData > 0,
        lastCompletedDate: null,
      );

      // Get weight progress data from user preferences and check-ins
      WeightProgressData? weightProgress;
      if (userModel != null) {
        final startWeight = userModel.preferences.weight;
        final goalWeight = userModel.preferences.desiredWeight;

        // Get current weight from check-ins if available
        double currentWeight = startWeight;
        final checkins = await ProgressService.getUserCheckins(userId);
        if (checkins.isNotEmpty) {
          final weightData = checkins.where((c) => c.weight != null).toList();
          if (weightData.isNotEmpty) {
            currentWeight =
                weightData.last.weight!; // Use latest check-in weight
          }
        }

        // Calculate progress percentage
        double progressPercentage = 0.0;
        if (startWeight != goalWeight) {
          final totalDistance = (startWeight - goalWeight).abs();
          final currentDistance = (startWeight - currentWeight).abs();
          progressPercentage = (currentDistance / totalDistance) * 100;
          progressPercentage = progressPercentage.clamp(0.0, 100.0);
        }

        weightProgress = WeightProgressData(
          currentWeight: currentWeight,
          startWeight: startWeight,
          goalWeight: goalWeight,
          progressPercentage: progressPercentage,
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

      return OverviewData(
        streak: streak,
        weightProgress: weightProgress,
        dailyCalories: DailyCaloriesData(
          dailyData: dailyData,
          weeklyTotal: weeklyTotal,
          weeklyAverage: weeklyTotal / 7,
        ),
        bmiData: _calculateBMIData(userModel),
      );
    } catch (e) {
      return OverviewData.empty();
    }
  }

  /// Refresh the overview data specifically
  void _refreshOverviewData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userModel?.id;
    final userModel = authProvider.userModel;

    if (userId != null) {
      setState(() {
        _overviewDataFuture =
            ProgressService.getOverviewData(userId, userModel: userModel);
      });
    }
  }

  /// Select a different week and refresh data
  void _selectWeek(int weekOffset) {
    // Update both state variables in a single setState to prevent multiple rebuilds
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userModel?.id;
    final userModel = authProvider.userModel;

    if (userId != null) {
      setState(() {
        _selectedWeekOffset = weekOffset;
        _overviewDataFuture = _getOverviewDataWithMealPlan(userId, userModel);
      });
    }
  }

  /// Calculate BMI data from user model
  BMIData _calculateBMIData(UserModel? userModel) {
    if (userModel == null) {
      return BMIData.empty();
    }

    final preferences = userModel.preferences;
    final height = preferences.height;
    final currentWeight = preferences.weight;

    if (height <= 0 || currentWeight <= 0) {
      return BMIData.empty();
    }

    final bmi = currentWeight / ((height / 100) * (height / 100));
    final bmiCategory = _getBMICategory(bmi);

    return BMIData(
      currentBMI: bmi,
      bmiCategory: bmiCategory,
      weight: currentWeight,
      height: height,
      isHealthy: bmiCategory == BMICategory.healthy,
    );
  }

  /// Get BMI category from BMI value
  BMICategory _getBMICategory(double bmi) {
    if (bmi < 18.5) return BMICategory.underweight;
    if (bmi < 25) return BMICategory.healthy;
    if (bmi < 30) return BMICategory.overweight;
    return BMICategory.obese;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Progress Tracking'),
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_outlined),
          onPressed: () => context.go('/profile'),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppConstants.primaryColor,
          unselectedLabelColor: AppConstants.textSecondary,
          indicatorColor: AppConstants.primaryColor,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Weight'),
            Tab(text: 'Mood'),
            Tab(text: 'Measurements'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                OverviewTab(
                  dataFuture: _overviewDataFuture,
                  onWeekSelected: _selectWeek,
                  selectedWeekOffset: _selectedWeekOffset,
                  scrollController: _overviewScrollController,
                ),
                WeightTab(dataFuture: _weightDataFuture),
                MoodTab(dataFuture: _moodDataFuture),
                MeasurementsTab(
                  typesFuture: _measurementTypesFuture,
                  dataFutures: _measurementDataFutures,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
