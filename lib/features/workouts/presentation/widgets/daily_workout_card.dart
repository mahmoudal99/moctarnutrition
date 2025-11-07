import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/workout_plan_model.dart';

class DailyWorkoutCard extends StatelessWidget {
  final DailyWorkout dailyWorkout;
  final bool isToday;

  const DailyWorkoutCard({
    super.key,
    required this.dailyWorkout,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
          elevation: 8,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.radiusM,
              ),
              side: BorderSide(
                color: isToday
                    ? AppConstants.textTertiary.withOpacity(0.8)
                    : AppConstants.surfaceColor,
              )),
          color: Colors.white,
          child: InkWell(
            onTap: () {
              _showWorkoutDetails(context);
            },
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            child: Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dailyWorkout.title,
                              style: AppTextStyles.heading5.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppConstants.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 0),
                  if (dailyWorkout.isRestDay) ...[
                    Text(
                      dailyWorkout.restDay ?? 'Time to rest and recover!',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    Row(
                      children: [
                        _buildWorkoutInfo(
                          Icons.bedtime,
                          'Rest Day',
                        ),
                        const SizedBox(width: AppConstants.spacingM),
                        _buildWorkoutInfo(
                          Icons.healing,
                          'Recovery',
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      dailyWorkout.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: AppConstants.primaryColor,
        ),
        const SizedBox(width: AppConstants.spacingXS),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppConstants.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  IconData _getDayIcon() {
    if (dailyWorkout.isRestDay) {
      return Icons.bedtime;
    }

    // Return different icons based on workout focus
    final title = dailyWorkout.title.toLowerCase();
    if (title.contains('chest') || title.contains('push')) {
      return Icons.fitness_center;
    } else if (title.contains('back') || title.contains('pull')) {
      return Icons.accessibility_new;
    } else if (title.contains('leg') || title.contains('lower')) {
      return Icons.directions_run;
    } else if (title.contains('shoulder')) {
      return Icons.sports_gymnastics;
    } else if (title.contains('arm')) {
      return Icons.fitness_center;
    } else if (title.contains('core')) {
      return Icons.accessibility;
    } else if (title.contains('full')) {
      return Icons.all_inclusive;
    } else {
      return Icons.fitness_center;
    }
  }

  void _showWorkoutDetails(BuildContext context) {
    context.push('/workout-details', extra: dailyWorkout);
  }
}
