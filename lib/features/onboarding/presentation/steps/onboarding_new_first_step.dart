import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';

class OnboardingNewFirstStep extends StatefulWidget {
  final bool? isBodybuilder;
  final ValueChanged<bool> onSelect;

  const OnboardingNewFirstStep({
    super.key,
    this.isBodybuilder,
    required this.onSelect,
  });

  @override
  State<OnboardingNewFirstStep> createState() => _OnboardingNewFirstStepState();
}

class _OnboardingNewFirstStepState extends State<OnboardingNewFirstStep> {
  bool? _selectedValue;
  bool _yesButtonVisible = false;
  bool _noButtonVisible = false;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.isBodybuilder;
    // Animate buttons in with a delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _yesButtonVisible = true;
        });
      }
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() {
          _noButtonVisible = true;
        });
      }
    });
  }

  @override
  void didUpdateWidget(OnboardingNewFirstStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isBodybuilder != widget.isBodybuilder) {
      _selectedValue = widget.isBodybuilder;
    }
  }

  void _handleSelection(bool value) {
    setState(() {
      _selectedValue = value;
    });
    widget.onSelect(value);
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
                _buildOption('Yes', _selectedValue == true, _yesButtonVisible, () {
                  HapticFeedback.lightImpact();
                  _handleSelection(true);
                }),
                const SizedBox(height: AppConstants.spacingM),
                _buildOption('No', _selectedValue == false, _noButtonVisible, () {
                  HapticFeedback.lightImpact();
                  _handleSelection(false);
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOption(String label, bool isSelected, bool isVisible, VoidCallback onTap) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(
                color: isSelected
                    ? AppConstants.primaryColor
                    : AppConstants.borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? AppConstants.primaryColor
                        : AppConstants.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
