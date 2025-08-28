import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/progress_service.dart';
import 'weight_chart.dart';
import 'weight_data_list.dart';

class WeightTab extends StatelessWidget {
  final Future<List<WeightDataPoint>>? dataFuture;

  const WeightTab({super.key, this.dataFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WeightDataPoint>>(
      future: dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 24,
                  color: AppConstants.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading weight data',
                  style: AppTextStyles.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data ?? [];

        if (data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.monitor_weight,
                  size: 24,
                  color: AppConstants.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Weight Data',
                  style: AppTextStyles.heading5.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start logging your weight in check-ins to see progress!',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppConstants.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              WeightChart(data: data),
              const SizedBox(height: 20),
              WeightDataList(data: data),
              const SizedBox(height: 128),
            ],
          ),
        );
      },
    );
  }
}
