import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/meal_plan_provider.dart';
import '../../../../shared/models/meal_model.dart';
import '../../../../shared/services/calorie_calculation_service.dart';
import '../widgets/day_selector.dart';
import '../widgets/calorie_summary_card.dart';
import '../widgets/nutrition_goals_card.dart';

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
  bool _isLoading = true;
  bool _isLoadingMealPlan = false;

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
        _loadCurrentDayMeals(mealPlanProvider);
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

  void _loadCurrentDayMeals(MealPlanProvider mealPlanProvider) {
    final mealPlan = mealPlanProvider.mealPlan;
    _logger.d(
        'HomeScreen - Loading current day meals, meal plan: ${mealPlan?.title ?? 'null'}');

    if (mealPlan != null) {
      // Find the meal day for the selected date based on day of week
      final dayOfWeek = _selectedDate.weekday; // 1 = Monday, 7 = Sunday
      final mealDayIndex = dayOfWeek - 1; // Convert to 0-based index
      _logger.d(
          'HomeScreen - Day of week: $dayOfWeek, meal day index: $mealDayIndex');

      if (mealDayIndex >= 0 && mealDayIndex < mealPlan.mealDays.length) {
        final mealDay = mealPlan.mealDays[mealDayIndex];
        _logger.d(
            'HomeScreen - Found meal day: ${_getDayName(mealDay.date)}');

        // Calculate consumed nutrition for the meal day
        mealDay.calculateConsumedNutrition();

        setState(() {
          _currentDayMeals = mealDay;
        });
        _logger.d(
            'HomeScreen - Current day meals set: ${_getDayName(_currentDayMeals?.date)}');
      } else {
        _logger.w('HomeScreen - No meal day found for index: $mealDayIndex');
        setState(() {
          _currentDayMeals = null;
        });
      }
    } else {
      _logger.w('HomeScreen - No meal plan available');
      setState(() {
        _currentDayMeals = null;
      });
    }
  }

  String _getDayName(DateTime? date) {
    if (date == null) return 'Unknown';
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  void _onDateSelected(DateTime date) {
    // Light haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      _selectedDate = date;
    });

    // Reload meals for the selected date
    final mealPlanProvider =
        Provider.of<MealPlanProvider>(context, listen: false);
    _loadCurrentDayMeals(mealPlanProvider);
  }

  @override
  Widget build(BuildContext context) {
    _logger.d(
        'HomeScreen - build called, isLoading: $_isLoading, isLoadingMealPlan: $_isLoadingMealPlan');

    return Consumer2<AuthProvider, MealPlanProvider>(
      builder: (context, authProvider, mealPlanProvider, child) {
        _logger.d('HomeScreen - Consumer builder called');
        _logger.d(
            'HomeScreen - Auth provider state: isAuthenticated=${authProvider.isAuthenticated}, userModel=${authProvider.userModel?.name ?? 'null'}');
        _logger.d(
            'HomeScreen - Meal plan provider state: mealPlan=${mealPlanProvider.mealPlan?.title ?? 'null'}, isLoading=${mealPlanProvider.isLoading}');

        // Log debug info to console instead of showing on screen
        print('=== HOME SCREEN DEBUG INFO ===');
        print('Auth: ${authProvider.isAuthenticated ? 'Yes' : 'No'}');
        print('User: ${authProvider.userModel?.name ?? 'null'}');
        print('Calorie Targets: ${_calorieTargets?.dailyTarget ?? 'null'}');
        print('Meal Plan: ${mealPlanProvider.mealPlan?.title ?? 'null'}');
        print('Current Day: ${_getDayName(_currentDayMeals?.date) ?? 'null'}');
        print('Loading: $_isLoading, Meal Plan Loading: $_isLoadingMealPlan');
        print('==============================');

        // Always get the latest meal day data from the provider
        if (mealPlanProvider.mealPlan != null) {
          try {
            // Find meal day based on day of week (Monday = 1, Sunday = 7)
            final dayOfWeek = _selectedDate.weekday; // 1 = Monday, 7 = Sunday
            final mealDayIndex = dayOfWeek - 1; // Convert to 0-based index

            if (mealDayIndex >= 0 &&
                mealDayIndex < mealPlanProvider.mealPlan!.mealDays.length) {
              final updatedMealDay =
                  mealPlanProvider.mealPlan!.mealDays[mealDayIndex];
              // Update current day meals with latest data
              _currentDayMeals = updatedMealDay;
              _currentDayMeals!.calculateConsumedNutrition();
              _logger.d(
                  'HomeScreen - Updated current day meals: ${_getDayName(_currentDayMeals?.date)}');
            } else {
              _logger
                  .w('HomeScreen - No meal day found for index: $mealDayIndex');
              _currentDayMeals = null;
            }
          } catch (e) {
            // No meal day found for this date
            _logger.w('HomeScreen - Error finding meal day: $e');
            _currentDayMeals = null;
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
                        const SizedBox(height: 100), // Space for bottom navigation
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildDebugInfo(
      AuthProvider authProvider, MealPlanProvider mealPlanProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Debug Info',
            style: AppTextStyles.heading5.copyWith(color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Text('Auth: ${authProvider.isAuthenticated ? 'Yes' : 'No'}'),
          Text('User: ${authProvider.userModel?.name ?? 'null'}'),
          Text('Calorie Targets: ${_calorieTargets?.dailyTarget ?? 'null'}'),
          Text('Meal Plan: ${mealPlanProvider.mealPlan?.title ?? 'null'}'),
          Text('Current Day: ${_getDayName(_currentDayMeals?.date) ?? 'null'}'),
          Text('Loading: $_isLoading, Meal Plan Loading: $_isLoadingMealPlan'),
        ],
      ),
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

            // Burned Calories Indicator
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
                    '0',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
