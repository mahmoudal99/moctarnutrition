import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:champions_gym_app/shared/models/user_model.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:champions_gym_app/shared/services/ai_meal_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

import '../../../meal_prep/presentation/widgets/setup_steps/goal_selection_step.dart';
import '../../../meal_prep/presentation/widgets/setup_steps/meal_frequency_step.dart';
import '../../../meal_prep/presentation/widgets/setup_steps/calories_step.dart';
import '../../../meal_prep/presentation/widgets/setup_steps/cheat_day_step.dart';
import '../../../meal_prep/presentation/widgets/setup_steps/plan_duration_step.dart';
import '../../../meal_prep/presentation/widgets/setup_steps/final_review_step.dart';

class AdminMealPlanSetupScreen extends StatefulWidget {
  final UserModel user;
  const AdminMealPlanSetupScreen({super.key, required this.user});

  @override
  State<AdminMealPlanSetupScreen> createState() => _AdminMealPlanSetupScreenState();
}

class _AdminMealPlanSetupScreenState extends State<AdminMealPlanSetupScreen> {
  int _setupStep = 0;
  NutritionGoal? _selectedNutritionGoal;
  MealFrequencyOption? _mealFrequency;
  String? _cheatDay;
  bool _weeklyRotation = true;
  bool _remindersEnabled = false;
  final int _selectedDays = 7;
  bool _isLoading = false;
  int _targetCalories = 2000;
  int _completedDays = 0;
  int _totalDays = 0;

  @override
  void dispose() {
    super.dispose();
  }

  void _onNextStep() {
    HapticFeedback.mediumImpact();
    setState(() {
      _setupStep++;
    });
  }

  void _onBackStep() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_setupStep > 0) _setupStep--;
    });
  }

  Future<void> _onSavePlan() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = widget.user.preferences;
      final userId = widget.user.id;
      print('[AdminMealPlanSetupScreen] Generating meal plan for userId: $userId');
      final dietPlanPreferences = DietPlanPreferences(
        age: prefs.age,
        gender: prefs.gender,
        weight: prefs.weight,
        height: prefs.height,
        fitnessGoal: prefs.fitnessGoal,
        activityLevel: prefs.activityLevel,
        dietaryRestrictions: prefs.dietaryRestrictions,
        preferredWorkoutStyles: prefs.preferredWorkoutStyles,
        nutritionGoal: _selectedNutritionGoal?.label ?? '',
        preferredCuisines: List<String>.from(prefs.preferredCuisines),
        foodsToAvoid: List<String>.from(prefs.foodsToAvoid),
        favoriteFoods: List<String>.from(prefs.favoriteFoods),
        mealFrequency: _mealFrequency?.toString().split('.').last ?? '',
        cheatDay: _cheatDay,
        weeklyRotation: _weeklyRotation,
        remindersEnabled: _remindersEnabled,
        targetCalories: _targetCalories,
      );
      final mealPlan = await AIMealService.generateMealPlan(
        preferences: dietPlanPreferences,
        days: _selectedDays,
        onProgress: (completedDays, totalDays) {
          print('[AdminMealPlanSetupScreen] Progress update: $completedDays/$totalDays');
          setState(() {
            _completedDays = completedDays;
            _totalDays = totalDays;
          });
        },
      );
      print('[AdminMealPlanSetupScreen] Meal plan generated: ${mealPlan.toJson()}');
      
      // Debug: Check ingredients for each meal
      for (int i = 0; i < mealPlan.mealDays.length; i++) {
        final day = mealPlan.mealDays[i];
        print('[AdminMealPlanSetupScreen] Day ${i + 1}:');
        for (int j = 0; j < day.meals.length; j++) {
          final meal = day.meals[j];
          print('[AdminMealPlanSetupScreen]   Meal ${j + 1} (${meal.type.name}): ${meal.name}');
          print('[AdminMealPlanSetupScreen]     Ingredients:');
          for (int k = 0; k < meal.ingredients.length; k++) {
            final ingredient = meal.ingredients[k];
            print('[AdminMealPlanSetupScreen]       ${k + 1}. ${ingredient.name} - ${ingredient.amount} ${ingredient.unit}');
          }
        }
      }
      
      // Check if this was a fallback meal plan
      final isFallbackPlan = mealPlan.title.contains('Fallback') || mealPlan.description.contains('fallback');
      
      // Ensure the meal plan has the correct userId
      final mealPlanWithUser = mealPlan.copyWith(userId: userId);
      print('[AdminMealPlanSetupScreen] Saving meal plan to Firestore with userId: $userId');
      final mealPlanRef = await FirebaseFirestore.instance.collection('meal_plans').add(mealPlanWithUser.toJson());
      print('[AdminMealPlanSetupScreen] Meal plan saved with ID: ${mealPlanRef.id}');
      // Update user's mealPlanId
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'mealPlanId': mealPlanRef.id,
      });
      print('[AdminMealPlanSetupScreen] Updated user document with mealPlanId: ${mealPlanRef.id}');
      
      if (mounted) {
        // Show appropriate message based on whether it was a fallback plan
        if (isFallbackPlan) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Meal plan generated using backup recipes due to high demand. All required meals are included!'),
              backgroundColor: AppConstants.warningColor ?? Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Meal plan generated successfully!'),
              backgroundColor: AppConstants.successColor ?? Colors.green,
            ),
          );
        }
        
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e, stack) {
      print('[AdminMealPlanSetupScreen] Error generating or saving meal plan: $e');
      print(stack);
      setState(() {
        _isLoading = false;
        _completedDays = 0;
        _totalDays = 0;
      });
      if (mounted) {
        // Show more user-friendly error message
        String errorMessage = 'Failed to generate meal plan';
        if (e.toString().contains('QuotaExceededException') || e.toString().contains('quota exceeded')) {
          errorMessage = 'Free token limit reached. Please try again tomorrow or contact support to upgrade your plan.';
        } else if (e.toString().contains('AuthenticationException') || e.toString().contains('Invalid API key')) {
          errorMessage = 'API key authentication failed. Please check your OpenAI configuration.';
        } else if (e.toString().contains('RegionNotSupportedException') || e.toString().contains('not supported')) {
          errorMessage = 'OpenAI is not available in your region. Please contact support.';
        } else if (e.toString().contains('RateLimitException') || e.toString().contains('rate limit')) {
          errorMessage = 'Service is temporarily busy. Please try again in a few minutes.';
        } else if (e.toString().contains('ServerOverloadedException') || e.toString().contains('overloaded')) {
          errorMessage = 'OpenAI servers are overloaded. Please try again later.';
        } else if (e.toString().contains('SlowDownException') || e.toString().contains('slow down')) {
          errorMessage = 'Too many requests. Please wait a moment and try again.';
        } else if (e.toString().contains('network') || e.toString().contains('connection')) {
          errorMessage = 'Network connection issue. Please check your internet and try again.';
        } else {
          errorMessage = 'Unable to generate meal plan at this time. Please try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppConstants.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
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
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
            child: Text(
              _getLoadingMessage(),
              style: AppTextStyles.heading4,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
            child: Text(
              'Hang tight while we craft delicious, healthy recipes just for you!',
              style: AppTextStyles.bodyMedium.copyWith(color: AppConstants.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
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
                      backgroundColor: AppConstants.textTertiary.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                      minHeight: 8,
                    );
                  },
                ),
                const SizedBox(height: AppConstants.spacingS),
                Text(
                  _totalDays > 0
                      ? 'Generated $_completedDays of $_totalDays days (${((_completedDays / _totalDays) * 100).toInt()}%)'
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

  String _getLoadingMessage() {
    if (_totalDays == 0) {
      return 'We are cooking up your personalized meal plan…';
    }
    final progress = _totalDays > 0 ? _completedDays / _totalDays : 0.0;
    if (progress < 0.25) {
      return 'Analyzing preferences and dietary needs…';
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

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Goal';
      case 1:
        return 'Frequency';
      case 2:
        return 'Calories';
      case 3:
        return 'Cheat Day';
      case 4:
        return 'Duration';
      case 5:
        return 'Review';
      default:
        return '';
    }
  }

  Widget _buildStepContent(UserPreferences prefs) {
    return Column(
      children: [
        // Progress indicator with colored dots
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  // Use the same colors as user onboarding for first 4 steps, then distinct colors for last 2
                  final List<Color> stepColors = [
                    AppConstants.primaryColor,    // Step 0: Goal Selection (Green - main goal)
                    AppConstants.accentColor,     // Step 1: Meal Frequency (Dark Green - meal planning)
                    AppConstants.secondaryColor,  // Step 2: Calories (Light Green - energy/nutrition)
                    AppConstants.warningColor,    // Step 3: Cheat Day (Orange - indulgence)
                    Colors.purple,                // Step 4: Plan Duration (Purple - commitment)
                    Colors.blue,                  // Step 5: Final Review (Blue - completion)
                  ];
                  
                  // Each dot shows its own color when completed, current step color when current, or gray when not reached
                  Color color;
                  if (i < _setupStep) {
                    // Completed steps show their own color
                    color = stepColors[i];
                  } else if (i == _setupStep) {
                    // Current step shows its own color
                    color = stepColors[i];
                  } else {
                    // Future steps show gray
                    color = AppConstants.textTertiary.withOpacity(0.2);
                  }
                  
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _setupStep ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              // Add step indicator text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  '${_setupStep + 1} of 6',
                  key: ValueKey(_setupStep),
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    color: AppConstants.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Step content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildCurrentStep(prefs),
          ),
        ),
        
        // Navigation buttons
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildNavigationButtons(),
        ),
        SizedBox(
          height: 24,
        )
      ],
    );
  }

  Widget _buildCurrentStep(UserPreferences prefs) {
    switch (_setupStep) {
      case 0:
        return GoalSelectionStep(
          selected: _selectedNutritionGoal,
          onSelect: (goal) => setState(() => _selectedNutritionGoal = goal),
          userName: widget.user.name,
        );
      case 1:
        return MealFrequencyStep(
          selected: _mealFrequency,
          onSelect: (frequency) => setState(() => _mealFrequency = frequency),
          userName: widget.user.name,
        );
      case 2:
        return CaloriesStep(
          targetCalories: _targetCalories,
          onChanged: (calories) => setState(() => _targetCalories = calories),
          userName: widget.user.name,
        );
      case 3:
        return CheatDayStep(
          selectedDay: _cheatDay,
          onSelect: (day) => setState(() => _cheatDay = day),
          userName: widget.user.name,
        );
      case 4:
        return PlanDurationStep(
          weeklyRotation: _weeklyRotation,
          onToggleWeeklyRotation: (value) => setState(() => _weeklyRotation = value),
          remindersEnabled: _remindersEnabled,
          onToggleReminders: (value) => setState(() => _remindersEnabled = value),
          userName: widget.user.name,
        );
      case 5:
        return FinalReviewStep(
          userPreferences: prefs,
          selectedDays: _selectedDays,
          userName: widget.user.name,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_setupStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _onBackStep,
              child: const Text('Back'),
            ),
          ),
        if (_setupStep > 0) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _setupStep == 5 ? _onSavePlan : _onNextStep,
            child: Text(_setupStep == 5 ? 'Generate Plan' : 'Next'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = widget.user.preferences;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Meal Plan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _buildStepContent(prefs),
    );
  }
} 