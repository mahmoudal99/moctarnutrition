import 'package:flutter/material.dart';
import '../../../../shared/models/meal_model.dart';
import '../../../../shared/models/user_model.dart';
import '../widgets/meal_plan_view.dart';
import '../widgets/admin_meal_setup_flow.dart';
import '../widgets/waiting_for_meal_plan.dart';
import '../widgets/shared/meal_prep_widgets.dart';

/// Demo screen showing how to use the refactored meal prep components
class MealPrepDemo extends StatefulWidget {
  const MealPrepDemo({super.key});

  @override
  State<MealPrepDemo> createState() => _MealPrepDemoState();
}

class _MealPrepDemoState extends State<MealPrepDemo> {
  int _currentDemo = 0;

  // Mock meal plan for demo
  final MealPlanModel _mockMealPlan = MealPlanModel(
    id: 'demo-plan',
    userId: 'demo-user',
    title: 'Demo Meal Plan',
    description: 'A sample meal plan for demonstration',
    startDate: DateTime.now(),
    endDate: DateTime.now().add(const Duration(days: 7)),
    totalCalories: 2100,
    totalProtein: 180,
    totalCarbs: 200,
    totalFat: 70,
    dietaryTags: ['healthy', 'balanced'],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    mealDays: [
      MealDay(
        id: 'day-1',
        date: DateTime.now(),
        totalCalories: 2100,
        totalProtein: 180,
        totalCarbs: 200,
        totalFat: 70,
        meals: [
          Meal(
            id: '1',
            name: 'Oatmeal with Berries',
            description: 'Healthy breakfast with antioxidants',
            type: MealType.breakfast,
            cuisineType: CuisineType.american,
            ingredients: [
              RecipeIngredient(name: 'Oats', amount: 1, unit: 'cup'),
              RecipeIngredient(name: 'Berries', amount: 0.5, unit: 'cup'),
              RecipeIngredient(name: 'Honey', amount: 1, unit: 'tbsp'),
            ],
            instructions: [
              'Mix oats with water',
              'Add berries',
              'Drizzle honey'
            ],
            prepTime: 5,
            cookTime: 10,
            servings: 1,
            nutrition: NutritionInfo(
              calories: 350,
              protein: 12,
              carbs: 45,
              fat: 8,
              fiber: 8,
              sugar: 20,
              sodium: 150,
            ),
            tags: ['breakfast', 'healthy'],
          ),
          Meal(
            id: '2',
            name: 'Grilled Chicken Salad',
            description: 'Protein-rich lunch option',
            type: MealType.lunch,
            cuisineType: CuisineType.mediterranean,
            ingredients: [
              RecipeIngredient(name: 'Chicken breast', amount: 6, unit: 'oz'),
              RecipeIngredient(name: 'Mixed greens', amount: 2, unit: 'cups'),
              RecipeIngredient(name: 'Olive oil', amount: 1, unit: 'tbsp'),
            ],
            instructions: ['Grill chicken', 'Mix salad', 'Add dressing'],
            prepTime: 10,
            cookTime: 15,
            servings: 1,
            nutrition: NutritionInfo(
              calories: 450,
              protein: 35,
              carbs: 15,
              fat: 25,
              fiber: 5,
              sugar: 8,
              sodium: 300,
            ),
            tags: ['lunch', 'protein'],
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Prep Components Demo'),
        actions: [
          PopupMenuButton<int>(
            onSelected: (value) => setState(() => _currentDemo = value),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 0,
                child: Text('Meal Plan View'),
              ),
              PopupMenuItem(
                value: 1,
                child: Text('Admin Setup Flow'),
              ),
              PopupMenuItem(
                value: 2,
                child: Text('Waiting State'),
              ),
              PopupMenuItem(
                value: 3,
                child: Text('Shared Widgets'),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(Icons.more_vert),
            ),
          ),
        ],
      ),
      body: _buildCurrentDemo(),
    );
  }

  Widget _buildCurrentDemo() {
    switch (_currentDemo) {
      case 0:
        return _buildMealPlanViewDemo();
      case 1:
        return _buildAdminSetupFlowDemo();
      case 2:
        return _buildWaitingStateDemo();
      case 3:
        return _buildSharedWidgetsDemo();
      default:
        return _buildMealPlanViewDemo();
    }
  }

  Widget _buildMealPlanViewDemo() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Meal Plan View Demo',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: MealPlanView(
            mealPlan: _mockMealPlan,
            onMealTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Meal tapped!')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdminSetupFlowDemo() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Admin Setup Flow Demo',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: AdminMealSetupFlow(
            targetUserPreferences: UserPreferences(
              age: 25,
              gender: 'Male',
              weight: 70.0,
              height: 175.0,
              fitnessGoal: FitnessGoal.muscleGain,
              activityLevel: ActivityLevel.moderatelyActive,
              dietaryRestrictions: ['None'],
              preferredWorkoutStyles: ['Strength Training'],
              targetCalories: 2200,
              preferredCuisines: ['Mediterranean', 'Asian'],
              foodsToAvoid: ['Shellfish'],
              favoriteFoods: ['Chicken', 'Rice', 'Vegetables'],
            ),
            userName: 'John',
            onMealPlanGenerated: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Meal plan generated!')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingStateDemo() {
    return const Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Waiting State Demo',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: WaitingForMealPlan(),
        ),
      ],
    );
  }

  Widget _buildSharedWidgetsDemo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shared Widgets Demo',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // MealInfoCard demo
          MealInfoCard(
            title: 'Sample Meal',
            subtitle: 'Healthy breakfast option',
            icon: Icons.breakfast_dining,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('MealInfoCard tapped!')),
              );
            },
            trailing: const Icon(Icons.arrow_forward_ios),
          ),

          const SizedBox(height: 16),

          // NutritionChip demo
          const Row(
            children: [
              NutritionChip(label: 'P', value: '25g', color: Colors.blue),
              SizedBox(width: 8),
              NutritionChip(label: 'C', value: '45g', color: Colors.green),
              SizedBox(width: 8),
              NutritionChip(label: 'F', value: '12g', color: Colors.orange),
            ],
          ),

          const SizedBox(height: 20),

          // MealPrepProgressIndicator demo
          const MealPrepProgressIndicator(
            progress: 0.75,
            message: 'Generating your meal plan...',
            showPercentage: true,
          ),

          const SizedBox(height: 20),

          // SectionHeader demo
          SectionHeader(
            title: 'Nutrition Summary',
            subtitle: 'Daily nutritional breakdown',
            action: IconButton(
              icon: const Icon(Icons.info),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Info button tapped!')),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // EmptyStateWidget demo
          EmptyStateWidget(
            icon: Icons.no_food,
            title: 'No Meals Available',
            message: 'Your meal plan is being prepared. Please wait.',
            onAction: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Action button tapped!')),
              );
            },
            actionText: 'Refresh',
          ),
        ],
      ),
    );
  }
}
