import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    return Column(
      children: [
        _buildHeader(),
        SizedBox(
          height: AppConstants.spacingS,
        ),
        _buildStatsGrid(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'Progress Summary',
          style: AppTextStyles.heading5,
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 1,
      crossAxisSpacing: 1,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          title: 'Completion Rate',
          value: '${(summary.completionRate * 100).toInt()}%',
          subtitle: '${summary.completedCheckins}/${summary.totalCheckins}',
          icon: "tick-double-03-stroke-rounded.svg",
          color: AppConstants.successColor,
        ),
        _buildStatCard(
          title: 'Current Streak',
          value: '${summary.currentStreak}',
          subtitle: summary.currentStreak == 1 ? 'week' : 'weeks',
          icon: "fire-stroke-rounded.svg",
          color: AppConstants.warningColor,
        ),
        _buildStatCard(
          title: 'Longest Streak',
          value: '${summary.longestStreak}',
          subtitle: summary.longestStreak == 1 ? 'week' : 'weeks',
          icon: "champion-stroke-rounded.svg",
          color: AppConstants.primaryColor,
        ),
        _buildStatCard(
          title: 'Missed',
          value: '${summary.missedCheckins}',
          subtitle: summary.missedCheckins == 1 ? 'check-in' : 'check-ins',
          icon: "spam-stroke-rounded.svg",
          color: AppConstants.textSecondary,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required String icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Row(
              children: [
                SvgPicture.asset(
                  "assets/images/${icon}",
                  color: Colors.black,
                  height: 20,
                ),
                SizedBox(
                  width: AppConstants.spacingS,
                ),
                Flexible(
                  child: Text(
                    title,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.black,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                Flexible(
                  child: Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppConstants.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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
          ],
        ),
        if (summary.averageEnergyLevel != null ||
            summary.averageMotivationLevel != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (summary.averageEnergyLevel != null)
                Expanded(
                  child: _buildMetricItem(
                    label: 'Energy',
                    value:
                        '${summary.averageEnergyLevel!.toStringAsFixed(1)}/10',
                    icon: Icons.flash_on,
                  ),
                ),
              if (summary.averageEnergyLevel != null &&
                  summary.averageMotivationLevel != null)
                const SizedBox(width: 16),
              if (summary.averageMotivationLevel != null)
                Expanded(
                  child: _buildMetricItem(
                    label: 'Motivation',
                    value:
                        '${summary.averageMotivationLevel!.toStringAsFixed(1)}/10',
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
