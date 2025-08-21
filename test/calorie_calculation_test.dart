import 'package:flutter_test/flutter_test.dart';
import '../lib/shared/models/user_model.dart';
import '../lib/shared/services/calorie_calculation_service.dart';

void main() {
  group('CalorieCalculationService Tests', () {
    test('Mifflin-St Jeor BMR calculation for male', () {
      // Test case: Male, 30 years old, 80kg, 180cm
      // Expected BMR = 10 × 80 + 6.25 × 180 - 5 × 30 + 5 = 800 + 1125 - 150 + 5 = 1780
      final user = _createTestUser(
        age: 30,
        weight: 80.0,
        height: 180.0,
        gender: 'Male',
        activityLevel: ActivityLevel.moderatelyActive,
        fitnessGoal: FitnessGoal.maintenance,
      );

      final targets = CalorieCalculationService.calculateCalorieTargets(user);
      
      // BMR should be approximately 1780 kcal
      expect(targets.rmr, closeTo(1780, 10));
    });

    test('Mifflin-St Jeor BMR calculation for female', () {
      // Test case: Female, 25 years old, 65kg, 165cm
      // Expected BMR = 10 × 65 + 6.25 × 165 - 5 × 25 - 161 = 650 + 1031.25 - 125 - 161 = 1395.25
      final user = _createTestUser(
        age: 25,
        weight: 65.0,
        height: 165.0,
        gender: 'Female',
        activityLevel: ActivityLevel.moderatelyActive,
        fitnessGoal: FitnessGoal.maintenance,
      );

      final targets = CalorieCalculationService.calculateCalorieTargets(user);
      
      // BMR should be approximately 1395 kcal
      expect(targets.rmr, closeTo(1395, 10));
    });

    test('TDEE calculation with activity multipliers', () {
      final user = _createTestUser(
        age: 30,
        weight: 80.0,
        height: 180.0,
        gender: 'Male',
        activityLevel: ActivityLevel.moderatelyActive,
        fitnessGoal: FitnessGoal.maintenance,
      );

      final targets = CalorieCalculationService.calculateCalorieTargets(user);
      
      // TDEE should be BMR × 1.55 for moderately active
      final expectedTDEE = targets.rmr * 1.55;
      expect(targets.tdee, closeTo(expectedTDEE, 10));
    });

    test('Weight loss goal adjustment', () {
      final user = _createTestUser(
        age: 30,
        weight: 80.0,
        height: 180.0,
        gender: 'Male',
        activityLevel: ActivityLevel.moderatelyActive,
        fitnessGoal: FitnessGoal.weightLoss,
      );

      final targets = CalorieCalculationService.calculateCalorieTargets(user);
      
      // Daily target should be TDEE - 500 for weight loss
      expect(targets.dailyTarget, closeTo(targets.tdee - 500, 10));
    });

    test('Muscle gain goal adjustment', () {
      final user = _createTestUser(
        age: 30,
        weight: 80.0,
        height: 180.0,
        gender: 'Male',
        activityLevel: ActivityLevel.moderatelyActive,
        fitnessGoal: FitnessGoal.muscleGain,
      );

      final targets = CalorieCalculationService.calculateCalorieTargets(user);
      
      // Daily target should be TDEE + 300 for muscle gain
      expect(targets.dailyTarget, closeTo(targets.tdee + 300, 10));
    });

    test('Macro calculations follow 4-4-9 kcal/g rule', () {
      final user = _createTestUser(
        age: 30,
        weight: 80.0,
        height: 180.0,
        gender: 'Male',
        activityLevel: ActivityLevel.moderatelyActive,
        fitnessGoal: FitnessGoal.maintenance,
      );

      final targets = CalorieCalculationService.calculateCalorieTargets(user);
      final macros = targets.macros;
      
      // Verify protein calories = grams × 4 (allow for rounding)
      expect(macros.protein.calories, closeTo(macros.protein.grams * 4, 1));
      
      // Verify carb calories = grams × 4 (allow for rounding)
      expect(macros.carbs.calories, closeTo(macros.carbs.grams * 4, 1));
      
      // Verify fat calories = grams × 9 (allow for rounding)
      expect(macros.fat.calories, closeTo(macros.fat.grams * 9, 5));
      
      // Verify total macro calories equal daily target (allow for small rounding differences)
      final totalMacroCalories = macros.protein.calories + macros.carbs.calories + macros.fat.calories;
      expect(totalMacroCalories, closeTo(targets.dailyTarget, 5));
    });

    test('Macro percentages sum to 100%', () {
      final user = _createTestUser(
        age: 30,
        weight: 80.0,
        height: 180.0,
        gender: 'Male',
        activityLevel: ActivityLevel.moderatelyActive,
        fitnessGoal: FitnessGoal.maintenance,
      );

      final targets = CalorieCalculationService.calculateCalorieTargets(user);
      final macros = targets.macros;
      
      final totalPercentage = macros.protein.percentage + macros.carbs.percentage + macros.fat.percentage;
      expect(totalPercentage, closeTo(100, 1)); // Allow 1% tolerance for rounding
    });

    test('Minimum safe calories are enforced', () {
      final user = _createTestUser(
        age: 30,
        weight: 50.0, // Low weight
        height: 160.0,
        gender: 'Female',
        activityLevel: ActivityLevel.sedentary,
        fitnessGoal: FitnessGoal.weightLoss,
      );

      final targets = CalorieCalculationService.calculateCalorieTargets(user);
      
      // Should not go below minimum safe calories (1200 for females)
      expect(targets.dailyTarget, greaterThanOrEqualTo(1200));
    });

    test('Protein targets are appropriate for fitness goals', () {
      // Test weight loss (should have higher protein)
      final weightLossUser = _createTestUser(
        age: 30,
        weight: 80.0,
        height: 180.0,
        gender: 'Male',
        activityLevel: ActivityLevel.moderatelyActive,
        fitnessGoal: FitnessGoal.weightLoss,
      );

      final weightLossTargets = CalorieCalculationService.calculateCalorieTargets(weightLossUser);
      final weightLossProtein = weightLossTargets.macros.protein.grams;
      
      // Should be around 2.2g/kg for weight loss
      expect(weightLossProtein, closeTo(80 * 2.2, 20));

      // Test muscle gain (should have moderate protein)
      final muscleGainUser = _createTestUser(
        age: 30,
        weight: 80.0,
        height: 180.0,
        gender: 'Male',
        activityLevel: ActivityLevel.moderatelyActive,
        fitnessGoal: FitnessGoal.muscleGain,
      );

      final muscleGainTargets = CalorieCalculationService.calculateCalorieTargets(muscleGainUser);
      final muscleGainProtein = muscleGainTargets.macros.protein.grams;
      
      // Should be around 1.6g/kg for muscle gain
      expect(muscleGainProtein, closeTo(80 * 1.6, 20));
    });
  });
}

UserModel _createTestUser({
  required int age,
  required double weight,
  required double height,
  required String gender,
  required ActivityLevel activityLevel,
  required FitnessGoal fitnessGoal,
}) {
  final preferences = UserPreferences(
    fitnessGoal: fitnessGoal,
    activityLevel: activityLevel,
    dietaryRestrictions: [],
    preferredWorkoutStyles: [],
    targetCalories: 2000,
    age: age,
    weight: weight,
    height: height,
    gender: gender,
  );

  return UserModel(
    id: 'test-user',
    email: 'test@example.com',
    preferences: preferences,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
