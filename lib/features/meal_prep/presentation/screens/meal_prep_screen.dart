import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../../shared/models/meal_model.dart';
import '../../../../shared/services/meal_plan_storage_service.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/meal_plan_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/meal_plan_view.dart';
import '../widgets/waiting_for_meal_plan.dart';

class MealPrepScreen extends StatefulWidget {
  const MealPrepScreen({super.key});

  @override
  State<MealPrepScreen> createState() => _MealPrepScreenState();
}

class _MealPrepScreenState extends State<MealPrepScreen> {
  static final _logger = Logger();
  MealPlanModel? _currentMealPlan;
  String? _cheatDay;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  /// Load saved meal plan from storage
  Future<void> _loadSavedData() async {
    try {
      // Fetch the current user from Firestore to get the latest mealPlanId
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.userModel;
      String? mealPlanId = user?.mealPlanId;
      MealPlanModel? firestoreMealPlan;

      if (mealPlanId != null) {
        // Try to fetch the meal plan from Firestore
        final doc = await FirebaseFirestore.instance
            .collection('meal_plans')
            .doc(mealPlanId)
            .get();
        if (doc.exists) {
          firestoreMealPlan = MealPlanModel.fromJson(doc.data()!);
        }
      }

      if (firestoreMealPlan != null) {
        setState(() {
          _currentMealPlan = firestoreMealPlan;
        });
        // Optionally cache to local storage
        await MealPlanStorageService.saveMealPlan(firestoreMealPlan);
        final mealPlanProvider =
            Provider.of<MealPlanProvider>(context, listen: false);
        mealPlanProvider.setMealPlan(firestoreMealPlan);
        _logger.i('Loaded meal plan from Firestore: ${firestoreMealPlan.title}');
        
        // Load cheat day from diet preferences
        await _loadCheatDay(user!.id);
        return;
      }

      // Fallback: Load saved meal plan from local storage
      if (user?.id != null) {
        final savedMealPlan =
            await MealPlanStorageService.loadMealPlan(user!.id);
        if (savedMealPlan != null) {
          setState(() {
            _currentMealPlan = savedMealPlan;
          });
          final mealPlanProvider =
              Provider.of<MealPlanProvider>(context, listen: false);
          mealPlanProvider.setMealPlan(savedMealPlan);
          _logger.i(
              'Loaded saved meal plan from local storage for user ${user.id}: ${savedMealPlan.title}');
          
          // Load cheat day from diet preferences
          await _loadCheatDay(user.id);
        }
      }

      // No meal plan exists - will show waiting state
    } catch (e) {
      _logger.e('Error loading saved data: $e');
      // Will show waiting state
    }
  }

  /// Load cheat day from diet preferences
  Future<void> _loadCheatDay(String userId) async {
    try {
      final dietPreferences = await MealPlanStorageService.loadDietPreferences(userId);
      if (dietPreferences != null) {
        setState(() {
          _cheatDay = dietPreferences.cheatDay;
        });
        _logger.i('Loaded cheat day: $_cheatDay');
      }
    } catch (e) {
      _logger.e('Error loading cheat day: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // If a meal plan exists, show it
    if (_currentMealPlan != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Meal Plan'),
        ),
        body: MealPlanView(
          mealPlan: _currentMealPlan!,
          user: Provider.of<AuthProvider>(context, listen: false).userModel,
          cheatDay: _cheatDay,
        ),
      );
    }

    // If no meal plan exists, show waiting state
    return const WaitingForMealPlan();
  }
}
