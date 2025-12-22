import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../../shared/widgets/onboarding_option_button.dart';

class OnboardingWeeklyWorkoutGoalStep extends StatefulWidget {
  final int? selectedDaysPerWeek;
  final List<int>? selectedSpecificDays;
  final ValueChanged<int> onDaysPerWeekChanged;
  final ValueChanged<List<int>> onSpecificDaysChanged;

  const OnboardingWeeklyWorkoutGoalStep({
    super.key,
    this.selectedDaysPerWeek,
    this.selectedSpecificDays,
    required this.onDaysPerWeekChanged,
    required this.onSpecificDaysChanged,
  });

  @override
  State<OnboardingWeeklyWorkoutGoalStep> createState() =>
      _OnboardingWeeklyWorkoutGoalStepState();
}

class _OnboardingWeeklyWorkoutGoalStepState
    extends State<OnboardingWeeklyWorkoutGoalStep> {
  late int _selectedDaysPerWeek;
  late List<int> _selectedSpecificDays;
  late bool _isSpecificDaysMode;

  final List<int> _workoutDaysOptions = [1, 2, 3, 4, 5, 6, 7];
  final List<String> _dayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDaysPerWeek = widget.selectedDaysPerWeek ?? 3;
    _selectedSpecificDays =
        widget.selectedSpecificDays ?? [1, 3, 5]; // Mon, Wed, Fri
    _isSpecificDaysMode = false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Segmented control for selection type
        _buildSegmentedControl(),
        const SizedBox(height: AppConstants.spacingL),

        // Days per week options or specific days
        _isSpecificDaysMode
            ? _buildSpecificDaysOptions()
            : _buildDaysPerWeekOptions(),
      ],
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingXS),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppConstants.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentButton(
              text: 'Days Per Week',
              isSelected: !_isSpecificDaysMode,
              onTap: () {
                setState(() {
                  _isSpecificDaysMode = false;
                });
              },
            ),
          ),
          const SizedBox(width: AppConstants.spacingXS),
          Expanded(
            child: _buildSegmentButton(
              text: 'Specific Days',
              isSelected: _isSpecificDaysMode,
              onTap: () {
                setState(() {
                  _isSpecificDaysMode = true;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.spacingS,
          horizontal: AppConstants.spacingM,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
        ),
        child: Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected
                ? AppConstants.surfaceColor
                : AppConstants.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDaysPerWeekOptions() {
    return Column(
      children: _workoutDaysOptions.map((days) {
        final isSelected = _selectedDaysPerWeek == days;
        return _buildDayOption(days, isSelected);
      }).toList(),
    );
  }

  Widget _buildDayOption(int days, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingXS),
      child: OnboardingOptionButton(
        label: _getDayOptionText(days),
        isSelected: isSelected,
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedDaysPerWeek = days;
          });
          widget.onDaysPerWeekChanged(days);
        },
        trailing: Container(
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
      ),
    );
  }

  Widget _buildSpecificDaysOptions() {
    return Column(
      children: List.generate(7, (index) {
        final dayIndex = index + 1; // 1 = Monday, 7 = Sunday
        final isSelected = _selectedSpecificDays.contains(dayIndex);
        return _buildSpecificDayOption(dayIndex, isSelected);
      }),
    );
  }

  Widget _buildSpecificDayOption(int dayIndex, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingXS),
      child: OnboardingOptionButton(
        label: _dayNames[dayIndex - 1],
        isSelected: isSelected,
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            if (isSelected) {
              _selectedSpecificDays.remove(dayIndex);
            } else {
              _selectedSpecificDays.add(dayIndex);
            }
          });
          widget.onSpecificDaysChanged(_selectedSpecificDays);
        },
        trailing: Container(
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
      ),
    );
  }

  String _getDayOptionText(int days) {
    switch (days) {
      case 1:
        return '1 day a week';
      case 2:
        return '2 days a week';
      case 3:
        return '3 days a week';
      case 4:
        return '4 days a week';
      case 5:
        return '5 days a week';
      case 6:
        return '6 days a week';
      case 7:
        return 'Every day';
      default:
        return '$days days a week';
    }
  }
}
