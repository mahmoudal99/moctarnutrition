import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/meal_model.dart';

class NutritionSummaryCard extends StatelessWidget {
  final MealDay mealDay;
  final int dayNumber;

  const NutritionSummaryCard({
    super.key,
    required this.mealDay,
    required this.dayNumber,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate consumed nutrition
    mealDay.calculateConsumedNutrition();

    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nutrition cards
          Row(
            children: [
              Expanded(
                child: _buildNutritionCard(
                  'Calories',
                  '${mealDay.totalCalories}',
                  Icons.local_fire_department,
                  AppConstants.copperwoodColor,
                ),
              ),
              const SizedBox(width: AppConstants.spacingS),
              Expanded(
                child: _buildNutritionCard(
                  'Protein',
                  '${mealDay.totalProtein.toStringAsFixed(0)}g',
                  Icons.fitness_center,
                  AppConstants.accentColor,
                ),
              ),
              const SizedBox(width: AppConstants.spacingS),
              Expanded(
                child: _buildNutritionCard(
                  'Carbs',
                  '${mealDay.totalCarbs.toStringAsFixed(0)}g',
                  Icons.grain,
                  AppConstants.secondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 8,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(
              height: AppConstants.spacingS,
            ),
            Text(
              label,
              style: AppTextStyles.bodySmall
            ),
          ],
        ),
      ),
    );
  }
}
