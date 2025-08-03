import 'package:flutter/material.dart';
import '../../../../../core/constants/app_constants.dart';

/// A reusable card widget for displaying meal-related information
class MealInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const MealInfoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppConstants.primaryColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppConstants.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppConstants.spacingS),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A reusable nutrition chip widget
class NutritionChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const NutritionChip({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: AppConstants.spacingXS,
      ),
      decoration: BoxDecoration(
        color: (color ?? AppConstants.primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        border: Border.all(
          color: (color ?? AppConstants.primaryColor).withOpacity(0.2),
        ),
      ),
      child: Text(
        '$label: $value',
        style: AppTextStyles.caption.copyWith(
          color: color ?? AppConstants.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A reusable progress indicator widget
class MealPrepProgressIndicator extends StatelessWidget {
  final double progress;
  final String message;
  final bool showPercentage;

  const MealPrepProgressIndicator({
    super.key,
    required this.progress,
    required this.message,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppConstants.textTertiary.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
          minHeight: 8,
        ),
        const SizedBox(height: AppConstants.spacingS),
        Text(
          message,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppConstants.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        if (showPercentage) ...[
          const SizedBox(height: AppConstants.spacingXS),
          Text(
            '${(progress * 100).toInt()}%',
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// A reusable section header widget
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.heading4,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppConstants.spacingXS),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// A reusable empty state widget
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onAction;
  final String? actionText;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppConstants.textTertiary,
            ),
            const SizedBox(height: AppConstants.spacingL),
            Text(
              title,
              style: AppTextStyles.heading4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionText != null) ...[
              const SizedBox(height: AppConstants.spacingL),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 