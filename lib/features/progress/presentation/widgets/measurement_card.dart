import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/progress_service.dart';
import 'measurement_chart.dart';

class MeasurementCard extends StatelessWidget {
  final String measurementType;
  final Future<List<MeasurementDataPoint>>? dataFuture;

  const MeasurementCard({
    super.key,
    required this.measurementType,
    this.dataFuture,
  });

  String get formattedType {
    return measurementType
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ExpansionTile(
        title: Text(
          formattedType,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.straighten,
            color: AppConstants.primaryColor,
            size: 20,
          ),
        ),
        children: [
          if (dataFuture != null)
            FutureBuilder<List<MeasurementDataPoint>>(
              future: dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error loading data',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppConstants.errorColor,
                      ),
                    ),
                  );
                }

                final data = snapshot.data ?? [];

                if (data.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No data available',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    if (data.length >= 2)
                      Container(
                        height: 200,
                        padding: const EdgeInsets.all(16),
                        child: MeasurementChart(data: data),
                      ),
                    ...data.reversed.take(3).map((point) {
                      return ListTile(
                        title: Text(
                          '${point.value.toStringAsFixed(1)} cm',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          point.weekRange,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppConstants.textSecondary,
                          ),
                        ),
                        trailing: Text(
                          DateFormat('MMM d').format(point.date),
                          style: AppTextStyles.caption.copyWith(
                            color: AppConstants.textTertiary,
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No data available',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
} 