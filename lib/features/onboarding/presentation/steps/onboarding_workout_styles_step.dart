import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class OnboardingWorkoutStylesStep extends StatelessWidget {
  final List<String> selectedWorkoutStyles;
  final ValueChanged<String> onSelect;
  final List<String> styles;

  const OnboardingWorkoutStylesStep({
    super.key,
    required this.selectedWorkoutStyles,
    required this.onSelect,
    required this.styles,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: styles.map((style) {
        final isSelected = selectedWorkoutStyles.contains(style);
        return _SelectionCard(
          title: style,
          subtitle: _getWorkoutStyleDescription(style),
          icon: _getWorkoutStyleIcon(style),
          isSelected: isSelected,
          isMultiSelect: true,
          onTap: () => onSelect(style),
        );
      }).toList(),
    );
  }

  IconData _getWorkoutStyleIcon(String style) {
    switch (style) {
      case 'Strength Training':
        return Icons.fitness_center;
      case 'Body Building':
        return Icons.sports_gymnastics;
      case 'Cardio':
        return Icons.favorite;
      case 'HIIT':
        return Icons.timer;
      case 'Running':
        return Icons.directions_run;
      default:
        return Icons.fitness_center;
    }
  }

  String _getWorkoutStyleDescription(String style) {
    switch (style) {
      case 'Strength Training':
        return 'Build muscle and strength';
      case 'Body Building':
        return 'Focus on muscle hypertrophy and definition';
      case 'Cardio':
        return 'Boost heart health and overall fitness';
      case 'HIIT':
        return 'High-intensity interval training';
      case 'Running':
        return 'Endurance and cardiovascular';
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
                      ? (isSelected ? Icons.check_box : Icons.check_box_outline_blank)
                      : (isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                  color: isSelected ? AppConstants.primaryColor : AppConstants.textTertiary,
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