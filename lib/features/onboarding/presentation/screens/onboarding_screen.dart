import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/services/onboarding_service.dart';
import 'package:flutter/services.dart';
import '../steps/onboarding_bmi_step.dart';
import '../steps/onboarding_fitness_goal_step.dart';
import '../steps/onboarding_activity_level_step.dart';
import '../steps/onboarding_dietary_restrictions_step.dart';
import '../steps/onboarding_workout_styles_step.dart';
import '../steps/onboarding_welcome_step.dart';
import '../steps/onboarding_schedule_step.dart';
import '../steps/onboarding_food_preferences_step.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../shared/providers/auth_provider.dart' as app_auth;
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/services/user_local_storage_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static final _logger = Logger();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // User preferences
  FitnessGoal _selectedFitnessGoal = FitnessGoal.maintenance;
  ActivityLevel _selectedActivityLevel = ActivityLevel.moderatelyActive;
  final List<String> _selectedDietaryRestrictions = [];
  final List<String> _selectedWorkoutStyles = [];
  int _targetCalories = 2000;

  // Food preferences
  final List<String> _preferredCuisines = [];
  final List<String> _foodsToAvoid = [];
  final List<String> _favoriteFoods = [];
  final TextEditingController _cuisineController = TextEditingController();
  final TextEditingController _avoidController = TextEditingController();
  final TextEditingController _favoriteController = TextEditingController();

  // User metrics
  int _age = 25;
  double _weight = 70.0; // in kg
  double _height = 170.0; // in cm
  String _gender = 'Male';

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      title: 'YOUR FITNESS JOURNEY IS ABOUT TO BEGIN',
      subtitle: 'Your journey to a healthier lifestyle starts here',
      description:
          'Let\'s personalize your experience by understanding your fitness goals and preferences.',
      icon: "arrow.json",
      showIconColor: false,
      color: AppConstants.primaryColor,
    ),
    // OnboardingStep(
    //   title: 'Choose Your Coach',
    //   subtitle: 'Sync with your Coach',
    //   description:
    //       'Choose from our handpicked personal trainers and start training with the right expert for your goals.',
    //   icon: "calendar.json",
    //   color: AppConstants.secondaryColor,
    //   showIconColor: false
    // ),
    OnboardingStep(
        title: 'Tell us about yourself',
        subtitle: 'Basic information for accurate calculations',
        description:
            'This helps us calculate your precise calorie needs and create personalized plans.',
        icon: "weight.json",
        color: AppConstants.accentColor,
        showIconColor: false),
    // Fitness Goal step (should come after BMI, which is inserted in initState)
    OnboardingStep(
        title: 'What is your primary objective?',
        subtitle: 'Choose your fitness goal',
        description:
            'This helps us create personalized workout and meal plans for you.',
        icon: "target.json",
        color: AppConstants.secondaryColor,
        showIconColor: false),
    // BMI step will be inserted in initState
    OnboardingStep(
      title: 'How active are you?',
      subtitle: 'Select your activity level',
      description:
          'This helps us calculate your daily calorie needs and workout intensity.',
      icon: "run.json",
      color: AppConstants.warningColor,
    ),
    OnboardingStep(
      title: 'Any dietary restrictions?',
      subtitle: 'Select all that apply',
      description:
          'We\'ll customize your meal plans to match your dietary needs.',
      icon: "diet.json",
      color: AppConstants.successColor,
    ),
    OnboardingStep(
      title: 'Preferred workout styles',
      subtitle: 'Choose your favorites',
      description:
          'We\'ll prioritize these types of workouts in your recommendations.',
      icon: "run.json",
      color: AppConstants.primaryColor,
    ),
    OnboardingStep(
      title: 'Food preferences',
      subtitle: 'Tell us what you like and don\'t like',
      description:
          'This helps us create personalized meal plans that match your taste preferences.',
      icon: "diet.json",
      color: AppConstants.successColor,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return _buildStepPage(index);
                },
                physics: _getPageViewPhysics(),
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  ScrollPhysics _getPageViewPhysics() {
    // Fitness Goal step: index 3
    // Dietary Restrictions step: index 5
    // Workout Styles step: index 6
    // Food Preferences step: index 7
    if (_currentPage == 3 && _selectedFitnessGoal == null) {
      return const NeverScrollableScrollPhysics();
    }
    if (_currentPage == 5 && _selectedDietaryRestrictions.isEmpty) {
      return const NeverScrollableScrollPhysics();
    }
    if (_currentPage == 6 && _selectedWorkoutStyles.isEmpty) {
      return const NeverScrollableScrollPhysics();
    }
    return const BouncingScrollPhysics();
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingL,
        vertical: AppConstants.spacingM,
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(_steps.length, (index) {
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: 3,
                  margin: EdgeInsets.only(
                    right:
                        index < _steps.length - 1 ? AppConstants.spacingXS : 0,
                  ),
                  decoration: BoxDecoration(
                    color: index <= _currentPage
                        ? _steps[index].color
                        : AppConstants.textTertiary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppConstants.spacingS),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              '${_currentPage + 1} of ${_steps.length}',
              key: ValueKey(_currentPage),
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                color: AppConstants.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepPage(int stepIndex) {
    final step = _steps[stepIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        child: Column(
          key: ValueKey(stepIndex),
          children: [
            _buildStepHeader(step),
            const SizedBox(height: AppConstants.spacingXL),
            _buildStepContent(stepIndex),
            const SizedBox(height: AppConstants.spacingL),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader(OnboardingStep step) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Column(
              children: [
                Container(
                  width: step.icon.contains("arrow") ? 100 : 64,
                  height: step.icon.contains("arrow") ? 100 : 64,
                  decoration: const BoxDecoration(
                      // color: step.color.withOpacity(0.1),
                      // borderRadius: BorxderRadius.circular(AppConstants.radiusL),
                      ),
                  child: Lottie.asset(
                    "assets/animations/${step.icon}",
                    delegates: LottieDelegates(
                      values: step.showIconColor
                          ? [
                              ValueDelegate.color(
                                const ['**', 'Fill 1'],
                                // Change this based on your animation
                                value: step.color,
                              ),
                            ]
                          : [
                              // ValueDelegate.color(
                              //   const ['**', 'Fill 1'], // Change this based on your animation
                              //   value: step.color,
                              // ),
                            ],
                    ),
                  ),
                ),
                SizedBox(
                    height: step.icon.contains("arrow")
                        ? 0
                        : AppConstants.spacingM),
                Text(
                  step.title,
                  style: AppTextStyles.heading3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spacingXS),
                Text(
                  step.subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spacingS),
                Text(
                  step.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppConstants.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepContent(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return const OnboardingWelcomeStep();
      // case 1:
      //   return const OnboardingScheduleStep();
      case 1:
        return _buildPersonalInfoStep();
      case 2:
        return _buildBMIStep();
      case 3:
        return _buildFitnessGoalStep();
      case 4:
        return _buildActivityLevelStep();
      case 5:
        return _buildDietaryRestrictionsStep();
      case 6:
        return _buildWorkoutStylesStep();
      case 7:
        return _buildFoodPreferencesStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWelcomeStep() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: AppConstants.primaryGradient,
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
                    boxShadow: AppConstants.shadowM,
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    size: 70,
                    color: AppConstants.surfaceColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Text(
                  'Ready to transform your fitness journey?',
                  style: AppTextStyles.heading3,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Transform.translate(
              offset: Offset(0, 15 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Text(
                  'We\'ll create a personalized experience just for you with AI-powered meal plans and expert trainer guidance.',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      children: [
        _buildMetricCard(
          'Age',
          '$_age years',
          Icons.cake,
          () => _showAgeSelector(),
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildMetricCard(
          'Gender',
          _gender,
          Icons.person,
          () => _showGenderSelector(),
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildMetricCard(
          'Weight',
          '${_weight.toStringAsFixed(1)} kg',
          Icons.monitor_weight,
          () => _showWeightSelector(),
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildMetricCard(
          'Height',
          '${_height.toStringAsFixed(0)} cm',
          Icons.height,
          () => _showHeightSelector(),
        ),
        // Removed BMI card from here
      ],
    );
  }

  Widget _buildFitnessGoalStep() {
    return OnboardingFitnessGoalStep(
      selectedFitnessGoal: _selectedFitnessGoal,
      onSelect: (goal) {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedFitnessGoal = goal;
        });
      },
    );
  }

  Widget _buildActivityLevelStep() {
    return OnboardingActivityLevelStep(
      selectedActivityLevel: _selectedActivityLevel,
      onSelect: (level) {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedActivityLevel = level;
        });
      },
    );
  }

  Widget _buildDietaryRestrictionsStep() {
    final restrictions = [
      'Vegetarian',
      'Vegan',
      'Gluten-Free',
      'Dairy-Free',
      'Keto',
      'Paleo',
      'Low-Carb',
      'None',
    ];

    return OnboardingDietaryRestrictionsStep(
      selectedDietaryRestrictions: _selectedDietaryRestrictions,
      restrictions: restrictions,
      onSelect: (restriction) {
        HapticFeedback.lightImpact();
        setState(() {
          if (restriction == 'None') {
            _selectedDietaryRestrictions.clear();
            _selectedDietaryRestrictions.add('None');
          } else {
            _selectedDietaryRestrictions.remove('None');
            if (_selectedDietaryRestrictions.contains(restriction)) {
              _selectedDietaryRestrictions.remove(restriction);
            } else {
              _selectedDietaryRestrictions.add(restriction);
            }
          }
        });
      },
    );
  }

  Widget _buildWorkoutStylesStep() {
    final styles = [
      'Strength Training',
      'Cardio',
      'HIIT',
      'Running',
    ];

    return OnboardingWorkoutStylesStep(
      selectedWorkoutStyles: _selectedWorkoutStyles,
      styles: styles,
      onSelect: (style) {
        HapticFeedback.lightImpact();
        setState(() {
          if (_selectedWorkoutStyles.contains(style)) {
            _selectedWorkoutStyles.remove(style);
          } else {
            _selectedWorkoutStyles.add(style);
          }
        });
      },
    );
  }

  Widget _buildFoodPreferencesStep() {
    return OnboardingFoodPreferencesStep(
      preferredCuisines: _preferredCuisines,
      onAddCuisine: (cuisine) {
        if (cuisine.isNotEmpty && !_preferredCuisines.contains(cuisine)) {
          setState(() => _preferredCuisines.add(cuisine));
        }
      },
      onRemoveCuisine: (cuisine) => setState(() => _preferredCuisines.remove(cuisine)),
      foodsToAvoid: _foodsToAvoid,
      onAddAvoid: (food) {
        if (food.isNotEmpty && !_foodsToAvoid.contains(food)) {
          setState(() => _foodsToAvoid.add(food));
        }
      },
      onRemoveAvoid: (food) => setState(() => _foodsToAvoid.remove(food)),
      favoriteFoods: _favoriteFoods,
      onAddFavorite: (food) {
        if (food.isNotEmpty && !_favoriteFoods.contains(food)) {
          setState(() => _favoriteFoods.add(food));
        }
      },
      onRemoveFavorite: (food) => setState(() => _favoriteFoods.remove(food)),
      cuisineController: _cuisineController,
      avoidController: _avoidController,
      favoriteController: _favoriteController,
    );
  }

  Widget _buildNavigationButtons() {
    final isDietaryStep = _currentPage == 5;
    final isWorkoutStep = _currentPage == 6;
    final isFoodPreferencesStep = _currentPage == 7;
    final isNextEnabled = !isDietaryStep && !isWorkoutStep && !isFoodPreferencesStep
        ? true
        : isDietaryStep
            ? _selectedDietaryRestrictions.isNotEmpty
            : isWorkoutStep
                ? _selectedWorkoutStyles.isNotEmpty
                : true; // Food preferences step is optional
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingL,
        vertical: AppConstants.spacingM,
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _currentPage > 0 ? 1.0 : 0.0,
                child: SizedBox(
                  height: 52,
                  child: CustomButton(
                    text: 'Back',
                    type: ButtonType.outline,
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: AppConstants.spacingS),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: SizedBox(
                key: ValueKey(_currentPage),
                height: 52,
                child: CustomButton(
                  text: _currentPage == _steps.length - 1
                      ? 'Get Started'
                      : 'Next',
                  onPressed: isNextEnabled
                      ? () {
                          HapticFeedback.mediumImpact();
                          if (_currentPage == _steps.length - 1) {
                            _completeOnboarding();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        }
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceColor,
                      border: Border.all(
                        color: AppConstants.textTertiary.withOpacity(0.2),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      boxShadow: AppConstants.shadowS,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.08),
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusS),
                          ),
                          child: Icon(
                            icon,
                            color: AppConstants.primaryColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppConstants.textSecondary,
                                ),
                              ),
                              Text(
                                value,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppConstants.textTertiary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBMIStep() {
    final bmi = _calculateBMI();
    final bmiCategory = _getBMICategory(bmi);
    final bmiColor = _getBMIColor(bmiCategory);
    return OnboardingBMIStep(
      bmi: bmi,
      bmiCategory: bmiCategory,
      bmiColor: bmiColor,
      height: _height,
      weight: _weight,
    );
  }

  double _calculateBMI() {
    final heightInMeters = _height / 100;
    return _weight / (heightInMeters * heightInMeters);
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getBMIColor(String category) {
    switch (category) {
      case 'Underweight':
        return AppConstants.warningColor;
      case 'Normal':
        return AppConstants.successColor;
      case 'Overweight':
        return AppConstants.warningColor;
      case 'Obese':
        return AppConstants.errorColor;
      default:
        return AppConstants.textSecondary;
    }
  }

  void _showAgeSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildAgeSelector(),
    );
  }

  Widget _buildAgeSelector() {
    int tempAge = _age;
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Age', style: AppTextStyles.heading4),
              const SizedBox(height: AppConstants.spacingL),
              SizedBox(
                height: 200,
                child: ListWheelScrollView(
                  itemExtent: 50,
                  diameterRatio: 1.5,
                  onSelectedItemChanged: (index) {
                    setModalState(() {
                      tempAge = 16 + index;
                    });
                  },
                  children: List.generate(84, (index) {
                    final age = 16 + index;
                    return Center(
                      child: Text(
                        '$age years',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: tempAge == age
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: tempAge == age
                              ? AppConstants.primaryColor
                              : AppConstants.textPrimary,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              CustomButton(
                text: 'Confirm',
                onPressed: () {
                  setState(() {
                    _age = tempAge;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGenderSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildGenderSelector(),
    );
  }

  Widget _buildGenderSelector() {
    String tempGender = _gender;
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Gender', style: AppTextStyles.heading4),
              const SizedBox(height: AppConstants.spacingL),
              Wrap(
                spacing: AppConstants.spacingM,
                children: ['Male', 'Female', 'Other'].map((gender) {
                  return ChoiceChip(
                    label: Text(gender),
                    selected: tempGender == gender,
                    onSelected: (selected) {
                      setModalState(() {
                        tempGender = gender;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppConstants.spacingL),
              CustomButton(
                text: 'Confirm',
                onPressed: () {
                  setState(() {
                    _gender = tempGender;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWeightSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildWeightSelector(),
    );
  }

  void _showHeightSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildHeightSelector(),
    );
  }

  // Add a new onboarding step for BMI after personal info
  @override
  void initState() {
    super.initState();
    // Insert BMI step after personal info (index 2)
    _steps.insert(
        2,
        OnboardingStep(
          title: 'Your BMI',
          subtitle: 'Body Mass Index',
          description:
              'Your BMI is calculated from your height and weight. This helps us personalize your experience.',
          icon: "heartbeat.json",
          color: AppConstants.warningColor,
        ));
  }

  @override
  void dispose() {
    _cuisineController.dispose();
    _avoidController.dispose();
    _favoriteController.dispose();
    super.dispose();
  }

  void _completeOnboarding() async {
    // Debug: Print selected preferences before saving
    _logger.i('Onboarding complete:');
    _logger.i('  Dietary Restrictions: ${_selectedDietaryRestrictions}');
    _logger.i('  Workout Styles: ${_selectedWorkoutStyles}');
    // Create user preferences
    final preferences = UserPreferences(
      fitnessGoal: _selectedFitnessGoal,
      activityLevel: _selectedActivityLevel,
      dietaryRestrictions: List<String>.from(_selectedDietaryRestrictions),
      preferredWorkoutStyles: List<String>.from(_selectedWorkoutStyles),
      targetCalories: _calculateTargetCalories(),
      age: _age,
      weight: _weight,
      height: _height,
      gender: _gender,
      preferredCuisines: List<String>.from(_preferredCuisines),
      foodsToAvoid: List<String>.from(_foodsToAvoid),
      favoriteFoods: List<String>.from(_favoriteFoods),
    );

    // Save onboarding data locally (Provider/SharedPreferences)
    final user = UserModel(
      id: 'local-user',
      email: 'user@example.com',
      name: 'User',
      photoUrl: null,
      preferences: preferences,
      role: UserRole.user,
      subscriptionStatus: SubscriptionStatus.free,
      hasSeenOnboarding: true,
      hasSeenGetStarted: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to local provider/storage only
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.setUser(user);
    // Persist onboarding data to SharedPreferences for migration after sign-up
    await UserLocalStorageService().saveUser(user);
    await OnboardingService.markOnboardingAsSeen();
    await OnboardingService.markGetStartedAsSeen();

    // Navigate to sign up/sign in or next step (e.g., subscription)
    if (mounted) {
      context.push('/subscription');
    }
  }

  int _calculateTargetCalories() {
    // Basic BMR calculation using Mifflin-St Jeor Equation
    double bmr;
    if (_gender == 'Male') {
      bmr = 10 * _weight + 6.25 * _height - 5 * _age + 5;
    } else {
      bmr = 10 * _weight + 6.25 * _height - 5 * _age - 161;
    }

    // Apply activity multiplier
    double activityMultiplier;
    switch (_selectedActivityLevel) {
      case ActivityLevel.sedentary:
        activityMultiplier = 1.2;
        break;
      case ActivityLevel.lightlyActive:
        activityMultiplier = 1.375;
        break;
      case ActivityLevel.moderatelyActive:
        activityMultiplier = 1.55;
        break;
      case ActivityLevel.veryActive:
        activityMultiplier = 1.725;
        break;
      case ActivityLevel.extremelyActive:
        activityMultiplier = 1.9;
        break;
    }

    double tdee = bmr * activityMultiplier;

    // Apply fitness goal adjustment
    switch (_selectedFitnessGoal) {
      case FitnessGoal.weightLoss:
        tdee -= 500; // 500 calorie deficit
        break;
      case FitnessGoal.muscleGain:
        tdee += 300; // 300 calorie surplus
        break;
      case FitnessGoal.maintenance:
        // No adjustment
        break;
      case FitnessGoal.endurance:
        tdee += 200; // Slight surplus for endurance
        break;
      case FitnessGoal.strength:
        tdee += 250; // Slight surplus for strength
        break;
    }

    return tdee.round();
  }

  Widget _buildWeightSelector() {
    double tempWeight = _weight;
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Weight', style: AppTextStyles.heading4),
              const SizedBox(height: AppConstants.spacingL),
              Slider(
                value: tempWeight,
                min: 30.0,
                max: 200.0,
                divisions: 170,
                label: '${tempWeight.toStringAsFixed(1)} kg',
                onChanged: (value) {
                  setModalState(() {
                    tempWeight = value;
                  });
                  HapticFeedback.selectionClick();
                },
              ),
              const SizedBox(height: AppConstants.spacingM),
              Text(
                '${tempWeight.toStringAsFixed(1)} kg',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              CustomButton(
                text: 'Confirm',
                onPressed: () {
                  setState(() {
                    _weight = tempWeight;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeightSelector() {
    double tempHeight = _height;
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Height', style: AppTextStyles.heading4),
              const SizedBox(height: AppConstants.spacingL),
              Slider(
                value: tempHeight,
                min: 120.0,
                max: 220.0,
                divisions: 100,
                label: '${tempHeight.toStringAsFixed(0)} cm',
                onChanged: (value) {
                  setModalState(() {
                    tempHeight = value;
                  });
                  HapticFeedback.selectionClick();
                },
              ),
              const SizedBox(height: AppConstants.spacingM),
              Text(
                '${tempHeight.toStringAsFixed(0)} cm',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              CustomButton(
                text: 'Confirm',
                onPressed: () {
                  setState(() {
                    _height = tempHeight;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class OnboardingStep {
  final String title;
  final String subtitle;
  final String description;
  final String icon;
  final Color color;
  bool showIconColor = true;

  OnboardingStep(
      {required this.title,
      required this.subtitle,
      required this.description,
      required this.icon,
      required this.color,
      this.showIconColor = true});
}
