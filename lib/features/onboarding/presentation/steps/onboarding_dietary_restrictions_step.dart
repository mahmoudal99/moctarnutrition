import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class OnboardingDietaryRestrictionsStep extends StatelessWidget {
  final List<String> selectedDietaryRestrictions;
  final ValueChanged<String> onSelect;
  final List<String> restrictions;

  const OnboardingDietaryRestrictionsStep({
    super.key,
    required this.selectedDietaryRestrictions,
    required this.onSelect,
    required this.restrictions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: restrictions.map((restriction) {
        final isSelected = selectedDietaryRestrictions.contains(restriction);
        return _SelectionCard(
          title: restriction,
          subtitle: _getDietaryRestrictionDescription(restriction),
          icon: Icons.restaurant,
          isSelected: isSelected,
          isMultiSelect: true,
          onTap: () => onSelect(restriction),
        );
      }).toList(),
    );
  }

  String _getDietaryRestrictionDescription(String restriction) {
    switch (restriction) {
      case 'Vegetarian':
        return 'No meat, but includes dairy and eggs';
      case 'Vegan':
        return 'No animal products';
      case 'Gluten-Free':
        return 'No gluten-containing foods (e.g., wheat, barley, rye)';
      case 'Dairy-Free':
        return 'No dairy products (milk, cheese, yogurt, etc.)';
      case 'Keto':
        return 'Low-carb, high-fat diet';
      case 'Paleo':
        return 'Whole foods, no processed foods';
      case 'Low-Carb':
        return 'Reduced carbohydrate intake';
      case 'None':
        return 'No dietary restrictions';
      default:
        return '';
    }
  }
}

class _SelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final bool isMultiSelect;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    this.isMultiSelect = false,
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
                  isMultiSelect
                      ? (isSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank)
                      : (isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked),
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
