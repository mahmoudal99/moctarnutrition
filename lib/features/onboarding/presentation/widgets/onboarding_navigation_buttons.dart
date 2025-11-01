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
    // Hide navigation buttons for final step only (but not rating step)
    if (currentPage == totalSteps - 1 && currentPage != 17) {
      return const SizedBox.shrink();
    }

    // Show notification-specific buttons for workout notifications step (step 16)
    if (currentPage == 16) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingL,
          vertical: AppConstants.spacingM,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 52,
                child: CustomButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onNotificationSkip?.call();
                  },
                  text: 'Not Now',
                  type: ButtonType.outline,
                ),
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: CustomButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onNotificationEnable?.call();
                  },
                  text: 'Enable Notifications',
                  type: ButtonType.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Default navigation buttons (Back & Next)
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
                  type: ButtonType.auth,
                  text: currentPage == totalSteps - 1 && currentPage != 17
                      ? 'Get Started'
                      : currentPage == 0
                          ? "Let's Begin"
                          : 'Next',
                  onPressed: isNextEnabled
                      ? () {
                          HapticFeedback.mediumImpact();
                          if (currentPage == totalSteps - 1 && currentPage != 17) {
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
