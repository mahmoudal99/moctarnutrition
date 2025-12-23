import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:champions_gym_app/shared/services/calorie_calculation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/services/onboarding_service.dart';
import '../../../../shared/services/user_local_storage_service.dart';
import '../../../../shared/services/notification_service.dart';
import '../models/onboarding_step.dart';
import '../widgets/onboarding_progress_indicator.dart';
import '../widgets/onboarding_step_page.dart';
import '../widgets/onboarding_navigation_buttons.dart';
import '../utils/onboarding_step_builder.dart';
import '../utils/onboarding_steps_config.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static final _logger = Logger();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late List<OnboardingStep> _steps;
  final OnboardingData _data = OnboardingData();

  @override
  void initState() {
    super.initState();
    _steps = OnboardingStepsConfig.getSteps();
    // Insert BMI step after Age (index 5), before HowWeDoThis (which shifts to index 7)
    _steps.insert(6, OnboardingStepsConfig.getBMIStep());
    _updateStepsForBodybuilder();
  }

  void _updateStepsForBodybuilder() {
    // Find and remove workout styles step if user is a bodybuilder
    if (_data.isBodybuilder == true) {
      // Workout styles step is at index 12 (after BMI insertion at index 6)
      // Original index 11 becomes 12 after BMI insertion
      if (_steps.length > 12 && _steps[12].title == 'Preferred workout styles') {
        _steps.removeAt(12);
      }
    } else {
      // If not a bodybuilder, ensure workout styles step exists
      // Rebuild steps if needed
      final hasWorkoutStylesStep = _steps.any((step) => step.title == 'Preferred workout styles');
      if (!hasWorkoutStylesStep) {
        // Rebuild steps to include workout styles
        _steps = OnboardingStepsConfig.getSteps();
        _steps.insert(6, OnboardingStepsConfig.getBMIStep());
      }
    }
  }

  @override
  void dispose() {
    _data.cuisineController.dispose();
    _data.avoidController.dispose();
    _data.favoriteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingProgressIndicator(
              steps: _steps,
              currentPage: _currentPage,
              onBack: () {
                HapticFeedback.mediumImpact();
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
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
                  // Use a key that includes bodybuilder selection for step 1 to force rebuild
                  final contentKey = index == 1 
                      ? 'step_${index}_bodybuilder_${_data.isBodybuilder}'
                      : null;
                  return OnboardingStepPage(
                    key: ValueKey(contentKey ?? 'step_$index'),
                    step: _steps[index],
                    stepIndex: index,
                    contentKey: contentKey,
                    content: OnboardingStepBuilder.buildStepContent(
                      stepIndex: index,
                      data: _data,
                      onBodybuilderChanged: (isBodybuilder) {
                        setState(() {
                          _data.isBodybuilder = isBodybuilder;
                          // Always update step 1 (index 1) based on selection
                          if (_steps.length > 1) {
                            if (isBodybuilder == true) {
                              // Bodybuilder intro
                              _steps[1] = OnboardingStep(
                                title: 'Hi, I\'m Moctar 👋',
                                subtitle: 'Discover how Moctar can help you achieve your bodybuilding goals.',
                                icon: "user.png",
                                color: AppConstants.textSecondary,
                                showIconColor: false,
                                highlightedWords: ['Moctar'],
                              );
                            } else {
                              // Generic fitness intro (for false or null)
                              _steps[1] = OnboardingStep(
                                title: 'Welcome to Your Fitness Journey',
                                subtitle: 'Let\'s build a healthier lifestyle together.',
                                icon: "arrow.json",
                                color: AppConstants.primaryColor,
                                showIconColor: false,
                                highlightedWords: [],
                              );
                            }
                          }
                          // Update steps list to skip workout styles if bodybuilder
                          _updateStepsForBodybuilder();
                        });
                      },
                      onFitnessGoalChanged: (goal) {
                        setState(() {
                          _data.selectedFitnessGoal = goal;
                        });
                      },
                      onActivityLevelChanged: (level) {
                        setState(() {
                          _data.selectedActivityLevel = level;
                        });
                      },
                      onDietaryRestrictionChanged: (restriction) {
                        setState(() {
                          if (restriction == 'None') {
                            _data.selectedDietaryRestrictions.clear();
                            _data.selectedDietaryRestrictions.add('None');
                          } else {
                            _data.selectedDietaryRestrictions.remove('None');
                            if (_data.selectedDietaryRestrictions
                                .contains(restriction)) {
                              _data.selectedDietaryRestrictions
                                  .remove(restriction);
                            } else {
                              _data.selectedDietaryRestrictions
                                  .add(restriction);
                            }
                          }
                        });
                      },
                      onWorkoutStyleChanged: (style) {
                        setState(() {
                          if (_data.selectedWorkoutStyles.contains(style)) {
                            _data.selectedWorkoutStyles.remove(style);
                          } else {
                            _data.selectedWorkoutStyles.add(style);
                          }
                        });
                      },
                      onWeeklyWorkoutDaysChanged: (days) {
                        setState(() {
                          _data.weeklyWorkoutDays = days;
                        });
                      },
                      onSpecificWorkoutDaysChanged: (days) {
                        setState(() {
                          _data.specificWorkoutDays = days;
                        });
                      },
                      onAddCuisine: (cuisine) {
                        if (cuisine.isNotEmpty &&
                            !_data.preferredCuisines.contains(cuisine)) {
                          setState(() => _data.preferredCuisines.add(cuisine));
                        }
                      },
                      onRemoveCuisine: (cuisine) {
                        setState(() => _data.preferredCuisines.remove(cuisine));
                      },
                      onAddAvoid: (food) {
                        if (food.isNotEmpty &&
                            !_data.foodsToAvoid.contains(food)) {
                          setState(() => _data.foodsToAvoid.add(food));
                        }
                      },
                      onRemoveAvoid: (food) {
                        setState(() => _data.foodsToAvoid.remove(food));
                      },
                      onAddFavorite: (food) {
                        if (food.isNotEmpty &&
                            !_data.favoriteFoods.contains(food)) {
                          setState(() => _data.favoriteFoods.add(food));
                        }
                      },
                      onRemoveFavorite: (food) {
                        setState(() => _data.favoriteFoods.remove(food));
                      },
                      onAllergiesChanged: (allergies) {
                        setState(() {
                          _data.selectedAllergies.clear();
                          _data.selectedAllergies.addAll(allergies);
                        });
                      },
                      onMealTimingChanged: (preferences) {
                        setState(() {
                          _data.mealTimingPreferences = preferences;
                        });
                      },
                      onBatchCookingChanged: (preferences) {
                        setState(() {
                          _data.batchCookingPreferences = preferences;
                        });
                      },
                      onCheatDayChanged: (day) {
                        setState(() {
                          _data.cheatDay = day;
                        });
                      },
                      onTimeChanged: (time) {
                        setState(() {
                          _data.workoutNotificationTime =
                              time ?? const TimeOfDay(hour: 9, minute: 0);
                        });
                      },
                      onNotificationsChanged: (enabled) {
                        setState(() {
                          _data.workoutNotificationsEnabled = enabled;
                        });
                      },
                      onComplete: _completeOnboarding,
                    ),
                  );
                },
                physics: _getPageViewPhysics(),
              ),
            ),
            OnboardingNavigationButtons(
              currentPage: _currentPage,
              totalSteps: _steps.length,
              isNextEnabled: _isNextEnabled(),
              onBack: () {
                // Back button removed - handled by progress indicator
              },
              onNext: () {
                HapticFeedback.mediumImpact();
                // Rating step index shifts if workout styles is removed
                final ratingStepIndex = _data.isBodybuilder == true ? 19 : 20;
                if (_currentPage == ratingStepIndex) {
                  // Show rating dialog for rating step
                  _showRatingDialog(context);
                } else {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              onComplete: _completeOnboarding,
              onNotificationSkip: () {
                _completeOnboarding();
              },
              onNotificationEnable: () async {
                final permissionResult = await NotificationService
                    .requestNotificationPermission();
                if (permissionResult.isGranted) {
                  setState(() {
                    _data.workoutNotificationsEnabled = true;
                  });
                  await NotificationService.showTestNotification();
                }
                // Go to next step instead of completing onboarding
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  ScrollPhysics _getPageViewPhysics() {
    // Disable page swiping for the desired weight step to allow weight selector interaction
    if (_currentPage == 9) {
      return const NeverScrollableScrollPhysics();
    }
    if (_currentPage == 11 && _data.selectedDietaryRestrictions.isEmpty) {
      return const NeverScrollableScrollPhysics();
    }
    // Workout styles step is skipped for bodybuilders, so only check if not bodybuilder
    if (_data.isBodybuilder != true && _currentPage == 12 && _data.selectedWorkoutStyles.isEmpty) {
      return const NeverScrollableScrollPhysics();
    }
    return const BouncingScrollPhysics();
  }

  Future<void> _showRatingDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Rate Moctar Nutrition',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enjoying Moctar Nutrition? Please take a moment to rate us!',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    onPressed: () async {
                      // Open app store for rating
                      final Uri url = Uri.parse(
                          'https://apps.apple.com/app/id123456789' // Replace with actual app store URL
                          );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url,
                            mode: LaunchMode.externalApplication);
                      }
                      Navigator.of(context).pop();
                      _completeOnboarding();
                    },
                    icon: Icon(
                      Icons.star,
                      color: Colors.amber[600],
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _completeOnboarding();
              },
              child: Text(
                'Maybe Later',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isNextEnabled() {
    final isBodybuilderStep = _currentPage == 0;
    final isDietaryStep = _currentPage == 11;
    // Workout styles step is skipped for bodybuilders, so adjust indices
    final workoutStylesStepIndex = _data.isBodybuilder == true ? -1 : 12;
    final isWorkoutStep = _currentPage == workoutStylesStepIndex;
    // Weekly workout goal step index shifts if workout styles is removed
    final weeklyWorkoutGoalStepIndex = _data.isBodybuilder == true ? 12 : 13;
    final isWeeklyWorkoutGoalStep = _currentPage == weeklyWorkoutGoalStepIndex;
    // Food preferences step index shifts if workout styles is removed
    final foodPreferencesStepIndex = _data.isBodybuilder == true ? 13 : 14;
    final isFoodPreferencesStep = _currentPage == foodPreferencesStepIndex;
    // Allergies step index shifts if workout styles is removed
    final allergiesStepIndex = _data.isBodybuilder == true ? 14 : 15;
    final isAllergiesStep = _currentPage == allergiesStepIndex;
    // Workout notifications step index shifts if workout styles is removed
    final workoutNotificationsStepIndex = _data.isBodybuilder == true ? 18 : 19;
    final isWorkoutNotificationsStep = _currentPage == workoutNotificationsStepIndex;
    // Rating step index shifts if workout styles is removed
    final ratingStepIndex = _data.isBodybuilder == true ? 19 : 20;
    final isRatingStep = _currentPage == ratingStepIndex;

    if (isBodybuilderStep) {
      return _data.isBodybuilder != null;
    }

    if (!isDietaryStep &&
        !isWorkoutStep &&
        !isWeeklyWorkoutGoalStep &&
        !isFoodPreferencesStep &&
        !isAllergiesStep &&
        !isWorkoutNotificationsStep &&
        !isRatingStep) {
      return true;
    }

    if (isDietaryStep) {
      return _data.selectedDietaryRestrictions.isNotEmpty;
    }
    if (isWorkoutStep) {
      return _data.selectedWorkoutStyles.isNotEmpty;
    }
    if (isWeeklyWorkoutGoalStep) {
      return _data.weeklyWorkoutDays > 0;
    }

    return true; // Food preferences and allergies steps are optional
  }

  void _completeOnboarding() async {
    _logger.i('Onboarding complete:');
    _logger.i('  Dietary Restrictions: ${_data.selectedDietaryRestrictions}');
    _logger.i('  Workout Styles: ${_data.selectedWorkoutStyles}');

    final allergiesJson =
        _data.selectedAllergies.map((allergy) => allergy.toJson()).toList();
    final mealTimingJson = _data.mealTimingPreferences?.toJson();
    final batchCookingJson = _data.batchCookingPreferences?.toJson();

    // Calculate initial BMR using Mifflin-St Jeor equation
    double bmr;
    if (_data.gender.toLowerCase() == 'male') {
      bmr = 10 * _data.weight + 6.25 * _data.height - 5 * _data.age + 5;
    } else {
      bmr = 10 * _data.weight + 6.25 * _data.height - 5 * _data.age - 161;
    }

    // Calculate initial TDEE
    double activityMultiplier;
    switch (_data.selectedActivityLevel) {
      case ActivityLevel.sedentary:
        activityMultiplier = 1.2;
        break;
      case ActivityLevel.lightlyActive:
        activityMultiplier = 1.35;
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
    
    final initialTdee = bmr * activityMultiplier;

    // Calculate calorie targets using the service
    final calculatedTargets = CalorieCalculationService.calculateCalorieTargets(
      UserModel(
        id: 'temp',
        email: 'temp@example.com',
        preferences: UserPreferences(
          fitnessGoal: _data.selectedFitnessGoal,
          activityLevel: _data.selectedActivityLevel,
          dietaryRestrictions: [],
          preferredWorkoutStyles: [],
          targetCalories: initialTdee.round(),
          age: _data.age,
          weight: _data.weight,
          height: _data.height,
          gender: _data.gender,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final preferences = UserPreferences(
      fitnessGoal: _data.selectedFitnessGoal,
      activityLevel: _data.selectedActivityLevel,
      dietaryRestrictions: List<String>.from(_data.selectedDietaryRestrictions),
      preferredWorkoutStyles: List<String>.from(_data.selectedWorkoutStyles),
      targetCalories: calculatedTargets.dailyTarget, // Use calculated target as initial value
      calculatedCalorieTargets: calculatedTargets, // Store the full calculation
      workoutNotificationsEnabled: _data.workoutNotificationsEnabled,
      workoutNotificationTime:
          '${_data.workoutNotificationTime.hour.toString().padLeft(2, '0')}:${_data.workoutNotificationTime.minute.toString().padLeft(2, '0')}',
      weeklyWorkoutDays: _data.weeklyWorkoutDays,
      specificWorkoutDays: _data.specificWorkoutDays,
      age: _data.age,
      weight: _data.weight,
      height: _data.height,
      desiredWeight: _data.desiredWeight,
      gender: _data.gender,
      preferredCuisines: List<String>.from(_data.preferredCuisines),
      foodsToAvoid: List<String>.from(_data.foodsToAvoid),
      favoriteFoods: List<String>.from(_data.favoriteFoods),
      allergies: allergiesJson,
      mealTimingPreferences: mealTimingJson,
      batchCookingPreferences: batchCookingJson,
      cheatDay: _data.cheatDay,
      isBodybuilder: _data.isBodybuilder ?? true,
    );

    final user = UserModel(
      id: 'local-user',
      email: 'user@example.com',
      name: 'User',
      photoUrl: null,
      preferences: preferences,
      role: UserRole.user,
      trainingProgramStatus: TrainingProgramStatus.none,
      hasSeenOnboarding: true,
      hasSeenGetStarted: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.setUser(user);
    await UserLocalStorageService().saveUser(user);
    await OnboardingService.markOnboardingAsSeen();
    await OnboardingService.markGetStartedAsSeen();

    if (mounted) {
      context.push('/protein-calculation');
    }
  }

  int _calculateTargetCalories() {
    // Use the same calculation as the CalorieCalculationService for consistency
    double bmr;
    if (_data.gender == 'Male') {
      bmr = 10 * _data.weight + 6.25 * _data.height - 5 * _data.age + 5;
    } else {
      bmr = 10 * _data.weight + 6.25 * _data.height - 5 * _data.age - 161;
    }

    // Activity level multipliers matching CalorieCalculationService
    double activityMultiplier;
    switch (_data.selectedActivityLevel) {
      case ActivityLevel.sedentary:
        activityMultiplier = 1.2;
        break;
      case ActivityLevel.lightlyActive:
        activityMultiplier = 1.35; // Updated to match service
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

    // Goal adjustments matching CalorieCalculationService
    switch (_data.selectedFitnessGoal) {
      case FitnessGoal.weightLoss:
        tdee -= 500; // 500 kcal deficit for 0.5 kg/week loss
        break;
      case FitnessGoal.weightGain:
        tdee += 500; // 500 kcal surplus for weight gain
        break;
      case FitnessGoal.muscleGain:
        tdee += 300; // 300 kcal surplus for moderate gain
        break;
      case FitnessGoal.maintenance:
        // No adjustment
        break;
      case FitnessGoal.endurance:
        tdee += 200; // 200 kcal surplus for performance
        break;
      case FitnessGoal.strength:
        tdee += 400; // 400 kcal surplus for strength training
        break;
    }

    // Apply safety rails
    final minSafe = _calculateMinSafeCalories(bmr, _data.gender);
    return tdee.clamp(minSafe, tdee * 1.5).round();
  }

  /// Calculate minimum safe calories (85% of BMR or gender-specific minimum)
  double _calculateMinSafeCalories(double bmr, String gender) {
    final rmrFloor = bmr * 0.85;
    final genderFloor = gender.toLowerCase() == 'male' ? 1500.0 : 1200.0;
    return rmrFloor.clamp(genderFloor, double.infinity);
  }
}
