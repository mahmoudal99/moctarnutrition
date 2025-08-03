import 'package:flutter/material.dart';
import '../../../../../core/constants/app_constants.dart';

enum MealFrequencyOption {
  threeMeals,
  threeMealsOneSnack,
  fourMeals,
  fourMealsOneSnack,
  fiveMeals,
  fiveMealsOneSnack
}

class MealFrequencyStep extends StatelessWidget {
  final MealFrequencyOption? selected;
  final ValueChanged<MealFrequencyOption> onSelect;

  const MealFrequencyStep({
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
          'How many meals would you like per day?',
          style: AppTextStyles.heading4,
        ),
        const SizedBox(height: AppConstants.spacingL),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildOptionCard(
                  context,
                  label: '3 meals',
                  value: MealFrequencyOption.threeMeals,
                  selected: selected == MealFrequencyOption.threeMeals,
                  onTap: () => onSelect(MealFrequencyOption.threeMeals),
                ),
                const SizedBox(height: AppConstants.spacingM),
                _buildOptionCard(
                  context,
                  label: '3 meals + 1 snack',
                  value: MealFrequencyOption.threeMealsOneSnack,
                  selected: selected == MealFrequencyOption.threeMealsOneSnack,
                  onTap: () => onSelect(MealFrequencyOption.threeMealsOneSnack),
                ),
                const SizedBox(height: AppConstants.spacingM),
                _buildOptionCard(
                  context,
                  label: '4 meals',
                  value: MealFrequencyOption.fourMeals,
                  selected: selected == MealFrequencyOption.fourMeals,
                  onTap: () => onSelect(MealFrequencyOption.fourMeals),
                ),
                const SizedBox(height: AppConstants.spacingM),
                _buildOptionCard(
                  context,
                  label: '4 meals + 1 snack',
                  value: MealFrequencyOption.fourMealsOneSnack,
                  selected: selected == MealFrequencyOption.fourMealsOneSnack,
                  onTap: () => onSelect(MealFrequencyOption.fourMealsOneSnack),
                ),
                const SizedBox(height: AppConstants.spacingM),
                _buildOptionCard(
                  context,
                  label: '5 meals',
                  value: MealFrequencyOption.fiveMeals,
                  selected: selected == MealFrequencyOption.fiveMeals,
                  onTap: () => onSelect(MealFrequencyOption.fiveMeals),
                ),
                const SizedBox(height: AppConstants.spacingM),
                _buildOptionCard(
                  context,
                  label: '5 meals + 1 snack',
                  value: MealFrequencyOption.fiveMealsOneSnack,
                  selected: selected == MealFrequencyOption.fiveMealsOneSnack,
                  onTap: () => onSelect(MealFrequencyOption.fiveMealsOneSnack),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String label,
    required MealFrequencyOption value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: selected ? AppConstants.primaryColor : Colors.white,
        elevation: selected ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          side: BorderSide(
            color: selected
                ? AppConstants.primaryColor
                : AppConstants.textTertiary.withOpacity(0.15),
            width: selected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected
                    ? AppConstants.surfaceColor
                    : AppConstants.primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: selected
                        ? AppConstants.surfaceColor
                        : AppConstants.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 