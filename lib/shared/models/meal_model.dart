import 'package:cloud_firestore/cloud_firestore.dart';

enum MealType { breakfast, lunch, dinner, snack }

enum CuisineType {
  american,
  italian,
  mexican,
  asian,
  mediterranean,
  indian,
  other
}

class MealPlanModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final List<MealDay> mealDays;
  double totalCalories; // Made mutable for nutrition calculations
  double totalProtein; // Made mutable for nutrition calculations
  double totalCarbs; // Made mutable for nutrition calculations
  double totalFat; // Made mutable for nutrition calculations
  final List<String> dietaryTags;
  final bool isAIGenerated;
  final DateTime createdAt;
  final DateTime updatedAt;

  MealPlanModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.mealDays,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.dietaryTags,
    this.isAIGenerated = true,
    required this.createdAt,
    required this.updatedAt,
  });

  MealPlanModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    List<MealDay>? mealDays,
    double? totalCalories,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
    List<String>? dietaryTags,
    bool? isAIGenerated,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MealPlanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      mealDays: mealDays ?? this.mealDays,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      isAIGenerated: isAIGenerated ?? this.isAIGenerated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MealPlanModel.fromJson(Map<String, dynamic> json, {String? documentId}) {
    // Debug the JSON structure
    print('🔥 MEAL PLAN DEBUG - JSON keys: ${json.keys.toList()}');
    print('🔥 MEAL PLAN DEBUG - nutritionSummary: ${json['nutritionSummary']}');
    print('🔥 MEAL PLAN DEBUG - dailyAverage: ${json['nutritionSummary']?['dailyAverage']}');
    
    // Extract nutrition data from the correct structure
    final nutritionSummary = json['nutritionSummary']?['dailyAverage'] as Map<String, dynamic>?;
    print('🔥 MEAL PLAN DEBUG - nutritionSummary type: ${nutritionSummary.runtimeType}');
    print('🔥 MEAL PLAN DEBUG - nutritionSummary content: $nutritionSummary');
    
    return MealPlanModel(
      id: json['id'] as String? ?? documentId ?? '',
      userId: _extractStringFromField(json['userId']) ?? '',
      title: json['title'] as String? ?? 'Untitled Meal Plan',
      description: json['description'] as String? ?? 'No description available',
      startDate: _extractDateTimeFromField(json['startDate']),
      endDate: _extractDateTimeFromField(json['endDate']),
      mealDays: (json['mealDays'] as List<dynamic>)
          .map((e) => MealDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCalories: nutritionSummary?['calories']?.toDouble() ?? (json['totalCalories'] as num?)?.toDouble() ?? 0.0,
      totalProtein: nutritionSummary?['protein']?.toDouble() ?? (json['totalProtein'] as num?)?.toDouble() ?? 0.0,
      totalCarbs: nutritionSummary?['carbs']?.toDouble() ?? (json['totalCarbs'] as num?)?.toDouble() ?? 0.0,
      totalFat: nutritionSummary?['fat']?.toDouble() ?? (json['totalFat'] as num?)?.toDouble() ?? 0.0,
      dietaryTags: List<String>.from(json['dietaryTags'] ?? []),
      isAIGenerated: json['isAIGenerated'] as bool? ?? true,
      createdAt: _extractDateTimeFromField(json['createdAt']),
      updatedAt: _extractDateTimeFromField(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'mealDays': mealDays.map((e) => e.toJson()).toList(),
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'dietaryTags': dietaryTags,
      'isAIGenerated': isAIGenerated,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
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

class MealDay {
  final String id;
  final DateTime date;
  final List<Meal> meals;
  double totalCalories; // Made mutable for nutrition calculations
  double totalProtein; // Made mutable for nutrition calculations
  double totalCarbs; // Made mutable for nutrition calculations
  double totalFat; // Made mutable for nutrition calculations
  double consumedCalories; // Track consumed calories
  double consumedProtein; // Track consumed protein
  double consumedCarbs; // Track consumed carbs
  double consumedFat; // Track consumed fat

  MealDay({
    required this.id,
    required this.date,
    required this.meals,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    this.consumedCalories = 0.0,
    this.consumedProtein = 0.0,
    this.consumedCarbs = 0.0,
    this.consumedFat = 0.0,
  });

  /// Calculate consumed nutrition from meals marked as consumed
  void calculateConsumedNutrition() {
    consumedCalories = 0.0;
    consumedProtein = 0.0;
    consumedCarbs = 0.0;
    consumedFat = 0.0;

    for (final meal in meals) {
      if (meal.isConsumed) {
        consumedCalories += meal.nutrition.calories;
        consumedProtein += meal.nutrition.protein;
        consumedCarbs += meal.nutrition.carbs;
        consumedFat += meal.nutrition.fat;
      }
    }
  }

  /// Get remaining calories for the day
  double get remainingCalories => totalCalories - consumedCalories;

  /// Get remaining protein for the day
  double get remainingProtein => totalProtein - consumedProtein;

  /// Get remaining carbs for the day
  double get remainingCarbs => totalCarbs - consumedCarbs;

  /// Get remaining fat for the day
  double get remainingFat => totalFat - consumedFat;

  factory MealDay.fromJson(Map<String, dynamic> json) {
    // Debug logging for meal day nutrition data
    print('🔥 MEAL DAY DEBUG - Day ${json['id']}:');
    print('🔥 MEAL DAY DEBUG - totalNutrition: ${json['totalNutrition']}');
    print('🔥 MEAL DAY DEBUG - totalCalories: ${json['totalCalories']} (type: ${json['totalCalories'].runtimeType})');
    print('🔥 MEAL DAY DEBUG - totalProtein: ${json['totalProtein']} (type: ${json['totalProtein'].runtimeType})');
    
    // Extract nutrition data from the correct structure
    final totalNutrition = json['totalNutrition'] as Map<String, dynamic>?;
    print('🔥 MEAL DAY DEBUG - totalNutrition type: ${totalNutrition.runtimeType}');
    print('🔥 MEAL DAY DEBUG - totalNutrition content: $totalNutrition');
    
    return MealDay(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      meals: (json['meals'] as List<dynamic>)
          .map((e) => Meal.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCalories: totalNutrition?['calories']?.toDouble() ?? (json['totalCalories'] as num?)?.toDouble() ?? 0.0,
      totalProtein: totalNutrition?['protein']?.toDouble() ?? (json['totalProtein'] as num?)?.toDouble() ?? 0.0,
      totalCarbs: totalNutrition?['carbs']?.toDouble() ?? (json['totalCarbs'] as num?)?.toDouble() ?? 0.0,
      totalFat: totalNutrition?['fat']?.toDouble() ?? (json['totalFat'] as num?)?.toDouble() ?? 0.0,
      consumedCalories: (json['consumedCalories'] as num?)?.toDouble() ?? 0.0,
      consumedProtein: (json['consumedProtein'] as num?)?.toDouble() ?? 0.0,
      consumedCarbs: (json['consumedCarbs'] as num?)?.toDouble() ?? 0.0,
      consumedFat: (json['consumedFat'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'meals': meals.map((e) => e.toJson()).toList(),
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'consumedCalories': consumedCalories,
      'consumedProtein': consumedProtein,
      'consumedCarbs': consumedCarbs,
      'consumedFat': consumedFat,
    };
  }
}

class Meal {
  final String id;
  final String name;
  final String description;
  final MealType type;
  final CuisineType cuisineType;
  final String? imageUrl;
  final String? videoUrl;
  final List<RecipeIngredient> ingredients;
  final List<String> instructions;
  final int prepTime; // in minutes
  final int cookTime; // in minutes
  final int servings;
  NutritionInfo nutrition; // Made mutable for nutrition calculations
  final List<String> tags;
  final List<String> dietaryTags; // Added for dietary restriction checking
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;
  final bool isDairyFree;
  final double rating;
  final int ratingCount;
  bool isConsumed; // Track if meal has been consumed

  Meal({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.cuisineType,
    this.imageUrl,
    this.videoUrl,
    required this.ingredients,
    required this.instructions,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.nutrition,
    required this.tags,
    this.dietaryTags = const [],
    this.isVegetarian = false,
    this.isVegan = false,
    this.isGlutenFree = false,
    this.isDairyFree = false,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.isConsumed = false,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    // Debug logging for meal nutrition data
    print('🔥 MEAL DEBUG - ${json['name']} (${json['id']}):');
    print('🔥 MEAL DEBUG - totalNutrition: ${json['totalNutrition']}');
    print('🔥 MEAL DEBUG - nutrition field: ${json['nutrition']}');
    
    // Extract nutrition data from the correct structure
    final totalNutrition = json['totalNutrition'] as Map<String, dynamic>?;
    print('🔥 MEAL DEBUG - totalNutrition type: ${totalNutrition.runtimeType}');
    print('🔥 MEAL DEBUG - totalNutrition content: $totalNutrition');
    
    // Create nutrition info from totalNutrition if available, otherwise use nutrition field
    NutritionInfo nutritionInfo;
    if (totalNutrition != null) {
      nutritionInfo = NutritionInfo(
        calories: totalNutrition['calories']?.toDouble() ?? 0.0,
        protein: totalNutrition['protein']?.toDouble() ?? 0.0,
        carbs: totalNutrition['carbs']?.toDouble() ?? 0.0,
        fat: totalNutrition['fat']?.toDouble() ?? 0.0,
        fiber: totalNutrition['fiber']?.toDouble() ?? 0.0,
        sugar: totalNutrition['sugar']?.toDouble() ?? 0.0,
        sodium: totalNutrition['sodium']?.toDouble() ?? 0.0,
      );
    } else if (json['nutrition'] != null) {
      nutritionInfo = NutritionInfo.fromJson(json['nutrition'] as Map<String, dynamic>);
    } else {
      nutritionInfo = NutritionInfo.empty();
    }
    
    return Meal(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: MealType.values.firstWhere(
        (e) => e.toString() == 'MealType.${json['type']}',
        orElse: () => MealType.breakfast,
      ),
      cuisineType: CuisineType.values.firstWhere(
        (e) => e.toString() == 'CuisineType.${json['cuisineType']}',
        orElse: () => CuisineType.american,
      ),
      imageUrl: json['imageUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      instructions: List<String>.from(json['instructions'] ?? []),
      prepTime: json['prepTime'] as int,
      cookTime: json['cookTime'] as int,
      servings: json['servings'] as int,
      nutrition: nutritionInfo,
      tags: List<String>.from(json['tags'] ?? []),
      dietaryTags: List<String>.from(json['dietaryTags'] ?? []),
      isVegetarian: json['isVegetarian'] as bool? ?? false,
      isVegan: json['isVegan'] as bool? ?? false,
      isGlutenFree: json['isGlutenFree'] as bool? ?? false,
      isDairyFree: json['isDairyFree'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['ratingCount'] as int? ?? 0,
      isConsumed: json['isConsumed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'cuisineType': cuisineType.toString().split('.').last,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'instructions': instructions,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'servings': servings,
      'nutrition': nutrition.toJson(),
      'tags': tags,
      'dietaryTags': dietaryTags,
      'isVegetarian': isVegetarian,
      'isVegan': isVegan,
      'isGlutenFree': isGlutenFree,
      'isDairyFree': isDairyFree,
      'rating': rating,
      'ratingCount': ratingCount,
      'isConsumed': isConsumed,
    };
  }

  /// Create a copy of this meal with modified properties
  Meal copyWith({
    String? id,
    String? name,
    String? description,
    MealType? type,
    CuisineType? cuisineType,
    String? imageUrl,
    String? videoUrl,
    List<RecipeIngredient>? ingredients,
    List<String>? instructions,
    int? prepTime,
    int? cookTime,
    int? servings,
    NutritionInfo? nutrition,
    List<String>? tags,
    List<String>? dietaryTags,
    bool? isVegetarian,
    bool? isVegan,
    bool? isGlutenFree,
    bool? isDairyFree,
    double? rating,
    int? ratingCount,
    bool? isConsumed,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      cuisineType: cuisineType ?? this.cuisineType,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      servings: servings ?? this.servings,
      nutrition: nutrition ?? this.nutrition,
      tags: tags ?? this.tags,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isVegan: isVegan ?? this.isVegan,
      isGlutenFree: isGlutenFree ?? this.isGlutenFree,
      isDairyFree: isDairyFree ?? this.isDairyFree,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      isConsumed: isConsumed ?? this.isConsumed,
    );
  }
}

class RecipeIngredient {
  final String name;
  final double amount;
  final String unit;
  final String? notes;
  final NutritionInfo? nutrition; // Nutritional data per ingredient

  RecipeIngredient({
    required this.name,
    required this.amount,
    required this.unit,
    this.notes,
    this.nutrition,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String,
      notes: json['notes'] as String?,
      nutrition: json['nutrition'] != null
          ? NutritionInfo.fromJson(json['nutrition'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
      'notes': notes,
      'nutrition': nutrition?.toJson(),
    };
  }
}

class NutritionInfo {
  final double calories; // Changed to double for USDA corrections
  final double protein; // in grams
  final double carbs; // in grams
  final double fat; // in grams
  final double fiber; // in grams
  final double sugar; // in grams
  final double sodium; // in mg

  NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0.0,
      sugar: (json['sugar'] as num?)?.toDouble() ?? 0.0,
      sodium: (json['sodium'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Creates an empty NutritionInfo instance with all values set to 0
  factory NutritionInfo.empty() {
    return NutritionInfo(
      calories: 0.0,
      protein: 0.0,
      carbs: 0.0,
      fat: 0.0,
      fiber: 0.0,
      sugar: 0.0,
      sodium: 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
    };
  }
}
