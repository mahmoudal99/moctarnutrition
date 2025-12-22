import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../../shared/widgets/onboarding_option_button.dart';

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
                OnboardingOptionButton(
                  label: 'Yes',
                  isSelected: _selectedValue == true,
                  isVisible: _yesButtonVisible,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _handleSelection(true);
                  },
                ),
                const SizedBox(height: AppConstants.spacingM),
                OnboardingOptionButton(
                  label: 'No',
                  isSelected: _selectedValue == false,
                  isVisible: _noButtonVisible,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _handleSelection(false);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}
