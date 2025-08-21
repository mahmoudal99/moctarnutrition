import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/meal_plan_provider.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/models/meal_model.dart';
import '../../../../shared/services/calorie_calculation_service.dart';
import '../../../../shared/services/nutrition_calculation_service.dart';
import '../widgets/day_selector.dart';
import '../widgets/calorie_summary_card.dart';
import '../widgets/nutrition_goals_card.dart';
import '../widgets/activity_ring.dart';

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
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final mealPlanProvider =
          Provider.of<MealPlanProvider>(context, listen: false);

      final user = authProvider.userModel;

      if (user != null) {
        _calorieTargets =
            CalorieCalculationService.calculateCalorieTargets(user);

        // Load meal plan if needed
        await _loadMealPlanIfNeeded(authProvider, mealPlanProvider);

        // Load current day's meals
        _loadCurrentDayMeals(mealPlanProvider);
      }
    } catch (e) {
      _logger.e('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        return;
      }

      // Check if the current meal plan belongs to the current user
      final currentMealPlan = mealPlanProvider.mealPlan;
      if (currentMealPlan != null) {
        if (currentMealPlan.userId == authProvider.userModel!.id) {
          return;
        } else {
          mealPlanProvider.clearMealPlan();
        }
      }

      // Load meal plan for current user
      await mealPlanProvider.loadMealPlan(authProvider.userModel!.id);
    } finally {
      setState(() {
        _isLoadingMealPlan = false;
      });
    }
  }

  void _loadCurrentDayMeals(MealPlanProvider mealPlanProvider) {
    final mealPlan = mealPlanProvider.mealPlan;
    if (mealPlan != null) {
      // Find the meal day for the selected date
      final selectedDateOnly =
          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

      MealDay? mealDay;
      try {
        mealDay = mealPlan.mealDays.firstWhere(
          (day) {
            final dayDateOnly =
                DateTime(day.date.year, day.date.month, day.date.day);
            return dayDateOnly.isAtSameMomentAs(selectedDateOnly);
          },
        );
      } catch (e) {
        // No meal day found for this date
        mealDay = null;
      }

      setState(() {
        _currentDayMeals = mealDay;
      });
    }
  }

  void _onDateSelected(DateTime date) {
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
    return Consumer2<AuthProvider, MealPlanProvider>(
      builder: (context, authProvider, mealPlanProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: _isLoading || _isLoadingMealPlan
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadUserData,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            ),

                          const SizedBox(height: 20),

                          // Nutrition Goals Cards
                          if (_calorieTargets != null)
                            NutritionGoalsCard(
                              macros: _calorieTargets!.macros,
                              selectedDate: _selectedDate,
                              currentDayMeals: _currentDayMeals,
                            ),

                          const SizedBox(
                              height: 100), // Space for bottom navigation
                        ],
                      ),
                    ),
                  ),
          ),
          // floatingActionButton: FloatingActionButton(
          //   onPressed: () {
          //     // TODO: Navigate to meal logging screen
          //     _logger.d('Add meal button pressed');
          //   },
          //   backgroundColor: Colors.black,
          //   child: const Icon(
          //     Icons.add,
          //     color: Colors.white,
          //     size: 24,
          //   ),
          // ),
        );
      },
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
