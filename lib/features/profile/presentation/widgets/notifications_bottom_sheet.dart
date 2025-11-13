import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import 'notifications_toggle.dart';
import 'reminders_toggle.dart';

class NotificationsBottomSheet extends StatelessWidget {
  const NotificationsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final padding = MediaQuery.of(context).padding;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: viewInsets.bottom + padding.bottom + 300,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppConstants.textTertiary.withOpacity(0.4),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'SETTINGS',
            style: AppTextStyles.caption
                .copyWith(color: AppConstants.accentColor),
          ),
          Text(
            'Notifications',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          const NotificationsToggle(),
          const SizedBox(height: 12),
          const RemindersToggle(),
        ],
      ),
    );
  }
}





