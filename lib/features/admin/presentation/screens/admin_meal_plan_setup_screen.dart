import 'package:flutter/material.dart';
import 'package:champions_gym_app/shared/models/user_model.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:champions_gym_app/features/meal_prep/presentation/screens/meal_prep_screen.dart';
import 'package:champions_gym_app/shared/services/ai_meal_service.dart';
import 'package:champions_gym_app/shared/models/meal_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminMealPlanSetupScreen extends StatefulWidget {
  final UserModel user;
  const AdminMealPlanSetupScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<AdminMealPlanSetupScreen> createState() => _AdminMealPlanSetupScreenState();
}

class _AdminMealPlanSetupScreenState extends State<AdminMealPlanSetupScreen> {
  int _setupStep = 0;
  NutritionGoal? _selectedNutritionGoal;
  final List<String> _preferredCuisines = [];
  final List<String> _foodsToAvoid = [];
  final List<String> _favoriteFoods = [];
  MealFrequencyOption? _mealFrequency;
  bool _weeklyRotation = true;
  bool _remindersEnabled = false;
  int _selectedDays = 7;
  bool _isLoading = false;

  // Controllers for text input
  final TextEditingController _cuisineController = TextEditingController();
  final TextEditingController _avoidController = TextEditingController();
  final TextEditingController _favoriteController = TextEditingController();

  @override
  void dispose() {
    _cuisineController.dispose();
    _avoidController.dispose();
    _favoriteController.dispose();
    super.dispose();
  }

  void _onNextStep() {
    setState(() {
      _setupStep++;
    });
  }

  void _onBackStep() {
    setState(() {
      if (_setupStep > 0) _setupStep--;
    });
  }

  Future<void> _onSavePlan() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = widget.user.preferences;
      final userId = widget.user.id;
      print('[AdminMealPlanSetupScreen] Generating meal plan for userId: $userId');
      final dietPlanPreferences = DietPlanPreferences(
        age: prefs.age,
        gender: prefs.gender,
        weight: prefs.weight,
        height: prefs.height,
        fitnessGoal: prefs.fitnessGoal,
        activityLevel: prefs.activityLevel,
        dietaryRestrictions: prefs.dietaryRestrictions,
        preferredWorkoutStyles: prefs.preferredWorkoutStyles,
        nutritionGoal: _selectedNutritionGoal?.label ?? '',
        preferredCuisines: List<String>.from(_preferredCuisines),
        foodsToAvoid: List<String>.from(_foodsToAvoid),
        favoriteFoods: List<String>.from(_favoriteFoods),
        mealFrequency: _mealFrequency?.toString().split('.').last ?? '',
        weeklyRotation: _weeklyRotation,
        remindersEnabled: _remindersEnabled,
        targetCalories: prefs.targetCalories,
      );
      final mealPlan = await AIMealService.generateMealPlan(
        preferences: dietPlanPreferences,
        days: _selectedDays,
      );
      print('[AdminMealPlanSetupScreen] Meal plan generated: ${mealPlan.toJson()}');
      // Ensure the meal plan has the correct userId
      final mealPlanWithUser = mealPlan.copyWith(userId: userId);
      print('[AdminMealPlanSetupScreen] Saving meal plan to Firestore with userId: $userId');
      final mealPlanRef = await FirebaseFirestore.instance.collection('meal_plans').add(mealPlanWithUser.toJson());
      print('[AdminMealPlanSetupScreen] Meal plan saved with ID: ${mealPlanRef.id}');
      // Update user's mealPlanId
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'mealPlanId': mealPlanRef.id,
      });
      print('[AdminMealPlanSetupScreen] Updated user document with mealPlanId: ${mealPlanRef.id}');
      if (mounted) {
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e, stack) {
      print('[AdminMealPlanSetupScreen] Error generating or saving meal plan: $e');
      print(stack);
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate meal plan: $e'), backgroundColor: AppConstants.errorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = widget.user.preferences;
    return Scaffold(
      appBar: AppBar(
        title: Text('Generate Meal Plan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DietPlanSetupFlow(
              step: _setupStep,
              onNext: _onNextStep,
              onBack: _onBackStep,
              selectedNutritionGoal: _selectedNutritionGoal,
              onSelectNutritionGoal: (goal) => setState(() => _selectedNutritionGoal = goal),
              preferredCuisines: _preferredCuisines,
              onAddCuisine: (cuisine) {
                if (cuisine.isNotEmpty && !_preferredCuisines.contains(cuisine)) {
                  setState(() => _preferredCuisines.add(cuisine));
                }
              },
              onRemoveCuisine: (cuisine) => setState(() => _preferredCuisines.remove(cuisine)),
              foodsToAvoid: _foodsToAvoid,
              onAddAvoid: (food) {
                if (food.isNotEmpty && !_foodsToAvoid.contains(food)) {
                  setState(() => _foodsToAvoid.add(food));
                }
              },
              onRemoveAvoid: (food) => setState(() => _foodsToAvoid.remove(food)),
              favoriteFoods: _favoriteFoods,
              onAddFavorite: (food) {
                if (food.isNotEmpty && !_favoriteFoods.contains(food)) {
                  setState(() => _favoriteFoods.add(food));
                }
              },
              onRemoveFavorite: (food) => setState(() => _favoriteFoods.remove(food)),
              mealFrequency: _mealFrequency,
              onSelectMealFrequency: (freq) => setState(() => _mealFrequency = freq),
              cuisineController: _cuisineController,
              avoidController: _avoidController,
              favoriteController: _favoriteController,
              isPreviewLoading: false,
              sampleDayPlan: const {}, // Not used in admin flow for now
              onRegeneratePreview: () {},
              onLooksGood: _onNextStep,
              onCustomize: _onNextStep,
              weeklyRotation: _weeklyRotation,
              onToggleWeeklyRotation: (val) => setState(() => _weeklyRotation = val),
              remindersEnabled: _remindersEnabled,
              onToggleReminders: (val) => setState(() => _remindersEnabled = val),
              onSavePlan: _onSavePlan,
              userPreferences: prefs,
              selectedDays: _selectedDays,
            ),
    );
  }
} 