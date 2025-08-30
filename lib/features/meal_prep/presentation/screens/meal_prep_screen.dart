import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../../shared/models/meal_model.dart';
import '../../../../shared/services/meal_plan_storage_service.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/meal_plan_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../widgets/meal_plan_view.dart';
import '../widgets/waiting_for_meal_plan.dart';
import '../widgets/meal_plan_loading_state.dart';
import '../../../food_search/presentation/screens/food_search_screen.dart';

class MealPrepScreen extends StatefulWidget {
  const MealPrepScreen({super.key});

  @override
  State<MealPrepScreen> createState() => _MealPrepScreenState();
}

class _MealPrepScreenState extends State<MealPrepScreen> {
  static final _logger = Logger();
  String? _cheatDay;
  bool _isLoadingMealPlan = false;
  bool _hasAttemptedLoad = false; // Track if we've attempted to load

  @override
  void initState() {
    super.initState();
    _logger.d('MealPrepScreen - initState called');
  }

  /// Load meal plan if needed
  Future<void> _loadMealPlanIfNeeded() async {
    // Prevent multiple simultaneous calls
    if (_isLoadingMealPlan) {
      _logger.d(
          'MealPrepScreen - Already loading meal plan, skipping duplicate call');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final mealPlanProvider =
        Provider.of<MealPlanProvider>(context, listen: false);

    _logger.d('MealPrepScreen - _loadMealPlanIfNeeded called');
    _logger.d(
        'MealPrepScreen - AuthProvider state: isLoading=${authProvider.isLoading}, isAuthenticated=${authProvider.isAuthenticated}, userModel=${authProvider.userModel?.name ?? 'null'}');
    _logger.d(
        'MealPrepScreen - MealPlanProvider state: isLoading=${mealPlanProvider.isLoading}, mealPlan=${mealPlanProvider.mealPlan?.title ?? 'null'}');

    // Set loading flag
    setState(() {
      _isLoadingMealPlan = true;
      _hasAttemptedLoad = true;
    });

    try {
      // Check if AuthProvider is still loading user data
      if (authProvider.isLoading) {
        _logger.d('AuthProvider is still loading, will retry in 500ms');
        // Retry after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            _isLoadingMealPlan = false;
          });
          return _loadMealPlanIfNeeded();
        }
        return;
      }

      // Check if user is authenticated
      if (!authProvider.isAuthenticated || authProvider.userModel == null) {
        _logger.w(
            'Cannot load meal plan: user not authenticated or userModel is null');
        return;
      }

      // Check if the current meal plan belongs to the current user
      final currentMealPlan = mealPlanProvider.mealPlan;
      if (currentMealPlan != null) {
        if (currentMealPlan.userId == authProvider.userModel!.id) {
          _logger.d(
              'Meal plan already loaded for current user, skipping API call');
          // Load cheat day from diet preferences
          await _loadCheatDay(authProvider.userModel!.id);
          return;
        } else {
          _logger
              .d('Meal plan belongs to different user, clearing and reloading');
          mealPlanProvider.clearMealPlan();
        }
      }

      // Load meal plan for current user
      _logger.d('Loading meal plan for user ${authProvider.userModel!.id}');
      await mealPlanProvider.loadMealPlan(authProvider.userModel!.id);

      // Load cheat day from diet preferences
      await _loadCheatDay(authProvider.userModel!.id);
    } finally {
      // Always reset loading flag
      if (mounted) {
        setState(() {
          _isLoadingMealPlan = false;
        });
      }
    }
  }

  /// Refresh meal plan (force refresh from server)
  Future<void> _refreshMealPlan() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final mealPlanProvider =
        Provider.of<MealPlanProvider>(context, listen: false);

    if (authProvider.isAuthenticated && authProvider.userModel != null) {
      _logger.d(
          'Force refreshing meal plan for user ${authProvider.userModel!.id}');
      await mealPlanProvider.refreshMealPlan(authProvider.userModel!.id);

      // Load cheat day from diet preferences
      await _loadCheatDay(authProvider.userModel!.id);
    }
  }

  /// Load cheat day from diet preferences
  Future<void> _loadCheatDay(String userId) async {
    try {
      final dietPreferences =
          await MealPlanStorageService.loadDietPreferences(userId);
      if (dietPreferences != null) {
        setState(() {
          _cheatDay = dietPreferences.cheatDay;
        });
        _logger.i('Loaded cheat day: $_cheatDay');
      }
    } catch (e) {
      _logger.e('Error loading cheat day: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, MealPlanProvider>(
      builder: (context, authProvider, mealPlanProvider, child) {
        // Handle AuthProvider loading state
        if (authProvider.isLoading) {
          return const MealPlanLoadingState();
        }

        // Check if user is authenticated
        if (!authProvider.isAuthenticated || authProvider.userModel == null) {
          return const WaitingForMealPlan();
        }

        // Check if user changed and meal plan needs to be reloaded
        if (mealPlanProvider.mealPlan != null &&
            mealPlanProvider.mealPlan!.userId != authProvider.userModel!.id) {
          _logger.d('User changed, reloading meal plan');
          // Use Future.microtask to avoid build-time side effects
          Future.microtask(() => _loadMealPlanIfNeeded());
        }

        // Show loading state if we're currently loading
        if (mealPlanProvider.isLoading || _isLoadingMealPlan) {
          return const MealPlanLoadingState();
        }

        // Show error state if there's an error
        if (mealPlanProvider.error != null) {
          return _buildErrorState(mealPlanProvider.error!);
        }

        // If we have a meal plan, show it
        if (mealPlanProvider.mealPlan != null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Meal Plan'),
              actions: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FoodSearchScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.search),
                  tooltip: 'Search & Add Foods',
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: _refreshMealPlan,
              child: MealPlanView(
                mealPlan: mealPlanProvider.mealPlan!,
                user: authProvider.userModel,
                cheatDay: _cheatDay,
                selectedDate: DateTime
                    .now(), // Pass current date for consumption tracking
              ),
            ),
          );
        }

        // If we haven't attempted to load yet, trigger the load
        if (!_hasAttemptedLoad) {
          _logger.d('First time loading meal plan, triggering load');
          Future.microtask(() => _loadMealPlanIfNeeded());
          return const MealPlanLoadingState();
        }

        // If we've attempted to load but have no meal plan, show waiting state
        return const WaitingForMealPlan();
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plan'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppConstants.errorColor,
              ),
              const SizedBox(height: AppConstants.spacingM),
              Text(
                'Error Loading Meal Plan',
                style: AppTextStyles.heading4.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingS),
              Text(
                error,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppConstants.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingL),
              ElevatedButton(
                onPressed: _retryLoading,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _retryLoading() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userModel != null) {
      _loadMealPlanIfNeeded();
    }
  }
}
