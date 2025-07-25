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
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
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

  factory MealPlanModel.fromJson(Map<String, dynamic> json) {
    return MealPlanModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      mealDays: (json['mealDays'] as List<dynamic>)
          .map((e) => MealDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCalories: (json['totalCalories'] as num).toDouble(),
      totalProtein: (json['totalProtein'] as num).toDouble(),
      totalCarbs: (json['totalCarbs'] as num).toDouble(),
      totalFat: (json['totalFat'] as num).toDouble(),
      dietaryTags: List<String>.from(json['dietaryTags'] ?? []),
      isAIGenerated: json['isAIGenerated'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
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
}

class MealDay {
  final String id;
  final DateTime date;
  final List<Meal> meals;
  double totalCalories; // Made mutable for corrections and changed to double
  double totalProtein; // Made mutable for corrections
  double totalCarbs; // Made mutable for corrections
  double totalFat; // Made mutable for corrections

  MealDay({
    required this.id,
    required this.date,
    required this.meals,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });

  factory MealDay.fromJson(Map<String, dynamic> json) {
    return MealDay(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      meals: (json['meals'] as List<dynamic>)
          .map((e) => Meal.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCalories: (json['totalCalories'] as num).toDouble(),
      totalProtein: (json['totalProtein'] as num).toDouble(),
      totalCarbs: (json['totalCarbs'] as num).toDouble(),
      totalFat: (json['totalFat'] as num).toDouble(),
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
  NutritionInfo nutrition; // Made mutable for corrections
  final List<String> tags;
  final List<String> dietaryTags; // Added for dietary restriction checking
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;
  final bool isDairyFree;
  final double rating;
  final int ratingCount;

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
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
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
      nutrition:
          NutritionInfo.fromJson(json['nutrition'] as Map<String, dynamic>),
      tags: List<String>.from(json['tags'] ?? []),
      dietaryTags: List<String>.from(json['dietaryTags'] ?? []),
      isVegetarian: json['isVegetarian'] as bool? ?? false,
      isVegan: json['isVegan'] as bool? ?? false,
      isGlutenFree: json['isGlutenFree'] as bool? ?? false,
      isDairyFree: json['isDairyFree'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['ratingCount'] as int? ?? 0,
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
    };
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
      fiber: (json['fiber'] as num).toDouble(),
      sugar: (json['sugar'] as num).toDouble(),
      sodium: (json['sodium'] as num).toDouble(),
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
