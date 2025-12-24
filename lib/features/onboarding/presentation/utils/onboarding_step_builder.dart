import 'package:champions_gym_app/features/onboarding/presentation/steps/onboarding_intro_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/models/user_model.dart';
import '../steps/onboarding_new_first_step.dart';
import '../steps/onboarding_bodybuilding_goal_step.dart';
import '../steps/onboarding_welcome_step.dart';
import '../steps/onboarding_generic_fitness_intro_step.dart';
import '../steps/onboarding_gender_step.dart';
import '../steps/onboarding_height_weight_step.dart';
import '../steps/onboarding_age_step.dart';
import '../steps/onboarding_desired_weight_step.dart';
import '../steps/onboarding_bmi_step.dart';
import '../steps/onboarding_how_we_do_this_step.dart';
import '../steps/onboarding_fitness_goal_step.dart';
import '../steps/onboarding_activity_level_step.dart';
import '../steps/onboarding_dietary_restrictions_step.dart';
import '../steps/onboarding_workout_styles_step.dart';
import '../steps/onboarding_weekly_workout_goal_step.dart';
import '../steps/onboarding_food_preferences_step.dart';
import '../steps/onboarding_allergies_step.dart';
import '../steps/onboarding_meal_timing_step.dart';
import '../steps/onboarding_batch_cooking_step.dart';
import '../steps/onboarding_workout_notifications_step.dart';
import '../steps/onboarding_rating_step.dart';
import '../steps/onboarding_cheat_day_step.dart';

class OnboardingStepBuilder {
  /// Maps the actual step index to the content builder case.
  /// When bodybuilder is true, an additional step (bodybuilding goal) is inserted at index 1,
  /// and workout styles step (case 13) is skipped.
  /// When bodybuilder is false, the bodybuilding goal step (case 1) and intro step (case 2) are skipped.
  /// 
  /// For non-bodybuilders, after removing bodybuilding goal step at index 1:
  /// - Step 0 → case 0 (bodybuilder question)
  /// - Step 1 → case 1 (generic fitness intro, replaces bodybuilding goal)
  /// - Step 2 → case 3 (welcome, skip case 2 which is bodybuilder intro)
  /// - Step 3 → case 4 (gender)
  /// - Step 4 → case 5 (height/weight)
  /// - Step 5 → case 6 (age)
  /// - Step 6 → case 7 (BMI)
  /// - Step 7 → case 8 (how we do this)
  /// - Step 8 → case 9 (fitness goal)
  /// - Step 9 → case 10 (desired weight)
  /// - Step 10 → case 11 (activity level)
  /// - Step 11 → case 12 (dietary restrictions)
  /// - Step 12 → case 13 (workout styles)
  /// - Step 13 → case 14 (weekly workout goal)
  /// - etc.
  static int _mapStepIndexToContentCase(int stepIndex, bool isBodybuilder) {
    if (isBodybuilder == true) {
      // Bodybuilding goal step is inserted at index 1
      if (stepIndex == 1) {
        return 1; // Bodybuilding goal step
      } else if (stepIndex > 1) {
        // After bodybuilding goal, shift by 1 for the intro step
        // Then skip workout styles (case 13), shift by additional 1
        if (stepIndex > 12) {
          return stepIndex + 1; // Skip workout styles
        }
        return stepIndex;
      }
    } else {
      // For non-bodybuilders:
      // - Step 0 → case 0
      // - Step 1 → case 1 (generic fitness intro)
      // - Steps 2+ → skip case 2 (bodybuilder intro), so shift by 1
      if (stepIndex == 0) {
        return 0;
      } else if (stepIndex == 1) {
        return 1; // Generic fitness intro
      } else {
        // Skip case 2 (bodybuilder intro), so shift by 1
        return stepIndex + 1;
      }
    }
    return stepIndex;
  }

  /// Maps step title to content case for non-bodybuilders
  /// This is more reliable than using step indices which can shift
  static int _mapStepTitleToContentCase(String stepTitle, bool isBodybuilder) {
    if (isBodybuilder) {
      // For bodybuilders, use index-based mapping (existing logic)
      return -1; // Not used for bodybuilders
    }
    
    // Map step titles to content cases for non-bodybuilders
    switch (stepTitle) {
      case 'Are you a bodybuilder?':
        return 0;
      case 'Hi, I\'m Regimen 👋':
        return 1; // Generic fitness intro for non-bodybuilders
      case 'Welcome to Regimen!':
        return 3;
      case 'Start with You':
        return 4;
      case 'Height & Weight':
        return 5;
      case 'Your Age':
        return 6;
      case 'Your BMI':
        return 7;
      case 'Fun & heatlhy meals':
        return 8;
      case 'What is your primary objective?':
        return 9;
      case 'Desired Weight':
        return 10;
      case 'How active are you?':
        return 11;
      case 'Any dietary restrictions?':
        return 12;
      case 'Preferred workout styles':
        return 13;
      case 'Weekly Workout Goal':
        return 14;
      case 'Food preferences':
        return 15;
      case 'Allergies & Intolerances':
        return 16;
      case 'Meal Count & Timing':
        return 17;
      case 'Batch Cooking Preferences':
        return 18;
      case 'Cheat Day':
        return 19;
      case 'Workout Previews':
        return 20;
      case 'Help Us Grow!':
        return 21;
      default:
        return -1; // Fallback to index-based mapping
    }
  }

  static Widget buildStepContent({
    required int stepIndex,
    required String stepTitle,
    required OnboardingData data,
    required Function(bool) onBodybuilderChanged,
    required Function(BodybuildingGoal) onBodybuildingGoalChanged,
    required Function(FitnessGoal) onFitnessGoalChanged,
    required Function(ActivityLevel) onActivityLevelChanged,
    required Function(String) onDietaryRestrictionChanged,
    required Function(String) onWorkoutStyleChanged,
    required Function(int) onWeeklyWorkoutDaysChanged,
    required Function(List<int>) onSpecificWorkoutDaysChanged,
    required Function(String) onAddCuisine,
    required Function(String) onRemoveCuisine,
    required Function(String) onAddAvoid,
    required Function(String) onRemoveAvoid,
    required Function(String) onAddFavorite,
    required Function(String) onRemoveFavorite,
    required Function(List<AllergyItem>) onAllergiesChanged,
    required Function(MealTimingPreferences?) onMealTimingChanged,
    required Function(BatchCookingPreferences?) onBatchCookingChanged,
    required Function(String?) onCheatDayChanged,
    required Function(TimeOfDay?) onTimeChanged,
    required Function(bool) onNotificationsChanged,
    required VoidCallback onComplete,
  }) {
    // Map step index to content case (accounts for skipped workout styles step)
    // For non-bodybuilders, use step title mapping which is more reliable
    int contentCase;
    if (data.isBodybuilder == true) {
      contentCase = _mapStepIndexToContentCase(stepIndex, true);
    } else {
      final titleBasedCase = _mapStepTitleToContentCase(stepTitle, false);
      if (titleBasedCase != -1) {
        contentCase = titleBasedCase;
      } else {
        // Fallback to index-based mapping
        contentCase = _mapStepIndexToContentCase(stepIndex, false);
      }
    }

    switch (contentCase) {
      case 0:
        return OnboardingNewFirstStep(
          isBodybuilder: data.isBodybuilder,
          onSelect: onBodybuilderChanged,
        );
      case 1:
        // Show bodybuilding goal selection only for bodybuilders
        if (data.isBodybuilder == true) {
          return OnboardingBodybuildingGoalStep(
            selectedGoal: data.bodybuildingGoal,
            onSelect: onBodybuildingGoalChanged,
          );
        } else {
          // For non-bodybuilders, show generic fitness intro
          return const OnboardingGenericFitnessIntroStep();
        }
      case 2:
        // Show bodybuilder intro after goal selection
        if (data.isBodybuilder == true) {
          return const OnboardingIntroStep();
        } else {
          // This shouldn't be reached for non-bodybuilders
          return const SizedBox.shrink();
        }
      case 3:
        return OnboardingWelcomeStep(
          isBodybuilder: data.isBodybuilder,
        );
      case 4:
        return OnboardingGenderStep(
          selectedGender: data.gender,
          onSelect: (gender) {
            HapticFeedback.lightImpact();
            data.gender = gender;
          },
        );
      case 5:
        return OnboardingHeightWeightStep(
          height: data.height,
          weight: data.weight,
          onHeightChanged: (height) => data.height = height,
          onWeightChanged: (weight) => data.weight = weight,
        );
      case 6:
        return OnboardingAgeStep(
          age: data.age,
          onAgeChanged: (age) => data.age = age,
        );
      case 7:
        return OnboardingBMIStep(
          bmi: _calculateBMI(data.height, data.weight),
          bmiCategory: _getBMICategory(_calculateBMI(data.height, data.weight)),
          bmiColor: _getBMIColor(
              _getBMICategory(_calculateBMI(data.height, data.weight))),
          height: data.height,
          weight: data.weight,
        );
      case 8:
        return const OnboardingHowWeDoThisStep();
      case 9:
        return OnboardingFitnessGoalStep(
          selectedFitnessGoal: data.selectedFitnessGoal,
          onSelect: onFitnessGoalChanged,
        );
      case 10:
        return OnboardingDesiredWeightStep(
          desiredWeight: data.desiredWeight,
          currentWeight: data.weight,
          fitnessGoal: data.selectedFitnessGoal,
          onDesiredWeightChanged: (weight) => data.desiredWeight = weight,
        );
      case 11:
        return OnboardingActivityLevelStep(
          selectedActivityLevel: data.selectedActivityLevel,
          onSelect: onActivityLevelChanged,
        );
      case 12:
        return OnboardingDietaryRestrictionsStep(
          selectedDietaryRestrictions: data.selectedDietaryRestrictions,
          restrictions: const [
            'Vegetarian',
            'Vegan',
            'Gluten-Free',
            'Dairy-Free',
            'Keto',
            'Paleo',
            'Low-Carb',
            'None',
          ],
          onSelect: onDietaryRestrictionChanged,
        );
      case 13:
        return OnboardingWorkoutStylesStep(
          selectedWorkoutStyles: data.selectedWorkoutStyles,
          styles: const [
            'Strength Training',
            'Cardio',
            'HIIT',
            'Running',
            'Boxing',
            'Swimming',
            'Bodyweight',
            'Walking',
          ],
          onSelect: onWorkoutStyleChanged,
        );
      case 14:
        return OnboardingWeeklyWorkoutGoalStep(
          selectedDaysPerWeek: data.weeklyWorkoutDays,
          selectedSpecificDays: data.specificWorkoutDays,
          onDaysPerWeekChanged: onWeeklyWorkoutDaysChanged,
          onSpecificDaysChanged: onSpecificWorkoutDaysChanged,
        );
      case 15:
        return OnboardingFoodPreferencesStep(
          preferredCuisines: data.preferredCuisines,
          onAddCuisine: onAddCuisine,
          onRemoveCuisine: onRemoveCuisine,
          foodsToAvoid: data.foodsToAvoid,
          onAddAvoid: onAddAvoid,
          onRemoveAvoid: onRemoveAvoid,
          favoriteFoods: data.favoriteFoods,
          onAddFavorite: onAddFavorite,
          onRemoveFavorite: onRemoveFavorite,
          cuisineController: data.cuisineController,
          avoidController: data.avoidController,
          favoriteController: data.favoriteController,
        );
      case 16:
        return OnboardingAllergiesStep(
          selectedAllergies: data.selectedAllergies,
          onAllergiesChanged: onAllergiesChanged,
        );
      case 17:
        return OnboardingMealTimingStep(
          selectedPreferences: data.mealTimingPreferences,
          onPreferencesChanged: onMealTimingChanged,
        );
      case 18:
        return OnboardingBatchCookingStep(
          selectedPreferences: data.batchCookingPreferences,
          onPreferencesChanged: onBatchCookingChanged,
        );
      case 19:
        return OnboardingCheatDayStep(
          selectedCheatDay: data.cheatDay,
          onCheatDayChanged: onCheatDayChanged,
          isBodybuilder: data.isBodybuilder,
        );
      case 20:
        return OnboardingWorkoutNotificationsStep(
          selectedTime: data.workoutNotificationTime,
          notificationsEnabled: data.workoutNotificationsEnabled,
          onTimeChanged: onTimeChanged,
          onNotificationsChanged: onNotificationsChanged,
        );
      case 21:
        return const OnboardingRatingStep();
      default:
        return const SizedBox.shrink();
    }
  }

  static double _calculateBMI(double height, double weight) {
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  static String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  static Color _getBMIColor(String category) {
    switch (category) {
      case 'Underweight':
        return const Color(0xFFFFA726); // warning color
      case 'Normal':
        return const Color(0xFF66BB6A); // success color
      case 'Overweight':
        return const Color(0xFFFFA726); // warning color
      case 'Obese':
        return const Color(0xFFEF5350); // error color
      default:
        return const Color(0xFF9E9E9E); // text secondary
    }
  }
}

class OnboardingData {
  bool? isBodybuilder;
  BodybuildingGoal? bodybuildingGoal;
  FitnessGoal selectedFitnessGoal = FitnessGoal.maintenance;
  ActivityLevel selectedActivityLevel = ActivityLevel.moderatelyActive;
  List<String> selectedDietaryRestrictions = [];
  List<String> selectedWorkoutStyles = [];
  List<String> preferredCuisines = [];
  List<String> foodsToAvoid = [];
  List<String> favoriteFoods = [];
  List<AllergyItem> selectedAllergies = [];
  MealTimingPreferences? mealTimingPreferences;
  BatchCookingPreferences? batchCookingPreferences;
  String? cheatDay; // e.g., "Monday"
  TimeOfDay workoutNotificationTime = const TimeOfDay(hour: 9, minute: 0);
  bool workoutNotificationsEnabled = false;
  int weeklyWorkoutDays = 3;
  List<int> specificWorkoutDays = [1, 3, 5];
  int age = 25;
  double weight = 70.0;
  double height = 170.0;
  double desiredWeight = 65.0;
  String gender = 'Male';
  TextEditingController cuisineController = TextEditingController();
  TextEditingController avoidController = TextEditingController();
  TextEditingController favoriteController = TextEditingController();
}
