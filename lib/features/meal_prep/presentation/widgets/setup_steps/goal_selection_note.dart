import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constants.dart';

class GoalSelectionNote extends StatelessWidget {
  final String message;
  final Color accentColor;
  final IconData icon;
  final Color iconColor;
  final TextStyle? textStyle;

  const GoalSelectionNote({
    super.key,
    required this.message,
    required this.accentColor,
    this.icon = Icons.info_outline,
    this.iconColor = Colors.black,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextStyle = textStyle ??
        AppTextStyles.bodySmall.copyWith(
          color: Colors.black87,
        );

    return DottedBorder(
      color: accentColor.withOpacity(0.5),
      strokeWidth: 1,
      dashPattern: const [6, 4],
      borderType: BorderType.RRect,
      radius: Radius.circular(AppConstants.radiusS),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
            const SizedBox(width: AppConstants.spacingS),
            Expanded(
              child: Text(
                message,
                style: effectiveTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

