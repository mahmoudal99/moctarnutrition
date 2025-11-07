import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

enum WorkoutViewType { day, week }

class ViewToggle extends StatelessWidget {
  final WorkoutViewType selectedView;
  final ValueChanged<WorkoutViewType> onViewChanged;
  final bool isFloating;

  const ViewToggle({
    super.key,
    required this.selectedView,
    required this.onViewChanged,
    this.isFloating = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: isFloating
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingM,
              vertical: AppConstants.spacingS,
            ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildToggleOption(
            WorkoutViewType.day,
            'Today',
            Icons.view_day,
          ),
          _buildToggleOption(
            WorkoutViewType.week,
            'Week',
            Icons.view_week,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
    WorkoutViewType viewType,
    String label,
    IconData icon,
  ) {
    final isSelected = selectedView == viewType;

    return GestureDetector(
      onTap: () => onViewChanged(viewType),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal:
              isFloating ? AppConstants.spacingS : AppConstants.spacingM,
          vertical: isFloating ? AppConstants.spacingXS : AppConstants.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isFloating ? 14 : 16,
              color: isSelected
                  ? AppConstants.surfaceColor
                  : AppConstants.textSecondary,
            ),
            SizedBox(
                width: isFloating
                    ? AppConstants.spacingXS
                    : AppConstants.spacingXS),
            Text(
              label,
              style:
                  (isFloating ? AppTextStyles.caption : AppTextStyles.bodySmall)
                      .copyWith(
                color: isSelected
                    ? AppConstants.surfaceColor
                    : AppConstants.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
