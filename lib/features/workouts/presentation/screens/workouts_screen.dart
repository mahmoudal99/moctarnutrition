import 'package:champions_gym_app/features/workouts/presentation/widgets/view_toggle.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/workout_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../widgets/edit_mode_header.dart';
import '../controllers/workout_controller.dart';
import '../controllers/workout_scroll_controller.dart';
import '../widgets/workout_view_builder.dart';
import '../widgets/floating_toggle_widget.dart';
import '../widgets/day_view_widget.dart';
import '../widgets/week_view_widget.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen>
    with TickerProviderStateMixin {
  static final _logger = Logger();
  WorkoutViewType _selectedView = WorkoutViewType.week; // Default to week view

  // Scroll and animation controller
  late WorkoutScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WorkoutController.loadWorkoutPlanIfNeeded(context);
    });

    // Initialize scroll controller and animations
    _scrollController = WorkoutScrollController();
    _scrollController.initialize(this);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Consumer2<AuthProvider, WorkoutProvider>(
        builder: (context, authProvider, workoutProvider, child) {
          if (WorkoutController.shouldReloadWorkoutPlan(context)) {
            _logger.d('User changed, reloading workout plan');
            Future.microtask(
                () => WorkoutController.loadWorkoutPlanIfNeeded(context));
          }

          if (workoutProvider.isLoading) {
            return WorkoutViewBuilder.buildLoadingState();
          }

          if (workoutProvider.error != null) {
            return WorkoutViewBuilder.buildErrorState(workoutProvider.error!, context);
          }

          if (workoutProvider.currentWorkoutPlan == null) {
            return WorkoutViewBuilder.buildNoWorkoutPlanState(context);
          }

          return _buildWorkoutPlanView(workoutProvider);
        },
      ),
    );
  }

  Widget _buildWorkoutPlanView(WorkoutProvider workoutProvider) {
    final workoutPlan = workoutProvider.currentWorkoutPlan!;
    final todayWorkout = workoutProvider.getTodayWorkout();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => WorkoutController.refreshWorkoutPlan(context),
            child: Column(
              children: [
                const EditModeHeader(),
                Expanded(
                  child: _selectedView == WorkoutViewType.day
                      ? DayViewWidget(
                          todayWorkout: todayWorkout,
                          selectedView: _selectedView,
                          onViewChanged: (viewType) {
                            setState(() {
                              _selectedView = viewType;
                            });
                          },
                          scrollController: _scrollController.scrollController,
                        )
                      : WeekViewWidget(
                          workoutPlan: workoutPlan,
                          todayWorkout: todayWorkout,
                          selectedView: _selectedView,
                          onViewChanged: (viewType) {
                            setState(() {
                              _selectedView = viewType;
                            });
                          },
                          scrollController: _scrollController.scrollController,
                        ),
                ),
              ],
            ),
          ),
          // Floating toggle (only show when not in edit mode)
          if (!workoutProvider.isEditMode)
            FloatingToggleWidget(
              selectedView: _selectedView,
              onViewChanged: (viewType) {
                setState(() {
                  _selectedView = viewType;
                });
              },
              opacityAnimation: _scrollController.toggleOpacityAnimation,
              scaleAnimation: _scrollController.toggleScaleAnimation,
            ),
        ],
      ),
    );
  }
}
