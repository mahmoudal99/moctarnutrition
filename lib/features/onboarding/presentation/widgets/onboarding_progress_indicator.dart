import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/onboarding_step.dart';

class OnboardingProgressIndicator extends StatelessWidget {
  final List<OnboardingStep> steps;
  final int currentPage;

  const OnboardingProgressIndicator({
    super.key,
    required this.steps,
    required this.currentPage,
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
            children: List.generate(steps.length, (index) {
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: 3,
                  margin: EdgeInsets.only(
                    right:
                        index < steps.length - 1 ? AppConstants.spacingXS : 0,
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
