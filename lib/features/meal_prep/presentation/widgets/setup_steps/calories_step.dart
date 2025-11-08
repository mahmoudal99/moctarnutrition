import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_constants.dart';
import 'goal_selection_note.dart';
import 'personalized_title.dart';

class CaloriesStep extends StatelessWidget {
  final int targetCalories;
  final ValueChanged<int> onChanged;
  final String? userName;
  final int?
      clientTargetCalories; // Client's calculated calories from onboarding

  const CaloriesStep({
    super.key,
    required this.targetCalories,
    required this.onChanged,
    this.userName,
    this.clientTargetCalories,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PersonalizedTitle(
          userName: userName,
          title: 'Set {name}\'s Daily Calorie Target',
          fallbackTitle: 'Set Your Daily Calorie Target',
        ),

        // Show client's calculated calories if available
        if (clientTargetCalories != null) ...[
          const SizedBox(height: AppConstants.spacingM),
          GoalSelectionNote(
            message:
                'Client\'s calculated target: $clientTargetCalories calories',
            accentColor: AppConstants.carbsColor,
          ),
        ],

        const SizedBox(height: AppConstants.spacingL),

        TextFormField(
          initialValue: targetCalories.toString(),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Daily calorie target',
            suffixText: 'cal',
          ),
          onChanged: (value) {
            final parsedValue = int.tryParse(value);
            if (parsedValue != null) {
              onChanged(parsedValue);
            }
          },
        ),
        const SizedBox(height: AppConstants.spacingL),
      ],
    );
  }
}
