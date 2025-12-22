import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../../shared/widgets/onboarding_option_button.dart';

class OnboardingCheatDayStep extends StatefulWidget {
  final String? selectedCheatDay; // e.g., "Monday"
  final ValueChanged<String?> onCheatDayChanged;
  final bool? isBodybuilder;

  const OnboardingCheatDayStep({
    super.key,
    required this.selectedCheatDay,
    required this.onCheatDayChanged,
    this.isBodybuilder,
  });

  @override
  State<OnboardingCheatDayStep> createState() => _OnboardingCheatDayStepState();
}

class _OnboardingCheatDayStepState extends State<OnboardingCheatDayStep> {
  static const List<String> _allDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _weekendDays = [
    'Saturday',
    'Sunday',
  ];

  String? _selectedDay;

  List<String> get _availableDays {
    // If user is a bodybuilder, only show Saturday and Sunday
    if (widget.isBodybuilder == true) {
      return _weekendDays;
    }
    return _allDays;
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.selectedCheatDay;
    // If bodybuilder and selected day is not weekend, clear selection
    if (widget.isBodybuilder == true && 
        _selectedDay != null && 
        !_weekendDays.contains(_selectedDay)) {
      _selectedDay = null;
      widget.onCheatDayChanged(null);
    }
  }

  @override
  void didUpdateWidget(OnboardingCheatDayStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If bodybuilder status changed and selected day is not valid, clear selection
    if (oldWidget.isBodybuilder != widget.isBodybuilder) {
      if (widget.isBodybuilder == true && 
          _selectedDay != null && 
          !_weekendDays.contains(_selectedDay)) {
        setState(() {
          _selectedDay = null;
          widget.onCheatDayChanged(null);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNoneOption(),
        const SizedBox(height: AppConstants.spacingM),
        ..._availableDays.map(_buildDayOption),
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
    return _buildOptionTile(
      title: day,
      isSelected: isSelected,
      onTap: () {
        setState(() => _selectedDay = isSelected ? null : day);
        widget.onCheatDayChanged(isSelected ? null : day);
      },
    );
  }

  Widget _buildOptionTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingXS),
      child: OnboardingOptionButton(
        label: title,
        isSelected: isSelected,
        onTap: onTap,
      ),
    );
  }
}





