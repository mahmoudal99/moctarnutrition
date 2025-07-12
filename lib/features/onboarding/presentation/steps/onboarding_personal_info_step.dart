import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class OnboardingPersonalInfoStep extends StatelessWidget {
  final int age;
  final String gender;
  final double weight;
  final double height;
  final VoidCallback onAgeTap;
  final VoidCallback onGenderTap;
  final VoidCallback onWeightTap;
  final VoidCallback onHeightTap;

  const OnboardingPersonalInfoStep({
    super.key,
    required this.age,
    required this.gender,
    required this.weight,
    required this.height,
    required this.onAgeTap,
    required this.onGenderTap,
    required this.onWeightTap,
    required this.onHeightTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMetricCard('Age', '$age years', Icons.cake, onAgeTap),
        const SizedBox(height: AppConstants.spacingM),
        _buildMetricCard('Gender', gender, Icons.person, onGenderTap),
        const SizedBox(height: AppConstants.spacingM),
        _buildMetricCard('Weight', '${weight.toStringAsFixed(1)} kg',
            Icons.monitor_weight, onWeightTap),
        const SizedBox(height: AppConstants.spacingM),
        _buildMetricCard('Height', '${height.toStringAsFixed(0)} cm',
            Icons.height, onHeightTap),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              border: Border.all(
                color: AppConstants.textTertiary.withOpacity(0.2),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              boxShadow: AppConstants.shadowS,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                  child: Icon(
                    icon,
                    color: AppConstants.primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.caption.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                      ),
                      Text(
                        value,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppConstants.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
