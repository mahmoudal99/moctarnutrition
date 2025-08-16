import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/progress_service.dart';
import 'mood_chart.dart';
import 'mood_data_list.dart';

class MoodTab extends StatelessWidget {
  final Future<List<MoodDataPoint>>? dataFuture;

  const MoodTab({super.key, this.dataFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MoodDataPoint>>(
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
                  'Error loading mood data',
                  style: AppTextStyles.bodyLarge,
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
                  Icons.mood,
                  size: 24,
                  color: AppConstants.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Mood Data',
                  style: AppTextStyles.heading5.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start logging your mood and energy levels to track wellness!',
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
              MoodChart(data: data),
              const SizedBox(height: 20),
              MoodDataList(data: data),
              const SizedBox(height: 128),
            ],
          ),
        );
      },
    );
  }
} 