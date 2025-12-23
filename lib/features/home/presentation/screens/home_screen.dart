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
import '../widgets/meal_plan_required_bottom_sheet.dart';
import '../../../food_search/presentation/screens/food_search_screen.dart';
import '../../../food_search/presentation/screens/barcode_scanner_screen.dart';

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
  String? _cheatDayName;
  int? _cheatDayIndex;
  DateTime? _planAnchorDate;

  bool get _isSelectedDateCheatDay {
    if (_cheatDayIndex == null) {
      return false;
    }
    return (_selectedDate.weekday - 1) == _cheatDayIndex;
  }

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
        _cheatDayName = user.preferences.cheatDay;
        _cheatDayIndex = _convertCheatDayToIndex(_cheatDayName);
        _planAnchorDate = _determinePlanAnchorDate(mealPlanProvider.mealPlan);
        _logger.d(
            'HomeScreen - User preferences: age=${user.preferences.age}, weight=${user.preferences.weight}, height=${user.preferences.height}');

        // Use stored calculated targets if available, otherwise calculate new ones
        try {
          if (user.preferences.calculatedCalorieTargets != null) {
            _calorieTargets = user.preferences.calculatedCalorieTargets;
            _logger.d(
                'HomeScreen - Using stored calorie targets: ${_calorieTargets?.dailyTarget}');
          } else {
            _calorieTargets =
                CalorieCalculationService.calculateCalorieTargets(user);
            _logger.d(
                'HomeScreen - Calorie targets calculated: ${_calorieTargets?.dailyTarget}');

            // Update user preferences with new calculations
            final updatedPreferences = user.preferences.copyWith(
              calculatedCalorieTargets: _calorieTargets,
            );
            final updatedUser = user.copyWith(
              preferences: updatedPreferences,
              updatedAt: DateTime.now(),
            );
            await authProvider.updateUserProfile(updatedUser);
          }
        } catch (e) {
          _logger.e('HomeScreen - Error handling calorie targets: $e');
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
      final user = authProvider.userModel!;
      _logger.d('HomeScreen - Loading meal plan for user: ${user.id}');
      _logger.d('HomeScreen - User email: ${user.email}');
      _logger.d('HomeScreen - User mealPlanId: ${user.mealPlanId ?? 'null'}');
      _logger.d('HomeScreen - User role: ${user.role}');
      _logger.d('HomeScreen - User created at: ${user.createdAt}');
      await mealPlanProvider.loadMealPlan(user.id, mealPlanId: user.mealPlanId);
      _logger.d(
          'HomeScreen - Meal plan loaded: ${mealPlanProvider.mealPlan?.title ?? 'null'}');
      _planAnchorDate = _determinePlanAnchorDate(mealPlanProvider.mealPlan);
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
          final templateMealDay = _resolveMealDayForDate(
            mealPlanProvider.mealPlan!,
            date,
          );

          if (templateMealDay == null) {
            // On cheat days we don't map template meals
            continue;
          }

          if (templateMealDay != null) {
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
      // For batch cooking meal plans, we need to map the selected date to the appropriate meal day
      // instead of using weekday indices
      final templateMealDay = _resolveMealDayForDate(mealPlan, _selectedDate);

      if (templateMealDay == null) {
        _logger.d(
            'HomeScreen - Selected date ${_selectedDate.toIso8601String()} is a cheat day. Skipping meal loading.');
        setState(() {
          _currentDayMeals = null;
        });
        return;
      }

      _logger.d('HomeScreen - Found template meal day: ${templateMealDay.id}');

      // Create a copy of the template meal day for the selected date
      _currentDayMeals = MealDay(
        id: '${templateMealDay.id}_${_selectedDate.toIso8601String()}',
        date: _selectedDate,
        meals: templateMealDay.meals.map((meal) => meal.copyWith()).toList(),
        // Keep original meal IDs
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
            final resolvedMealDay = _resolveMealDayForDate(
                mealPlanProvider.mealPlan!, _selectedDate);
            if (resolvedMealDay != null) {
              _logger.d(
                  'HomeScreen - Mapped date ${_selectedDate.toIso8601String()} to meal day ${resolvedMealDay.id}');
            } else if (_isSelectedDateCheatDay) {
              _logger.d(
                  'HomeScreen - ${_selectedDate.toIso8601String()} is the configured cheat day ($_cheatDayName)');
            } else {
              _logger.w(
                  'HomeScreen - No meal day found for date: ${_selectedDate.toIso8601String()}, meal plan has ${mealPlanProvider.mealPlan!.mealDays.length} days');
            }
          } catch (e) {
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
                          isCheatDay: _isSelectedDateCheatDay,
                          cheatDayName: _cheatDayName,
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

  void _showMealPlanRequiredMessage() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const MealPlanRequiredBottomSheet(),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      useSafeArea: true,
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
              'Regimen',
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
            const SizedBox(width: 10),
            // Space between streak and search icon
            IconButton(
              onPressed: () async {
                final mealPlanProvider =
                    Provider.of<MealPlanProvider>(context, listen: false);
                if (mealPlanProvider.mealPlan == null) {
                  _showMealPlanRequiredMessage();
                  return;
                }
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FoodSearchScreen(),
                  ),
                );

                // If food was added, refresh the data
                if (result == true) {
                  _loadCurrentDayMeals();
                  _loadMultiDayConsumptionData();
                }
              },
              icon: const Icon(Icons.search, color: Colors.black),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            // Space between search and barcode scanner
            IconButton(
              onPressed: () async {
                final mealPlanProvider =
                    Provider.of<MealPlanProvider>(context, listen: false);
                if (mealPlanProvider.mealPlan == null) {
                  _showMealPlanRequiredMessage();
                  return;
                }
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BarcodeScannerScreen(),
                  ),
                );

                // If food was added, refresh the data
                if (result == true) {
                  _loadCurrentDayMeals();
                  _loadMultiDayConsumptionData();
                }
              },
              icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }

  int? _convertCheatDayToIndex(String? cheatDay) {
    if (cheatDay == null) {
      return null;
    }
    switch (cheatDay.toLowerCase()) {
      case 'monday':
        return 0;
      case 'tuesday':
        return 1;
      case 'wednesday':
        return 2;
      case 'thursday':
        return 3;
      case 'friday':
        return 4;
      case 'saturday':
        return 5;
      case 'sunday':
        return 6;
      default:
        return null;
    }
  }

  bool _isCheatDay(DateTime date) {
    if (_cheatDayIndex == null) {
      return false;
    }
    return (date.weekday - 1) == _cheatDayIndex;
  }

  DateTime? _determinePlanAnchorDate(MealPlanModel? mealPlan) {
    if (mealPlan == null) {
      return null;
    }
    final normalizedStart = _normalizeDate(mealPlan.startDate);
    if (mealPlan.mealDays.isEmpty) {
      return normalizedStart;
    }

    final sortedDates = mealPlan.mealDays
        .map((day) => _normalizeDate(day.date))
        .toList()
      ..sort();

    return sortedDates.first;
  }

  MealDay? _resolveMealDayForDate(MealPlanModel mealPlan, DateTime date) {
    if (mealPlan.mealDays.isEmpty) {
      return null;
    }

    if (_isCheatDay(date)) {
      return null;
    }

    _planAnchorDate ??= _determinePlanAnchorDate(mealPlan);
    final anchor = _planAnchorDate ?? _normalizeDate(mealPlan.startDate);

    final normalizedAnchor = _normalizeDate(anchor);
    final normalizedTarget = _normalizeDate(date);

    final offset = _calculateNonCheatDayOffset(
      normalizedAnchor,
      normalizedTarget,
      _cheatDayIndex,
    );

    final mealCount = mealPlan.mealDays.length;
    int resolvedIndex = offset % mealCount;
    if (resolvedIndex < 0) {
      resolvedIndex = (mealCount + resolvedIndex) % mealCount;
    }

    // Guard against any negative overflow
    if (resolvedIndex < 0 || resolvedIndex >= mealCount) {
      resolvedIndex = resolvedIndex.abs() % mealCount;
    }

    return mealPlan.mealDays[resolvedIndex];
  }

  int _calculateNonCheatDayOffset(
    DateTime start,
    DateTime target,
    int? cheatDayIndex,
  ) {
    final difference = target.difference(start).inDays;
    if (difference == 0) {
      return 0;
    }

    if (cheatDayIndex == null) {
      return difference;
    }

    final forward = difference > 0;
    final absDays = difference.abs();

    int cheatDays = absDays ~/ 7;
    final remainder = absDays % 7;

    int currentWeekday = start.weekday - 1;

    for (int i = 0; i < remainder; i++) {
      currentWeekday =
          forward ? (currentWeekday + 1) % 7 : (currentWeekday - 1 + 7) % 7;
      if (currentWeekday == cheatDayIndex) {
        cheatDays += 1;
      }
    }

    final nonCheatDays = absDays - cheatDays;
    return forward ? nonCheatDays : -nonCheatDays;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
