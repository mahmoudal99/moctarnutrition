import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/progress_service.dart';

class MoodChart extends StatelessWidget {
  final List<MoodDataPoint> data;

  const MoodChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final energyData = data.where((d) => d.energyLevel != null).toList();
    final motivationData =
        data.where((d) => d.motivationLevel != null).toList();

    if (energyData.isEmpty && motivationData.isEmpty) {
      return Container(
        height: 200,
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
        child: Center(
          child: Text(
            'No energy or motivation data available',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
        ),
      );
    }

    final energySpots = energyData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.energyLevel!.toDouble());
    }).toList();

    final motivationSpots = motivationData.asMap().entries.map((entry) {
      return FlSpot(
          entry.key.toDouble(), entry.value.motivationLevel!.toDouble());
    }).toList();

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mood & Energy Levels',
                style: AppTextStyles.heading4,
              ),
              if (energySpots.isNotEmpty || motivationSpots.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (energySpots.isNotEmpty) ...[
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppConstants.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Energy',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (motivationSpots.isNotEmpty) ...[
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppConstants.accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Motivation',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
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
                      reservedSize: 30,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
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
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              data[index].weekRange,
                              style: AppTextStyles.caption.copyWith(
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
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
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: AppConstants.textTertiary.withOpacity(0.2),
                    ),
                    left: BorderSide(
                      color: AppConstants.textTertiary.withOpacity(0.2),
                    ),
                  ),
                ),
                lineBarsData: [
                  if (energySpots.isNotEmpty)
                    LineChartBarData(
                      spots: energySpots,
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
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                    ),
                  if (motivationSpots.isNotEmpty)
                    LineChartBarData(
                      spots: motivationSpots,
                      isCurved: true,
                      color: AppConstants.accentColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: AppConstants.accentColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                    ),
                ],
                minY: 0,
                maxY: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
