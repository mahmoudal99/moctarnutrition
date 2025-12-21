import 'package:champions_gym_app/shared/services/calorie_calculation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { user, trainer, admin }

enum FitnessGoal { weightLoss, weightGain, muscleGain, maintenance, endurance, strength }

enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extremelyActive
}

enum TrainingProgramStatus { none, winter, summer, bodybuilding }

class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? phoneNumber;
  final String? photoUrl;
  final UserRole role;
  final TrainingProgramStatus trainingProgramStatus;
  final DateTime? programPurchaseDate;
  final String? currentProgramId; // Reference to the active training program document
  final UserPreferences preferences;
  final String? selectedTrainerId;
  // Reference to the user's current meal plan (Firestore best practice)
  final String? mealPlanId;
  final String? stripeCustomerId; // Stripe customer ID for subscription management
  final bool hasSeenSubscriptionScreen;
  final bool hasSeenOnboarding;
  final bool hasSeenGetStarted;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.phoneNumber,
    this.photoUrl,
    this.role = UserRole.user,
    this.trainingProgramStatus = TrainingProgramStatus.none,
    this.programPurchaseDate,
    this.currentProgramId,
    required this.preferences,
    this.selectedTrainerId,
    this.mealPlanId,
    this.stripeCustomerId,
    this.hasSeenSubscriptionScreen = false,
    this.hasSeenOnboarding = false,
    this.hasSeenGetStarted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      photoUrl: json['photoUrl'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.user,
      ),
      trainingProgramStatus: TrainingProgramStatus.values.firstWhere(
        (e) => e.name == json['trainingProgramStatus'],
        orElse: () => TrainingProgramStatus.none,
      ),
      programPurchaseDate: json['programPurchaseDate'] != null
          ? _extractDateTimeFromField(json['programPurchaseDate'])
          : null,
      currentProgramId: _extractStringFromField(json['currentProgramId']),
      preferences:
          UserPreferences.fromJson(json['preferences'] as Map<String, dynamic>),
      selectedTrainerId: _extractStringFromField(json['selectedTrainerId']),
      mealPlanId: _extractStringFromField(json['mealPlanId']),
      stripeCustomerId: _extractStringFromField(json['stripeCustomerId']),
      hasSeenSubscriptionScreen:
          json['hasSeenSubscriptionScreen'] as bool? ?? false,
      hasSeenOnboarding: json['hasSeenOnboarding'] as bool? ?? false,
      hasSeenGetStarted: json['hasSeenGetStarted'] as bool? ?? false,
      createdAt: _extractDateTimeFromField(json['createdAt']),
      updatedAt: _extractDateTimeFromField(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'role': role.toString().split('.').last,
      'trainingProgramStatus': trainingProgramStatus.toString().split('.').last,
      'programPurchaseDate': programPurchaseDate?.toIso8601String(),
      'currentProgramId': currentProgramId,
      'preferences': preferences.toJson(),
      'selectedTrainerId': selectedTrainerId,
      'mealPlanId': mealPlanId,
      'stripeCustomerId': stripeCustomerId,
      'hasSeenSubscriptionScreen': hasSeenSubscriptionScreen,
      'hasSeenOnboarding': hasSeenOnboarding,
      'hasSeenGetStarted': hasSeenGetStarted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? photoUrl,
    UserRole? role,
    TrainingProgramStatus? trainingProgramStatus,
    DateTime? programPurchaseDate,
    String? currentProgramId,
    UserPreferences? preferences,
    String? selectedTrainerId,
    String? mealPlanId,
    String? stripeCustomerId,
    bool? hasSeenSubscriptionScreen,
    bool? hasSeenOnboarding,
    bool? hasSeenGetStarted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      trainingProgramStatus: trainingProgramStatus ?? this.trainingProgramStatus,
      programPurchaseDate: programPurchaseDate ?? this.programPurchaseDate,
      currentProgramId: currentProgramId ?? this.currentProgramId,
      preferences: preferences ?? this.preferences,
      selectedTrainerId: selectedTrainerId ?? this.selectedTrainerId,
      mealPlanId: mealPlanId ?? this.mealPlanId,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      hasSeenSubscriptionScreen:
          hasSeenSubscriptionScreen ?? this.hasSeenSubscriptionScreen,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      hasSeenGetStarted: hasSeenGetStarted ?? this.hasSeenGetStarted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Helper method to extract string from field that might be DocumentReference or String
  static String? _extractStringFromField(dynamic field) {
    if (field == null) return null;
    if (field is String) return field;
    if (field is DocumentReference) return field.id;
    return field.toString();
  }

  /// Helper method to extract DateTime from field that might be Timestamp or String
  static DateTime _extractDateTimeFromField(dynamic field) {
    if (field is Timestamp) {
      return field.toDate();
    } else if (field is String) {
      return DateTime.parse(field);
    } else {
      throw Exception('Invalid date field type: ${field.runtimeType}');
    }
  }
}

class UserPreferences {
  final FitnessGoal fitnessGoal;
  final ActivityLevel activityLevel;
  final List<String> dietaryRestrictions;
  final List<String> preferredWorkoutStyles;
  final int targetCalories; // User-set target calories
  final CalorieTargets? calculatedCalorieTargets; // Calculated using scientific formulas
  final bool notificationsEnabled;
  final bool workoutNotificationsEnabled;
  final String? workoutNotificationTime; // Format: "HH:mm"
  final int weeklyWorkoutDays;
  final List<int>? specificWorkoutDays; // 1 = Monday, 7 = Sunday
  final String? timezone;

  // Personal metrics
  final int age;
  final double weight; // in kg
  final double height; // in cm
  final double desiredWeight; // in kg
  final String gender;

  // Food preferences
  final List<String> preferredCuisines;
  final List<String> foodsToAvoid;
  final List<String> favoriteFoods;

  // Allergies & Intolerances
  final List<Map<String, dynamic>> allergies;

  // Meal Timing Preferences
  final Map<String, dynamic>? mealTimingPreferences;

  // Batch Cooking Preferences
  final Map<String, dynamic>? batchCookingPreferences;

  // Cheat Day Preference
  final String? cheatDay; // e.g., "Monday"

  // Protein Targets
  final Map<String, dynamic>? proteinTargets;

  // Calorie Targets
  final Map<String, dynamic>? calorieTargets;

  UserPreferences({
    required this.fitnessGoal,
    required this.activityLevel,
    required this.dietaryRestrictions,
    required this.preferredWorkoutStyles,
    required this.targetCalories,
    this.calculatedCalorieTargets,
    this.notificationsEnabled = true,
    this.workoutNotificationsEnabled = false,
    this.workoutNotificationTime,
    this.weeklyWorkoutDays = 3,
    this.specificWorkoutDays,
    this.timezone,
    this.age = 25,
    this.weight = 70.0,
    this.height = 170.0,
    this.desiredWeight = 65.0,
    this.gender = 'Male',
    this.preferredCuisines = const [],
    this.foodsToAvoid = const [],
    this.favoriteFoods = const [],
    this.allergies = const [],
    this.mealTimingPreferences,
    this.batchCookingPreferences,
    this.cheatDay,
    this.proteinTargets,
    this.calorieTargets,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      fitnessGoal: FitnessGoal.values.firstWhere(
        (e) => e.toString() == 'FitnessGoal.${json['fitnessGoal']}',
        orElse: () => FitnessGoal.maintenance,
      ),
      activityLevel: ActivityLevel.values.firstWhere(
        (e) => e.toString() == 'ActivityLevel.${json['activityLevel']}',
        orElse: () => ActivityLevel.moderatelyActive,
      ),
      dietaryRestrictions: List<String>.from(json['dietaryRestrictions'] ?? []),
      preferredWorkoutStyles:
          List<String>.from(json['preferredWorkoutStyles'] ?? []),
      targetCalories: json['targetCalories'] as int? ?? 2000,
      calculatedCalorieTargets: json['calculatedCalorieTargets'] != null
          ? CalorieTargets.fromJson(json['calculatedCalorieTargets'] as Map<String, dynamic>)
          : null,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      workoutNotificationsEnabled:
          json['workoutNotificationsEnabled'] as bool? ?? false,
      workoutNotificationTime: json['workoutNotificationTime'] as String?,
      weeklyWorkoutDays: json['weeklyWorkoutDays'] as int? ?? 3,
      specificWorkoutDays: json['specificWorkoutDays'] != null
          ? List<int>.from(json['specificWorkoutDays'])
          : null,
      timezone: json['timezone'] as String?,
      age: json['age'] as int? ?? 25,
      weight: (json['weight'] as num?)?.toDouble() ?? 70.0,
      height: (json['height'] as num?)?.toDouble() ?? 170.0,
      desiredWeight: (json['desiredWeight'] as num?)?.toDouble() ?? 65.0,
      gender: json['gender'] as String? ?? 'Male',
      preferredCuisines: List<String>.from(json['preferredCuisines'] ?? []),
      foodsToAvoid: List<String>.from(json['foodsToAvoid'] ?? []),
      favoriteFoods: List<String>.from(json['favoriteFoods'] ?? []),
      allergies: List<Map<String, dynamic>>.from(json['allergies'] ?? []),
      mealTimingPreferences:
          json['mealTimingPreferences'] as Map<String, dynamic>?,
      batchCookingPreferences:
          json['batchCookingPreferences'] as Map<String, dynamic>?,
      cheatDay: json['cheatDay'] as String?,
      proteinTargets: json['proteinTargets'] as Map<String, dynamic>?,
      calorieTargets: json['calorieTargets'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fitnessGoal': fitnessGoal.toString().split('.').last,
      'activityLevel': activityLevel.toString().split('.').last,
      'dietaryRestrictions': dietaryRestrictions,
      'preferredWorkoutStyles': preferredWorkoutStyles,
      'targetCalories': targetCalories,
      'calculatedCalorieTargets': calculatedCalorieTargets?.toJson(),
      'notificationsEnabled': notificationsEnabled,
      'workoutNotificationsEnabled': workoutNotificationsEnabled,
      'workoutNotificationTime': workoutNotificationTime,
      'weeklyWorkoutDays': weeklyWorkoutDays,
      'specificWorkoutDays': specificWorkoutDays,
      'timezone': timezone,
      'age': age,
      'weight': weight,
      'height': height,
      'desiredWeight': desiredWeight,
      'gender': gender,
      'preferredCuisines': preferredCuisines,
      'foodsToAvoid': foodsToAvoid,
      'favoriteFoods': favoriteFoods,
      'allergies': allergies,
      'mealTimingPreferences': mealTimingPreferences,
      'batchCookingPreferences': batchCookingPreferences,
      'cheatDay': cheatDay,
      'proteinTargets': proteinTargets,
      'calorieTargets': calorieTargets,
    };
  }

  UserPreferences copyWith({
    FitnessGoal? fitnessGoal,
    ActivityLevel? activityLevel,
    List<String>? dietaryRestrictions,
    List<String>? preferredWorkoutStyles,
    int? targetCalories,
    CalorieTargets? calculatedCalorieTargets,
    bool? notificationsEnabled,
    bool? workoutNotificationsEnabled,
    String? workoutNotificationTime,
    int? weeklyWorkoutDays,
    List<int>? specificWorkoutDays,
    String? timezone,
    int? age,
    double? weight,
    double? height,
    double? desiredWeight,
    String? gender,
    List<String>? preferredCuisines,
    List<String>? foodsToAvoid,
    List<String>? favoriteFoods,
    List<Map<String, dynamic>>? allergies,
    Map<String, dynamic>? mealTimingPreferences,
    Map<String, dynamic>? batchCookingPreferences,
    String? cheatDay,
    Map<String, dynamic>? proteinTargets,
    Map<String, dynamic>? calorieTargets,
  }) {
    return UserPreferences(
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      activityLevel: activityLevel ?? this.activityLevel,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      preferredWorkoutStyles:
          preferredWorkoutStyles ?? this.preferredWorkoutStyles,
      targetCalories: targetCalories ?? this.targetCalories,
      calculatedCalorieTargets: calculatedCalorieTargets ?? this.calculatedCalorieTargets,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      workoutNotificationsEnabled:
          workoutNotificationsEnabled ?? this.workoutNotificationsEnabled,
      workoutNotificationTime:
          workoutNotificationTime ?? this.workoutNotificationTime,
      weeklyWorkoutDays: weeklyWorkoutDays ?? this.weeklyWorkoutDays,
      specificWorkoutDays: specificWorkoutDays ?? this.specificWorkoutDays,
      timezone: timezone ?? this.timezone,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      desiredWeight: desiredWeight ?? this.desiredWeight,
      gender: gender ?? this.gender,
      preferredCuisines: preferredCuisines ?? this.preferredCuisines,
      foodsToAvoid: foodsToAvoid ?? this.foodsToAvoid,
      favoriteFoods: favoriteFoods ?? this.favoriteFoods,
      allergies: allergies ?? this.allergies,
      mealTimingPreferences:
          mealTimingPreferences ?? this.mealTimingPreferences,
      batchCookingPreferences:
          batchCookingPreferences ?? this.batchCookingPreferences,
      cheatDay: cheatDay ?? this.cheatDay,
      proteinTargets: proteinTargets ?? this.proteinTargets,
      calorieTargets: calorieTargets ?? this.calorieTargets,
    );
  }

  /// Create default user preferences
  static UserPreferences defaultPreferences() {
    return UserPreferences(
      fitnessGoal: FitnessGoal.maintenance,
      activityLevel: ActivityLevel.moderatelyActive,
      dietaryRestrictions: [],
      preferredWorkoutStyles: [],
      targetCalories: 2000,
      notificationsEnabled: true,
      workoutNotificationsEnabled: false,
      weeklyWorkoutDays: 3,
      age: 25,
      weight: 70.0,
      height: 170.0,
      desiredWeight: 65.0,
      gender: 'Male',
      preferredCuisines: [],
      foodsToAvoid: [],
      favoriteFoods: [],
      allergies: [],
      mealTimingPreferences: null,
      batchCookingPreferences: null,
      cheatDay: null,
      proteinTargets: null,
      calorieTargets: null,
    );
  }
}

class DietPlanPreferences {
  // Onboarding info
  final int age;
  final String gender;
  final double weight;
  final double height;
  final FitnessGoal fitnessGoal;
  final ActivityLevel activityLevel;
  final List<String> dietaryRestrictions;
  final List<String> preferredWorkoutStyles;

  // Nutrition onboarding
  final String nutritionGoal; // e.g. "Lose fat", "Build muscle"
  final List<String> preferredCuisines;
  final List<String> foodsToAvoid;
  final List<String> favoriteFoods;

  // Meal prep preferences
  final String
      mealFrequency; // e.g. "3 meals", "3 meals + 2 snacks", "16:8 fasting"
  final String? cheatDay; // e.g. "Monday", "Saturday", null for no cheat day
  final bool weeklyRotation;
  final bool remindersEnabled;

  // Calculated nutrition targets
  final int targetCalories;
  final int? targetProtein; // Daily protein target in grams
  final Map<String, dynamic>? proteinTargets; // Full protein targets object
  final Map<String, dynamic>? calorieTargets; // Full calorie targets object

  // Additional onboarding data
  final List<Map<String, dynamic>>? allergies; // Allergies & intolerances
  final Map<String, dynamic>? mealTimingPreferences; // Meal timing & frequency
  final Map<String, dynamic>?
      batchCookingPreferences; // Batch cooking preferences

  DietPlanPreferences({
    required this.age,
    required this.gender,
    required this.weight,
    required this.height,
    required this.fitnessGoal,
    required this.activityLevel,
    required this.dietaryRestrictions,
    required this.preferredWorkoutStyles,
    required this.nutritionGoal,
    required this.preferredCuisines,
    required this.foodsToAvoid,
    required this.favoriteFoods,
    required this.mealFrequency,
    this.cheatDay,
    required this.weeklyRotation,
    required this.remindersEnabled,
    required this.targetCalories,
    this.targetProtein,
    this.proteinTargets,
    this.calorieTargets,
    this.allergies,
    this.mealTimingPreferences,
    this.batchCookingPreferences,
  });
}
