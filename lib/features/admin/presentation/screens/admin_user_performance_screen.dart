import 'package:flutter/material.dart';
import 'package:champions_gym_app/shared/models/user_model.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:champions_gym_app/shared/services/progress_service.dart';
import 'package:champions_gym_app/shared/widgets/bmi_widget.dart';
import 'package:champions_gym_app/shared/widgets/weight_chart_widget.dart';
import 'package:champions_gym_app/features/admin/presentation/widgets/admin_user_app_bar.dart';

class AdminUserPerformanceScreen extends StatelessWidget {
  final UserModel user;

  const AdminUserPerformanceScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffafafa),
      appBar: AdminUserAppBar(
        user: user,
        title: 'Performance',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // BMI Widget
            BMIWidget(
              bmiData: _calculateBMIData(),
              title: 'BMI Information',
              weightLabel: 'Weight is',
            ),

            const SizedBox(height: 16),

            // Weight Progress Widget - Using GoalProgressGraph
            FutureBuilder<WeightProgressData?>(
              future: _getWeightProgressData(),
              builder: (context, snapshot) {
                final weightProgress = snapshot.data;
                final progressPercentage =
                    weightProgress?.progressPercentage ?? 0.0;

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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Weight Progress',
                            style: AppTextStyles.body1.copyWith(
                              color: AppConstants.textPrimary,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.flag,
                                size: 16,
                                color: AppConstants.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${progressPercentage.toStringAsFixed(0)}% of goal',
                                style: AppTextStyles.body2.copyWith(
                                  color: AppConstants.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingL),
                      WeightChartWidget(
                        weightProgress: weightProgress,
                        height: 200,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 128),
          ],
        ),
      ),
    );
  }

  /// Calculate BMI data from user model
  BMIData _calculateBMIData() {
    if (user.preferences.height <= 0 || user.preferences.weight <= 0) {
      return BMIData.empty();
    }

    final bmi = user.preferences.weight /
        ((user.preferences.height / 100) * (user.preferences.height / 100));
    final bmiCategory = _getBMICategory(bmi);

    return BMIData(
      currentBMI: bmi,
      bmiCategory: bmiCategory,
      weight: user.preferences.weight,
      height: user.preferences.height,
      isHealthy: bmiCategory == BMICategory.healthy,
    );
  }

  /// Get weight progress data for the user
  Future<WeightProgressData?> _getWeightProgressData() async {
    try {
      final startWeight = user.preferences.weight;
      final goalWeight = user.preferences.desiredWeight;

      // Get current weight from check-ins if available
      double currentWeight = startWeight;
      final checkins = await ProgressService.getUserCheckins(user.id);
      if (checkins.isNotEmpty) {
        final weightData = checkins.where((c) => c.weight != null).toList();
        if (weightData.isNotEmpty) {
          currentWeight = weightData.last.weight!; // Use latest check-in weight
        }
      }

      // Calculate progress percentage
      double progressPercentage = 0.0;
      if (startWeight != goalWeight) {
        final totalDistance = (startWeight - goalWeight).abs();
        final currentDistance = (startWeight - currentWeight).abs();
        progressPercentage = (currentDistance / totalDistance) * 100;
        progressPercentage = progressPercentage.clamp(0.0, 100.0);
      }

      return WeightProgressData(
        currentWeight: currentWeight,
        startWeight: startWeight,
        goalWeight: goalWeight,
        progressPercentage: progressPercentage,
        dataPoints: checkins.isNotEmpty
            ? checkins
                .where((c) => c.weight != null)
                .map((c) => WeightDataPoint(
                      date: c.weekStartDate,
                      weight: c.weight!,
                      weekRange: c.weekRange,
                    ))
                .toList()
            : [],
      );
    } catch (e) {
      return null;
    }
  }

  /// Get BMI category from BMI value
  BMICategory _getBMICategory(double bmi) {
    if (bmi < 18.5) return BMICategory.underweight;
    if (bmi < 25) return BMICategory.healthy;
    if (bmi < 30) return BMICategory.overweight;
    return BMICategory.obese;
  }
}
