import 'package:flutter/material.dart';
import '../../../../shared/models/meal_model.dart';
import '../../../../shared/services/meal_plan_storage_service.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/meal_plan_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/meal_plan_view.dart';
import '../widgets/admin_meal_setup_flow.dart';
import '../widgets/waiting_for_meal_plan.dart';


class MealPrepScreen extends StatefulWidget {
  const MealPrepScreen({super.key});

  @override
  State<MealPrepScreen> createState() => _MealPrepScreenState();
}

class _MealPrepScreenState extends State<MealPrepScreen> {
  MealPlanModel? _currentMealPlan;
  bool _showAdminSetup = false;

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
          _showAdminSetup = false;
        });
        // Optionally cache to local storage
        await MealPlanStorageService.saveMealPlan(firestoreMealPlan);
        final mealPlanProvider = Provider.of<MealPlanProvider>(context, listen: false);
        mealPlanProvider.setMealPlan(firestoreMealPlan);
        print('Loaded meal plan from Firestore: ${firestoreMealPlan.title}');
        return;
      }
      
      // Fallback: Load saved meal plan from local storage
      final savedMealPlan = await MealPlanStorageService.loadMealPlan();
      if (savedMealPlan != null) {
        setState(() {
          _currentMealPlan = savedMealPlan;
          _showAdminSetup = false;
        });
        final mealPlanProvider = Provider.of<MealPlanProvider>(context, listen: false);
        mealPlanProvider.setMealPlan(savedMealPlan);
        print('Loaded saved meal plan from local storage: ${savedMealPlan.title}');
      }
      
      // Show admin setup if no meal plan exists
      if (_currentMealPlan == null) {
        setState(() {
          _showAdminSetup = true;
        });
      }
    } catch (e) {
      print('Error loading saved data: $e');
      setState(() {
        _showAdminSetup = true;
      });
    }
  }

  void _onMealPlanGenerated() {
    setState(() {
      _showAdminSetup = false;
    });
    _loadSavedData(); // Reload to get the new meal plan
  }

  void _onMealTap() {
    // Handle meal tap if needed
  }

  @override
  Widget build(BuildContext context) {
    // If admin setup is active, show the setup flow
    if (_showAdminSetup) {
      return AdminMealSetupFlow(
        onMealPlanGenerated: _onMealPlanGenerated,
      );
    }

    // If a meal plan exists, show it
    if (_currentMealPlan != null) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plan'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
      setState(() {
                  _showAdminSetup = true;
                });
              },
              tooltip: 'Generate New Plan',
          ),
        ],
      ),
        body: MealPlanView(
          mealPlan: _currentMealPlan!,
          onMealTap: _onMealTap,
      ),
    );
  }

    // If no meal plan exists, show waiting state
    return const WaitingForMealPlan();
  }
}
