import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/workout_plan_model.dart';
import '../widgets/daily_workout_card.dart';
import '../widgets/workout_plan_header.dart';

class WorkoutContent extends StatelessWidget {
  final WorkoutPlanModel workoutPlan;
  final DailyWorkout? todayWorkout;
  final VoidCallback onRefresh;

  const WorkoutContent({
    super.key,
    required this.workoutPlan,
    required this.todayWorkout,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        children: [
          WorkoutPlanHeader(workoutPlan: workoutPlan),
          const SizedBox(height: AppConstants.spacingL),
          if (todayWorkout != null) ...[
            _buildTodaySection(),
            const SizedBox(height: AppConstants.spacingL),
          ],
          _buildWeeklySection(),
          const SizedBox(height: AppConstants.spacingM),
          ..._buildWeeklyWorkoutList(),
          const SizedBox(height: 128),
        ],
      ),
    );
  }

  Widget _buildTodaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Workout",
          style: AppTextStyles.heading4,
        ),
        const SizedBox(height: AppConstants.spacingM),
        DailyWorkoutCard(
          dailyWorkout: todayWorkout!,
          isToday: true,
        ),
      ],
    );
  }

  Widget _buildWeeklySection() {
    return Text(
      'Weekly Plan',
      style: AppTextStyles.heading4,
    );
  }

  List<Widget> _buildWeeklyWorkoutList() {
    return workoutPlan.dailyWorkouts.map((dailyWorkout) {
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
    }).toList();
  }
} 