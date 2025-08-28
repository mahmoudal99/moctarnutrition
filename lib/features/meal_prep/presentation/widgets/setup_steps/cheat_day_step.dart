import 'package:flutter/material.dart';
import '../../../../../core/constants/app_constants.dart';
import 'personalized_title.dart';

class CheatDayStep extends StatelessWidget {
  final String? selectedDay;
  final ValueChanged<String?> onSelect;
  final String? userName;

  const CheatDayStep({
    super.key,
    required this.selectedDay,
    required this.onSelect,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PersonalizedTitle(
          userName: userName,
          title: 'Choose {name}\'s cheat day',
          fallbackTitle: 'Choose your cheat day',
        ),
        const SizedBox(height: AppConstants.spacingS),
        PersonalizedTitle(
          userName: userName,
          title:
              'Select one day per week where {name} can enjoy their favorite foods',
          fallbackTitle:
              'Select one day per week where you can enjoy your favorite foods',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppConstants.textSecondary),
        ),
        const SizedBox(height: AppConstants.spacingL),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ...daysOfWeek.map((day) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppConstants.spacingM),
                      child: _buildDayCard(
                        context,
                        day: day,
                        isSelected: selectedDay == day,
                        onTap: () => onSelect(day),
                      ),
                    )),
                const SizedBox(height: AppConstants.spacingM),
                _buildDayCard(
                  context,
                  day: 'No cheat day',
                  isSelected: selectedDay == null,
                  onTap: () => onSelect(null),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(
    BuildContext context, {
    required String day,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: isSelected ? AppConstants.primaryColor : Colors.white,
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          side: BorderSide(
            color: isSelected
                ? AppConstants.primaryColor
                : AppConstants.textTertiary.withOpacity(0.15),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected
                    ? AppConstants.surfaceColor
                    : AppConstants.primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  day,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected
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
