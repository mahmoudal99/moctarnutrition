import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/workout_plan_model.dart';
import '../widgets/workout_app_header.dart';
import '../widgets/view_toggle.dart';
import '../widgets/day_view.dart';
import '../utils/workout_message_generator.dart';
import '../../../../shared/providers/workout_provider.dart';

class DayViewWidget extends StatelessWidget {
  final DailyWorkout? todayWorkout;
  final WorkoutViewType selectedView;
  final Function(WorkoutViewType) onViewChanged;
  final ScrollController scrollController;

  const DayViewWidget({
    super.key,
    required this.todayWorkout,
    required this.selectedView,
    required this.onViewChanged,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (todayWorkout == null) {
      return _buildNoWorkoutState();
    }

    return _buildWorkoutState();
  }

  Widget _buildNoWorkoutState() {
    return Consumer<WorkoutProvider>(
      builder: (context, workoutProvider, child) {
        return CustomScrollView(
          controller: scrollController,
          slivers: [
            const WorkoutAppHeader(message: 'No workout scheduled for today'),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  if (!workoutProvider.isEditMode) ...[
                    ViewToggle(
                      selectedView: selectedView,
                      onViewChanged: onViewChanged,
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingL),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.fitness_center,
                            size: 64,
                            color: AppConstants.textTertiary,
                          ),
                          const SizedBox(height: AppConstants.spacingM),
                          Text(
                            'No Workout Today',
                            style: AppTextStyles.heading4.copyWith(
                              color: AppConstants.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingS),
                          Text(
                            'Switch to week view to see your full workout plan.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppConstants.textTertiary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWorkoutState() {
    return Consumer<WorkoutProvider>(
      builder: (context, workoutProvider, child) {
        return CustomScrollView(
          controller: scrollController,
          slivers: [
            if (!workoutProvider.isEditMode)
              WorkoutAppHeader(
                  message: WorkoutMessageGenerator.generateWorkoutMessage(todayWorkout)),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  if (!workoutProvider.isEditMode) ...[
                    ViewToggle(
                      selectedView: selectedView,
                      onViewChanged: onViewChanged,
                    ),
                    DayView(dailyWorkout: todayWorkout!),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
