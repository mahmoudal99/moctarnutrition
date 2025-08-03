import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/meal_model.dart';

class NutritionSummaryCard extends StatelessWidget {
  final MealPlanModel mealPlan;

  const NutritionSummaryCard({
    super.key,
    required this.mealPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutrition Summary',
              style: AppTextStyles.heading4,
            ),
            const SizedBox(height: AppConstants.spacingS),
            Row(
              children: [
                Expanded(
                  child: _buildNutritionCard(
                    'Calories',
                    '${mealPlan.totalCalories}',
                    Icons.local_fire_department,
                    AppConstants.warningColor,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingS),
                Expanded(
                  child: _buildNutritionCard(
                    'Protein',
                    '${mealPlan.totalProtein.toStringAsFixed(0)}g',
                    Icons.fitness_center,
                    AppConstants.accentColor,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingS),
                Expanded(
                  child: _buildNutritionCard(
                    'Carbs',
                    '${mealPlan.totalCarbs.toStringAsFixed(0)}g',
                    Icons.grain,
                    AppConstants.secondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingS),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppConstants.spacingXS),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
} 