import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class EditModeInstructions extends StatefulWidget {
  const EditModeInstructions({super.key});

  @override
  State<EditModeInstructions> createState() => _EditModeInstructionsState();
}

class _EditModeInstructionsState extends State<EditModeInstructions> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(AppConstants.spacingM),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.05),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: AppConstants.spacingS),
              Expanded(
                child: Text(
                  'Edit Mode',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isVisible = false;
                  });
                },
                icon: const Icon(Icons.close),
                iconSize: 16,
                color: AppConstants.textTertiary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            '• Drag workout cards between days to swap schedules\n'
            '• Tap Save to apply changes or Cancel to revert\n'
            '• Rest days cannot be moved',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppConstants.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
