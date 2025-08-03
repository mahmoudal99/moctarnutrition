import 'package:flutter/material.dart';
import '../../../../../core/constants/app_constants.dart';

enum NutritionGoal { loseFat, buildMuscle, improveEnergy, maintainWeight }

extension NutritionGoalExt on NutritionGoal {
  String get label {
    switch (this) {
      case NutritionGoal.loseFat:
        return 'Lose fat';
      case NutritionGoal.buildMuscle:
        return 'Build muscle';
      case NutritionGoal.improveEnergy:
        return 'Improve energy';
      case NutritionGoal.maintainWeight:
        return 'Maintain weight';
    }
  }

  IconData get icon {
    switch (this) {
      case NutritionGoal.loseFat:
        return Icons.trending_down;
      case NutritionGoal.buildMuscle:
        return Icons.fitness_center;
      case NutritionGoal.improveEnergy:
        return Icons.bolt;
      case NutritionGoal.maintainWeight:
        return Icons.track_changes;
    }
  }
}

class GoalSelectionStep extends StatelessWidget {
  final NutritionGoal? selected;
  final ValueChanged<NutritionGoal> onSelect;

  const GoalSelectionStep({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "What's your primary nutrition goal?",
          style: AppTextStyles.heading4,
        ),
        const SizedBox(height: AppConstants.spacingL),
        Wrap(
          spacing: AppConstants.spacingM,
          runSpacing: AppConstants.spacingM,
          children: NutritionGoal.values.map((goal) {
            final isSelected = selected == goal;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    goal.icon,
                    size: 18,
                    color: isSelected
                        ? AppConstants.surfaceColor
                        : AppConstants.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(goal.label),
                ],
              ),
              selected: isSelected,
              selectedColor: AppConstants.primaryColor,
              backgroundColor: AppConstants.primaryColor.withOpacity(0.08),
              labelStyle: AppTextStyles.bodyMedium.copyWith(
                color: isSelected
                    ? AppConstants.surfaceColor
                    : AppConstants.primaryColor,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) => onSelect(goal),
            );
          }).toList(),
        ),
        const SizedBox(height: AppConstants.spacingL),
      ],
    );
  }
} 