import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:champions_gym_app/shared/services/progress_service.dart';

/// A reusable weight chart widget that displays weight progress as a line chart
class WeightChartWidget extends StatelessWidget {
  final WeightProgressData? weightProgress;
  final double height;

  const WeightChartWidget({
    super.key,
    this.weightProgress,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (weightProgress == null || weightProgress!.dataPoints.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No weight data available',
                style: AppTextStyles.body2.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingS),
              Text(
                'Complete your first check-in to see progress',
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final dataPoints = weightProgress!.dataPoints;

    // Sort data points by date to ensure proper chronological order
    final sortedDataPoints = List<WeightDataPoint>.from(dataPoints)
      ..sort((a, b) => a.date.compareTo(b.date));

    if (sortedDataPoints.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No weight data available',
            style: AppTextStyles.body2.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
        ),
      );
    }

    // Prepare chart data
    final spots = sortedDataPoints.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      return FlSpot(index.toDouble(), point.weight);
    }).toList();

    // Calculate weight range for Y-axis
    final weights = sortedDataPoints.map((dp) => dp.weight).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final weightRange = maxWeight - minWeight;

    // Add padding to make chart more readable
    final yMin = weightRange == 0 ? minWeight - 1 : minWeight - (weightRange * 0.1);
    final yMax = weightRange == 0 ? maxWeight + 1 : maxWeight + (weightRange * 0.1);

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (yMax - yMin) / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppConstants.borderColor.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (yMax - yMin) / 5,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: AppTextStyles.caption,
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (sortedDataPoints.length - 1).toDouble(),
          minY: yMin,
          maxY: yMax,
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
    );
  }
}
