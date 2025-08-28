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

  const OnboardingNavigationButtons({
    super.key,
    required this.currentPage,
    required this.totalSteps,
    required this.isNextEnabled,
    required this.onBack,
    required this.onNext,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    // Hide navigation buttons for workout notifications step and rating step since they have their own
    if (currentPage == 16 ||
        currentPage == 17 ||
        currentPage == totalSteps - 1) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingL,
        vertical: AppConstants.spacingM,
      ),
      child: Row(
        children: [
          if (currentPage > 0)
            Expanded(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: currentPage > 0 ? 1.0 : 0.0,
                child: SizedBox(
                  height: 52,
                  child: CustomButton(
                    text: 'Back',
                    type: ButtonType.outline,
                    onPressed: onBack,
                  ),
                ),
              ),
            ),
          if (currentPage > 0) const SizedBox(width: AppConstants.spacingS),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: SizedBox(
                key: ValueKey(currentPage),
                height: 52,
                child: CustomButton(
                  text: currentPage == totalSteps - 1 ? 'Get Started' : 'Next',
                  onPressed: isNextEnabled
                      ? () {
                          HapticFeedback.mediumImpact();
                          if (currentPage == totalSteps - 1) {
                            onComplete?.call();
                          } else {
                            onNext();
                          }
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
