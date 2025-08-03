import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/ai_meal_service.dart';
import '../../../../shared/services/meal_plan_storage_service.dart';

import 'package:lottie/lottie.dart';
import 'setup_steps/goal_selection_step.dart' show GoalSelectionStep, NutritionGoal, NutritionGoalExt;
import 'setup_steps/meal_frequency_step.dart' show MealFrequencyOption, MealFrequencyStep;
import 'setup_steps/calories_step.dart';
import 'setup_steps/cheat_day_step.dart';
import 'setup_steps/plan_duration_step.dart';
import 'setup_steps/final_review_step.dart';

class AdminMealSetupFlow extends StatefulWidget {
  final UserPreferences targetUserPreferences;
  final VoidCallback? onMealPlanGenerated;

  const AdminMealSetupFlow({
    super.key,
    required this.targetUserPreferences,
    this.onMealPlanGenerated,
  });

  @override
  State<AdminMealSetupFlow> createState() => _AdminMealSetupFlowState();
}

class _AdminMealSetupFlowState extends State<AdminMealSetupFlow> {
  bool _isLoading = false;
  int _setupStep = 0;
  NutritionGoal? _selectedNutritionGoal;
  MealFrequencyOption? _mealFrequency;
  String? _cheatDay;
  bool _weeklyRotation = true;
  bool _remindersEnabled = false;
  final int _selectedDays = 7;
  int _targetCalories = 2000;

  // Progress tracking
  int _completedDays = 0;
  int _totalDays = 0;

  UserPreferences get _userPreferences => widget.targetUserPreferences;

  void _nextStep() {
    if (_setupStep < 6) {
      setState(() {
        _setupStep++;
      });
    }
  }

  void _prevStep() {
    if (_setupStep > 0) {
      setState(() {
        _setupStep--;
      });
    }
  }

  void _generateMealPlan() async {

    final dietPlanPreferences = DietPlanPreferences(
      age: _userPreferences.age,
      gender: _userPreferences.gender,
      weight: _userPreferences.weight,
      height: _userPreferences.height,
      fitnessGoal: _userPreferences.fitnessGoal,
      activityLevel: _userPreferences.activityLevel,
      dietaryRestrictions: _userPreferences.dietaryRestrictions,
      preferredWorkoutStyles: _userPreferences.preferredWorkoutStyles,
      nutritionGoal: _selectedNutritionGoal?.label ?? '',
      preferredCuisines: List<String>.from(_userPreferences.preferredCuisines),
      foodsToAvoid: List<String>.from(_userPreferences.foodsToAvoid),
      favoriteFoods: List<String>.from(_userPreferences.favoriteFoods),
      mealFrequency: _mealFrequency
          ?.toString()
          .split('.')
          .last ?? '',
      cheatDay: _cheatDay,
      weeklyRotation: _weeklyRotation,
      remindersEnabled: _remindersEnabled,
      targetCalories: _targetCalories,
    );

    setState(() {
      _isLoading = true;
      _completedDays = 0;
      _totalDays = _selectedDays;
    });

    try {
      final mealPlan = await AIMealService.generateMealPlan(
        preferences: dietPlanPreferences,
        days: _selectedDays,
        onProgress: (completedDays, totalDays) {
          setState(() {
            _completedDays = completedDays;
            _totalDays = totalDays;
          });
        },
      );

      await MealPlanStorageService.saveMealPlan(mealPlan);
      // Note: We don't save diet preferences here since we don't have the user ID
      // The diet preferences are already saved when the meal plan is generated

      setState(() {
        _isLoading = false;
        _completedDays = 0;
        _totalDays = 0;
      });

      widget.onMealPlanGenerated?.call();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _completedDays = 0;
          _totalDays = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate meal plan: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  String _getLoadingMessage() {
    if (_totalDays == 0) {
      return 'We are cooking up your personalized meal plan…';
    }

    final progress = _completedDays / _totalDays;

    if (progress < 0.25) {
      return 'Analyzing your preferences and dietary needs…';
    } else if (progress < 0.5) {
      return 'Crafting delicious, healthy recipes…';
    } else if (progress < 0.75) {
      return 'Optimizing nutrition and meal timing…';
    } else if (progress < 1.0) {
      return 'Finalizing your personalized meal plan…';
    } else {
      return 'Your meal plan is ready!';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppConstants.spacingL),
            _ProgressDots(current: _setupStep, total: 6),
            const SizedBox(height: AppConstants.spacingL),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spacingL),
                child: _buildStepContent(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: _buildNavBar(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: AppConstants.surfaceColor,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: Lottie.asset(
              'assets/animations/loading.json',
              repeat: true,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingL),
            child: Text(
              _getLoadingMessage(),
              style: AppTextStyles.heading4,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingL),
            child: Text(
              'Hang tight while we craft delicious, healthy recipes just for you!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingL),
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  tween: Tween<double>(
                    begin: 0.0,
                    end: _totalDays > 0 ? _completedDays / _totalDays : 0.0,
                  ),
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      backgroundColor: AppConstants.textTertiary.withOpacity(
                          0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppConstants.primaryColor,
                      ),
                      minHeight: 8,
                    );
                  },
                ),
                const SizedBox(height: AppConstants.spacingS),
                Text(
                  _totalDays > 0
                      ? 'Generated $_completedDays of $_totalDays days (${((_completedDays /
                      _totalDays) * 100).toInt()}%)'
                      : 'Preparing your meal plan...',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppConstants.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {

    switch (_setupStep) {
      case 0:
        return GoalSelectionStep(
          selected: _selectedNutritionGoal,
          onSelect: (goal) => setState(() => _selectedNutritionGoal = goal),
        );
      case 1:
        return MealFrequencyStep(
          selected: _mealFrequency,
          onSelect: (frequency) => setState(() => _mealFrequency = frequency),
        );
      case 2:
        return CaloriesStep(
          targetCalories: _targetCalories,
          onChanged: (calories) => setState(() => _targetCalories = calories),
        );
      case 3:
        return CheatDayStep(
          selectedDay: _cheatDay,
          onSelect: (day) => setState(() => _cheatDay = day),
        );
      case 4:
        return PlanDurationStep(
          weeklyRotation: _weeklyRotation,
          onToggleWeeklyRotation: (value) =>
              setState(() => _weeklyRotation = value),
          remindersEnabled: _remindersEnabled,
          onToggleReminders: (value) =>
              setState(() => _remindersEnabled = value),
        );
      case 5:
        return FinalReviewStep(
          userPreferences: _userPreferences,
          selectedDays: _selectedDays,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavBar() {
    switch (_setupStep) {
      case 0:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: CustomButton(
            text: 'Next',
            onPressed: _selectedNutritionGoal != null ? _nextStep : null,
          ),
        );
      case 1:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: CustomButton(
            text: 'Next',
            onPressed: _mealFrequency != null ? _nextStep : null,
          ),
        );
      case 2:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: CustomButton(
            text: 'Next',
            onPressed: _nextStep,
          ),
        );
      case 3:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _nextStep,
                child: const Text('Next'),
              ),
            ),
          ],
        );
      case 4:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _nextStep,
                child: const Text('Next'),
              ),
            ),
          ],
        );
      case 5:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: CustomButton(
            text: 'Generate Meal Plan',
            onPressed: _generateMealPlan,
            icon: Icons.psychology,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ProgressDots extends StatelessWidget {
  final int current;
  final int total;

  const _ProgressDots({required this.current, required this.total});

  static const List<Color> _stepColors = [
    AppConstants.primaryColor,
    AppConstants.secondaryColor,
    AppConstants.accentColor,
    AppConstants.warningColor,
    AppConstants.successColor,
    AppConstants.primaryColor,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final color = i <= current
            ? _stepColors[i % _stepColors.length]
            : AppConstants.textTertiary.withOpacity(0.2);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == current ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
}
