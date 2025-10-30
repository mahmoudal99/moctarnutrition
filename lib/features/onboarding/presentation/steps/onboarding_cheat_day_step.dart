import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class OnboardingCheatDayStep extends StatefulWidget {
  final String? selectedCheatDay; // e.g., "Monday"
  final ValueChanged<String?> onCheatDayChanged;

  const OnboardingCheatDayStep({
    super.key,
    required this.selectedCheatDay,
    required this.onCheatDayChanged,
  });

  @override
  State<OnboardingCheatDayStep> createState() => _OnboardingCheatDayStepState();
}

class _OnboardingCheatDayStepState extends State<OnboardingCheatDayStep> {
  static const List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.selectedCheatDay;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNoneOption(),
        const SizedBox(height: AppConstants.spacingS),
        ..._days.map(_buildDayOption),
      ],
    );
  }

  Widget _buildNoneOption() {
    final bool isSelected = _selectedDay == null || _selectedDay!.isEmpty;
    return _buildOptionTile(
      title: 'No cheat day',
      isSelected: isSelected,
      onTap: () {
        setState(() => _selectedDay = null);
        widget.onCheatDayChanged(null);
      },
    );
  }

  Widget _buildDayOption(String day) {
    final bool isSelected = _selectedDay == day;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingXS),
      child: _buildOptionTile(
        title: day,
        isSelected: isSelected,
        onTap: () {
          setState(() => _selectedDay = isSelected ? null : day);
          widget.onCheatDayChanged(isSelected ? null : day);
        },
      ),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
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
                  : AppConstants.borderColor,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected
                        ? AppConstants.primaryColor
                        : AppConstants.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppConstants.primaryColor
                        : AppConstants.textTertiary,
                    width: 2,
                  ),
                  color: isSelected
                      ? AppConstants.primaryColor
                      : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: AppConstants.surfaceColor,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


