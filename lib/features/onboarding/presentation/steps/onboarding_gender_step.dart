import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';

class OnboardingGenderStep extends StatelessWidget {
  final String? selectedGender;
  final ValueChanged<String> onSelect;

  const OnboardingGenderStep({
    super.key,
    this.selectedGender,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildGenderOption('Male', Icons.male, selectedGender == 'Male', () {
          HapticFeedback.lightImpact();
          onSelect('Male');
        }),
        const SizedBox(height: AppConstants.spacingM),
        _buildGenderOption('Female', Icons.female, selectedGender == 'Female', () {
          HapticFeedback.lightImpact();
          onSelect('Female');
        }),
      ],
    );
  }

  Widget _buildGenderOption(String gender, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.spacingL),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor.withOpacity(0.1) : AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : AppConstants.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingS),
              decoration: BoxDecoration(
                color: isSelected ? AppConstants.primaryColor : AppConstants.surfaceColor,
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppConstants.surfaceColor : AppConstants.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Text(
                gender,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppConstants.primaryColor : AppConstants.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppConstants.primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
