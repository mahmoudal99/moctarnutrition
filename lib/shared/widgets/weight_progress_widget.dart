import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:champions_gym_app/shared/services/progress_service.dart';

/// A reusable weight progress widget that displays weight information and progress
class WeightProgressWidget extends StatelessWidget {
  final WeightProgressData? weightProgress;
  final String? title;
  final bool showCheckinInfo;
  final bool showChart;
  final String? noDataMessage;
  final String? noDataSubMessage;

  const WeightProgressWidget({
    super.key,
    this.weightProgress,
    this.title,
    this.showCheckinInfo = true,
    this.showChart = false,
    this.noDataMessage,
    this.noDataSubMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (weightProgress == null) {
      return _buildNoDataCard();
    }

    if (showChart && weightProgress!.dataPoints.isNotEmpty) {
      return _buildChartCard();
    }

    return _buildProgressCard();
  }

  Widget _buildNoDataCard() {
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: AppConstants.shadowM,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title ?? 'Weight Progress',
            style: AppTextStyles.body1.copyWith(
              color: AppConstants.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            noDataMessage ?? 'No data',
            style: AppTextStyles.body2.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            noDataSubMessage ?? 'Complete your first check-in to track weight progress',
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    // Calculate days until next Sunday check-in
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysUntilSunday = _calculateDaysUntilSunday(today);
    final nextCheckinText = daysUntilSunday == 0
        ? 'Check-in today'
        : 'Next check-in: ${daysUntilSunday}d';

    // Calculate progress percentage (capped at 100%)
    final progressPercentage = _calculateWeightProgress(
      weightProgress!.startWeight,
      weightProgress!.currentWeight,
      weightProgress!.goalWeight,
    );

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: AppConstants.shadowM,
      ),
      child: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title - centered
                Center(
                  child: Text(
                    title ?? 'Weight Progress',
                    style: AppTextStyles.body1.copyWith(
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingS),
                // Current Weight - large and bold
                Text(
                  '${weightProgress!.currentWeight.toStringAsFixed(1)} kg',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppConstants.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingS),
                // Progress Bar - with proper calculation
                LinearProgressIndicator(
                  value: (progressPercentage / 100).clamp(0.0, 1.0),
                  backgroundColor: AppConstants.borderColor,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppConstants.primaryColor),
                ),
                const SizedBox(height: AppConstants.spacingS),
                // Goal Weight
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Goal ',
                        style: AppTextStyles.body2.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                      ),
                      TextSpan(
                        text: '${weightProgress!.goalWeight.toStringAsFixed(1)} kg',
                        style: AppTextStyles.body2.copyWith(
                          color: AppConstants.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Grey background section at bottom - fills corners
          if (showCheckinInfo)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppConstants.borderColor.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppConstants.radiusL),
                    bottomRight: Radius.circular(AppConstants.radiusL),
                  ),
                ),
                child: Center(
                  child: Text(
                    nextCheckinText,
                    style: AppTextStyles.body2.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    final dataPoints = weightProgress!.dataPoints;

    // Sort data points by date to ensure proper chronological order
    final sortedDataPoints = List<WeightDataPoint>.from(dataPoints)
      ..sort((a, b) => a.date.compareTo(b.date));

    if (sortedDataPoints.length < 2) {
      return _buildNoDataCard();
    }

    // Prepare chart data
    final spots = sortedDataPoints.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      return FlSpot(index.toDouble(), point.weight);
    }).toList();

    // Calculate weight range for better visualization
    final weights = sortedDataPoints.map((p) => p.weight).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final weightRange = maxWeight - minWeight;
    final padding = weightRange * 0.1;

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
            title ?? 'Weight Progress',
            style: AppTextStyles.body1.copyWith(
              color: AppConstants.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: weightRange > 0 ? weightRange / 4 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppConstants.textTertiary.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: weightRange > 0 ? weightRange / 4 : 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toStringAsFixed(1)}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppConstants.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < sortedDataPoints.length) {
                          final point = sortedDataPoints[value.toInt()];
                          return Text(
                            _formatDate(point.date),
                            style: AppTextStyles.caption.copyWith(
                              color: AppConstants.textSecondary,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (sortedDataPoints.length - 1).toDouble(),
                minY: minWeight - padding,
                maxY: maxWeight + padding,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppConstants.primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppConstants.primaryColor,
                          strokeWidth: 2,
                          strokeColor: AppConstants.surfaceColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppConstants.primaryColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Calculate days until next Sunday (0 if today is Sunday)
  int _calculateDaysUntilSunday(DateTime today) {
    final weekday = today.weekday; // 1 = Monday, 7 = Sunday
    if (weekday == 7) return 0; // Today is Sunday
    return 7 - weekday; // Days until next Sunday
  }

  /// Calculate weight progress percentage from starting weight to goal
  double _calculateWeightProgress(
      double startWeight, double currentWeight, double goalWeight) {
    if (startWeight == goalWeight) return 0.0; // No goal difference

    final totalDistance = (startWeight - goalWeight).abs();
    final currentDistance = (startWeight - currentWeight).abs();
    final progress = (currentDistance / totalDistance) * 100;

    // Cap at 100% to avoid showing more than 100% progress
    return progress.clamp(0.0, 100.0);
  }

  /// Format date for chart display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}
