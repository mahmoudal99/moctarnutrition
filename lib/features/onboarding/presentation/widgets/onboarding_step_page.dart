import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/onboarding_step.dart';
import 'onboarding_step_header.dart';

class OnboardingStepPage extends StatelessWidget {
  final OnboardingStep step;
  final int stepIndex;
  final Widget content;
  final String? contentKey;

  const OnboardingStepPage({
    super.key,
    required this.step,
    required this.stepIndex,
    required this.content,
    this.contentKey,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingL,
        vertical: AppConstants.spacingM,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        child: Column(
          key: ValueKey(contentKey ?? stepIndex),
          children: [
            OnboardingStepHeader(step: step),
            const SizedBox(height: AppConstants.spacingM),
            content,
            const SizedBox(height: AppConstants.spacingL),
          ],
        ),
      ),
    );
  }
}
