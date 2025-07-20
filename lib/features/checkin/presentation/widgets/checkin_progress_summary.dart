import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/checkin_model.dart';

class CheckinProgressSummaryWidget extends StatelessWidget {
  final CheckinProgressSummary summary;

  const CheckinProgressSummaryWidget({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildStatsGrid(),
            if (summary.averageWeight != null || summary.averageBodyFat != null)
              ...[
                const SizedBox(height: 20),
                _buildMetricsSection(),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.trending_up,
            color: AppConstants.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progress Summary',
                style: AppTextStyles.heading4,
              ),
              Text(
                'Your check-in journey so far',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.0,
      children: [
        _buildStatCard(
          title: 'Completion Rate',
          value: '${(summary.completionRate * 100).toInt()}%',
          subtitle: '${summary.completedCheckins}/${summary.totalCheckins}',
          icon: Icons.check_circle_outline,
          color: AppConstants.successColor,
        ),
        _buildStatCard(
          title: 'Current Streak',
          value: '${summary.currentStreak}',
          subtitle: summary.currentStreak == 1 ? 'week' : 'weeks',
          icon: Icons.local_fire_department,
          color: AppConstants.warningColor,
        ),
        _buildStatCard(
          title: 'Longest Streak',
          value: '${summary.longestStreak}',
          subtitle: summary.longestStreak == 1 ? 'week' : 'weeks',
          icon: Icons.emoji_events,
          color: AppConstants.primaryColor,
        ),
        _buildStatCard(
          title: 'Missed',
          value: '${summary.missedCheckins}',
          subtitle: summary.missedCheckins == 1 ? 'check-in' : 'check-ins',
          icon: Icons.schedule,
          color: AppConstants.textSecondary,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.heading4.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              title,
              style: AppTextStyles.caption.copyWith(
                color: AppConstants.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 1),
          Flexible(
            child: Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: AppConstants.textTertiary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Average Metrics',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (summary.averageWeight != null)
              Expanded(
                child: _buildMetricItem(
                  label: 'Weight',
                  value: '${summary.averageWeight!.toStringAsFixed(1)} kg',
                  icon: Icons.monitor_weight,
                ),
              ),
            if (summary.averageWeight != null && summary.averageBodyFat != null)
              const SizedBox(width: 16),
            if (summary.averageBodyFat != null)
              Expanded(
                child: _buildMetricItem(
                  label: 'Body Fat',
                  value: '${summary.averageBodyFat!.toStringAsFixed(1)}%',
                  icon: Icons.pie_chart,
                ),
              ),
          ],
        ),
        if (summary.averageEnergyLevel != null || summary.averageMotivationLevel != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (summary.averageEnergyLevel != null)
                Expanded(
                  child: _buildMetricItem(
                    label: 'Energy',
                    value: '${summary.averageEnergyLevel!.toStringAsFixed(1)}/10',
                    icon: Icons.flash_on,
                  ),
                ),
              if (summary.averageEnergyLevel != null && summary.averageMotivationLevel != null)
                const SizedBox(width: 16),
              if (summary.averageMotivationLevel != null)
                Expanded(
                  child: _buildMetricItem(
                    label: 'Motivation',
                    value: '${summary.averageMotivationLevel!.toStringAsFixed(1)}/10',
                    icon: Icons.psychology,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppConstants.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
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
        ],
      ),
    );
  }
} 