import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/calorie_calculation_service.dart';
import '../../../../shared/models/meal_model.dart';
import '../../../../shared/services/nutrition_calculation_service.dart';
import '../../../../shared/widgets/animated_counter.dart';
import 'activity_ring.dart';

class CalorieSummaryCard extends StatelessWidget {
  final CalorieTargets calorieTargets;
  final DateTime selectedDate;
  final MealDay? currentDayMeals;

  const CalorieSummaryCard({
    super.key,
    required this.calorieTargets,
    required this.selectedDate,
    this.currentDayMeals,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate consumed calories from current day meals
    double consumedCalories = 0.0;
    if (currentDayMeals != null) {
      // Always use consumed calories, even if it's 0
      consumedCalories = currentDayMeals!.consumedCalories;
    }

    final caloriesLeft =
        (calorieTargets.dailyTarget - consumedCalories).round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left side - Calories info
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calories left
                AnimatedCounter(
                  value: caloriesLeft.toDouble(),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Text(
                      'Calories left',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(width: 8),
                    // Activity bonus - Add Later
                    // Row(
                    //   children: [
                    //     const Icon(
                    //       Icons.person_add,
                    //       size: 16,
                    //       color: Colors.black,
                    //     ),
                    //     const SizedBox(width: 4),
                    //     Text(
                    //       '+$activityBonus',
                    //       style: const TextStyle(
                    //         fontSize: 14,
                    //         color: Colors.black,
                    //         fontWeight: FontWeight.w600,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ],
            ),
          ),

          // Right side - Activity ring
          Expanded(
            flex: 1,
            child: Center(
              child: ActivityRing(
                consumedCalories: consumedCalories.round(),
                targetCalories: calorieTargets.dailyTarget,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
