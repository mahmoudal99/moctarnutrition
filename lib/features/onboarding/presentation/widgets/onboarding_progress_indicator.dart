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
    final progress = (currentPage + 1) / steps.length;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingL,
        vertical: AppConstants.spacingS,
      ),
      child: Row(
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
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ),
          if (currentPage > 0 && onBack != null)
            const SizedBox(width: AppConstants.spacingM),
          // Progress bar
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(1.5),
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: AppConstants.textTertiary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(1.5),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: AppConstants.successColor,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
