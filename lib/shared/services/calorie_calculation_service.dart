import 'package:logger/logger.dart';
import '../models/user_model.dart';

class CalorieCalculationService {
  static final _logger = Logger();

  // Activity level multipliers (PAL - Physical Activity Level)
  static const Map<ActivityLevel, double> _activityMultipliers = {
    ActivityLevel.sedentary: 1.2,
    ActivityLevel.lightlyActive: 1.35,
    ActivityLevel.moderatelyActive: 1.5,
    ActivityLevel.veryActive: 1.7,
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
    
    // Calculate body fat percentage (rough estimate using BMI)
    final bmi = weight / ((height / 100) * (height / 100));
    final bodyFatPercentage = _estimateBodyFatPercentage(bmi, age, gender);
    
    // Calculate lean body mass (FFM - Fat Free Mass)
    final fatFreeMass = weight * (1 - bodyFatPercentage / 100);
    
    // Choose RMR equation based on body composition
    final rmr = _calculateRMR(weight, height, age, gender, fatFreeMass, bodyFatPercentage);
    
    // Calculate TDEE (Total Daily Energy Expenditure)
    final tdee = _calculateTDEE(rmr, activityLevel);
    
    // Apply goal adjustments
    final dailyTarget = _applyGoalAdjustments(tdee, rmr, fitnessGoal, weight, gender);
    
    // Calculate macronutrient breakdown
    final macros = _calculateMacros(dailyTarget, preferences);
    
    return CalorieTargets(
      rmr: rmr.round(),
      tdee: tdee.round(),
      dailyTarget: dailyTarget.round(),
      fitnessGoal: _getFitnessGoalName(fitnessGoal),
      activityLevel: _getActivityLevelName(activityLevel),
      bodyFatPercentage: bodyFatPercentage,
      fatFreeMass: fatFreeMass,
      macros: macros,
      recommendations: _getRecommendations(fitnessGoal, preferences),
    );
  }

  static double _estimateBodyFatPercentage(double bmi, int age, String gender) {
    // Rough estimation based on BMI, age, and gender
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

  static double _calculateRMR(double weight, double height, int age, String gender, double fatFreeMass, double bodyFatPercentage) {
    // Choose equation based on body composition
    // Use Katch-McArdle for high body fat or when we have FFM
    // Use Cunningham for athletes (could be enhanced with activity level detection)
    // Default to Mifflin-St Jeor for general population
    
    if (bodyFatPercentage > 25) {
      // High body fat - prefer Katch-McArdle
      return _rmrKatchMcArdle(fatFreeMass);
    } else if (_isAthlete(gender, age, weight, height)) {
      // Athlete - use Cunningham
      return _rmrCunningham(fatFreeMass);
    } else {
      // General population - use Mifflin-St Jeor
      return _rmrMifflinStJeor(weight, height, age, gender);
    }
  }

  static double _rmrMifflinStJeor(double weight, double height, int age, String gender) {
    // Mifflin-St Jeor Equation
    // Male: RMR = 10*kg + 6.25*cm - 5*age + 5
    // Female: RMR = 10*kg + 6.25*cm - 5*age - 161
    
    final base = 10 * weight + 6.25 * height - 5 * age;
    return gender.toLowerCase() == 'male' ? base + 5 : base - 161;
  }

  static double _rmrKatchMcArdle(double fatFreeMass) {
    // Katch-McArdle Equation
    // RMR = 370 + 21.6 * FFM_kg
    return 370 + 21.6 * fatFreeMass;
  }

  static double _rmrCunningham(double fatFreeMass) {
    // Cunningham Equation (for athletes)
    // RMR = 500 + 22 * FFM_kg
    return 500 + 22 * fatFreeMass;
  }

  static bool _isAthlete(String gender, int age, double weight, double height) {
    // Simple heuristic to identify potential athletes
    // This could be enhanced with actual activity data
    final bmi = weight / ((height / 100) * (height / 100));
    
    // Athletes typically have lower body fat and higher muscle mass
    return bmi >= 20 && bmi <= 28 && age >= 18 && age <= 45;
  }

  static double _calculateTDEE(double rmr, ActivityLevel activityLevel) {
    // TDEE = RMR * PAL (Physical Activity Level)
    return rmr * _activityMultipliers[activityLevel]!;
  }

  static double _applyGoalAdjustments(double tdee, double rmr, FitnessGoal fitnessGoal, double weight, String gender) {
    double targetCalories = tdee;
    
    switch (fitnessGoal) {
      case FitnessGoal.weightLoss:
        // Fat loss: subtract 10-25% of TDEE
        // 7,700 kcal ≈ 1 kg fat
        // Calculate deficit based on desired rate (default 0.5 kg/week)
        final weeklyRateKg = 0.5; // Could be made configurable
        final deficitByRate = 7700 * weeklyRateKg / 7; // kcal/day
        final deficitPercentage = (deficitByRate / tdee).clamp(0.10, 0.25);
        targetCalories = tdee * (1 - deficitPercentage);
        break;
        
      case FitnessGoal.muscleGain:
        // Muscle gain: add 5-15% (new lifters toward high end; advanced toward low)
        final surplusPercentage = 0.10; // Default 10%, could be configurable
        targetCalories = tdee * (1 + surplusPercentage);
        break;
        
      case FitnessGoal.maintenance:
        // Maintenance: no adjustment
        targetCalories = tdee;
        break;
        
      case FitnessGoal.endurance:
        // Endurance: slight surplus for performance
        targetCalories = tdee * 1.05; // 5% surplus
        break;
        
      case FitnessGoal.strength:
        // Strength: moderate surplus for muscle building
        targetCalories = tdee * 1.08; // 8% surplus
        break;
    }
    
    // Safety rails
    final minSafe = _calculateMinSafeCalories(rmr, gender);
    return targetCalories.clamp(minSafe, tdee * 1.5); // Cap at 50% surplus
  }

  static double _calculateMinSafeCalories(double rmr, String gender) {
    // Don't set below ~85-90% of RMR without medical oversight
    // Consider soft floors of ≥1,200 kcal (F) / ≥1,500 kcal (M) for general UX
    final rmrFloor = rmr * 0.85;
    final genderFloor = gender.toLowerCase() == 'male' ? 1500.0 : 1200.0;
    return rmrFloor.clamp(genderFloor, double.infinity);
  }

  static MacroBreakdown _calculateMacros(double dailyCalories, UserPreferences preferences) {
    final weight = preferences.weight;
    final dietaryRestrictions = preferences.dietaryRestrictions;
    final isVegan = dietaryRestrictions.contains('Vegan');
    
    // Protein calculation (from protein service)
    final proteinGrams = _calculateProteinGrams(weight, preferences.fitnessGoal, isVegan);
    final proteinCalories = proteinGrams * 4; // 4 kcal per gram
    
    // Fat calculation: ≥0.6 g/kg (health floor), then 20-35% of calories
    final minFatGrams = weight * 0.6;
    final maxFatPercentage = 0.35;
    final maxFatCalories = dailyCalories * maxFatPercentage;
    final maxFatGrams = maxFatCalories / 9; // 9 kcal per gram
    
    // Use 25% of calories for fat (middle of 20-35% range)
    final targetFatPercentage = 0.25;
    final targetFatCalories = dailyCalories * targetFatPercentage;
    final fatGrams = (targetFatCalories / 9).clamp(minFatGrams, maxFatGrams);
    final fatCalories = fatGrams * 9;
    
    // Carbs: rest of calories after protein + fat
    final remainingCalories = dailyCalories - proteinCalories - fatCalories;
    final carbGrams = remainingCalories / 4; // 4 kcal per gram
    final carbCalories = carbGrams * 4;
    
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

  static double _calculateProteinGrams(double weight, FitnessGoal fitnessGoal, bool isVegan) {
    // Simplified protein calculation (could use the full protein service)
    double proteinPerKg;
    
    switch (fitnessGoal) {
      case FitnessGoal.muscleGain:
        proteinPerKg = isVegan ? 2.0 : 1.6;
        break;
      case FitnessGoal.weightLoss:
        proteinPerKg = isVegan ? 2.4 : 2.2;
        break;
      case FitnessGoal.maintenance:
        proteinPerKg = isVegan ? 1.8 : 1.4;
        break;
      case FitnessGoal.endurance:
        proteinPerKg = isVegan ? 1.6 : 1.3;
        break;
      case FitnessGoal.strength:
        proteinPerKg = isVegan ? 2.0 : 1.7;
        break;
    }
    
    return weight * proteinPerKg;
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

  static List<String> _getRecommendations(FitnessGoal fitnessGoal, UserPreferences preferences) {
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
          recommendations.add('Consider leucine supplementation for muscle protein synthesis');
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
        recommendations.add('Time protein intake around strength training sessions');
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
        recommendations.add('Focus on nutrient-dense foods during eating windows');
        recommendations.add('Stay hydrated during fasting periods');
      } else if (mealFrequency == 'fiveMeals' || mealFrequency == 'fiveMealsOneSnack') {
        recommendations.add('Keep meal sizes moderate to avoid overeating');
      }
    }
    
    // Add batch cooking specific recommendations
    if (batchCooking != null) {
      final frequency = batchCooking['frequency'] as String?;
      final batchSize = batchCooking['batchSize'] as String?;
      final preferLeftovers = batchCooking['preferLeftovers'] as bool? ?? true;
      
      if (frequency == 'weekly') {
        recommendations.add('Plan weekly meal prep to meet your targets consistently');
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
        recommendations.add('Choose gluten-free whole grains for carbohydrates');
      }
      if (preferences.dietaryRestrictions.contains('Dairy-Free')) {
        recommendations.add('Include alternative calcium sources');
      }
      if (preferences.dietaryRestrictions.contains('Vegetarian')) {
        recommendations.add('Combine plant proteins for complete amino acid profiles');
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