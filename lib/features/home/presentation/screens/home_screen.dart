import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/meal_plan_provider.dart';
import '../../../../shared/models/meal_model.dart';
import '../../../../shared/services/calorie_calculation_service.dart';
import '../../../../shared/services/daily_consumption_service.dart';
import '../../../../shared/services/streak_service.dart';
import '../widgets/day_selector.dart';
import '../widgets/calorie_summary_card.dart';
import '../widgets/nutrition_goals_card.dart';
import '../widgets/next_meal_card.dart';
import '../../../food_search/presentation/screens/food_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final _logger = Logger();
  late DateTime _selectedDate;
  CalorieTargets? _calorieTargets;
  MealDay? _currentDayMeals;
  Map<DateTime, Map<String, dynamic>> _dailyConsumptionData = {};
  bool _isLoading = true;
  bool _isLoadingMealPlan = false;
  int _currentStreak = 0; // Add streak tracking

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _logger.d('HomeScreen - initState called');

    // Use addPostFrameCallback to delay data loading until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCurrentStreak();
  }

  Future<void> _loadUserData() async {
    _logger.d('HomeScreen - _loadUserData called');
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final mealPlanProvider =
          Provider.of<MealPlanProvider>(context, listen: false);

      final user = authProvider.userModel;
      _logger.d('HomeScreen - User model: ${user?.name ?? 'null'}');
      _logger
          .d('HomeScreen - Is authenticated: ${authProvider.isAuthenticated}');

      if (user != null) {
        _logger.d(
            'HomeScreen - User preferences: age=${user.preferences.age}, weight=${user.preferences.weight}, height=${user.preferences.height}');

        try {
          _calorieTargets =
              CalorieCalculationService.calculateCalorieTargets(user);
          _logger.d(
              'HomeScreen - Calorie targets calculated: ${_calorieTargets?.dailyTarget}');
        } catch (e) {
          _logger.e('HomeScreen - Error calculating calorie targets: $e');
        }

        // Load meal plan if needed
        await _loadMealPlanIfNeeded(authProvider, mealPlanProvider);

        // Load current day's meals
        _loadCurrentDayMeals();

        // Load multi-day consumption data for DaySelector
        await _loadMultiDayConsumptionData();

        // Load current streak
        _loadCurrentStreak();
      } else {
        _logger.w('HomeScreen - No user model available');
      }
    } catch (e) {
      _logger.e('HomeScreen - Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
      _logger.d('HomeScreen - _loadUserData completed, isLoading: $_isLoading');
    }
  }

  Future<void> _loadMealPlanIfNeeded(
      AuthProvider authProvider, MealPlanProvider mealPlanProvider) async {
    if (_isLoadingMealPlan) {
      return;
    }

    setState(() {
      _isLoadingMealPlan = true;
    });

    try {
      // Check if user is authenticated
      if (!authProvider.isAuthenticated || authProvider.userModel == null) {
        _logger
            .w('HomeScreen - User not authenticated, skipping meal plan load');
        return;
      }

      // Check if the current meal plan belongs to the current user
      final currentMealPlan = mealPlanProvider.mealPlan;
      if (currentMealPlan != null) {
        if (currentMealPlan.userId == authProvider.userModel!.id) {
          _logger.d('HomeScreen - Meal plan already loaded for current user');
          return;
        } else {
          _logger.d('HomeScreen - Clearing meal plan for different user');
          mealPlanProvider.clearMealPlan();
        }
      }

      // Load meal plan for current user
      _logger.d(
          'HomeScreen - Loading meal plan for user: ${authProvider.userModel!.id}');
      await mealPlanProvider.loadMealPlan(authProvider.userModel!.id);
      _logger.d(
          'HomeScreen - Meal plan loaded: ${mealPlanProvider.mealPlan?.title ?? 'null'}');
    } catch (e) {
      _logger.e('HomeScreen - Error loading meal plan: $e');
    } finally {
      setState(() {
        _isLoadingMealPlan = false;
      });
    }
  }

  /// Load consumption data for the last 6 days (5 previous + today)
  Future<void> _loadMultiDayConsumptionData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final mealPlanProvider =
        Provider.of<MealPlanProvider>(context, listen: false);
    final userId = authProvider.userModel?.id;

    if (userId == null || mealPlanProvider.mealPlan == null) return;

    try {
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 5));

      // Clear existing data
      _dailyConsumptionData.clear();

      // Load consumption data for each day
      for (int i = 0; i < 6; i++) {
        final date = startDate.add(Duration(days: i));

        // Get consumption data from service
        final consumptionData =
            await DailyConsumptionService.getDailyConsumptionSummary(
          userId,
          date,
        );

        if (consumptionData != null) {
          // Calculate actual consumed calories from meal plan data
          final weekdayIndex = date.weekday - 1;
          if (weekdayIndex >= 0 &&
              weekdayIndex < mealPlanProvider.mealPlan!.mealDays.length) {
            final templateMealDay =
                mealPlanProvider.mealPlan!.mealDays[weekdayIndex];
            final mealConsumption = Map<String, bool>.from(
                consumptionData['mealConsumption'] ?? {});

            // Calculate consumed nutrition from the template meals
            double consumedCalories = 0.0;
            double consumedProtein = 0.0;
            double consumedCarbs = 0.0;
            double consumedFat = 0.0;

            for (final meal in templateMealDay.meals) {
              if (mealConsumption[meal.id] == true) {
                consumedCalories += meal.nutrition.calories;
                consumedProtein += meal.nutrition.protein;
                consumedCarbs += meal.nutrition.carbs;
                consumedFat += meal.nutrition.fat;
              }
            }

            // Update the consumption data with calculated values
            consumptionData['consumedCalories'] = consumedCalories;
            consumptionData['consumedProtein'] = consumedProtein;
            consumptionData['consumedCarbs'] = consumedCarbs;
            consumptionData['consumedFat'] = consumedFat;

            _logger.d(
                'HomeScreen - Calculated consumption for ${date.toIso8601String()}: $consumedCalories calories');
          }

          _dailyConsumptionData[date] = consumptionData;
        }
      }

      _logger.d(
          'HomeScreen - Loaded consumption data for ${_dailyConsumptionData.length} days');
    } catch (e) {
      _logger.e('HomeScreen - Error loading multi-day consumption data: $e');
    }
  }

  /// Load meals for the currently selected date
  Future<void> _loadCurrentDayMeals() async {
    final mealPlanProvider =
        Provider.of<MealPlanProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final mealPlan = mealPlanProvider.mealPlan;

    if (mealPlan == null) {
      _logger.w('HomeScreen - No meal plan available');
      return;
    }

    try {
      // Get the weekday index (0 = Monday, 6 = Sunday)
      final weekdayIndex = _selectedDate.weekday - 1;
      _logger.d(
          'HomeScreen - Loading meals for weekday index: $weekdayIndex (${_selectedDate.weekday})');

      // Get the meal day from the weekly template
      if (weekdayIndex >= 0 && weekdayIndex < mealPlan.mealDays.length) {
        final templateMealDay = mealPlan.mealDays[weekdayIndex];
        _logger
            .d('HomeScreen - Found template meal day: ${templateMealDay.id}');

        // Create a copy of the template meal day for the selected date
        _currentDayMeals = MealDay(
          id: '${templateMealDay.id}_${_selectedDate.toIso8601String()}',
          date: _selectedDate,
          meals: templateMealDay.meals
              .map((meal) => meal.copyWith())
              .toList(), // Keep original meal IDs
          totalCalories: templateMealDay.totalCalories,
          totalProtein: templateMealDay.totalProtein,
          totalCarbs: templateMealDay.totalCarbs,
          totalFat: templateMealDay.totalFat,
        );

        // Load consumption data for the selected date
        final consumptionData =
            await DailyConsumptionService.getDailyConsumptionSummary(
          authProvider.userModel?.id ?? '',
          _selectedDate,
        );

        if (consumptionData != null) {
          _logger.d(
              'HomeScreen - Loaded consumption data for ${_selectedDate.toIso8601String()}: ${consumptionData['consumedCalories']} calories');

          // Debug: Log the meal consumption data
          final mealConsumption =
              Map<String, bool>.from(consumptionData['mealConsumption'] ?? {});
          _logger.d('HomeScreen - Meal consumption data: $mealConsumption');

          // Debug: Log the template meal IDs
          _logger.d(
              'HomeScreen - Template meal IDs: ${_currentDayMeals!.meals.map((m) => m.id).toList()}');

          // Apply consumption data to meals
          for (final meal in _currentDayMeals!.meals) {
            if (mealConsumption.containsKey(meal.id)) {
              meal.isConsumed = mealConsumption[meal.id]!;
              _logger.d(
                  'HomeScreen - Applied consumption ${mealConsumption[meal.id]} to meal: ${meal.name} (${meal.id})');
            } else {
              _logger.d(
                  'HomeScreen - No consumption data for meal: ${meal.name} (${meal.id})');
            }
          }

          // Update consumed nutrition
          _currentDayMeals!.calculateConsumedNutrition();

          _logger.d(
              'HomeScreen - Applied consumption data: ${_currentDayMeals!.consumedCalories}/${_currentDayMeals!.totalCalories} calories');
        } else {
          _logger.d(
              'HomeScreen - No consumption data found for ${_selectedDate.toIso8601String()}, using fresh template');
          // Reset all meals to not consumed for new dates
          for (final meal in _currentDayMeals!.meals) {
            meal.isConsumed = false;
          }
          _currentDayMeals!.calculateConsumedNutrition();
        }
        setState(() {});
      } else {
        _logger.w('HomeScreen - Invalid weekday index: $weekdayIndex');
      }
    } catch (e) {
      _logger.e('HomeScreen - Error loading current day meals: $e');
    }
  }

  String _getDayName(DateTime? date) {
    if (date == null) return 'Unknown';
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[date.weekday - 1];
  }

  /// Load the current streak for the user
  Future<void> _loadCurrentStreak() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userModel?.id;

      if (userId != null) {
        final streak = await StreakService.getCurrentStreak(userId);
        setState(() {
          _currentStreak = streak;
        });
        _logger.d('HomeScreen - Loaded current streak: $_currentStreak');
      }
    } catch (e) {
      _logger.e('HomeScreen - Error loading streak: $e');
    }
  }

  void _onDateSelected(DateTime date) {
    // Light haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      _selectedDate = date;
    });

    // Reload meals for the selected date
    _loadCurrentDayMeals();

    // Refresh multi-day consumption data to update progress indicators
    _loadMultiDayConsumptionData();

    // Debug logging to see what data we have after loading
    _logger.d(
        'HomeScreen - After date selection, _dailyConsumptionData: ${_dailyConsumptionData.map((key, value) => MapEntry('${key.year}-${key.month}-${key.day}', value['consumedCalories']))}');
  }

  @override
  Widget build(BuildContext context) {
    _logger.d(
        'HomeScreen - build called, isLoading: $_isLoading, isLoadingMealPlan: $_isLoadingMealPlan');

    return Consumer2<AuthProvider, MealPlanProvider>(
      builder: (context, authProvider, mealPlanProvider, child) {
        // Always get the latest meal day data from the provider
        if (mealPlanProvider.mealPlan != null) {
          try {
            // Find meal day based on day of week (Monday = 1, Sunday = 7)
            final dayOfWeek = _selectedDate.weekday; // 1 = Monday, 7 = Sunday
            final mealDayIndex = dayOfWeek - 1; // Convert to 0-based index

            if (mealDayIndex >= 0 &&
                mealDayIndex < mealPlanProvider.mealPlan!.mealDays.length) {
              // Don't override _currentDayMeals here - let the date selection handle it
              _logger.d('HomeScreen - Found meal day for index: $mealDayIndex');
            } else {
              _logger
                  .w('HomeScreen - No meal day found for index: $mealDayIndex');
            }
          } catch (e) {
            // No meal day found for this date
            _logger.w('HomeScreen - Error finding meal day: $e');
          }
        } else {
          _logger.d('HomeScreen - No meal plan available');
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: _isLoading || _isLoadingMealPlan
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading...'),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadUserData,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        const SizedBox(height: 16),
                        // App Header
                        _buildAppHeader(),
                        const SizedBox(height: 24),
                        // Day Selector
                        DaySelector(
                          selectedDate: _selectedDate,
                          onDateSelected: _onDateSelected,
                          currentDayMeals: _currentDayMeals,
                          targetCalories: _calorieTargets?.dailyTarget,
                          dailyConsumptionData: _dailyConsumptionData,
                        ),
                        const SizedBox(height: 24),
                        // Calorie Summary Card
                        if (_calorieTargets != null)
                          CalorieSummaryCard(
                            calorieTargets: _calorieTargets!,
                            selectedDate: _selectedDate,
                            currentDayMeals: _currentDayMeals,
                          )
                        else
                          _buildNoDataCard('No Calorie Targets',
                              'User preferences may not be set'),

                        const SizedBox(height: 20),
                        // Nutrition Goals Cards
                        if (_calorieTargets != null)
                          NutritionGoalsCard(
                            macros: _calorieTargets!.macros,
                            selectedDate: _selectedDate,
                            currentDayMeals: _currentDayMeals,
                          )
                        else
                          _buildNoDataCard('No Nutrition Goals',
                              'Complete onboarding to set goals'),
                        const SizedBox(height: 20),
                        // Next Meal Card
                        NextMealCard(
                          currentDayMeals: _currentDayMeals,
                          selectedDate: _selectedDate,
                        ),
                        const SizedBox(
                            height: 100), // Space for bottom navigation
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildNoDataCard(String title, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.heading5,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAppHeader() {
    return Column(
      children: [
        Row(
          children: [
            // App Logo and Name
            Text(
              'Moctar Nutrition',
              style: AppTextStyles.heading4.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const Spacer(),

            // Streak Widget
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                border: Border.all(color: Colors.black, width: 1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Color(0xFFF59E0B),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_currentStreak',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10), // Space between streak and search icon
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FoodSearchScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.search, color: Colors.black),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }
}
