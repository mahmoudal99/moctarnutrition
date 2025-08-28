import 'package:logger/logger.dart';
import '../models/user_model.dart';

class CalorieCalculationService {
  static final _logger = Logger();

  // Activity level multipliers (PAL - Physical Activity Level)
  static const Map<ActivityLevel, double> _activityMultipliers = {
    ActivityLevel.sedentary: 1.2,
    ActivityLevel.lightlyActive: 1.35,
    ActivityLevel.moderatelyActive:
        1.55, // Updated to match standard 1.55 for moderate activity
    ActivityLevel.veryActive:
        1.725, // Updated to match standard 1.725 for very active
    ActivityLevel.extremelyActive: 1.9,
  };

  static CalorieTargets calculateCalorieTargets(UserModel user) {
    final preferences = user.preferences;
    final weight = preferences.weight; // in kg
    final height = preferences.height; // in cm
    final age = preferences.age;
    final gender = preferences.gender;
    final fitnessGoal = preferences.fitnessGoal;
    final activityLevel = preferences.activityLevel;

    // Calculate BMR using Mifflin-St Jeor equation
    final bmr = _calculateBMR(weight, height, age, gender);

    // Calculate TDEE (Total Daily Energy Expenditure)
    final tdee = _calculateTDEE(bmr, activityLevel);

    // Apply goal adjustments
    final dailyTarget =
        _applyGoalAdjustments(tdee, bmr, fitnessGoal, weight, gender);

    // Calculate macronutrient breakdown using standard ratios
    final macros = _calculateMacros(dailyTarget, preferences);

    return CalorieTargets(
      rmr: bmr.round(),
      tdee: tdee.round(),
      dailyTarget: dailyTarget.round(),
      fitnessGoal: _getFitnessGoalName(fitnessGoal),
      activityLevel: _getActivityLevelName(activityLevel),
      bodyFatPercentage:
          _estimateBodyFatPercentage(weight, height, age, gender),
      fatFreeMass: weight *
          (1 - _estimateBodyFatPercentage(weight, height, age, gender) / 100),
      macros: macros,
      recommendations: _getRecommendations(fitnessGoal, preferences),
    );
  }

  /// Calculate BMR using the Mifflin-St Jeor equation
  /// For men: BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age(y) + 5
  /// For women: BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age(y) - 161
  static double _calculateBMR(
      double weight, double height, int age, String gender) {
    final base = 10 * weight + 6.25 * height - 5 * age;
    return gender.toLowerCase() == 'male' ? base + 5 : base - 161;
  }

  /// Calculate TDEE by multiplying BMR by activity factor
  static double _calculateTDEE(double bmr, ActivityLevel activityLevel) {
    return bmr * _activityMultipliers[activityLevel]!;
  }

  /// Apply goal adjustments to TDEE
  static double _applyGoalAdjustments(double tdee, double bmr,
      FitnessGoal fitnessGoal, double weight, String gender) {
    double targetCalories = tdee;

    switch (fitnessGoal) {
      case FitnessGoal.weightLoss:
        // Weight loss: subtract 500 kcal/day for 0.5 kg/week loss
        // This creates a 3500 kcal weekly deficit (500 * 7 = 3500 kcal)
        // 7700 kcal ≈ 1 kg fat, so 3500 kcal ≈ 0.5 kg fat loss per week
        targetCalories = tdee - 500;
        break;

      case FitnessGoal.muscleGain:
        // Muscle gain: add 300-500 kcal surplus
        // Start with 300 kcal surplus for moderate gain
        targetCalories = tdee + 300;
        break;

      case FitnessGoal.maintenance:
        // Maintenance: no adjustment
        targetCalories = tdee;
        break;

      case FitnessGoal.endurance:
        // Endurance: slight surplus for performance
        targetCalories = tdee + 200; // 200 kcal surplus
        break;

      case FitnessGoal.strength:
        // Strength: moderate surplus for muscle building
        targetCalories = tdee + 400; // 400 kcal surplus
        break;
    }

    // Safety rails - ensure minimum safe calories
    final minSafe = _calculateMinSafeCalories(bmr, gender);
    return targetCalories.clamp(minSafe, tdee * 1.5); // Cap at 50% surplus
  }

  /// Calculate minimum safe calories (85% of BMR or gender-specific minimum)
  static double _calculateMinSafeCalories(double bmr, String gender) {
    final rmrFloor = bmr * 0.85;
    final genderFloor = gender.toLowerCase() == 'male' ? 1500.0 : 1200.0;
    return rmrFloor.clamp(genderFloor, double.infinity);
  }

  /// Calculate macronutrient breakdown using standard ratios
  /// Default: 40% protein, 40% carbs, 20% fat
  /// Protein: 4 kcal/g, Carbs: 4 kcal/g, Fat: 9 kcal/g
  static MacroBreakdown _calculateMacros(
      double dailyCalories, UserPreferences preferences) {
    final weight = preferences.weight;
    final fitnessGoal = preferences.fitnessGoal;
    final dietaryRestrictions = preferences.dietaryRestrictions;
    final isVegan = dietaryRestrictions.contains('Vegan');

    // Calculate protein first (priority macro)
    final proteinGrams = _calculateProteinGrams(weight, fitnessGoal, isVegan);
    final proteinCalories = proteinGrams * 4; // 4 kcal per gram

    // Calculate fat (minimum 20% of calories, maximum 35%)
    const minFatPercentage = 0.20;
    const maxFatPercentage = 0.35;
    const targetFatPercentage = 0.25; // Default to 25% (middle of range)

    final minFatCalories = dailyCalories * minFatPercentage;
    final maxFatCalories = dailyCalories * maxFatPercentage;
    final targetFatCalories = dailyCalories * targetFatPercentage;

    // Ensure minimum fat grams (0.6 g/kg body weight)
    final minFatGrams = weight * 0.6;
    final minFatCaloriesFromWeight = minFatGrams * 9;

    final fatCalories = targetFatCalories.clamp(
        minFatCalories.clamp(minFatCaloriesFromWeight, maxFatCalories),
        maxFatCalories);
    final fatGrams = fatCalories / 9; // 9 kcal per gram

    // Calculate carbs from remaining calories
    final remainingCalories = dailyCalories - proteinCalories - fatCalories;
    final carbGrams = remainingCalories / 4; // 4 kcal per gram
    final carbCalories = carbGrams * 4;

    // Ensure minimum carb intake (130g for brain function)
    const minCarbGrams = 130.0;
    if (carbGrams < minCarbGrams) {
      // Adjust fat down to accommodate minimum carbs
      // ignore: prefer_const_declarations
      final adjustedCarbGrams = minCarbGrams;
      final adjustedCarbCalories = adjustedCarbGrams * 4;
      final adjustedFatCalories =
          dailyCalories - proteinCalories - adjustedCarbCalories;
      final adjustedFatGrams = adjustedFatCalories / 9;

      return MacroBreakdown(
        protein: MacroNutrient(
          grams: proteinGrams.round(),
          calories: proteinCalories.round(),
          percentage: ((proteinCalories / dailyCalories) * 100).round(),
        ),
        fat: MacroNutrient(
          grams: adjustedFatGrams.round(),
          calories: adjustedFatCalories.round(),
          percentage: ((adjustedFatCalories / dailyCalories) * 100).round(),
        ),
        carbs: MacroNutrient(
          grams: adjustedCarbGrams.round(),
          calories: adjustedCarbCalories.round(),
          percentage: ((adjustedCarbCalories / dailyCalories) * 100).round(),
        ),
      );
    }

    return MacroBreakdown(
      protein: MacroNutrient(
        grams: proteinGrams.round(),
        calories: proteinCalories.round(),
        percentage: ((proteinCalories / dailyCalories) * 100).round(),
      ),
      fat: MacroNutrient(
        grams: fatGrams.round(),
        calories: fatCalories.round(),
        percentage: ((fatCalories / dailyCalories) * 100).round(),
      ),
      carbs: MacroNutrient(
        grams: carbGrams.round(),
        calories: carbCalories.round(),
        percentage: ((carbCalories / dailyCalories) * 100).round(),
      ),
    );
  }

  /// Calculate protein grams based on body weight and fitness goal
  /// Using evidence-based recommendations
  static double _calculateProteinGrams(
      double weight, FitnessGoal fitnessGoal, bool isVegan) {
    double proteinPerKg;

    switch (fitnessGoal) {
      case FitnessGoal.muscleGain:
        proteinPerKg = isVegan
            ? 2.0
            : 1.6; // Higher for vegans due to lower bioavailability
        break;
      case FitnessGoal.weightLoss:
        proteinPerKg = isVegan ? 2.4 : 2.2; // Higher to preserve muscle mass
        break;
      case FitnessGoal.maintenance:
        proteinPerKg = isVegan ? 1.8 : 1.4; // Standard recommendations
        break;
      case FitnessGoal.endurance:
        proteinPerKg = isVegan ? 1.6 : 1.3; // Moderate protein for endurance
        break;
      case FitnessGoal.strength:
        proteinPerKg = isVegan ? 2.0 : 1.7; // Higher for strength training
        break;
    }

    return weight * proteinPerKg;
  }

  /// Estimate body fat percentage based on BMI, age, and gender
  static double _estimateBodyFatPercentage(
      double weight, double height, int age, String gender) {
    final bmi = weight / ((height / 100) * (height / 100));
    double baseBodyFat;

    if (gender.toLowerCase() == 'male') {
      if (bmi < 18.5) {
        baseBodyFat = 8.0; // Underweight
      } else if (bmi < 25) {
        baseBodyFat = 15.0; // Normal weight
      } else if (bmi < 30) {
        baseBodyFat = 25.0; // Overweight
      } else {
        baseBodyFat = 35.0; // Obese
      }
    } else {
      if (bmi < 18.5) {
        baseBodyFat = 15.0; // Underweight
      } else if (bmi < 25) {
        baseBodyFat = 25.0; // Normal weight
      } else if (bmi < 30) {
        baseBodyFat = 35.0; // Overweight
      } else {
        baseBodyFat = 45.0; // Obese
      }
    }

    // Adjust for age
    if (age > 50) {
      baseBodyFat += 2.0;
    } else if (age > 30) {
      baseBodyFat += 1.0;
    }

    return baseBodyFat;
  }

  static String _getFitnessGoalName(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return 'Fat Loss';
      case FitnessGoal.muscleGain:
        return 'Muscle Growth';
      case FitnessGoal.maintenance:
        return 'Maintenance';
      case FitnessGoal.endurance:
        return 'Endurance';
      case FitnessGoal.strength:
        return 'Strength';
    }
  }

  static String _getActivityLevelName(ActivityLevel level) {
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

  static List<String> _getRecommendations(
      FitnessGoal fitnessGoal, UserPreferences preferences) {
    final recommendations = <String>[];
    final isVegan = preferences.dietaryRestrictions.contains('Vegan');
    final workoutStyles = preferences.preferredWorkoutStyles;
    final mealTiming = preferences.mealTimingPreferences;
    final batchCooking = preferences.batchCookingPreferences;

    // Add goal-specific recommendations
    switch (fitnessGoal) {
      case FitnessGoal.weightLoss:
        recommendations.addAll([
          'Create a sustainable calorie deficit of 10-25%',
          'Prioritize protein to preserve muscle mass',
          'Include regular strength training',
          'Monitor weight changes weekly',
          'Adjust calories based on progress',
        ]);
        if (isVegan) {
          recommendations.add('Ensure adequate protein from plant sources');
        }
        break;

      case FitnessGoal.muscleGain:
        recommendations.addAll([
          'Consume a moderate calorie surplus (5-15%)',
          'Prioritize protein timing around workouts',
          'Include progressive strength training',
          'Get adequate sleep for recovery',
          'Monitor body composition changes',
        ]);
        if (isVegan) {
          recommendations.add(
              'Consider leucine supplementation for muscle protein synthesis');
        }
        break;

      case FitnessGoal.maintenance:
        recommendations.addAll([
          'Maintain consistent calorie intake',
          'Focus on nutrient-dense foods',
          'Include regular physical activity',
          'Monitor weight trends monthly',
        ]);
        break;

      case FitnessGoal.endurance:
        recommendations.addAll([
          'Slight calorie surplus for performance',
          'Prioritize carbohydrates for fuel',
          'Include protein for recovery',
          'Stay hydrated during training',
        ]);
        break;

      case FitnessGoal.strength:
        recommendations.addAll([
          'Moderate calorie surplus for strength gains',
          'High protein intake for muscle building',
          'Progressive overload in training',
          'Adequate rest between sessions',
        ]);
        break;
    }

    // Add workout style specific recommendations
    if (workoutStyles.isNotEmpty) {
      if (workoutStyles.contains('Strength Training')) {
        recommendations
            .add('Time protein intake around strength training sessions');
      }
      if (workoutStyles.contains('Cardio')) {
        recommendations.add('Include carbohydrates before cardio sessions');
      }
      if (workoutStyles.contains('Yoga')) {
        recommendations.add('Focus on anti-inflammatory foods for recovery');
      }
      if (workoutStyles.contains('HIIT')) {
        recommendations.add('Ensure adequate hydration and electrolytes');
      }
    }

    // Add meal timing specific recommendations
    if (mealTiming != null) {
      final mealFrequency = mealTiming['mealFrequency'] as String?;
      if (mealFrequency == 'intermittentFasting') {
        recommendations
            .add('Focus on nutrient-dense foods during eating windows');
        recommendations.add('Stay hydrated during fasting periods');
      } else if (mealFrequency == 'fiveMeals' ||
          mealFrequency == 'fiveMealsOneSnack') {
        recommendations.add('Keep meal sizes moderate to avoid overeating');
      }
    }

    // Add batch cooking specific recommendations
    if (batchCooking != null) {
      final frequency = batchCooking['frequency'] as String?;
      final batchSize = batchCooking['batchSize'] as String?;
      final preferLeftovers = batchCooking['preferLeftovers'] as bool? ?? true;

      if (frequency == 'weekly') {
        recommendations
            .add('Plan weekly meal prep to meet your targets consistently');
      }
      if (batchSize == 'weeklyPrep') {
        recommendations.add('Portion meals appropriately to avoid overeating');
      }
      if (!preferLeftovers) {
        recommendations.add('Focus on fresh meal preparation strategies');
      }
    }

    // Add dietary restriction specific recommendations
    if (preferences.dietaryRestrictions.isNotEmpty) {
      if (preferences.dietaryRestrictions.contains('Gluten-Free')) {
        recommendations
            .add('Choose gluten-free whole grains for carbohydrates');
      }
      if (preferences.dietaryRestrictions.contains('Dairy-Free')) {
        recommendations.add('Include alternative calcium sources');
      }
      if (preferences.dietaryRestrictions.contains('Vegetarian')) {
        recommendations
            .add('Combine plant proteins for complete amino acid profiles');
      }
    }

    return recommendations;
  }
}

class CalorieTargets {
  final int rmr;
  final int tdee;
  final int dailyTarget;
  final String fitnessGoal;
  final String activityLevel;
  final double bodyFatPercentage;
  final double fatFreeMass;
  final MacroBreakdown macros;
  final List<String> recommendations;

  CalorieTargets({
    required this.rmr,
    required this.tdee,
    required this.dailyTarget,
    required this.fitnessGoal,
    required this.activityLevel,
    required this.bodyFatPercentage,
    required this.fatFreeMass,
    required this.macros,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() {
    return {
      'rmr': rmr,
      'tdee': tdee,
      'dailyTarget': dailyTarget,
      'fitnessGoal': fitnessGoal,
      'activityLevel': activityLevel,
      'bodyFatPercentage': bodyFatPercentage,
      'fatFreeMass': fatFreeMass,
      'macros': macros.toJson(),
      'recommendations': recommendations,
    };
  }

  factory CalorieTargets.fromJson(Map<String, dynamic> json) {
    return CalorieTargets(
      rmr: json['rmr'] as int,
      tdee: json['tdee'] as int,
      dailyTarget: json['dailyTarget'] as int,
      fitnessGoal: json['fitnessGoal'] as String,
      activityLevel: json['activityLevel'] as String,
      bodyFatPercentage: json['bodyFatPercentage'] as double,
      fatFreeMass: json['fatFreeMass'] as double,
      macros: MacroBreakdown.fromJson(json['macros']),
      recommendations: List<String>.from(json['recommendations']),
    );
  }
}

class MacroBreakdown {
  final MacroNutrient protein;
  final MacroNutrient fat;
  final MacroNutrient carbs;

  MacroBreakdown({
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  Map<String, dynamic> toJson() {
    return {
      'protein': protein.toJson(),
      'fat': fat.toJson(),
      'carbs': carbs.toJson(),
    };
  }

  factory MacroBreakdown.fromJson(Map<String, dynamic> json) {
    return MacroBreakdown(
      protein: MacroNutrient.fromJson(json['protein']),
      fat: MacroNutrient.fromJson(json['fat']),
      carbs: MacroNutrient.fromJson(json['carbs']),
    );
  }
}

class MacroNutrient {
  final int grams;
  final int calories;
  final int percentage;

  MacroNutrient({
    required this.grams,
    required this.calories,
    required this.percentage,
  });

  Map<String, dynamic> toJson() {
    return {
      'grams': grams,
      'calories': calories,
      'percentage': percentage,
    };
  }

  factory MacroNutrient.fromJson(Map<String, dynamic> json) {
    return MacroNutrient(
      grams: json['grams'] as int,
      calories: json['calories'] as int,
      percentage: json['percentage'] as int,
    );
  }
}
