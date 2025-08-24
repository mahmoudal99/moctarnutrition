import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/calorie_calculation_service.dart';
import '../../../../shared/models/meal_model.dart';

class NutritionGoalsCard extends StatefulWidget {
  final MacroBreakdown macros;
  final DateTime selectedDate;
  final MealDay? currentDayMeals;

  const NutritionGoalsCard({
    super.key,
    required this.macros,
    required this.selectedDate,
    this.currentDayMeals,
  });

  @override
  State<NutritionGoalsCard> createState() => _NutritionGoalsCardState();
}

class _NutritionGoalsCardState extends State<NutritionGoalsCard> {
  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutrition Goals',
            style: AppTextStyles.heading5.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),

          // Macro cards in a row
          Row(
            children: [
              Expanded(child: _buildMacroCard(0)), // Protein
              const SizedBox(width: 12),
              Expanded(child: _buildMacroCard(1)), // Carbs
              const SizedBox(width: 12),
              Expanded(child: _buildMacroCard(2)), // Fat
            ],
          ),

          const SizedBox(height: AppConstants.spacingM),

          // Pagination dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPaginationDot(0, true),
              const SizedBox(width: 8),
              _buildPaginationDot(1, false),
              const SizedBox(width: 8),
              _buildPaginationDot(2, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(int index) {
    final macroData = _getMacroData(index);

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Macro amount
          Text(
            '${macroData.grams}g',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(
            height: AppConstants.spacingS,
          ),
          // Macro label with bold "left"
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
              children: [
                TextSpan(text: macroData.label.split(' ')[0] + ' '),
                const TextSpan(
                  text: 'left',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Circular progress indicator with icon
          Center(
            child: SizedBox(
              width: 50,
              height: 50,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                  ),

                  // Progress circle
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      value: _getMacroProgress(index),
                      strokeWidth: 2,
                      backgroundColor: Colors.transparent,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(macroData.color),
                    ),
                  ),

                  // Light grey background circle for icon
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                  ),

                  // Icon in center
                  Icon(
                    macroData.icon,
                    color: macroData.color,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationDot(int index, bool isActive) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppConstants.primaryColor : Colors.grey.shade300,
      ),
    );
  }

  MacroData _getMacroData(int index) {
    // Calculate consumed macros from current day meals
    double consumedProtein = 0.0;
    double consumedCarbs = 0.0;
    double consumedFat = 0.0;

    if (widget.currentDayMeals != null) {
      // Always use consumed macros, even if they're 0
      consumedProtein = widget.currentDayMeals!.consumedProtein;
      consumedCarbs = widget.currentDayMeals!.consumedCarbs;
      consumedFat = widget.currentDayMeals!.consumedFat;
    }

    switch (index) {
      case 0:
        return MacroData(
          grams: (widget.macros.protein.grams - consumedProtein).round(),
          label: 'Protein left',
          icon: Icons.restaurant, // Fork and knife icon
          color: Colors.red,
        );
      case 1:
        return MacroData(
          grams: (widget.macros.carbs.grams - consumedCarbs).round(),
          label: 'Carbs left',
          icon: Icons.grain, // Wheat/grain icon
          color: Colors.orange,
        );
      case 2:
        return MacroData(
          grams: (widget.macros.fat.grams - consumedFat).round(),
          label: 'Fat left',
          icon: Icons.water_drop, // Water drop/avocado icon
          color: Colors.blue,
        );
      default:
        return MacroData(
          grams: 0,
          label: '',
          icon: Icons.circle,
          color: Colors.black,
        );
    }
  }

  double _getMacroProgress(int index) {
    if (widget.currentDayMeals == null) return 0.0;

    double targetGrams = 0.0;
    double consumedGrams = 0.0;

    switch (index) {
      case 0: // Protein
        targetGrams = widget.macros.protein.grams.toDouble();
        consumedGrams = widget.currentDayMeals!.consumedProtein;
        break;
      case 1: // Carbs
        targetGrams = widget.macros.carbs.grams.toDouble();
        consumedGrams = widget.currentDayMeals!.consumedCarbs;
        break;
      case 2: // Fat
        targetGrams = widget.macros.fat.grams.toDouble();
        consumedGrams = widget.currentDayMeals!.consumedFat;
        break;
    }

    final progress = targetGrams > 0 ? consumedGrams / targetGrams : 0.0;
    return progress.clamp(0.0, 1.0);
  }
}

class MacroData {
  final int grams;
  final String label;
  final IconData icon;
  final Color color;

  MacroData({
    required this.grams,
    required this.label,
    required this.icon,
    required this.color,
  });
}
