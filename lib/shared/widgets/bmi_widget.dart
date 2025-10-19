import 'package:flutter/material.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:champions_gym_app/shared/services/progress_service.dart';

/// A reusable BMI widget that displays BMI information with a visual scale
class BMIWidget extends StatelessWidget {
  final BMIData bmiData;
  final String? title;
  final bool showHelpIcon;
  final String weightLabel;

  const BMIWidget({
    super.key,
    required this.bmiData,
    this.title,
    this.showHelpIcon = true,
    this.weightLabel = 'Your weight is',
  });

  @override
  Widget build(BuildContext context) {
    if (bmiData.currentBMI == 0.0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.spacingL),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          boxShadow: AppConstants.shadowM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title ?? 'BMI Information',
              style: AppTextStyles.body1.copyWith(
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'No BMI data available',
              style: AppTextStyles.body2.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Height and weight information required',
              style: AppTextStyles.caption.copyWith(
                color: AppConstants.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: AppConstants.shadowM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title ?? 'Your BMI',
                style: AppTextStyles.body1.copyWith(
                  color: AppConstants.textPrimary,
                ),
              ),
              if (showHelpIcon)
                const Icon(
                  Icons.help_outline,
                  color: AppConstants.textSecondary,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                bmiData.currentBMI.toStringAsFixed(1),
                style: AppTextStyles.heading2.copyWith(
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(width: AppConstants.spacingS),
              Text(
                weightLabel,
                style: AppTextStyles.body1.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(width: AppConstants.spacingS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: bmiData.categoryColor,
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                ),
                child: Text(
                  bmiData.categoryText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppConstants.surfaceColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          BMIScale(currentBMI: bmiData.currentBMI),
        ],
      ),
    );
  }
}

/// BMI scale component with gradient bar and position indicator
class BMIScale extends StatelessWidget {
  final double currentBMI;

  const BMIScale({super.key, required this.currentBMI});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Container to hold the bar and indicator
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            final indicatorPosition = _getBMIPosition(currentBMI, barWidth);

            return SizedBox(
              height: 20,
              child: Stack(
                children: [
                  // Bar graph positioned in the middle
                  Positioned(
                    top: 6, // Center the bar vertically
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppConstants.radiusS),
                        gradient: const LinearGradient(
                          colors: [
                            Colors.blue,
                            Colors.green,
                            Colors.orange,
                            Colors.red
                          ],
                          stops: [0.0, 0.25, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // BMI indicator line OVER the bar graph
                  Positioned(
                    top: 0,
                    left: indicatorPosition,
                    child: Container(
                      width: 2,
                      height: 20,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppConstants.spacingS),
        // Legend below
        const BMILegend(),
      ],
    );
  }

  /// Calculate the position for the BMI indicator line in pixels
  double _getBMIPosition(double bmi, double barWidth) {
    // Normalize BMI to 0-1 range for the scale
    // The scale goes from roughly 15 to 40+ BMI
    const minBMI = 15.0;
    const maxBMI = 40.0;

    // Clamp BMI to scale range
    final clampedBMI = bmi.clamp(minBMI, maxBMI);

    // Calculate position as percentage (0.0 = left edge, 1.0 = right edge)
    final position = (clampedBMI - minBMI) / (maxBMI - minBMI);

    // Convert to pixel position on the bar
    return position * barWidth;
  }
}

/// BMI legend component
class BMILegend extends StatelessWidget {
  const BMILegend({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        LegendItem(label: 'Underweight', color: Colors.blue),
        LegendItem(label: 'Healthy', color: Colors.green),
        LegendItem(label: 'Overweight', color: Colors.orange),
        LegendItem(label: 'Obese', color: Colors.red),
      ],
    );
  }
}

/// Individual legend item component
class LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const LegendItem({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
      ],
    );
  }
}
