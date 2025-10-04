import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/models/user_model.dart';
import '../steps/onboarding_welcome_step.dart';
import '../steps/onboarding_gender_step.dart';
import '../steps/onboarding_height_weight_step.dart';
import '../steps/onboarding_age_step.dart';
import '../steps/onboarding_desired_weight_step.dart';
import '../steps/onboarding_bmi_step.dart';
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

class OnboardingStepBuilder {
  static Widget buildStepContent({
    required int stepIndex,
    required OnboardingData data,
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
    required Function(TimeOfDay?) onTimeChanged,
    required Function(bool) onNotificationsChanged,
    required VoidCallback onComplete,
  }) {
    switch (stepIndex) {
      case 0:
        return const OnboardingWelcomeStep();
      case 1:
        return OnboardingGenderStep(
          selectedGender: data.gender,
          onSelect: (gender) {
            HapticFeedback.lightImpact();
            data.gender = gender;
          },
        );
      case 2:
        return OnboardingHeightWeightStep(
          height: data.height,
          weight: data.weight,
          onHeightChanged: (height) => data.height = height,
          onWeightChanged: (weight) => data.weight = weight,
        );
      case 3:
        return OnboardingAgeStep(
          age: data.age,
          onAgeChanged: (age) => data.age = age,
        );
      case 4:
        return OnboardingDesiredWeightStep(
          desiredWeight: data.desiredWeight,
          onDesiredWeightChanged: (weight) => data.desiredWeight = weight,
        );
      case 5:
        return OnboardingBMIStep(
          bmi: _calculateBMI(data.height, data.weight),
          bmiCategory: _getBMICategory(_calculateBMI(data.height, data.weight)),
          bmiColor: _getBMIColor(
              _getBMICategory(_calculateBMI(data.height, data.weight))),
          height: data.height,
          weight: data.weight,
        );
      case 6:
        return OnboardingFitnessGoalStep(
          selectedFitnessGoal: data.selectedFitnessGoal,
          onSelect: onFitnessGoalChanged,
        );
      case 7:
        return OnboardingActivityLevelStep(
          selectedActivityLevel: data.selectedActivityLevel,
          onSelect: onActivityLevelChanged,
        );
      case 8:
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
      case 9:
        return OnboardingWorkoutStylesStep(
          selectedWorkoutStyles: data.selectedWorkoutStyles,
          styles: const [
            'Strength Training',
            'Cardio',
            'HIIT',
            'Running',
          ],
          onSelect: onWorkoutStyleChanged,
        );
      case 10:
        return OnboardingWeeklyWorkoutGoalStep(
          selectedDaysPerWeek: data.weeklyWorkoutDays,
          selectedSpecificDays: data.specificWorkoutDays,
          onDaysPerWeekChanged: onWeeklyWorkoutDaysChanged,
          onSpecificDaysChanged: onSpecificWorkoutDaysChanged,
        );
      case 11:
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
      case 12:
        return OnboardingAllergiesStep(
          selectedAllergies: data.selectedAllergies,
          onAllergiesChanged: onAllergiesChanged,
        );
      case 13:
        return OnboardingMealTimingStep(
          selectedPreferences: data.mealTimingPreferences,
          onPreferencesChanged: onMealTimingChanged,
        );
      case 14:
        return OnboardingBatchCookingStep(
          selectedPreferences: data.batchCookingPreferences,
          onPreferencesChanged: onBatchCookingChanged,
        );
      case 15:
        return OnboardingWorkoutNotificationsStep(
          selectedTime: data.workoutNotificationTime,
          notificationsEnabled: data.workoutNotificationsEnabled,
          onTimeChanged: onTimeChanged,
          onNotificationsChanged: onNotificationsChanged,
        );
      case 16:
        return OnboardingRatingStep(
          onContinue: onComplete,
        );
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
