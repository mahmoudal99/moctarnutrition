import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_button.dart';

class OnboardingNavigationButtons extends StatelessWidget {
  final int currentPage;
  final int totalSteps;
  final bool isNextEnabled;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback? onComplete;
  final VoidCallback? onNotificationSkip;
  final VoidCallback? onNotificationEnable;

  const OnboardingNavigationButtons({
    super.key,
    required this.currentPage,
    required this.totalSteps,
    required this.isNextEnabled,
    required this.onBack,
    required this.onNext,
    this.onComplete,
    this.onNotificationSkip,
    this.onNotificationEnable,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFinalStep = currentPage == totalSteps - 1;

    // Default navigation buttons (Next only)
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingL,
        vertical: AppConstants.spacingM,
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: SizedBox(
                key: ValueKey(currentPage),
                height: 52,
                child: CustomButton(
                  type: ButtonType.auth,
                  text: isFinalStep
                      ? 'Support Regimen'
                      : currentPage == 0
                          ? "Let's Begin"
                          : 'Next',
                  onPressed: isNextEnabled
                      ? () {
                          HapticFeedback.mediumImpact();
                          onNext();
                        }
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
