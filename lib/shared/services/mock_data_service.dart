import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/meal_model.dart';

/// Service for generating mock meal data as fallback
class MockDataService {
  /// Generate mock meal plan as fallback
  static MealPlanModel generateMockMealPlan(
    DietPlanPreferences preferences,
    int days,
  ) {
    print('Generating mock meal plan as fallback');
    final mealDays = List.generate(days, (index) {
      final date = DateTime.now().add(Duration(days: index));
      // Use different seed for each day to get varied meals
      final daySeed = DateTime.now().millisecondsSinceEpoch + index;
      return MealDay(
        id: const Uuid().v4(),
        date: date,
        meals: _generateMockMeals(preferences, daySeed),
        totalCalories: preferences.targetCalories.toDouble(),
        totalProtein: preferences.targetCalories * 0.3 / 4, // 30% protein
        totalCarbs: preferences.targetCalories * 0.4 / 4, // 40% carbs
        totalFat: preferences.targetCalories * 0.3 / 9, // 30% fat
      );
    });

    return MealPlanModel(
      id: const Uuid().v4(),
      userId: 'current_user',
      title: 'AI-Generated $days-Day Meal Plan',
      description: 'Personalized meal plan based on your preferences',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: days - 1)),
      mealDays: mealDays,
      totalCalories: (preferences.targetCalories * days).toDouble(),
      totalProtein: preferences.targetCalories * days * 0.3 / 4,
      totalCarbs: preferences.targetCalories * days * 0.4 / 4,
      totalFat: preferences.targetCalories * days * 0.3 / 9,
      dietaryTags: preferences.dietaryRestrictions,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Generate a single mock meal day with specific required meal types
  static MealDay generateMockMealDay(
    DietPlanPreferences preferences,
    int dayIndex,
    List<MealType> requiredMealTypes,
  ) {
    print('Generating mock meal day for day $dayIndex with required meals: ${requiredMealTypes.map((t) => t.name).join(', ')}');
    
    final date = DateTime.now().add(Duration(days: dayIndex - 1));
    final daySeed = DateTime.now().millisecondsSinceEpoch + dayIndex;
    
    final meals = _generateMockMealsWithTypes(preferences, requiredMealTypes, daySeed);
    
    // Calculate totals from meals
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    
    for (final meal in meals) {
      totalCalories += meal.nutrition.calories;
      totalProtein += meal.nutrition.protein;
      totalCarbs += meal.nutrition.carbs;
      totalFat += meal.nutrition.fat;
    }
    
    return MealDay(
      id: const Uuid().v4(),
      date: date,
      meals: meals,
      totalCalories: totalCalories,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
    );
  }

  /// Generate mock meals for fallback
  static List<Meal> _generateMockMeals(
      DietPlanPreferences preferences, [int? seed]) {
    // Create varied meal options based on preferences
    final isVegan = preferences.dietaryRestrictions.contains('Vegan');
    final isVegetarian = preferences.dietaryRestrictions.contains('Vegetarian');

    final breakfastOptions = isVegan ? [
      ('Oatmeal with Berries', 'Steel-cut oats topped with fresh berries and maple syrup'),
      ('Vegan Protein Smoothie Bowl', 'Plant-based smoothie bowl with berries and granola'),
      ('Avocado Toast', 'Whole grain toast with avocado and microgreens'),
      ('Vegan Breakfast Burrito', 'Tofu scramble with black beans and salsa in a whole wheat tortilla'),
      ('Chia Pudding', 'Chia seeds soaked in almond milk with fresh fruits'),
    ] : isVegetarian ? [
      ('Oatmeal with Berries', 'Steel-cut oats topped with fresh berries and honey'),
      ('Greek Yogurt Parfait', 'Greek yogurt layered with granola and mixed berries'),
      ('Protein Smoothie Bowl', 'Nutritious smoothie bowl with berries and granola'),
      ('Avocado Toast', 'Whole grain toast with avocado, eggs, and microgreens'),
      ('Breakfast Burrito', 'Scrambled eggs with black beans and salsa in a whole wheat tortilla'),
    ] : [
      ('Oatmeal with Berries', 'Steel-cut oats topped with fresh berries and honey'),
      ('Greek Yogurt Parfait', 'Greek yogurt layered with granola and mixed berries'),
      ('Protein Smoothie Bowl', 'Nutritious smoothie bowl with berries and granola'),
      ('Avocado Toast', 'Whole grain toast with avocado, eggs, and microgreens'),
      ('Breakfast Burrito', 'Scrambled eggs with black beans and salsa in a whole wheat tortilla'),
    ];

    final lunchOptions = isVegan ? [
      ('Quinoa Buddha Bowl', 'Quinoa bowl with roasted vegetables and tahini dressing'),
      ('Lentil Soup', 'Hearty lentil soup with vegetables and herbs'),
      ('Mediterranean Plate', 'Hummus, falafel, and fresh vegetables'),
      ('Vegan Wrap', 'Chickpea and avocado wrap with mixed greens'),
      ('Vegan Buddha Bowl', 'Brown rice with tofu, vegetables, and peanut sauce'),
    ] : isVegetarian ? [
      ('Quinoa Buddha Bowl', 'Quinoa bowl with roasted vegetables and tahini dressing'),
      ('Lentil Soup', 'Hearty lentil soup with vegetables and herbs'),
      ('Mediterranean Plate', 'Hummus, falafel, and fresh vegetables'),
      ('Vegetarian Wrap', 'Cheese and avocado wrap with mixed greens'),
      ('Vegetarian Buddha Bowl', 'Brown rice with eggs, vegetables, and peanut sauce'),
    ] : [
      ('Grilled Chicken Salad', 'Fresh salad with grilled chicken and vegetables'),
      ('Quinoa Buddha Bowl', 'Quinoa bowl with roasted vegetables and tahini dressing'),
      ('Turkey Wrap', 'Turkey and avocado wrap with mixed greens'),
      ('Lentil Soup', 'Hearty lentil soup with vegetables and herbs'),
      ('Mediterranean Plate', 'Hummus, falafel, and fresh vegetables'),
    ];

    final dinnerOptions = isVegan ? [
      ('Vegan Pasta', 'Whole wheat pasta with tomato sauce and vegetables'),
      ('Tofu Stir-Fry', 'Stir-fried tofu with broccoli and brown rice'),
      ('Vegan Buddha Bowl', 'Quinoa with roasted vegetables and tahini dressing'),
      ('Lentil Curry', 'Spiced lentil curry with brown rice'),
      ('Vegan Tacos', 'Black bean and vegetable tacos with avocado'),
    ] : isVegetarian ? [
      ('Vegetarian Pasta', 'Whole wheat pasta with tomato sauce and vegetables'),
      ('Eggplant Parmesan', 'Baked eggplant with marinara and cheese'),
      ('Vegetarian Buddha Bowl', 'Quinoa with roasted vegetables and tahini dressing'),
      ('Lentil Curry', 'Spiced lentil curry with brown rice'),
      ('Vegetarian Tacos', 'Black bean and vegetable tacos with cheese'),
    ] : [
      ('Salmon with Quinoa', 'Baked salmon with quinoa and roasted vegetables'),
      ('Lean Beef Stir-Fry', 'Stir-fried beef with broccoli and brown rice'),
      ('Vegetarian Pasta', 'Whole wheat pasta with tomato sauce and vegetables'),
      ('Grilled Shrimp Skewers', 'Grilled shrimp with couscous and vegetables'),
      ('Chicken Breast with Sweet Potato', 'Grilled chicken with roasted sweet potato'),
    ];

    final snackOptions = isVegan ? [
      ('Vegan Yogurt with Nuts', 'Plant-based yogurt with mixed nuts'),
      ('Apple with Almond Butter', 'Fresh apple slices with almond butter'),
      ('Vegan Protein Bar', 'Homemade protein bar with nuts and dried fruit'),
      ('Hummus with Carrots', 'Fresh carrot sticks with hummus'),
      ('Mixed Nuts', 'Assorted nuts and dried fruits'),
    ] : [
      ('Greek Yogurt with Nuts', 'Protein-rich snack with mixed nuts'),
      ('Apple with Almond Butter', 'Fresh apple slices with almond butter'),
      ('Protein Bar', 'Homemade protein bar with nuts and dried fruit'),
      ('Hummus with Carrots', 'Fresh carrot sticks with hummus'),
      ('Mixed Nuts', 'Assorted nuts and dried fruits'),
    ];

    // Select random meals based on preferences
    final random = seed ?? DateTime.now().millisecondsSinceEpoch;
    final breakfast = breakfastOptions[random % breakfastOptions.length];
    final lunch = lunchOptions[random % lunchOptions.length];
    final dinner = dinnerOptions[random % dinnerOptions.length];
    final snack = snackOptions[random % snackOptions.length];

    final meals = [
      _createMockMeal(
        breakfast.$1,
        breakfast.$2,
        MealType.breakfast,
        (preferences.targetCalories * 0.25).round(),
        preferences,
      ),
      _createMockMeal(
        lunch.$1,
        lunch.$2,
        MealType.lunch,
        (preferences.targetCalories * 0.35).round(),
        preferences,
      ),
      _createMockMeal(
        dinner.$1,
        dinner.$2,
        MealType.dinner,
        (preferences.targetCalories * 0.35).round(),
        preferences,
      ),
      _createMockMeal(
        snack.$1,
        snack.$2,
        MealType.snack,
        (preferences.targetCalories * 0.05).round(),
        preferences,
      ),
    ];

    return meals;
  }

  /// Generate mock meals with specific required meal types
  static List<Meal> _generateMockMealsWithTypes(
    DietPlanPreferences preferences,
    List<MealType> requiredMealTypes,
    int seed,
  ) {
    // Create varied meal options based on preferences
    final isVegan = preferences.dietaryRestrictions.contains('Vegan');
    final isVegetarian = preferences.dietaryRestrictions.contains('Vegetarian');

    final breakfastOptions = isVegan ? [
      ('Oatmeal with Berries', 'Steel-cut oats topped with fresh berries and maple syrup'),
      ('Vegan Protein Smoothie Bowl', 'Plant-based smoothie bowl with berries and granola'),
      ('Avocado Toast', 'Whole grain toast with avocado and microgreens'),
      ('Vegan Breakfast Burrito', 'Tofu scramble with black beans and salsa in a whole wheat tortilla'),
      ('Chia Pudding', 'Chia seeds soaked in almond milk with fresh fruits'),
    ] : isVegetarian ? [
      ('Oatmeal with Berries', 'Steel-cut oats topped with fresh berries and honey'),
      ('Greek Yogurt Parfait', 'Greek yogurt layered with granola and mixed berries'),
      ('Protein Smoothie Bowl', 'Nutritious smoothie bowl with berries and granola'),
      ('Avocado Toast', 'Whole grain toast with avocado, eggs, and microgreens'),
      ('Breakfast Burrito', 'Scrambled eggs with black beans and salsa in a whole wheat tortilla'),
    ] : [
      ('Oatmeal with Berries', 'Steel-cut oats topped with fresh berries and honey'),
      ('Greek Yogurt Parfait', 'Greek yogurt layered with granola and mixed berries'),
      ('Protein Smoothie Bowl', 'Nutritious smoothie bowl with berries and granola'),
      ('Avocado Toast', 'Whole grain toast with avocado, eggs, and microgreens'),
      ('Breakfast Burrito', 'Scrambled eggs with black beans and salsa in a whole wheat tortilla'),
    ];

    final lunchOptions = isVegan ? [
      ('Quinoa Buddha Bowl', 'Quinoa bowl with roasted vegetables and tahini dressing'),
      ('Lentil Soup', 'Hearty lentil soup with vegetables and herbs'),
      ('Mediterranean Plate', 'Hummus, falafel, and fresh vegetables'),
      ('Vegan Wrap', 'Chickpea and avocado wrap with mixed greens'),
      ('Vegan Buddha Bowl', 'Brown rice with tofu, vegetables, and peanut sauce'),
    ] : isVegetarian ? [
      ('Quinoa Buddha Bowl', 'Quinoa bowl with roasted vegetables and tahini dressing'),
      ('Lentil Soup', 'Hearty lentil soup with vegetables and herbs'),
      ('Mediterranean Plate', 'Hummus, falafel, and fresh vegetables'),
      ('Vegetarian Wrap', 'Cheese and avocado wrap with mixed greens'),
      ('Vegetarian Buddha Bowl', 'Brown rice with eggs, vegetables, and peanut sauce'),
    ] : [
      ('Grilled Chicken Salad', 'Fresh salad with grilled chicken and vegetables'),
      ('Quinoa Buddha Bowl', 'Quinoa bowl with roasted vegetables and tahini dressing'),
      ('Turkey Wrap', 'Turkey and avocado wrap with mixed greens'),
      ('Lentil Soup', 'Hearty lentil soup with vegetables and herbs'),
      ('Mediterranean Plate', 'Hummus, falafel, and fresh vegetables'),
    ];

    final dinnerOptions = isVegan ? [
      ('Vegan Pasta', 'Whole wheat pasta with tomato sauce and vegetables'),
      ('Tofu Stir-Fry', 'Stir-fried tofu with broccoli and brown rice'),
      ('Vegan Buddha Bowl', 'Quinoa with roasted vegetables and tahini dressing'),
      ('Lentil Curry', 'Spiced lentil curry with brown rice'),
      ('Vegan Tacos', 'Black bean and vegetable tacos with avocado'),
    ] : isVegetarian ? [
      ('Vegetarian Pasta', 'Whole wheat pasta with tomato sauce and vegetables'),
      ('Eggplant Parmesan', 'Baked eggplant with marinara and cheese'),
      ('Vegetarian Buddha Bowl', 'Quinoa with roasted vegetables and tahini dressing'),
      ('Lentil Curry', 'Spiced lentil curry with brown rice'),
      ('Vegetarian Tacos', 'Black bean and vegetable tacos with cheese'),
    ] : [
      ('Salmon with Quinoa', 'Baked salmon with quinoa and roasted vegetables'),
      ('Lean Beef Stir-Fry', 'Stir-fried beef with broccoli and brown rice'),
      ('Vegetarian Pasta', 'Whole wheat pasta with tomato sauce and vegetables'),
      ('Grilled Shrimp Skewers', 'Grilled shrimp with couscous and vegetables'),
      ('Chicken Breast with Sweet Potato', 'Grilled chicken with roasted sweet potato'),
    ];

    final snackOptions = isVegan ? [
      ('Vegan Yogurt with Nuts', 'Plant-based yogurt with mixed nuts'),
      ('Apple with Almond Butter', 'Fresh apple slices with almond butter'),
      ('Vegan Protein Bar', 'Homemade protein bar with nuts and dried fruit'),
      ('Hummus with Carrots', 'Fresh carrot sticks with hummus'),
      ('Mixed Nuts', 'Assorted nuts and dried fruits'),
    ] : [
      ('Greek Yogurt with Nuts', 'Protein-rich snack with mixed nuts'),
      ('Apple with Almond Butter', 'Fresh apple slices with almond butter'),
      ('Protein Bar', 'Homemade protein bar with nuts and dried fruit'),
      ('Hummus with Carrots', 'Fresh carrot sticks with hummus'),
      ('Mixed Nuts', 'Assorted nuts and dried fruits'),
    ];

    final meals = <Meal>[];
    final random = seed;
    int mealIndex = 0;

    // Generate meals for each required type
    for (final mealType in requiredMealTypes) {
      String name;
      String description;
      int calories;

      switch (mealType) {
        case MealType.breakfast:
          final breakfast = breakfastOptions[(random + mealIndex) % breakfastOptions.length];
          name = breakfast.$1;
          description = breakfast.$2;
          calories = (preferences.targetCalories * 0.25).round();
          break;
        case MealType.lunch:
          final lunch = lunchOptions[(random + mealIndex) % lunchOptions.length];
          name = lunch.$1;
          description = lunch.$2;
          calories = (preferences.targetCalories * 0.35).round();
          break;
        case MealType.dinner:
          final dinner = dinnerOptions[(random + mealIndex) % dinnerOptions.length];
          name = dinner.$1;
          description = dinner.$2;
          calories = (preferences.targetCalories * 0.35).round();
          break;
        case MealType.snack:
          final snack = snackOptions[(random + mealIndex) % snackOptions.length];
          name = snack.$1;
          description = snack.$2;
          calories = (preferences.targetCalories * 0.05).round();
          break;
      }

      meals.add(_createMockMeal(name, description, mealType, calories, preferences));
      mealIndex++;
    }

    return meals;
  }

  /// Create a mock meal
  static Meal _createMockMeal(
    String name,
    String description,
    MealType type,
    int calories,
    DietPlanPreferences preferences,
  ) {
    return Meal(
      id: const Uuid().v4(),
      name: name,
      description: description,
      type: type,
      cuisineType: CuisineType.american,
      ingredients: [
        RecipeIngredient(name: 'Ingredient 1', amount: 1.0, unit: 'cup'),
        RecipeIngredient(name: 'Ingredient 2', amount: 2.0, unit: 'tbsp'),
      ],
      instructions: [
        'Step 1: Prepare ingredients',
        'Step 2: Cook according to recipe',
        'Step 3: Serve and enjoy',
      ],
      prepTime: 10,
      cookTime: 20,
      servings: 1,
      nutrition: NutritionInfo(
        calories: calories.toDouble(),
        protein: calories * 0.3 / 4,
        carbs: calories * 0.4 / 4,
        fat: calories * 0.3 / 9,
        fiber: 5.0,
        sugar: 10.0,
        sodium: 500.0,
      ),
      tags: ['healthy', 'balanced'],
      isVegetarian: preferences.dietaryRestrictions.contains('Vegetarian'),
      isVegan: preferences.dietaryRestrictions.contains('Vegan'),
      isGlutenFree: preferences.dietaryRestrictions.contains('Gluten-Free'),
      isDairyFree: preferences.dietaryRestrictions.contains('Dairy-Free'),
    );
  }
} 