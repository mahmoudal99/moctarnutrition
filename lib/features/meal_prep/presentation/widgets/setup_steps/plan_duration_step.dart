import 'package:flutter/material.dart';
import '../../../../../core/constants/app_constants.dart';

class PlanDurationStep extends StatelessWidget {
  final bool weeklyRotation;
  final ValueChanged<bool> onToggleWeeklyRotation;
  final bool remindersEnabled;
  final ValueChanged<bool> onToggleReminders;

  const PlanDurationStep({
    super.key,
    required this.weeklyRotation,
    required this.onToggleWeeklyRotation,
    required this.remindersEnabled,
    required this.onToggleReminders,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Plan Duration & Reminders',
            style: AppTextStyles.heading4,
          ),
          const SizedBox(height: AppConstants.spacingL),
          Row(
            children: [
              Expanded(
                child: Card(
                  color: weeklyRotation ? AppConstants.primaryColor : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    side: BorderSide(
                      color: weeklyRotation
                          ? AppConstants.primaryColor
                          : AppConstants.textTertiary.withOpacity(0.15),
                      width: weeklyRotation ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    onTap: () => onToggleWeeklyRotation(true),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 16,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            color: weeklyRotation
                                ? AppConstants.surfaceColor
                                : AppConstants.primaryColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Weekly rotating plan',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: weeklyRotation
                                  ? AppConstants.surfaceColor
                                  : AppConstants.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  color: !weeklyRotation ? AppConstants.primaryColor : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    side: BorderSide(
                      color: !weeklyRotation
                          ? AppConstants.primaryColor
                          : AppConstants.textTertiary.withOpacity(0.15),
                      width: !weeklyRotation ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    onTap: () => onToggleWeeklyRotation(false),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 16,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.repeat_one,
                            color: !weeklyRotation
                                ? AppConstants.surfaceColor
                                : AppConstants.primaryColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Repeat daily plan',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: !weeklyRotation
                                  ? AppConstants.surfaceColor
                                  : AppConstants.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),
          Row(
            children: [
              Switch(
                value: remindersEnabled,
                onChanged: onToggleReminders,
                activeColor: AppConstants.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Enable reminders',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),
        ],
      ),
    );
  }
} 