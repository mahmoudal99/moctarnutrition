import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// A standardized option button widget for onboarding steps.
/// 
/// This widget provides consistent styling across all onboarding steps:
/// - Background: AppConstants.containerColor
/// - Border: AppConstants.primaryColor when selected, AppConstants.borderColor when not
/// - Border width: 2 (consistent for both states)
/// - Text: AppTextStyles.bodySmall
/// - Font weight: bold when selected, normal when not
class OnboardingOptionButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isVisible;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsets? padding;
  final double? maxWidth;

  const OnboardingOptionButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isVisible = true,
    this.leading,
    this.trailing,
    this.padding,
    this.maxWidth = 400,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
          child: Container(
            width: double.infinity,
            padding: padding ?? const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: AppConstants.containerColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(
                color: isSelected
                    ? AppConstants.primaryColor
                    : AppConstants.borderColor,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppConstants.spacingM),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: leading != null || trailing != null
                        ? TextAlign.start
                        : TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? AppConstants.primaryColor
                          : AppConstants.textPrimary,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppConstants.spacingM),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

