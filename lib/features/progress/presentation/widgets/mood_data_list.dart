import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/progress_service.dart';

class MoodDataList extends StatelessWidget {
  final List<MoodDataPoint> data;

  const MoodDataList({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Mood History',
              style: AppTextStyles.heading4,
            ),
          ),
          ...data.reversed.take(5).map((point) {
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppConstants.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.mood,
                  color: AppConstants.accentColor,
                  size: 20,
                ),
              ),
              title: Text(
                point.mood,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    point.weekRange,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  if (point.energyLevel != null ||
                      point.motivationLevel != null)
                    Row(
                      children: [
                        if (point.energyLevel != null) ...[
                          Text(
                            'Energy: ${point.energyLevel}/10',
                            style: AppTextStyles.caption.copyWith(
                              color: AppConstants.textTertiary,
                            ),
                          ),
                          if (point.motivationLevel != null)
                            const SizedBox(width: 12),
                        ],
                        if (point.motivationLevel != null)
                          Text(
                            'Motivation: ${point.motivationLevel}/10',
                            style: AppTextStyles.caption.copyWith(
                              color: AppConstants.textTertiary,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              trailing: Text(
                DateFormat('MMM d').format(point.date),
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.textTertiary,
                ),
              ),
            );
          }),
          if (data.length > 5)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Showing latest 5 entries',
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
