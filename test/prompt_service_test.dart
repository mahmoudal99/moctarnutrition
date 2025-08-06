import 'package:flutter_test/flutter_test.dart';
import 'package:champions_gym_app/shared/services/prompt_service.dart';
import 'package:champions_gym_app/shared/models/user_model.dart';

void main() {
  group('PromptService Cheat Day Tests', () {
    test('should include cheat day instructions when day matches cheat day', () {
      // Create preferences with Saturday as cheat day
      final preferences = DietPlanPreferences(
        age: 25,
        gender: 'Male',
        weight: 70.0,
        height: 175.0,
        fitnessGoal: FitnessGoal.weightLoss,
        activityLevel: ActivityLevel.moderatelyActive,
        dietaryRestrictions: [],
        preferredWorkoutStyles: [],
        nutritionGoal: 'Weight Loss',
        preferredCuisines: ['Italian'],
        foodsToAvoid: [],
        favoriteFoods: ['Pizza'],
        mealFrequency: '3',
        cheatDay: 'Saturday',
        weeklyRotation: true,
        remindersEnabled: false,
        targetCalories: 2000,
      );

      // Mock current date to be a Saturday
      final saturdayDate = DateTime(2024, 1, 6); // This was a Saturday
      
      // Generate prompt for day 1 (which would be Saturday if today is Saturday)
      final prompt = PromptService.buildSingleDayPrompt(preferences, 1);
      
      // Check that cheat day instructions are included
      expect(prompt, contains('CURRENT DAY IS CHEAT DAY'));
      expect(prompt, contains('CHEAT DAY INSTRUCTIONS'));
      expect(prompt, contains('Saturday'));
      expect(prompt, contains('indulgent meals'));
      expect(prompt, contains('favorite foods'));
    });

    test('should not include cheat day instructions when day does not match cheat day', () {
      // Create preferences with Saturday as cheat day
      final preferences = DietPlanPreferences(
        age: 25,
        gender: 'Male',
        weight: 70.0,
        height: 175.0,
        fitnessGoal: FitnessGoal.weightLoss,
        activityLevel: ActivityLevel.moderatelyActive,
        dietaryRestrictions: [],
        preferredWorkoutStyles: [],
        nutritionGoal: 'Weight Loss',
        preferredCuisines: ['Italian'],
        foodsToAvoid: [],
        favoriteFoods: ['Pizza'],
        mealFrequency: '3',
        cheatDay: 'Saturday',
        weeklyRotation: true,
        remindersEnabled: false,
        targetCalories: 2000,
      );

      // Mock current date to be a Monday
      final mondayDate = DateTime(2024, 1, 1); // This was a Monday
      
      // Generate prompt for day 1 (which would be Monday if today is Monday)
      final prompt = PromptService.buildSingleDayPrompt(preferences, 1);
      
      // Check that cheat day instructions are NOT included
      expect(prompt, isNot(contains('CURRENT DAY IS CHEAT DAY')));
      expect(prompt, isNot(contains('CHEAT DAY INSTRUCTIONS')));
      expect(prompt, isNot(contains('indulgent meals')));
    });

    test('should not include cheat day instructions when no cheat day is set', () {
      // Create preferences with no cheat day
      final preferences = DietPlanPreferences(
        age: 25,
        gender: 'Male',
        weight: 70.0,
        height: 175.0,
        fitnessGoal: FitnessGoal.weightLoss,
        activityLevel: ActivityLevel.moderatelyActive,
        dietaryRestrictions: [],
        preferredWorkoutStyles: [],
        nutritionGoal: 'Weight Loss',
        preferredCuisines: ['Italian'],
        foodsToAvoid: [],
        favoriteFoods: ['Pizza'],
        mealFrequency: '3',
        cheatDay: null, // No cheat day
        weeklyRotation: true,
        remindersEnabled: false,
        targetCalories: 2000,
      );

      // Generate prompt for any day
      final prompt = PromptService.buildSingleDayPrompt(preferences, 1);
      
      // Check that cheat day instructions are NOT included
      expect(prompt, isNot(contains('CURRENT DAY IS CHEAT DAY')));
      expect(prompt, isNot(contains('CHEAT DAY INSTRUCTIONS')));
      expect(prompt, contains('Cheat Day: None'));
    });

    test('should correctly identify different days of the week', () {
      // Test all days of the week
      final testDates = [
        DateTime(2024, 1, 1), // Monday
        DateTime(2024, 1, 2), // Tuesday
        DateTime(2024, 1, 3), // Wednesday
        DateTime(2024, 1, 4), // Thursday
        DateTime(2024, 1, 5), // Friday
        DateTime(2024, 1, 6), // Saturday
        DateTime(2024, 1, 7), // Sunday
      ];

      final expectedDays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];

      for (int i = 0; i < testDates.length; i++) {
        final dayOfWeek = PromptService._getDayOfWeek(testDates[i]);
        expect(dayOfWeek, equals(expectedDays[i]));
      }
    });
  });
} 