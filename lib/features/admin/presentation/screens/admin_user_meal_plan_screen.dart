import 'package:flutter/material.dart';
import 'package:champions_gym_app/shared/models/user_model.dart';
import 'package:champions_gym_app/shared/models/meal_model.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:champions_gym_app/features/admin/presentation/widgets/admin_create_meal_plan_card.dart';
import 'package:champions_gym_app/features/admin/presentation/screens/admin_meal_plan_setup_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserMealPlanScreen extends StatelessWidget {
  final UserModel user;
  final String? mealPlanId;
  final VoidCallback? onMealPlanCreated;

  const AdminUserMealPlanScreen({
    Key? key,
    required this.user,
    this.mealPlanId,
    this.onMealPlanCreated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (mealPlanId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant_menu_outlined,
                size: 32,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Meal Plan Yet',
                style: AppTextStyles.heading4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a personalized meal plan for ${user.name?.split(' ').first ?? 'this user'} to help them achieve their fitness goals',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminMealPlanSetupScreen(user: user),
                    ),
                  );
                  if (result == true) {
                    onMealPlanCreated?.call();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Meal Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<MealPlanModel?>(
      future: _fetchMealPlan(mealPlanId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading meal plan',
                  style:
                      AppTextStyles.bodyLarge.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final mealPlan = snapshot.data;
        if (mealPlan == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Meal plan not found',
                  style:
                      AppTextStyles.bodyLarge.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Meal plan overview card
                _buildMealPlanOverviewCard(mealPlan),

                const SizedBox(height: 24),

                // Daily meal cards
                ...mealPlan.mealDays.asMap().entries.map((entry) {
                  final index = entry.key;
                  final day = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildMealDayCard(day, index + 1),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<MealPlanModel?> _fetchMealPlan(String mealPlanId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('mealPlans')
          .doc(mealPlanId)
          .get();

      if (doc.exists) {
        return MealPlanModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error fetching meal plan: $e');
      return null;
    }
  }

  Widget _buildMealPlanOverviewCard(MealPlanModel mealPlan) {
    final totalCalories = mealPlan.mealDays.fold<double>(
      0,
      (sum, day) =>
          sum +
          day.meals.fold<double>(
            0,
            (daySum, meal) => daySum + meal.nutrition.calories,
          ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor.withOpacity(0.1),
            AppConstants.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meal Plan Overview',
                      style: AppTextStyles.heading4.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${mealPlan.mealDays.length} days • ${totalCalories.round()} total calories',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealDayCard(MealDay day, int dayNumber) {
    final totalCalories = day.meals.fold<double>(
      0,
      (sum, meal) => sum + meal.nutrition.calories,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Day $dayNumber',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '${totalCalories.round()} kcal',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: day.meals.map((meal) => _buildMealItem(meal)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealItem(Meal meal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${meal.nutrition.calories.round()} kcal • ${meal.nutrition.protein}g protein • ${meal.nutrition.carbs}g carbs • ${meal.nutrition.fat}g fat',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
