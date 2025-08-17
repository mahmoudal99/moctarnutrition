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

class MealPrepScreen extends StatefulWidget {
  const MealPrepScreen({super.key});

  @override
  State<MealPrepScreen> createState() => _MealPrepScreenState();
}

class _MealPrepScreenState extends State<MealPrepScreen> {
  static final _logger = Logger();
  String? _cheatDay;

  @override
  void initState() {
    super.initState();
    _loadMealPlanIfNeeded();
  }

  /// Load meal plan if needed
  Future<void> _loadMealPlanIfNeeded() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final mealPlanProvider = Provider.of<MealPlanProvider>(context, listen: false);
    
    // Check if user is authenticated
    if (!authProvider.isAuthenticated || authProvider.userModel == null) {
      _logger.w('Cannot load meal plan: user not authenticated or userModel is null');
      return;
    }

    // Check if the current meal plan belongs to the current user
    final currentMealPlan = mealPlanProvider.mealPlan;
    if (currentMealPlan != null) {
      if (currentMealPlan.userId == authProvider.userModel!.id) {
        _logger.d('Meal plan already loaded for current user, skipping API call');
        // Load cheat day from diet preferences
        await _loadCheatDay(authProvider.userModel!.id);
        return;
      } else {
        _logger.d('Meal plan belongs to different user, clearing and reloading');
        mealPlanProvider.clearMealPlan();
      }
    }

    // Load meal plan for current user
    _logger.d('Loading meal plan for user ${authProvider.userModel!.id}');
    await mealPlanProvider.loadMealPlan(authProvider.userModel!.id);
    
    // Load cheat day from diet preferences
    await _loadCheatDay(authProvider.userModel!.id);
  }

  /// Refresh meal plan (force refresh from server)
  Future<void> _refreshMealPlan() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final mealPlanProvider = Provider.of<MealPlanProvider>(context, listen: false);
    
    if (authProvider.isAuthenticated && authProvider.userModel != null) {
      _logger.d('Force refreshing meal plan for user ${authProvider.userModel!.id}');
      await mealPlanProvider.refreshMealPlan(authProvider.userModel!.id);
      
      // Load cheat day from diet preferences
      await _loadCheatDay(authProvider.userModel!.id);
    }
  }

  /// Load cheat day from diet preferences
  Future<void> _loadCheatDay(String userId) async {
    try {
      final dietPreferences = await MealPlanStorageService.loadDietPreferences(userId);
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
        // Check if user changed and meal plan needs to be reloaded
        if (authProvider.isAuthenticated &&
            authProvider.userModel != null &&
            mealPlanProvider.mealPlan != null &&
            mealPlanProvider.mealPlan!.userId != authProvider.userModel!.id) {
          _logger.d('User changed, reloading meal plan');
          // Use Future.microtask to avoid build-time side effects
          Future.microtask(() => _loadMealPlanIfNeeded());
        }

        if (mealPlanProvider.isLoading) {
          return const MealPlanLoadingState();
        }

        if (mealPlanProvider.error != null) {
          return _buildErrorState(mealPlanProvider.error!);
        }

        if (mealPlanProvider.mealPlan == null) {
          return const WaitingForMealPlan();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Meal Plan'),
          ),
          body: RefreshIndicator(
            onRefresh: _refreshMealPlan,
            child: MealPlanView(
              mealPlan: mealPlanProvider.mealPlan!,
              user: authProvider.userModel,
              cheatDay: _cheatDay,
            ),
          ),
        );
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
                onPressed: () {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  if (authProvider.userModel != null) {
                    _loadMealPlanIfNeeded();
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
