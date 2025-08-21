import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
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
    // Insert BMI step after age (index 4)
    _steps.insert(4, OnboardingStepsConfig.getBMIStep());
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
      body: SafeArea(
        child: Column(
          children: [
            OnboardingProgressIndicator(
              steps: _steps,
              currentPage: _currentPage,
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
                  return OnboardingStepPage(
                    step: _steps[index],
                    stepIndex: index,
                    content: OnboardingStepBuilder.buildStepContent(
                      stepIndex: index,
                      data: _data,
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
                            if (_data.selectedDietaryRestrictions.contains(restriction)) {
                              _data.selectedDietaryRestrictions.remove(restriction);
                            } else {
                              _data.selectedDietaryRestrictions.add(restriction);
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
                        if (cuisine.isNotEmpty && !_data.preferredCuisines.contains(cuisine)) {
                          setState(() => _data.preferredCuisines.add(cuisine));
                        }
                      },
                      onRemoveCuisine: (cuisine) {
                        setState(() => _data.preferredCuisines.remove(cuisine));
                      },
                      onAddAvoid: (food) {
                        if (food.isNotEmpty && !_data.foodsToAvoid.contains(food)) {
                          setState(() => _data.foodsToAvoid.add(food));
                        }
                      },
                      onRemoveAvoid: (food) {
                        setState(() => _data.foodsToAvoid.remove(food));
                      },
                      onAddFavorite: (food) {
                        if (food.isNotEmpty && !_data.favoriteFoods.contains(food)) {
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
                      onTimeChanged: (time) {
                        setState(() {
                          _data.workoutNotificationTime = time ?? const TimeOfDay(hour: 9, minute: 0);
                        });
                      },
                      onNotificationsChanged: (enabled) {
                        setState(() {
                          _data.workoutNotificationsEnabled = enabled;
                        });
                      },
                      onSkip: () {
                        _completeOnboarding();
                      },
                      onEnable: () async {
                        final permissionResult = await NotificationService.requestNotificationPermission();
                        if (permissionResult.isGranted) {
                          setState(() {
                            _data.workoutNotificationsEnabled = true;
                          });
                          await NotificationService.showTestNotification();
                        }
                        _completeOnboarding();
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
                HapticFeedback.mediumImpact();
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              onNext: () {
                HapticFeedback.mediumImpact();
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              onComplete: _completeOnboarding,
            ),
          ],
        ),
      ),
    );
  }

  ScrollPhysics _getPageViewPhysics() {
    if (_currentPage == 5 && _data.selectedDietaryRestrictions.isEmpty) {
      return const NeverScrollableScrollPhysics();
    }
    if (_currentPage == 8 && _data.selectedWorkoutStyles.isEmpty) {
      return const NeverScrollableScrollPhysics();
    }
    return const BouncingScrollPhysics();
  }

  bool _isNextEnabled() {
    final isDietaryStep = _currentPage == 7;
    final isWorkoutStep = _currentPage == 8;
    final isWeeklyWorkoutGoalStep = _currentPage == 9;
    final isFoodPreferencesStep = _currentPage == 10;
    final isAllergiesStep = _currentPage == 11;
    final isWorkoutNotificationsStep = _currentPage == 14;

    if (!isDietaryStep && !isWorkoutStep && !isWeeklyWorkoutGoalStep && 
        !isFoodPreferencesStep && !isAllergiesStep && !isWorkoutNotificationsStep) {
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

    final allergiesJson = _data.selectedAllergies.map((allergy) => allergy.toJson()).toList();
    final mealTimingJson = _data.mealTimingPreferences?.toJson();
    final batchCookingJson = _data.batchCookingPreferences?.toJson();

    final preferences = UserPreferences(
      fitnessGoal: _data.selectedFitnessGoal,
      activityLevel: _data.selectedActivityLevel,
      dietaryRestrictions: List<String>.from(_data.selectedDietaryRestrictions),
      preferredWorkoutStyles: List<String>.from(_data.selectedWorkoutStyles),
      targetCalories: _calculateTargetCalories(),
      workoutNotificationsEnabled: _data.workoutNotificationsEnabled,
      workoutNotificationTime: '${_data.workoutNotificationTime.hour.toString().padLeft(2, '0')}:${_data.workoutNotificationTime.minute.toString().padLeft(2, '0')}',
      weeklyWorkoutDays: _data.weeklyWorkoutDays,
      specificWorkoutDays: _data.specificWorkoutDays,
      age: _data.age,
      weight: _data.weight,
      height: _data.height,
      gender: _data.gender,
      preferredCuisines: List<String>.from(_data.preferredCuisines),
      foodsToAvoid: List<String>.from(_data.foodsToAvoid),
      favoriteFoods: List<String>.from(_data.favoriteFoods),
      allergies: allergiesJson,
      mealTimingPreferences: mealTimingJson,
      batchCookingPreferences: batchCookingJson,
    );

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
    double bmr;
    if (_data.gender == 'Male') {
      bmr = 10 * _data.weight + 6.25 * _data.height - 5 * _data.age + 5;
    } else {
      bmr = 10 * _data.weight + 6.25 * _data.height - 5 * _data.age - 161;
    }

    double activityMultiplier;
    switch (_data.selectedActivityLevel) {
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

    switch (_data.selectedFitnessGoal) {
      case FitnessGoal.weightLoss:
        tdee -= 500;
        break;
      case FitnessGoal.muscleGain:
        tdee += 300;
        break;
      case FitnessGoal.maintenance:
        break;
      case FitnessGoal.endurance:
        tdee += 200;
        break;
      case FitnessGoal.strength:
        tdee += 250;
        break;
    }

    return tdee.round();
  }
}
