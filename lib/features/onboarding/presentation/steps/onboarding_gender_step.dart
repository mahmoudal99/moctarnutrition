import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../../shared/widgets/onboarding_option_button.dart';

class OnboardingGenderStep extends StatefulWidget {
  final String? selectedGender;
  final ValueChanged<String> onSelect;

  const OnboardingGenderStep({
    super.key,
    this.selectedGender,
    required this.onSelect,
  });

  @override
  State<OnboardingGenderStep> createState() => _OnboardingGenderStepState();
}

class _OnboardingGenderStepState extends State<OnboardingGenderStep> {
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.selectedGender;
  }

  @override
  void didUpdateWidget(OnboardingGenderStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedGender != widget.selectedGender) {
      _selectedGender = widget.selectedGender;
    }
  }

  void _handleGenderSelection(String gender) {
    setState(() {
      _selectedGender = gender;
    });
    widget.onSelect(gender);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OnboardingOptionButton(
                  label: 'Male',
                  isSelected: _selectedGender == 'Male',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _handleGenderSelection('Male');
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(AppConstants.spacingS),
                    decoration: BoxDecoration(
                      color: _selectedGender == 'Male'
                          ? AppConstants.primaryColor
                          : AppConstants.surfaceColor,
                      borderRadius: BorderRadius.circular(AppConstants.radiusS),
                    ),
                    child: Icon(
                      Icons.male,
                      color: _selectedGender == 'Male'
                          ? AppConstants.surfaceColor
                          : AppConstants.textSecondary,
                      size: 20,
                    ),
                  ),
                  trailing: _selectedGender == 'Male'
                      ? const Icon(
                          Icons.circle_outlined,
                          color: AppConstants.primaryColor,
                          size: 24,
                        )
                      : null,
                ),
                const SizedBox(height: AppConstants.spacingM),
                OnboardingOptionButton(
                  label: 'Female',
                  isSelected: _selectedGender == 'Female',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _handleGenderSelection('Female');
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(AppConstants.spacingS),
                    decoration: BoxDecoration(
                      color: _selectedGender == 'Female'
                          ? AppConstants.primaryColor
                          : AppConstants.surfaceColor,
                      borderRadius: BorderRadius.circular(AppConstants.radiusS),
                    ),
                    child: Icon(
                      Icons.female,
                      color: _selectedGender == 'Female'
                          ? AppConstants.surfaceColor
                          : AppConstants.textSecondary,
                      size: 20,
                    ),
                  ),
                  trailing: _selectedGender == 'Female'
                      ? const Icon(
                          Icons.circle_outlined,
                          color: AppConstants.primaryColor,
                          size: 24,
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}
