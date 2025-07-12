import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../../shared/models/user_model.dart';

class OnboardingFitnessGoalStep extends StatelessWidget {
  final FitnessGoal selectedFitnessGoal;
  final ValueChanged<FitnessGoal> onSelect;

  const OnboardingFitnessGoalStep({
    super.key,
    required this.selectedFitnessGoal,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: FitnessGoal.values.map((goal) {
        final isSelected = selectedFitnessGoal == goal;
        return _SelectionCard(
          title: _getFitnessGoalTitle(goal),
          subtitle: _getFitnessGoalDescription(goal),
          icon: _getFitnessGoalIcon(goal),
          isSelected: isSelected,
          onTap: () => onSelect(goal),
        );
      }).toList(),
    );
  }

  String _getFitnessGoalTitle(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return 'Weight Loss';
      case FitnessGoal.muscleGain:
        return 'Muscle Gain';
      case FitnessGoal.maintenance:
        return 'Maintenance';
      case FitnessGoal.endurance:
        return 'Endurance';
      case FitnessGoal.strength:
        return 'Strength';
    }
  }

  String _getFitnessGoalDescription(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return 'Lose weight and improve body composition';
      case FitnessGoal.muscleGain:
        return 'Build muscle mass and strength';
      case FitnessGoal.maintenance:
        return 'Maintain current fitness level';
      case FitnessGoal.endurance:
        return 'Improve cardiovascular fitness';
      case FitnessGoal.strength:
        return 'Increase overall strength';
    }
  }

  IconData _getFitnessGoalIcon(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return Icons.trending_down;
      case FitnessGoal.muscleGain:
        return Icons.fitness_center;
      case FitnessGoal.maintenance:
        return Icons.balance;
      case FitnessGoal.endurance:
        return Icons.directions_run;
      case FitnessGoal.strength:
        return Icons.bolt;
    }
  }
}

class _SelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppConstants.primaryColor.withOpacity(0.08)
                  : AppConstants.surfaceColor,
              border: Border.all(
                color: isSelected
                    ? AppConstants.primaryColor.withOpacity(0.3)
                    : AppConstants.textTertiary.withOpacity(0.2),
                width: isSelected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              boxShadow: isSelected ? AppConstants.shadowS : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppConstants.primaryColor
                        : AppConstants.textTertiary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? AppConstants.surfaceColor
                        : AppConstants.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppConstants.primaryColor
                              : AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingXS),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.radio_button_checked,
                  color: isSelected
                      ? AppConstants.primaryColor
                      : AppConstants.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 