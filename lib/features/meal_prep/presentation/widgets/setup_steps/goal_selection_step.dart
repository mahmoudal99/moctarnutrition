import 'package:champions_gym_app/shared/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import '../../../../../core/constants/app_constants.dart';
import 'personalized_title.dart';
import 'goal_selection_note.dart';

// Use the same FitnessGoal enum as the client onboarding
// This ensures language consistency between client and admin sides

class GoalSelectionStep extends StatelessWidget {
  final FitnessGoal? selected;
  final ValueChanged<FitnessGoal> onSelect;
  final String? userName;
  final FitnessGoal? clientFitnessGoal; // Client's onboarding choice

  const GoalSelectionStep({
    super.key,
    required this.selected,
    required this.onSelect,
    this.userName,
    this.clientFitnessGoal,
  });

  @override
  Widget build(BuildContext context) {
    // No mapping needed since we're using the same FitnessGoal enum
    FitnessGoal? clientGoal = clientFitnessGoal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PersonalizedTitle(
          userName: userName,
          title: "What's {name}'s primary nutrition goal?",
          fallbackTitle: "What's your primary nutrition goal?",
        ),

        // Show client's onboarding choice if available
        if (clientFitnessGoal != null) ...[
          const SizedBox(height: AppConstants.spacingM),
          GoalSelectionNote(
            message:
                'Client selected: ${_getFitnessGoalTitle(clientFitnessGoal!)} during onboarding',
            accentColor: AppConstants.carbsColor,
          ),
        ],

        const SizedBox(height: AppConstants.spacingL),

        // Pre-select client's choice if no admin selection yet
        if (selected == null && clientGoal != null) ...[
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              border: Border.all(
                color: AppConstants.primaryColor.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: AppConstants.spacingS),
                Expanded(
                  child: Text(
                    'Pre-selected based on client\'s onboarding choice',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
        ],

        Wrap(
          spacing: AppConstants.spacingM,
          runSpacing: AppConstants.spacingM,
          children: FitnessGoal.values.map((goal) {
            final isSelected = selected == goal;
            final isClientChoice = clientGoal == goal;

            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getFitnessGoalTitle(goal)),
                  if (isClientChoice && selected == null) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: AppConstants.primaryColor,
                    ),
                  ],
                ],
              ),
              selected: isSelected,
              selectedColor: AppConstants.primaryColor.withOpacity(0.8),
              backgroundColor: Colors.white,
              labelStyle: isSelected
                  ? AppTextStyles.bodySmall.copyWith(color: Colors.white)
                  : AppTextStyles.bodySmall.copyWith(color: Colors.black),
              onSelected: (_) => onSelect(goal),
            );
          }).toList(),
        ),
        const SizedBox(height: AppConstants.spacingL),
      ],
    );
  }

  String _getFitnessGoalTitle(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return 'Weight Loss';
      case FitnessGoal.weightGain:
        return 'Gain Weight';
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
      case FitnessGoal.weightGain:
        return 'Gain weight and increase body mass';
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
      case FitnessGoal.weightGain:
        return Icons.trending_up;
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
