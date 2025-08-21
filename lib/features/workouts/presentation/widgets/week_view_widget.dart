import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/workout_plan_model.dart';
import '../widgets/workout_app_header.dart';
import '../widgets/view_toggle.dart';
import '../widgets/daily_workout_card.dart';
import '../widgets/edit_mode_instructions.dart';
import '../widgets/droppable_day_area.dart';
import '../utils/workout_message_generator.dart';
import '../../../../shared/providers/workout_provider.dart';

class WeekViewWidget extends StatelessWidget {
  final WorkoutPlanModel workoutPlan;
  final DailyWorkout? todayWorkout;
  final WorkoutViewType selectedView;
  final Function(WorkoutViewType) onViewChanged;
  final ScrollController scrollController;

  const WeekViewWidget({
    super.key,
    required this.workoutPlan,
    required this.todayWorkout,
    required this.selectedView,
    required this.onViewChanged,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
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
                  ],
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (todayWorkout != null && !workoutProvider.isEditMode) ...[
                          Text(
                            "Today's Workout",
                            style: AppTextStyles.heading4,
                          ),
                          const SizedBox(height: AppConstants.spacingM),
                          DailyWorkoutCard(
                            dailyWorkout: todayWorkout!,
                            isToday: true,
                          ),
                          const SizedBox(height: AppConstants.spacingL),
                        ],
                        if (!workoutProvider.isEditMode) ...[
                          Text(
                            'Weekly Plan',
                            style: AppTextStyles.heading4,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (workoutProvider.isEditMode) ...[
              const SliverToBoxAdapter(
                child: EditModeInstructions(),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final dailyWorkout = workoutPlan.dailyWorkouts[index];
                    final isToday = dailyWorkout.dayName == todayWorkout?.dayName;

                    return DroppableDayArea(
                      dayName: dailyWorkout.dayName,
                      dailyWorkout: dailyWorkout,
                      isToday: isToday,
                      isEditMode: workoutProvider.isEditMode,
                    );
                  },
                  childCount: workoutPlan.dailyWorkouts.length,
                ),
              ),
            ] else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final dailyWorkout = workoutPlan.dailyWorkouts[index];
                    final isToday = dailyWorkout.dayName == todayWorkout?.dayName;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingM,
                        vertical: AppConstants.spacingS,
                      ),
                      child: DailyWorkoutCard(
                        dailyWorkout: dailyWorkout,
                        isToday: isToday,
                      ),
                    );
                  },
                  childCount: workoutPlan.dailyWorkouts.length,
                ),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 128),
            ),
          ],
        );
      },
    );
  }
}
