import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:champions_gym_app/shared/models/user_model.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:champions_gym_app/shared/services/ai_meal_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

import '../../../meal_prep/presentation/widgets/setup_steps/goal_selection_step.dart';
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
  static final _logger = Logger();
  int _setupStep = 0;
  FitnessGoal? _selectedFitnessGoal;
  String? _cheatDay;
  bool _weeklyRotation = true;
  bool _remindersEnabled = false;
  final int _selectedDays = 7;
  bool _isLoading = false;
  int _targetCalories = 2000;
  int _completedDays = 0;
  int _totalDays = 0;

  @override
  void initState() {
    super.initState();
    // Pre-populate with client's onboarding choices
    _initializeFromClientPreferences();
  }

  void _initializeFromClientPreferences() {
    _logger.i('Initializing from client preferences');
    _logger.i('Client fitness goal: ${widget.user.preferences.fitnessGoal}');
    _logger.i('Client target calories: ${widget.user.preferences.targetCalories}');
    
    // Pre-select fitness goal from client's onboarding choice
    if (widget.user.preferences.fitnessGoal != null) {
      _selectedFitnessGoal = widget.user.preferences.fitnessGoal!;
      _logger.i('Pre-selected fitness goal: $_selectedFitnessGoal');
    } else {
      _logger.w('No fitness goal found in client preferences');
    }

    // Pre-populate calories from client's calculated target
    if (widget.user.preferences.targetCalories > 0) {
      _targetCalories = widget.user.preferences.targetCalories;
      _logger.i('Pre-selected target calories: $_targetCalories');
    } else {
      _logger.w('No target calories found in client preferences');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _getFitnessGoalLabel(FitnessGoal? goal) {
    if (goal == null) return '';
    
    switch (goal) {
      case FitnessGoal.weightLoss:
        return 'Weight Loss';
      case FitnessGoal.muscleGain:
        return 'Muscle Gain';
      case FitnessGoal.maintenance:
        return 'Maintenance';
      case FitnessGoal.endurance:
        return 'Endurance';
      case FitnessGoal.strength:
        return 'Strength';
    }
  }

  String _getMealFrequencyFromUserPreferences() {
    // Get meal timing preferences from user onboarding
    final mealTimingJson = widget.user.preferences.mealTimingPreferences;
    if (mealTimingJson == null) {
      return '3 meals'; // Default fallback
    }

    final mealFrequency = mealTimingJson['mealFrequency'] as String?;
    if (mealFrequency == null) {
      return '3 meals'; // Default fallback
    }

    // Convert onboarding meal frequency to DietPlanPreferences format
    switch (mealFrequency) {
      case 'threeMeals':
        return '3 meals';
      case 'threeMealsOneSnack':
        return '3 meals + 1 snack';
      case 'fourMeals':
        return '4 meals';
      case 'fourMealsOneSnack':
        return '4 meals + 1 snack';
      case 'fiveMeals':
        return '5 meals';
      case 'fiveMealsOneSnack':
        return '5 meals + 1 snack';
      case 'intermittentFasting':
        // For intermittent fasting, we need to check the fasting type
        final fastingType = mealTimingJson['fastingType'] as String?;
        switch (fastingType) {
          case 'sixteenEight':
            return '16:8 fasting';
          case 'eighteenSix':
            return '18:6 fasting';
          case 'twentyFour':
            return '20:4 fasting';
          case 'alternateDay':
            return 'Alternate day fasting';
          case 'fiveTwo':
            return '5:2 fasting';
          case 'custom':
            return 'Custom fasting';
          default:
            return '16:8 fasting'; // Default fasting protocol
        }
      case 'custom':
        return 'Custom';
      default:
        return '3 meals'; // Default fallback
    }
  }

  void _onNextStep() {
    if (!_isCurrentStepValid()) {
      HapticFeedback.lightImpact();
      return;
    }
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

  // Add validation method to check if current step is complete
  bool _isCurrentStepValid() {
    bool isValid;
    switch (_setupStep) {
      case 0:
        isValid = _selectedFitnessGoal != null;
        break;
      case 1:
        isValid = _targetCalories >= 1200 && _targetCalories <= 4000;
        break;
      case 2:
        // Cheat day should have a selection (either a day or null for "No cheat day")
        // The step allows selecting null, so we need to check if user has made any selection
        // Since the step starts with null and user can select null, we'll consider it always valid
        isValid = true;
        break;
      case 3:
        // Plan duration step has default values (_weeklyRotation = true, _remindersEnabled = false)
        // and both options are always valid, so this step is always complete
        isValid = true;
        break;
      case 4:
        // Final review step - check all required fields
        isValid = _selectedFitnessGoal != null && 
                  _targetCalories >= 1200 && 
                  _targetCalories <= 4000;
        break;
      default:
        isValid = false;
        break;
    }
    
    // Debug logging
    _logger.i('Step $_setupStep validation: $isValid');
    if (_setupStep == 0) _logger.d('Fitness goal: $_selectedFitnessGoal');
    if (_setupStep == 1) _logger.d('Target calories: $_targetCalories');
    if (_setupStep == 4) {
      _logger.i('Final validation - Fitness goal: $_selectedFitnessGoal, Calories: $_targetCalories');
    }
    
    return isValid;
  }

  // Get validation message for current step
  String _getValidationMessage() {
    switch (_setupStep) {
      case 0:
        return 'Please select a nutrition goal to continue';
      case 1:
        if (_targetCalories < 1200) {
          return 'Calorie target must be at least 1,200 calories';
        } else if (_targetCalories > 4000) {
          return 'Calorie target must be no more than 4,000 calories';
        }
        return 'Please set a valid calorie target';
      case 2:
        // Cheat day is optional, so this should never be reached
        return 'Please make a selection for cheat day';
      case 3:
        // Plan duration step has default values, so this should never be reached
        return 'Please configure plan duration and reminders';
      case 4:
        if (_selectedFitnessGoal == null) {
          return 'Please select a nutrition goal';
        } else if (_targetCalories < 1200 || _targetCalories > 4000) {
          return 'Please set a valid calorie target (1,200-4,000 calories)';
        }
        return 'Please complete all required fields';
      default:
        return 'Please complete this step to continue';
    }
  }

  Future<void> _onSavePlan() async {
    if (!_isCurrentStepValid()) {
      HapticFeedback.lightImpact();
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = widget.user.preferences;
      final userId = widget.user.id;
      _logger.i('Generating meal plan for userId: $userId');
      final dietPlanPreferences = DietPlanPreferences(
        age: prefs.age,
        gender: prefs.gender,
        weight: prefs.weight,
        height: prefs.height,
        fitnessGoal: prefs.fitnessGoal,
        activityLevel: prefs.activityLevel,
        dietaryRestrictions: prefs.dietaryRestrictions,
        preferredWorkoutStyles: prefs.preferredWorkoutStyles,
        nutritionGoal: _getFitnessGoalLabel(_selectedFitnessGoal ?? prefs.fitnessGoal),
        preferredCuisines: List<String>.from(prefs.preferredCuisines),
        foodsToAvoid: List<String>.from(prefs.foodsToAvoid),
        favoriteFoods: List<String>.from(prefs.favoriteFoods),
        mealFrequency: _getMealFrequencyFromUserPreferences(),
        cheatDay: _cheatDay,
        weeklyRotation: _weeklyRotation,
        remindersEnabled: _remindersEnabled,
        targetCalories: _targetCalories,
        targetProtein: prefs.proteinTargets?['dailyTarget'],
        proteinTargets: prefs.proteinTargets,
        calorieTargets: prefs.calorieTargets,
        allergies: prefs.allergies,
        mealTimingPreferences: prefs.mealTimingPreferences,
        batchCookingPreferences: prefs.batchCookingPreferences,
      );
      final mealPlan = await AIMealService.generateMealPlan(
        preferences: dietPlanPreferences,
        days: _selectedDays,
        onProgress: (completedMeals, totalMeals) {
          _logger.d('Progress update: $completedMeals/$totalMeals meals');
          setState(() {
            _completedDays = completedMeals;
            _totalDays = totalMeals;
          });
        },
      );
      _logger.i('Meal plan generated: ${mealPlan.toJson()}');
      
      // Debug: Check ingredients for each meal
      for (int i = 0; i < mealPlan.mealDays.length; i++) {
        final day = mealPlan.mealDays[i];
        _logger.d('Day ${i + 1}:');
        for (int j = 0; j < day.meals.length; j++) {
          final meal = day.meals[j];
          _logger.d('  Meal ${j + 1} (${meal.type.name}): ${meal.name}');
          _logger.d('    Ingredients:');
          for (int k = 0; k < meal.ingredients.length; k++) {
            final ingredient = meal.ingredients[k];
            _logger.d('      ${k + 1}. ${ingredient.name} - ${ingredient.amount} ${ingredient.unit}');
          }
        }
      }
      
      // Check if this was a fallback meal plan
      final isFallbackPlan = mealPlan.title.contains('Fallback') || mealPlan.description.contains('fallback');
      
      // Ensure the meal plan has the correct userId
      final mealPlanWithUser = mealPlan.copyWith(userId: userId);
      _logger.i('Saving meal plan to Firestore with userId: $userId');
      final mealPlanRef = await FirebaseFirestore.instance.collection('meal_plans').add(mealPlanWithUser.toJson());
      _logger.i('Meal plan saved with ID: ${mealPlanRef.id}');
      // Update user's mealPlanId
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'mealPlanId': mealPlanRef.id,
      });
      _logger.i('Updated user document with mealPlanId: ${mealPlanRef.id}');
      
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
      _logger.e('Error generating or saving meal plan: $e', error: e, stackTrace: stack);
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
                      ? 'Generated $_completedDays of $_totalDays meals (${((_completedDays / _totalDays) * 100).toInt()}%)'
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
                    // Current step shows warning color if invalid, or its own color if valid
                    color = _isCurrentStepValid() ? stepColors[i] : (AppConstants.warningColor ?? Colors.orange);
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
            child: Column(
              children: [
                Expanded(child: _buildCurrentStep(prefs)),
                // Show validation message if current step is not valid
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: !_isCurrentStepValid() 
                    ? Container(
                        key: ValueKey('validation_$_setupStep'),
                        margin: const EdgeInsets.only(top: AppConstants.spacingM),
                        padding: const EdgeInsets.all(AppConstants.spacingM),
                        decoration: BoxDecoration(
                          color: AppConstants.warningColor?.withOpacity(0.1) ?? Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppConstants.radiusS),
                          border: Border.all(
                            color: AppConstants.warningColor?.withOpacity(0.3) ?? Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppConstants.warningColor ?? Colors.orange,
                            ),
                            const SizedBox(width: AppConstants.spacingS),
                            Expanded(
                              child: Text(
                                _getValidationMessage(),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppConstants.warningColor ?? Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
                ),
              ],
            ),
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
          selected: _selectedFitnessGoal,
          onSelect: (goal) => setState(() => _selectedFitnessGoal = goal),
          userName: widget.user.name,
          clientFitnessGoal: widget.user.preferences.fitnessGoal,
        );
      case 1:
        return CaloriesStep(
          targetCalories: _targetCalories,
          onChanged: (calories) => setState(() => _targetCalories = calories),
          userName: widget.user.name,
          clientTargetCalories: widget.user.preferences.targetCalories > 0 ? widget.user.preferences.targetCalories : null,
        );
      case 2:
        return CheatDayStep(
          selectedDay: _cheatDay,
          onSelect: (day) => setState(() => _cheatDay = day),
          userName: widget.user.name,
        );
      case 3:
        return PlanDurationStep(
          weeklyRotation: _weeklyRotation,
          onToggleWeeklyRotation: (value) => setState(() => _weeklyRotation = value),
          remindersEnabled: _remindersEnabled,
          onToggleReminders: (value) => setState(() => _remindersEnabled = value),
          userName: widget.user.name,
        );
      case 4:
        return FinalReviewStep(
          userPreferences: prefs,
          selectedDays: _selectedDays,
          userName: widget.user.name,
          cheatDay: _cheatDay,
          targetCalories: _targetCalories,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigationButtons() {
    final isCurrentStepValid = _isCurrentStepValid();
    
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
              onPressed: isCurrentStepValid 
                  ? (_setupStep == 4 ? _onSavePlan : _onNextStep)
                  : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentStepValid 
                  ? AppConstants.primaryColor 
                  : AppConstants.textTertiary.withOpacity(0.3),
              foregroundColor: isCurrentStepValid 
                  ? AppConstants.surfaceColor 
                  : AppConstants.textSecondary,
            ),
                          child: Text(_setupStep == 4 ? 'Generate Plan' : 'Next'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = widget.user.preferences;
    _logger.d('Building admin meal plan setup screen');
    _logger.d('User preferences fitness goal: ${prefs.fitnessGoal}');
    _logger.d('Selected fitness goal: $_selectedFitnessGoal');
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