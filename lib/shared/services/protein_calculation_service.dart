import 'package:logger/logger.dart';
import '../models/user_model.dart';

class ProteinCalculationService {
  static final _logger = Logger();

  static ProteinTargets calculateProteinTargets(UserModel user) {
    final preferences = user.preferences;
    final weight = preferences.weight; // in kg
    final height = preferences.height; // in cm
    final age = preferences.age;
    final gender = preferences.gender;
    final fitnessGoal = preferences.fitnessGoal;
    final dietaryRestrictions = preferences.dietaryRestrictions;
    final workoutStyles = preferences.preferredWorkoutStyles;
    final mealTiming = preferences.mealTimingPreferences;
    final batchCooking = preferences.batchCookingPreferences;

    // Calculate body fat percentage (rough estimate using BMI)
    final bmi = weight / ((height / 100) * (height / 100));
    final bodyFatPercentage = _estimateBodyFatPercentage(bmi, age, gender);

    // Calculate lean body mass (LBM)
    final leanBodyMass = weight * (1 - bodyFatPercentage / 100);

    // Determine if user is vegan
    final isVegan = dietaryRestrictions.contains('Vegan');

    // Calculate protein targets based on fitness goal
    ProteinTargets targets;

    switch (fitnessGoal) {
      case FitnessGoal.muscleGain:
        targets = _calculateMuscleGrowthTargets(
            weight, leanBodyMass, bodyFatPercentage, isVegan, preferences);
        break;
      case FitnessGoal.weightLoss:
        targets = _calculateFatLossTargets(
            weight, leanBodyMass, bodyFatPercentage, isVegan, preferences);
        break;
      case FitnessGoal.maintenance:
        targets = _calculateMaintenanceTargets(
            weight, leanBodyMass, bodyFatPercentage, isVegan, preferences);
        break;
      case FitnessGoal.endurance:
        targets = _calculateEnduranceTargets(
            weight, leanBodyMass, bodyFatPercentage, isVegan, preferences);
        break;
      case FitnessGoal.strength:
        targets = _calculateStrengthTargets(
            weight, leanBodyMass, bodyFatPercentage, isVegan, preferences);
        break;
    }

    // Calculate meal distribution
    final mealDistribution = _calculateMealDistribution(targets, preferences);

    return targets.copyWith(mealDistribution: mealDistribution);
  }

  static double _estimateBodyFatPercentage(double bmi, int age, String gender) {
    // Rough estimation based on BMI, age, and gender
    // This is a simplified calculation - in a real app, you might want to use more accurate methods

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

  static ProteinTargets _calculateMuscleGrowthTargets(
      double weight,
      double leanBodyMass,
      double bodyFatPercentage,
      bool isVegan,
      UserPreferences preferences) {
    double proteinPerKg;
    String weightBase;
    double baseWeight;

    // Use LBM if body fat is high (>25%)
    if (bodyFatPercentage > 25) {
      proteinPerKg = isVegan ? 2.2 : 1.8; // Higher end for vegans
      weightBase = 'lean body mass';
      baseWeight = leanBodyMass;
    } else {
      proteinPerKg = isVegan ? 2.0 : 1.6; // Standard range
      weightBase = 'total body weight';
      baseWeight = weight;
    }

    final dailyProtein = baseWeight * proteinPerKg;
    final proteinPerLb = proteinPerKg * 0.453592; // Convert g/kg to g/lb

    return ProteinTargets(
      dailyTarget: dailyProtein.round(),
      proteinPerKg: proteinPerKg,
      proteinPerLb: proteinPerLb,
      weightBase: weightBase,
      baseWeight: baseWeight,
      fitnessGoal: 'Muscle Growth',
      recommendations:
          _getEnhancedMuscleGrowthRecommendations(isVegan, preferences),
    );
  }

  static ProteinTargets _calculateFatLossTargets(
      double weight,
      double leanBodyMass,
      double bodyFatPercentage,
      bool isVegan,
      UserPreferences preferences) {
    double proteinPerKg;
    String weightBase;
    double baseWeight;

    // Use goal weight or LBM if overweight
    if (bodyFatPercentage > 25) {
      // Estimate goal weight (assuming 15% body fat for men, 25% for women)
      final targetBodyFat = 20.0; // Average target
      final goalWeight = leanBodyMass / (1 - targetBodyFat / 100);
      proteinPerKg = isVegan ? 2.5 : 2.2;
      weightBase = 'goal weight';
      baseWeight = goalWeight;
    } else {
      proteinPerKg = isVegan ? 2.4 : 2.2;
      weightBase = 'total body weight';
      baseWeight = weight;
    }

    final dailyProtein = baseWeight * proteinPerKg;
    final proteinPerLb = proteinPerKg * 0.453592; // Convert g/kg to g/lb

    return ProteinTargets(
      dailyTarget: dailyProtein.round(),
      proteinPerKg: proteinPerKg,
      proteinPerLb: proteinPerLb,
      weightBase: weightBase,
      baseWeight: baseWeight,
      fitnessGoal: 'Fat Loss',
      recommendations: _getEnhancedFatLossRecommendations(isVegan, preferences),
    );
  }

  static ProteinTargets _calculateMaintenanceTargets(
      double weight,
      double leanBodyMass,
      double bodyFatPercentage,
      bool isVegan,
      UserPreferences preferences) {
    // Similar to muscle growth but slightly lower
    final proteinPerKg = isVegan ? 1.8 : 1.4;
    final dailyProtein = weight * proteinPerKg;
    final proteinPerLb = proteinPerKg * 0.453592; // Convert g/kg to g/lb

    return ProteinTargets(
      dailyTarget: dailyProtein.round(),
      proteinPerKg: proteinPerKg,
      proteinPerLb: proteinPerLb,
      weightBase: 'total body weight',
      baseWeight: weight,
      fitnessGoal: 'Maintenance',
      recommendations:
          _getEnhancedMaintenanceRecommendations(isVegan, preferences),
    );
  }

  static ProteinTargets _calculateEnduranceTargets(
      double weight,
      double leanBodyMass,
      double bodyFatPercentage,
      bool isVegan,
      UserPreferences preferences) {
    // Endurance athletes need moderate protein
    final proteinPerKg = isVegan ? 1.6 : 1.3;
    final dailyProtein = weight * proteinPerKg;
    final proteinPerLb = proteinPerKg * 0.453592; // Convert g/kg to g/lb

    return ProteinTargets(
      dailyTarget: dailyProtein.round(),
      proteinPerKg: proteinPerKg,
      proteinPerLb: proteinPerLb,
      weightBase: 'total body weight',
      baseWeight: weight,
      fitnessGoal: 'Endurance',
      recommendations:
          _getEnhancedEnduranceRecommendations(isVegan, preferences),
    );
  }

  static ProteinTargets _calculateStrengthTargets(
      double weight,
      double leanBodyMass,
      double bodyFatPercentage,
      bool isVegan,
      UserPreferences preferences) {
    // Strength athletes need higher protein
    final proteinPerKg = isVegan ? 2.0 : 1.7;
    final dailyProtein = weight * proteinPerKg;
    final proteinPerLb = proteinPerKg * 0.453592; // Convert g/kg to g/lb

    return ProteinTargets(
      dailyTarget: dailyProtein.round(),
      proteinPerKg: proteinPerKg,
      proteinPerLb: proteinPerLb,
      weightBase: 'total body weight',
      baseWeight: weight,
      fitnessGoal: 'Strength',
      recommendations:
          _getEnhancedStrengthRecommendations(isVegan, preferences),
    );
  }

  static List<String> _getEnhancedMuscleGrowthRecommendations(
      bool isVegan, UserPreferences preferences) {
    final baseRecommendations = [
      'Spread protein over 3-5 meals (20-40g per meal)',
      'Consume protein within 2 hours after workouts',
      'Include protein in every meal and snack',
    ];

    if (isVegan) {
      baseRecommendations.addAll([
        'Aim for higher end of protein range due to lower digestibility',
        'Combine complementary proteins (legumes + grains)',
        'Consider leucine supplementation for muscle protein synthesis',
        'Prioritize high-quality plant proteins: soy, seitan, legumes',
      ]);
    } else {
      baseRecommendations.addAll([
        'Include lean animal proteins: chicken, fish, eggs, dairy',
        'Consider whey protein for post-workout recovery',
      ]);
    }

    // Add workout style specific recommendations
    if (preferences.preferredWorkoutStyles.isNotEmpty) {
      if (preferences.preferredWorkoutStyles.contains('Strength Training')) {
        baseRecommendations.add(
            'Prioritize protein intake within 30 minutes after strength training');
      }
      if (preferences.preferredWorkoutStyles.contains('HIIT')) {
        baseRecommendations.add(
            'Include fast-digesting protein after high-intensity sessions');
      }
    }

    // Add meal timing specific recommendations
    if (preferences.mealTimingPreferences != null) {
      final mealFrequency =
          preferences.mealTimingPreferences!['mealFrequency'] as String?;
      if (mealFrequency == 'intermittentFasting') {
        baseRecommendations.add(
            'Focus protein intake during eating windows for muscle synthesis');
      }
    }

    // Add batch cooking specific recommendations
    if (preferences.batchCookingPreferences != null) {
      final frequency =
          preferences.batchCookingPreferences!['frequency'] as String?;
      if (frequency == 'weekly') {
        baseRecommendations
            .add('Prep protein-rich meals weekly to ensure consistent intake');
      }
    }

    return baseRecommendations;
  }

  static List<String> _getEnhancedFatLossRecommendations(
      bool isVegan, UserPreferences preferences) {
    final baseRecommendations = [
      'Spread protein over 4-5 meals to preserve muscle and reduce hunger',
      'Consume protein with every meal to maintain satiety',
      'Prioritize protein over carbs in meals',
    ];

    if (isVegan) {
      baseRecommendations.addAll([
        'Higher protein targets help compensate for lower digestibility',
        'Include protein-rich snacks: nuts, seeds, edamame',
        'Use plant protein powders to meet daily targets',
      ]);
    } else {
      baseRecommendations.addAll([
        'Choose lean protein sources to minimize calorie intake',
        'Include protein in breakfast to control hunger throughout the day',
      ]);
    }

    // Add meal timing specific recommendations
    if (preferences.mealTimingPreferences != null) {
      final mealFrequency =
          preferences.mealTimingPreferences!['mealFrequency'] as String?;
      if (mealFrequency == 'intermittentFasting') {
        baseRecommendations
            .add('Focus on high-protein meals during eating windows');
      } else if (mealFrequency == 'fiveMeals' ||
          mealFrequency == 'fiveMealsOneSnack') {
        baseRecommendations
            .add('Keep protein portions moderate across frequent meals');
      }
    }

    // Add batch cooking specific recommendations
    if (preferences.batchCookingPreferences != null) {
      final preferLeftovers =
          preferences.batchCookingPreferences!['preferLeftovers'] as bool? ??
              true;
      if (!preferLeftovers) {
        baseRecommendations
            .add('Focus on fresh protein sources for optimal satiety');
      }
    }

    return baseRecommendations;
  }

  static List<String> _getEnhancedMaintenanceRecommendations(
      bool isVegan, UserPreferences preferences) {
    final baseRecommendations = [
      'Maintain consistent protein intake across meals',
      'Focus on whole food protein sources',
    ];

    if (isVegan) {
      baseRecommendations.addAll([
        'Ensure variety in plant protein sources',
        'Include protein in most meals',
      ]);
    }

    // Add meal timing specific recommendations
    if (preferences.mealTimingPreferences != null) {
      final mealFrequency =
          preferences.mealTimingPreferences!['mealFrequency'] as String?;
      if (mealFrequency == 'intermittentFasting') {
        baseRecommendations
            .add('Distribute protein evenly across eating windows');
      }
    }

    return baseRecommendations;
  }

  static List<String> _getEnhancedEnduranceRecommendations(
      bool isVegan, UserPreferences preferences) {
    final baseRecommendations = [
      'Moderate protein needs for endurance training',
      'Focus on timing protein around workouts',
      'Balance protein with adequate carbohydrates',
    ];

    if (isVegan) {
      baseRecommendations.addAll([
        'Include protein in recovery meals',
        'Choose easily digestible plant proteins post-workout',
      ]);
    }

    // Add workout style specific recommendations
    if (preferences.preferredWorkoutStyles.isNotEmpty) {
      if (preferences.preferredWorkoutStyles.contains('Cardio')) {
        baseRecommendations
            .add('Include protein in post-cardio recovery meals');
      }
      if (preferences.preferredWorkoutStyles.contains('Running')) {
        baseRecommendations
            .add('Prioritize protein within 30 minutes after long runs');
      }
    }

    return baseRecommendations;
  }

  static List<String> _getEnhancedStrengthRecommendations(
      bool isVegan, UserPreferences preferences) {
    final baseRecommendations = [
      'Higher protein needs for strength training',
      'Consume protein within 1-2 hours after strength workouts',
      'Include protein in pre-workout meals',
    ];

    if (isVegan) {
      baseRecommendations.addAll([
        'Consider timing plant protein intake around workouts',
        'Use protein powders to meet higher targets',
      ]);
    }

    // Add workout style specific recommendations
    if (preferences.preferredWorkoutStyles.isNotEmpty) {
      if (preferences.preferredWorkoutStyles.contains('Strength Training')) {
        baseRecommendations.add(
            'Prioritize protein within 30 minutes after strength sessions');
      }
      if (preferences.preferredWorkoutStyles.contains('Weightlifting')) {
        baseRecommendations
            .add('Include protein in both pre and post-workout meals');
      }
    }

    // Add meal timing specific recommendations
    if (preferences.mealTimingPreferences != null) {
      final mealFrequency =
          preferences.mealTimingPreferences!['mealFrequency'] as String?;
      if (mealFrequency == 'intermittentFasting') {
        baseRecommendations
            .add('Time eating windows around strength training sessions');
      }
    }

    return baseRecommendations;
  }

  static List<MealProteinDistribution> _calculateMealDistribution(
      ProteinTargets targets, UserPreferences preferences) {
    final dailyProtein = targets.dailyTarget;
    final mealTiming = preferences.mealTimingPreferences;
    final batchCooking = preferences.batchCookingPreferences;

    // Determine number of meals based on meal timing preferences
    int numberOfMeals = 4; // Default

    if (mealTiming != null) {
      final mealFrequency = mealTiming['mealFrequency'] as String?;
      switch (mealFrequency) {
        case 'threeMeals':
          numberOfMeals = 3;
          break;
        case 'threeMealsOneSnack':
          numberOfMeals = 4;
          break;
        case 'fourMeals':
          numberOfMeals = 4;
          break;
        case 'fourMealsOneSnack':
          numberOfMeals = 5;
          break;
        case 'fiveMeals':
          numberOfMeals = 5;
          break;
        case 'fiveMealsOneSnack':
          numberOfMeals = 6;
          break;
        case 'intermittentFasting':
          numberOfMeals = 2; // Eating window meals
          break;
        default:
          numberOfMeals = 4;
      }
    }

    // Adjust protein distribution based on meal timing and batch cooking preferences
    final distribution = <MealProteinDistribution>[];
    double remainingProtein = dailyProtein.toDouble();

    for (int i = 0; i < numberOfMeals; i++) {
      String mealName;
      int proteinTarget;

      // Determine meal name based on timing preferences
      if (mealTiming != null) {
        final mealFrequency = mealTiming['mealFrequency'] as String?;
        if (mealFrequency == 'intermittentFasting') {
          mealName = i == 0 ? 'First Meal' : 'Second Meal';
        } else {
          switch (i) {
            case 0:
              mealName = 'Breakfast';
              break;
            case 1:
              mealName = 'Lunch';
              break;
            case 2:
              mealName = 'Dinner';
              break;
            case 3:
              mealName = numberOfMeals == 4 ? 'Snack' : 'Snack 1';
              break;
            case 4:
              mealName = 'Snack 2';
              break;
            case 5:
              mealName = 'Snack 3';
              break;
            default:
              mealName = 'Meal ${i + 1}';
          }
        }
      } else {
        switch (i) {
          case 0:
            mealName = 'Breakfast';
            break;
          case 1:
            mealName = 'Lunch';
            break;
          case 2:
            mealName = 'Dinner';
            break;
          case 3:
            mealName = numberOfMeals == 4 ? 'Snack' : 'Snack 1';
            break;
          case 4:
            mealName = 'Snack 2';
            break;
          case 5:
            mealName = 'Snack 3';
            break;
          default:
            mealName = 'Meal ${i + 1}';
        }
      }

      // Calculate protein target for this meal
      if (i == numberOfMeals - 1) {
        // Last meal gets remaining protein
        proteinTarget = remainingProtein.round();
      } else {
        // Distribute protein based on meal type and batch cooking preferences
        double baseProtein = dailyProtein / numberOfMeals;

        // Adjust for main meals vs snacks
        if (mealName.toLowerCase().contains('snack')) {
          proteinTarget =
              (baseProtein * 0.6).round(); // Snacks get less protein
        } else if (mealName.toLowerCase().contains('breakfast')) {
          proteinTarget =
              (baseProtein * 0.8).round(); // Breakfast slightly less
        } else {
          proteinTarget = (baseProtein * 1.1).round(); // Lunch/Dinner get more
        }

        // Ensure minimum protein per meal (20g for main meals, 10g for snacks)
        final minProtein = mealName.toLowerCase().contains('snack') ? 10 : 20;
        proteinTarget =
            proteinTarget.clamp(minProtein, (remainingProtein * 0.4).round());
      }

      remainingProtein -= proteinTarget;

      distribution.add(MealProteinDistribution(
        mealName: mealName,
        proteinTarget: proteinTarget,
        mealNumber: i + 1,
      ));
    }

    return distribution;
  }
}

class ProteinTargets {
  final int dailyTarget;
  final double proteinPerKg;
  final double proteinPerLb;
  final String weightBase;
  final double baseWeight;
  final String fitnessGoal;
  final List<String> recommendations;
  final List<MealProteinDistribution>? mealDistribution;

  ProteinTargets({
    required this.dailyTarget,
    required this.proteinPerKg,
    required this.proteinPerLb,
    required this.weightBase,
    required this.baseWeight,
    required this.fitnessGoal,
    required this.recommendations,
    this.mealDistribution,
  });

  ProteinTargets copyWith({
    int? dailyTarget,
    double? proteinPerKg,
    double? proteinPerLb,
    String? weightBase,
    double? baseWeight,
    String? fitnessGoal,
    List<String>? recommendations,
    List<MealProteinDistribution>? mealDistribution,
  }) {
    return ProteinTargets(
      dailyTarget: dailyTarget ?? this.dailyTarget,
      proteinPerKg: proteinPerKg ?? this.proteinPerKg,
      proteinPerLb: proteinPerLb ?? this.proteinPerLb,
      weightBase: weightBase ?? this.weightBase,
      baseWeight: baseWeight ?? this.baseWeight,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      recommendations: recommendations ?? this.recommendations,
      mealDistribution: mealDistribution ?? this.mealDistribution,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyTarget': dailyTarget,
      'proteinPerKg': proteinPerKg,
      'proteinPerLb': proteinPerLb,
      'weightBase': weightBase,
      'baseWeight': baseWeight,
      'fitnessGoal': fitnessGoal,
      'recommendations': recommendations,
      'mealDistribution': mealDistribution?.map((m) => m.toJson()).toList(),
    };
  }

  factory ProteinTargets.fromJson(Map<String, dynamic> json) {
    return ProteinTargets(
      dailyTarget: json['dailyTarget'] as int,
      proteinPerKg: json['proteinPerKg'] as double,
      proteinPerLb: json['proteinPerLb'] as double,
      weightBase: json['weightBase'] as String,
      baseWeight: json['baseWeight'] as double,
      fitnessGoal: json['fitnessGoal'] as String,
      recommendations: List<String>.from(json['recommendations']),
      mealDistribution: json['mealDistribution'] != null
          ? (json['mealDistribution'] as List)
              .map((m) => MealProteinDistribution.fromJson(m))
              .toList()
          : null,
    );
  }
}

class MealProteinDistribution {
  final String mealName;
  final int proteinTarget;
  final int mealNumber;

  MealProteinDistribution({
    required this.mealName,
    required this.proteinTarget,
    required this.mealNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'mealName': mealName,
      'proteinTarget': proteinTarget,
      'mealNumber': mealNumber,
    };
  }

  factory MealProteinDistribution.fromJson(Map<String, dynamic> json) {
    return MealProteinDistribution(
      mealName: json['mealName'] as String,
      proteinTarget: json['proteinTarget'] as int,
      mealNumber: json['mealNumber'] as int,
    );
  }
}
