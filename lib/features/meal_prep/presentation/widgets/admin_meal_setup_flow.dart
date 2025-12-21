import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/backend_meal_service.dart';
import '../../../../shared/services/meal_plan_storage_service.dart';
import '../../../../shared/services/email_service.dart';

import 'package:lottie/lottie.dart';
import 'setup_steps/goal_selection_step.dart' show GoalSelectionStep;
import 'setup_steps/calories_step.dart';
import 'setup_steps/plan_duration_step.dart';
import 'setup_steps/final_review_step.dart';

class AdminMealSetupFlow extends StatefulWidget {
  final UserPreferences targetUserPreferences;
  final String? userName;
  final String? userEmail;
  final VoidCallback? onMealPlanGenerated;

  const AdminMealSetupFlow({
    super.key,
    required this.targetUserPreferences,
    this.userName,
    this.userEmail,
    this.onMealPlanGenerated,
  });

  @override
  State<AdminMealSetupFlow> createState() => _AdminMealSetupFlowState();
}

class _AdminMealSetupFlowState extends State<AdminMealSetupFlow> {
  final _logger = Logger();
  bool _isLoading = false;
  int _setupStep = 0;
  FitnessGoal? _selectedFitnessGoal;
  bool _weeklyRotation = true;
  bool _remindersEnabled = false;
  final int _selectedDays = 7;
  int _targetCalories = 2000;

  @override
  void initState() {
    super.initState();
    // Pre-populate with client's onboarding choices
    _initializeFromClientPreferences();
  }

  void _initializeFromClientPreferences() {
    _logger.i('Initializing from client preferences');
    _logger.i('Client fitness goal: ${_userPreferences.fitnessGoal}');
    _logger.i('Client target calories: ${_userPreferences.targetCalories}');

    // Pre-select fitness goal from client's onboarding choice
    _selectedFitnessGoal = _userPreferences.fitnessGoal;
    _logger.i('Pre-selected fitness goal: $_selectedFitnessGoal');

    // Pre-populate calories from client's calculated target
    if (_userPreferences.targetCalories > 0) {
      _targetCalories = _userPreferences.targetCalories;
      _logger.i('Pre-selected target calories: $_targetCalories');
    } else {
      _logger.w('No target calories found in client preferences');
    }
  }

  // Progress tracking
  int _completedDays = 0;
  int _totalDays = 0;

  UserPreferences get _userPreferences => widget.targetUserPreferences;

  String _getFitnessGoalLabel(FitnessGoal? goal) {
    if (goal == null) return '';

    switch (goal) {
      case FitnessGoal.weightLoss:
        return 'Weight Loss';
      case FitnessGoal.weightGain:
        return 'Gain Weight';
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
    final mealTimingJson = _userPreferences.mealTimingPreferences;
    if (mealTimingJson == null) {
      return 'threeMeals'; // Default fallback
    }

    final mealFrequency = mealTimingJson['mealFrequency'] as String?;
    if (mealFrequency == null) {
      return 'threeMeals'; // Default fallback
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

  void _nextStep() {
    if (_setupStep < 4) {
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
    if (_isLoading) return;

    final dietPlanPreferences = DietPlanPreferences(
      age: _userPreferences.age,
      gender: _userPreferences.gender,
      weight: _userPreferences.weight,
      height: _userPreferences.height,
      fitnessGoal: _userPreferences.fitnessGoal,
      activityLevel: _userPreferences.activityLevel,
      dietaryRestrictions: _userPreferences.dietaryRestrictions,
      preferredWorkoutStyles: _userPreferences.preferredWorkoutStyles,
      nutritionGoal: _getFitnessGoalLabel(
          _selectedFitnessGoal ?? _userPreferences.fitnessGoal),
      preferredCuisines: List<String>.from(_userPreferences.preferredCuisines),
      foodsToAvoid: List<String>.from(_userPreferences.foodsToAvoid),
      favoriteFoods: List<String>.from(_userPreferences.favoriteFoods),
      mealFrequency: _getMealFrequencyFromUserPreferences(),
      weeklyRotation: _weeklyRotation,
      remindersEnabled: _remindersEnabled,
      targetCalories: _targetCalories,
      targetProtein: _userPreferences.proteinTargets?['dailyTarget'],
      proteinTargets: _userPreferences.proteinTargets,
      calorieTargets: _userPreferences.calorieTargets,
      allergies: _userPreferences.allergies,
      mealTimingPreferences: _userPreferences.mealTimingPreferences,
      batchCookingPreferences: _userPreferences.batchCookingPreferences,
    );

    setState(() {
      _isLoading = true;
      _completedDays = 0;
      _totalDays = _selectedDays;
    });

    try {
      final mealPlan = await BackendMealService.generateMealPlan(
        preferences: dietPlanPreferences,
        days: _selectedDays,
        userId: 'admin_generated_${DateTime.now().millisecondsSinceEpoch}', // Admin-generated meal plan
        onProgress: (completedMeals, totalMeals) {
          setState(() {
            _completedDays = completedMeals;
            _totalDays = totalMeals;
          });
        },
      );

      await MealPlanStorageService.saveMealPlan(mealPlan);
      // Note: We don't save diet preferences here since we don't have the user ID
      // The diet preferences are already saved when the meal plan is generated

      // Send email notification if user email is available
      if (widget.userEmail != null) {
        try {
          final emailSent = await EmailService.sendMealPlanReadyEmail(
            userEmail: widget.userEmail!,
            userName: widget.userName ?? widget.userEmail!.split('@').first,
            mealPlanId: mealPlan.id ??
                'demo_plan_${DateTime.now().millisecondsSinceEpoch}',
            planDuration: _selectedDays,
            fitnessGoal: _getFitnessGoalLabel(
                _selectedFitnessGoal ?? _userPreferences.fitnessGoal),
            targetCalories: _targetCalories,
          );

          if (emailSent) {
            _logger.i(
                'Meal plan ready email sent successfully to: ${widget.userEmail}');
          } else {
            _logger.w(
                'Failed to send meal plan ready email to: ${widget.userEmail}');
          }
        } catch (e) {
          _logger.e('Error sending meal plan ready email: $e');
          // Don't fail the entire operation if email fails
        }
      }

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
            _ProgressDots(current: _setupStep, total: 4),
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
            padding:
                const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
            child: Text(
              _getLoadingMessage(),
              style: AppTextStyles.heading4,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
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
            padding:
                const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
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
                      backgroundColor:
                          AppConstants.textTertiary.withOpacity(0.2),
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

  Widget _buildStepContent() {
    switch (_setupStep) {
      case 0:
        return GoalSelectionStep(
          selected: _selectedFitnessGoal,
          onSelect: (goal) => setState(() => _selectedFitnessGoal = goal),
          userName: widget.userName,
          clientFitnessGoal: _userPreferences.fitnessGoal,
        );
      case 1:
        return CaloriesStep(
          targetCalories: _targetCalories,
          onChanged: (calories) => setState(() => _targetCalories = calories),
          userName: widget.userName,
          clientTargetCalories: _userPreferences.targetCalories > 0
              ? _userPreferences.targetCalories
              : null,
        );
      case 2:
        return PlanDurationStep(
          weeklyRotation: _weeklyRotation,
          onToggleWeeklyRotation: (value) =>
              setState(() => _weeklyRotation = value),
          remindersEnabled: _remindersEnabled,
          onToggleReminders: (value) =>
              setState(() => _remindersEnabled = value),
          userName: widget.userName,
        );
      case 3:
        return FinalReviewStep(
          userPreferences: _userPreferences,
          selectedDays: _selectedDays,
          userName: widget.userName,
          targetCalories: _targetCalories,
          selectedFitnessGoal: _selectedFitnessGoal,
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
            onPressed: _selectedFitnessGoal != null ? _nextStep : null,
          ),
        );
      case 1:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: CustomButton(
            text: 'Next',
            onPressed: _nextStep,
          ),
        );
      case 2:
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
      case 3:
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

  // Use the same colors as user onboarding for first 4 steps, then distinct colors for last 2
  static const List<Color> _stepColors = [
    AppConstants.primaryColor,
    // Step 0: Goal Selection (Green - main goal)
    AppConstants.secondaryColor,
    // Step 1: Calories (Light Green - energy/nutrition)
    AppConstants.copperwoodColor,
    // Step 2: Cheat Day (Orange - indulgence)
    Colors.purple,
    // Step 3: Plan Duration (Purple - commitment)
    Colors.blue,
    // Step 4: Final Review (Blue - completion)
  ];

  // Step titles for better context
  static const List<String> _stepTitles = [
    'Goal',
    'Calories',
    'Cheat Day',
    'Duration',
    'Review',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(total, (i) {
            // Each dot shows its own color when completed, current step color when current, or gray when not reached
            Color color;
            if (i < current) {
              // Completed steps show their own color
              color = _stepColors[i];
            } else if (i == current) {
              // Current step shows its own color
              color = _stepColors[i];
            } else {
              // Future steps show gray
              color = AppConstants.textTertiary.withOpacity(0.2);
            }

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
        ),
        const SizedBox(height: 8),
        // Add step indicator text
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            '${current + 1} of $total • ${_stepTitles[current]}',
            key: ValueKey(current),
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              color: AppConstants.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}
