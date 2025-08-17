import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/workout_plan_model.dart';
import '../../../../shared/providers/workout_provider.dart';
import 'draggable_workout_card.dart';

class DroppableDayArea extends StatefulWidget {
  final String dayName;
  final DailyWorkout? dailyWorkout;
  final bool isToday;
  final bool isEditMode;

  const DroppableDayArea({
    super.key,
    required this.dayName,
    required this.dailyWorkout,
    this.isToday = false,
    this.isEditMode = false,
  });

  @override
  State<DroppableDayArea> createState() => _DroppableDayAreaState();
}

class _DroppableDayAreaState extends State<DroppableDayArea> {
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<DailyWorkout>(
      onWillAccept: (data) {
        // Only accept if it's a different day and we're in edit mode
        return widget.isEditMode && 
               data != null && 
               data.dayName != widget.dayName &&
               !data.isRestDay;
      },
      onAccept: (data) {
        // Swap the workouts between the two days
        final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
        workoutProvider.swapDailyWorkouts(data.dayName, widget.dayName);
      },
      onMove: (details) {
        setState(() {
          _isDragOver = true;
        });
      },
      onLeave: (data) {
        setState(() {
          _isDragOver = false;
        });
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingS,
          ),
          decoration: BoxDecoration(
            color: _isDragOver 
                ? AppConstants.primaryColor.withOpacity(0.05)
                : Colors.transparent,
            border: _isDragOver
                ? Border.all(
                    color: AppConstants.primaryColor.withOpacity(0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  )
                : null,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          child: widget.dailyWorkout != null
              ? DraggableWorkoutCard(
                  dailyWorkout: widget.dailyWorkout!,
                  isToday: widget.isToday,
                  isEditMode: widget.isEditMode,
                )
              : _buildEmptyDayArea(),
        );
      },
    );
  }

  Widget _buildEmptyDayArea() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_circle_outline,
            size: 32,
            color: AppConstants.textTertiary,
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            widget.dayName,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXS),
          Text(
            'Drop workout here',
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
} 