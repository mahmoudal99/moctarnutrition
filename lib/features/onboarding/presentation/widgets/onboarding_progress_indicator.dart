import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/onboarding_step.dart';

class OnboardingProgressIndicator extends StatelessWidget {
  final List<OnboardingStep> steps;
  final int currentPage;
  final VoidCallback? onBack;

  const OnboardingProgressIndicator({
    super.key,
    required this.steps,
    required this.currentPage,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingL,
        vertical: AppConstants.spacingS,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Back arrow button
              if (currentPage > 0 && onBack != null)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: currentPage > 0 ? 1.0 : 0.0,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onBack?.call();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ),
              if (currentPage > 0 && onBack != null)
                const SizedBox(width: AppConstants.spacingM),
              // Progress bar
              Expanded(
                child: Row(
                  children: List.generate(steps.length, (index) {
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: 3,
                        margin: EdgeInsets.only(
                          right: index < steps.length - 1
                              ? AppConstants.spacingXS
                              : 0,
                        ),
                        decoration: BoxDecoration(
                          color: index <= currentPage
                              ? steps[index].color
                              : AppConstants.textTertiary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingXS),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              '${currentPage + 1} of ${steps.length}',
              key: ValueKey(currentPage),
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                color: AppConstants.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
