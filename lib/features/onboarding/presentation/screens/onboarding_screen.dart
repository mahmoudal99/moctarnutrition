import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/models/user_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // User preferences
  FitnessGoal _selectedFitnessGoal = FitnessGoal.maintenance;
  ActivityLevel _selectedActivityLevel = ActivityLevel.moderatelyActive;
  final List<String> _selectedDietaryRestrictions = [];
  final List<String> _selectedWorkoutStyles = [];
  int _targetCalories = 2000;
  
  // User metrics
  int _age = 25;
  double _weight = 70.0; // in kg
  double _height = 170.0; // in cm
  String _gender = 'Male';

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      title: 'Welcome to Champions Gym',
      subtitle: 'Your journey to a healthier lifestyle starts here',
      description:
          'Let\'s personalize your experience by understanding your fitness goals and preferences.',
      icon: Icons.fitness_center,
      color: AppConstants.primaryColor,
    ),
    OnboardingStep(
      title: 'Tell us about yourself',
      subtitle: 'Basic information for accurate calculations',
      description:
          'This helps us calculate your precise calorie needs and create personalized plans.',
      icon: Icons.person,
      color: AppConstants.accentColor,
    ),
    OnboardingStep(
      title: 'What\'s your fitness goal?',
      subtitle: 'Choose your primary objective',
      description:
          'This helps us create personalized workout and meal plans for you.',
      icon: Icons.track_changes,
      color: AppConstants.secondaryColor,
    ),
    OnboardingStep(
      title: 'How active are you?',
      subtitle: 'Select your activity level',
      description:
          'This helps us calculate your daily calorie needs and workout intensity.',
      icon: Icons.directions_run,
      color: AppConstants.warningColor,
    ),
    OnboardingStep(
      title: 'Any dietary restrictions?',
      subtitle: 'Select all that apply',
      description:
          'We\'ll customize your meal plans to match your dietary needs.',
      icon: Icons.restaurant,
      color: AppConstants.successColor,
    ),
    OnboardingStep(
      title: 'Preferred workout styles',
      subtitle: 'Choose your favorites',
      description:
          'We\'ll prioritize these types of workouts in your recommendations.',
      icon: Icons.sports_gymnastics,
      color: AppConstants.primaryColor,
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
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
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
                child: Container(
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
          Text(
            '${_currentPage + 1} of ${_steps.length}',
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              color: AppConstants.textTertiary,
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
      child: Column(
        children: [
          _buildStepHeader(step),
          const SizedBox(height: AppConstants.spacingXL),
          _buildStepContent(stepIndex),
          const SizedBox(height: AppConstants.spacingL),
        ],
      ),
    );
  }

  Widget _buildStepHeader(OnboardingStep step) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: step.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          child: Icon(
            step.icon,
            size: 32,
            color: step.color,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
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
    );
  }

  Widget _buildStepContent(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return _buildWelcomeStep();
      case 1:
        return _buildPersonalInfoStep();
      case 2:
        return _buildFitnessGoalStep();
      case 3:
        return _buildActivityLevelStep();
      case 4:
        return _buildDietaryRestrictionsStep();
      case 5:
        return _buildWorkoutStylesStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWelcomeStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
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
        const SizedBox(height: AppConstants.spacingL),
        Text(
          'Ready to transform your fitness journey?',
          style: AppTextStyles.heading3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingS),
        Text(
          'We\'ll create a personalized experience just for you with AI-powered meal plans and expert trainer guidance.',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
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
        const SizedBox(height: AppConstants.spacingL),
        _buildBMICard(),
      ],
    );
  }

  Widget _buildFitnessGoalStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: FitnessGoal.values.map((goal) {
        final isSelected = _selectedFitnessGoal == goal;
        return _buildSelectionCard(
          title: _getFitnessGoalTitle(goal),
          subtitle: _getFitnessGoalDescription(goal),
          icon: _getFitnessGoalIcon(goal),
          isSelected: isSelected,
          onTap: () {
            setState(() {
              _selectedFitnessGoal = goal;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildActivityLevelStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: ActivityLevel.values.map((level) {
        final isSelected = _selectedActivityLevel == level;
        return _buildSelectionCard(
          title: _getActivityLevelTitle(level),
          subtitle: _getActivityLevelDescription(level),
          icon: _getActivityLevelIcon(level),
          isSelected: isSelected,
          onTap: () {
            setState(() {
              _selectedActivityLevel = level;
            });
          },
        );
      }).toList(),
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: restrictions.map((restriction) {
        final isSelected = _selectedDietaryRestrictions.contains(restriction);
        return _buildSelectionCard(
          title: restriction,
          subtitle: _getDietaryRestrictionDescription(restriction),
          icon: Icons.restaurant,
          isSelected: isSelected,
          isMultiSelect: true,
          onTap: () {
            setState(() {
              if (restriction == 'None') {
                _selectedDietaryRestrictions.clear();
              } else {
                _selectedDietaryRestrictions.remove('None');
                if (isSelected) {
                  _selectedDietaryRestrictions.remove(restriction);
                } else {
                  _selectedDietaryRestrictions.add(restriction);
                }
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildWorkoutStylesStep() {
    final styles = [
      'Strength Training',
      'Cardio',
      'Yoga',
      'HIIT',
      'Pilates',
      'CrossFit',
      'Running',
      'Swimming',
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: styles.map((style) {
        final isSelected = _selectedWorkoutStyles.contains(style);
        return _buildSelectionCard(
          title: style,
          subtitle: _getWorkoutStyleDescription(style),
          icon: _getWorkoutStyleIcon(style),
          isSelected: isSelected,
          isMultiSelect: true,
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedWorkoutStyles.remove(style);
              } else {
                _selectedWorkoutStyles.add(style);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    bool isMultiSelect = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppConstants.primaryColor.withOpacity(0.08)
                  : AppConstants.surfaceColor,
              border: Border.all(
                color: isSelected
                    ? AppConstants.primaryColor.withOpacity(0.3)
                    : AppConstants.textTertiary.withOpacity(0.2),
                width: isSelected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              boxShadow: isSelected ? AppConstants.shadowS : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppConstants.primaryColor
                        : AppConstants.textTertiary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? AppConstants.surfaceColor
                        : AppConstants.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppConstants.primaryColor
                              : AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingXS),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    isMultiSelect
                        ? Icons.check_box
                        : Icons.radio_button_checked,
                    color: AppConstants.primaryColor,
                    size: 20,
                  )
                else
                  Icon(
                    isMultiSelect
                        ? Icons.check_box_outline_blank
                        : Icons.radio_button_unchecked,
                    color: AppConstants.textTertiary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingL,
        vertical: AppConstants.spacingM,
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: SizedBox(
                height: 44,
                child: CustomButton(
                  text: 'Back',
                  type: ButtonType.outline,
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: AppConstants.spacingS),
          Expanded(
            child: SizedBox(
              height: 44,
              child: CustomButton(
                text: _currentPage == _steps.length - 1 ? 'Get Started' : 'Next',
                onPressed: () {
                  if (_currentPage == _steps.length - 1) {
                    _completeOnboarding();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
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
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child: Container(
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
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
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
                Icon(
                  Icons.chevron_right,
                  color: AppConstants.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBMICard() {
    final bmi = _calculateBMI();
    final bmiCategory = _getBMICategory(bmi);
    final bmiColor = _getBMIColor(bmiCategory);

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: bmiColor.withOpacity(0.08),
        border: Border.all(
          color: bmiColor.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BMI',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                bmiCategory,
                style: AppTextStyles.bodySmall.copyWith(
                  color: bmiColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingXS),
          Text(
            bmi.toStringAsFixed(1),
            style: AppTextStyles.heading4.copyWith(
              color: bmiColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXS),
          Text(
            '${_height.toStringAsFixed(0)}cm, ${_weight.toStringAsFixed(1)}kg',
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
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

  void _showGenderSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildGenderSelector(),
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

  Widget _buildAgeSelector() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Age',
            style: AppTextStyles.heading4,
          ),
          const SizedBox(height: AppConstants.spacingL),
          SizedBox(
            height: 200,
            child: ListWheelScrollView(
              itemExtent: 50,
              diameterRatio: 1.5,
              onSelectedItemChanged: (index) {
                setState(() {
                  _age = 16 + index;
                });
              },
              children: List.generate(84, (index) {
                final age = 16 + index;
                return Center(
                  child: Text(
                    '$age years',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: _age == age ? FontWeight.bold : FontWeight.normal,
                      color: _age == age ? AppConstants.primaryColor : AppConstants.textPrimary,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          CustomButton(
            text: 'Confirm',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Gender',
            style: AppTextStyles.heading4,
          ),
          const SizedBox(height: AppConstants.spacingL),
          Wrap(
            spacing: AppConstants.spacingM,
            children: ['Male', 'Female', 'Other'].map((gender) {
              return ChoiceChip(
                label: Text(gender),
                selected: _gender == gender,
                onSelected: (selected) {
                  setState(() {
                    _gender = gender;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightSelector() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Weight',
            style: AppTextStyles.heading4,
          ),
          const SizedBox(height: AppConstants.spacingL),
          Slider(
            value: _weight,
            min: 30.0,
            max: 200.0,
            divisions: 170,
            label: '${_weight.toStringAsFixed(1)} kg',
            onChanged: (value) {
              setState(() {
                _weight = value;
              });
            },
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            '${_weight.toStringAsFixed(1)} kg',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          CustomButton(
            text: 'Confirm',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeightSelector() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Height',
            style: AppTextStyles.heading4,
          ),
          const SizedBox(height: AppConstants.spacingL),
          Slider(
            value: _height,
            min: 120.0,
            max: 220.0,
            divisions: 100,
            label: '${_height.toStringAsFixed(0)} cm',
            onChanged: (value) {
              setState(() {
                _height = value;
              });
            },
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            '${_height.toStringAsFixed(0)} cm',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          CustomButton(
            text: 'Confirm',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _completeOnboarding() {
    // Create user preferences
    final preferences = UserPreferences(
      fitnessGoal: _selectedFitnessGoal,
      activityLevel: _selectedActivityLevel,
      dietaryRestrictions: _selectedDietaryRestrictions,
      preferredWorkoutStyles: _selectedWorkoutStyles,
      targetCalories: _calculateTargetCalories(),
      age: _age,
      weight: _weight,
      height: _height,
      gender: _gender,
    );

    // TODO: Save user preferences temporarily and navigate to subscription screen
    // After subscription, we'll collect auth info and save everything
    context.go('/subscription');
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

  // Helper methods for fitness goals
  String _getFitnessGoalTitle(FitnessGoal goal) {
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

  String _getFitnessGoalDescription(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return 'Lose weight and improve body composition';
      case FitnessGoal.muscleGain:
        return 'Build muscle mass and strength';
      case FitnessGoal.maintenance:
        return 'Maintain current fitness level';
      case FitnessGoal.endurance:
        return 'Improve cardiovascular fitness';
      case FitnessGoal.strength:
        return 'Increase overall strength';
    }
  }

  IconData _getFitnessGoalIcon(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return Icons.trending_down;
      case FitnessGoal.muscleGain:
        return Icons.fitness_center;
      case FitnessGoal.maintenance:
        return Icons.balance;
      case FitnessGoal.endurance:
        return Icons.directions_run;
      case FitnessGoal.strength:
        return Icons.bolt;
    }
  }

  // Helper methods for activity levels
  String _getActivityLevelTitle(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
      case ActivityLevel.extremelyActive:
        return 'Extremely Active';
    }
  }

  String _getActivityLevelDescription(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Little to no exercise';
      case ActivityLevel.lightlyActive:
        return 'Light exercise 1-3 days/week';
      case ActivityLevel.moderatelyActive:
        return 'Moderate exercise 3-5 days/week';
      case ActivityLevel.veryActive:
        return 'Hard exercise 6-7 days/week';
      case ActivityLevel.extremelyActive:
        return 'Very hard exercise, physical job';
    }
  }

  IconData _getActivityLevelIcon(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return Icons.weekend;
      case ActivityLevel.lightlyActive:
        return Icons.directions_walk;
      case ActivityLevel.moderatelyActive:
        return Icons.directions_run;
      case ActivityLevel.veryActive:
        return Icons.sports_soccer;
      case ActivityLevel.extremelyActive:
        return Icons.fitness_center;
    }
  }

  String _getDietaryRestrictionDescription(String restriction) {
    switch (restriction) {
      case 'Vegetarian':
        return 'No meat, but includes dairy and eggs';
      case 'Vegan':
        return 'No animal products';
      case 'Gluten-Free':
        return 'No gluten-containing foods';
      case 'Dairy-Free':
        return 'No dairy products';
      case 'Keto':
        return 'Low-carb, high-fat diet';
      case 'Paleo':
        return 'Whole foods, no processed foods';
      case 'Low-Carb':
        return 'Reduced carbohydrate intake';
      case 'None':
        return 'No dietary restrictions';
      default:
        return '';
    }
  }

  IconData _getWorkoutStyleIcon(String style) {
    switch (style) {
      case 'Strength Training':
        return Icons.fitness_center;
      case 'Cardio':
        return Icons.favorite;
      case 'Yoga':
        return Icons.self_improvement;
      case 'HIIT':
        return Icons.timer;
      case 'Pilates':
        return Icons.accessibility_new;
      case 'CrossFit':
        return Icons.sports_gymnastics;
      case 'Running':
        return Icons.directions_run;
      case 'Swimming':
        return Icons.pool;
      default:
        return Icons.fitness_center;
    }
  }

  String _getWorkoutStyleDescription(String style) {
    switch (style) {
      case 'Strength Training':
        return 'Build muscle and strength';
      case 'Cardio':
        return 'Improve cardiovascular health';
      case 'Yoga':
        return 'Flexibility and mindfulness';
      case 'HIIT':
        return 'High-intensity interval training';
      case 'Pilates':
        return 'Core strength and flexibility';
      case 'CrossFit':
        return 'Functional fitness training';
      case 'Running':
        return 'Endurance and cardiovascular';
      case 'Swimming':
        return 'Low-impact full-body workout';
      default:
        return '';
    }
  }
}

class OnboardingStep {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}
