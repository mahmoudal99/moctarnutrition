import 'package:champions_gym_app/shared/models/workout_plan_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/workout_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/user_provider.dart';
import '../widgets/workout_loading_state.dart';
import '../widgets/workout_error_state.dart';
import '../widgets/workout_empty_state.dart';
import '../widgets/workout_app_header.dart';
import '../widgets/daily_workout_card.dart';
import '../widgets/workout_plan_header.dart';
import '../widgets/view_toggle.dart';
import '../widgets/day_view.dart';
import '../utils/workout_message_generator.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  static final _logger = Logger();
  WorkoutViewType _selectedView = WorkoutViewType.week; // Default to week view

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWorkoutPlanIfNeeded();
    });
  }

  Future<void> _loadWorkoutPlanIfNeeded() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    Provider.of<UserProvider>(context, listen: false);
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);

    // Check if user is authenticated
    if (!authProvider.isAuthenticated || authProvider.userModel == null) {
      _logger.w(
          'Cannot load workout plan: user not authenticated or userModel is null');
      return;
    }

    // Check if the current workout plan belongs to the current user
    final currentWorkoutPlan = workoutProvider.currentWorkoutPlan;
    if (currentWorkoutPlan != null) {
      if (currentWorkoutPlan.userId == authProvider.userModel!.id) {
        _logger.d(
            'Workout plan already loaded for current user, skipping API call');
        return;
      } else {
        _logger.d(
            'Workout plan belongs to different user, clearing and reloading');
        await workoutProvider.clearWorkoutPlanForUserChange();
      }
    }

    // Load workout plan for current user
    final workoutStyles =
        authProvider.userModel!.preferences.preferredWorkoutStyles;
    _logger.d(
        'Loading workout plan for user ${authProvider.userModel!.id} with styles: $workoutStyles');
    await workoutProvider.loadWorkoutPlan(
        authProvider.userModel!.id, workoutStyles, authProvider.userModel);
  }

  Future<void> _loadWorkoutPlan() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    Provider.of<UserProvider>(context, listen: false);
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);

    if (authProvider.isAuthenticated && authProvider.userModel != null) {
      final workoutStyles =
          authProvider.userModel!.preferences.preferredWorkoutStyles;
      _logger.d(
          'Force loading workout plan for user ${authProvider.userModel!.id} with styles: $workoutStyles');
      await workoutProvider.loadWorkoutPlan(
          authProvider.userModel!.id, workoutStyles, authProvider.userModel);
    } else {
      _logger.w(
          'Cannot load workout plan: user not authenticated or userModel is null');
    }
  }

  Future<void> _refreshWorkoutPlan() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);

    if (authProvider.isAuthenticated && authProvider.userModel != null) {
      // Clear local cache to force refresh from server
      await workoutProvider.clearLocalCache();

      final workoutStyles =
          authProvider.userModel!.preferences.preferredWorkoutStyles;
      _logger
          .d('Refreshing workout plan for user ${authProvider.userModel!.id}');
      await workoutProvider.loadWorkoutPlan(
          authProvider.userModel!.id, workoutStyles, authProvider.userModel);
    }
  }

  Widget _buildLoadingState() {
    return const WorkoutLoadingState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Consumer2<AuthProvider, WorkoutProvider>(
        builder: (context, authProvider, workoutProvider, child) {
          // Check if user changed and workout plan needs to be reloaded
          if (authProvider.isAuthenticated &&
              authProvider.userModel != null &&
              workoutProvider.currentWorkoutPlan != null &&
              workoutProvider.currentWorkoutPlan!.userId !=
                  authProvider.userModel!.id) {
            _logger.d('User changed, reloading workout plan');
            // Use Future.microtask to avoid build-time side effects
            Future.microtask(() => _loadWorkoutPlanIfNeeded());
          }

          if (workoutProvider.isLoading) {
            return _buildLoadingState();
          }

          if (workoutProvider.error != null) {
            return _buildErrorState(workoutProvider.error!);
          }

          if (workoutProvider.currentWorkoutPlan == null) {
            return _buildNoWorkoutPlanState();
          }

          return _buildWorkoutPlanView(workoutProvider);
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return WorkoutErrorState(
      error: error,
      onRetry: _loadWorkoutPlan,
    );
  }

  Widget _buildNoWorkoutPlanState() {
    return WorkoutEmptyState(
      onUpdatePreferences: () {
        Navigator.pushNamed(context, '/profile');
      },
    );
  }

  Widget _buildWorkoutPlanView(WorkoutProvider workoutProvider) {
    final workoutPlan = workoutProvider.currentWorkoutPlan!;
    final todayWorkout = workoutProvider.getTodayWorkout();
    final workoutMessage = WorkoutMessageGenerator.generateWorkoutMessage(todayWorkout);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _refreshWorkoutPlan,
        child: _selectedView == WorkoutViewType.day
            ? _buildDayView(todayWorkout)
            : _buildWeekView(workoutPlan, todayWorkout),
      ),
    );
  }

  Widget _buildDayView(DailyWorkout? todayWorkout) {
    if (todayWorkout == null) {
      return CustomScrollView(
        slivers: [
          const WorkoutAppHeader(message: 'No workout scheduled for today'),
          SliverToBoxAdapter(
            child: Padding(
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
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        WorkoutAppHeader(message: WorkoutMessageGenerator.generateWorkoutMessage(todayWorkout)),
        SliverToBoxAdapter(
          child: Column(
            children: [
              ViewToggle(
                selectedView: _selectedView,
                onViewChanged: (viewType) {
                  setState(() {
                    _selectedView = viewType;
                  });
                },
              ),
              DayView(dailyWorkout: todayWorkout),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeekView(WorkoutPlanModel workoutPlan, DailyWorkout? todayWorkout) {
    return CustomScrollView(
      slivers: [
        WorkoutAppHeader(message: WorkoutMessageGenerator.generateWorkoutMessage(todayWorkout)),
        SliverToBoxAdapter(
          child: Column(
            children: [
              ViewToggle(
                selectedView: _selectedView,
                onViewChanged: (viewType) {
                  setState(() {
                    _selectedView = viewType;
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WorkoutPlanHeader(workoutPlan: workoutPlan),
                    const SizedBox(height: AppConstants.spacingL),
                    if (todayWorkout != null) ...[
                      Text(
                        "Today's Workout",
                        style: AppTextStyles.heading4,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      DailyWorkoutCard(
                        dailyWorkout: todayWorkout,
                        isToday: true,
                      ),
                      const SizedBox(height: AppConstants.spacingL),
                    ],
                    Text(
                      'Weekly Plan',
                      style: AppTextStyles.heading4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
  }
}
