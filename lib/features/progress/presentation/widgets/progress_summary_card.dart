import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/progress_service.dart';

class ProgressSummaryCard extends StatelessWidget {
  final ProgressSummary summary;

  const ProgressSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary.totalCheckins == 0) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'No Progress Data Yet',
              style: AppTextStyles.heading5.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your first check-in to start tracking your progress!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppConstants.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SummaryItem(
                  label: 'Check-ins',
                  value: '${summary.totalCheckins}',
                  icon: Icons.assignment_turned_in,
                ),
              ),
              Expanded(
                child: SummaryItem(
                  label: 'Weeks Tracked',
                  value: '${summary.trackingWeeks}',
                  icon: Icons.calendar_month,
                ),
              ),
              if (summary.weightStats?.hasProgress == true)
                Expanded(
                  child: SummaryItem(
                    label: 'Weight Change',
                    value: summary.weightStats!.changeText,
                    icon: Icons.monitor_weight,
                    valueColor: summary.weightStats!.change >= 0
                        ? AppConstants.successColor
                        : AppConstants.errorColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const SummaryItem({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppConstants.primaryColor,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppConstants.textPrimary,
          ),
        ),
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
