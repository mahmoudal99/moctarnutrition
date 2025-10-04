import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/onboarding_step.dart';

class OnboardingStepHeader extends StatelessWidget {
  final OnboardingStep step;

  const OnboardingStepHeader({
    super.key,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Column(
              children: [
                Container(
                  width: step.icon.contains("arrow") ? 80 : 48,
                  height: step.icon.contains("arrow") ? 80 : 48,
                  decoration: const BoxDecoration(),
                  child: Lottie.asset(
                    "assets/animations/${step.icon}",
                    delegates: LottieDelegates(
                      values: step.showIconColor
                          ? [
                              ValueDelegate.color(
                                const ['**', 'Fill 1'],
                                value: step.color,
                              ),
                            ]
                          : [],
                    ),
                  ),
                ),
                SizedBox(
                    height: step.icon.contains("arrow")
                        ? 0
                        : AppConstants.spacingS),
                Text(
                  step.title,
                  style: AppTextStyles.heading5,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spacingXS),
                Text(
                  step.subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
