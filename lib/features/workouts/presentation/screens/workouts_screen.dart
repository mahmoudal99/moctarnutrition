import 'package:champions_gym_app/shared/models/workout_plan_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/workout_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/services/notification_service.dart';
import '../widgets/workout_loading_state.dart';
import '../widgets/workout_generation_loading_state.dart';
import '../widgets/workout_error_state.dart';
import '../widgets/workout_empty_state.dart';
import '../widgets/workout_app_header.dart';
import '../widgets/daily_workout_card.dart';
import '../widgets/workout_plan_header.dart';
import '../widgets/view_toggle.dart';
import '../widgets/day_view.dart';
import '../widgets/edit_mode_header.dart';
import '../widgets/droppable_day_area.dart';
import '../widgets/edit_mode_instructions.dart';
import '../utils/workout_message_generator.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen>
    with TickerProviderStateMixin {
  static final _logger = Logger();
  WorkoutViewType _selectedView = WorkoutViewType.week; // Default to week view
  
  // Scroll and animation controllers for floating toggle
  late ScrollController _scrollController;
  late AnimationController _toggleAnimationController;
  late Animation<double> _toggleOpacityAnimation;
  late Animation<double> _toggleScaleAnimation;
  
  double _scrollOffset = 0.0;
  static const double _scrollThreshold = 100.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWorkoutPlanIfNeeded();
    });
    
    // Initialize scroll controller and animations
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    _toggleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _toggleOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _toggleAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _toggleScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _toggleAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _toggleAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
    
    if (_scrollOffset > _scrollThreshold && _toggleAnimationController.value == 0) {
      _toggleAnimationController.forward();
      // Add haptic feedback when toggle appears
      HapticFeedback.selectionClick();
    } else if (_scrollOffset <= _scrollThreshold && _toggleAnimationController.value == 1) {
      _toggleAnimationController.reverse();
    }
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
        // Still schedule notifications in case they were missed (non-blocking)
        _scheduleWorkoutNotificationsInBackground();
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

    // Schedule notifications after workout plan is loaded (non-blocking)
    _scheduleWorkoutNotificationsInBackground();
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

      // Schedule notifications after workout plan is refreshed (non-blocking)
      _scheduleWorkoutNotificationsInBackground();
    }
  }

  /// Schedule workout notifications in background (non-blocking)
  void _scheduleWorkoutNotificationsInBackground() {
    // Schedule notifications in background to avoid blocking UI
    Future.microtask(() async {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final workoutProvider =
            Provider.of<WorkoutProvider>(context, listen: false);

        // Check if user is authenticated and has workout notifications enabled
        if (!authProvider.isAuthenticated ||
            authProvider.userModel == null ||
            !authProvider.userModel!.preferences.workoutNotificationsEnabled ||
            authProvider.userModel!.preferences.workoutNotificationTime ==
                null) {
          _logger.d(
              'Workout notifications not enabled or missing time preference');
          return;
        }

        // Check if workout plan is loaded
        if (workoutProvider.currentWorkoutPlan == null) {
          _logger.d('No workout plan loaded, skipping notification scheduling');
          return;
        }

        // Check if notifications are already scheduled to avoid unnecessary processing
        final pendingNotifications = await FlutterLocalNotificationsPlugin()
            .pendingNotificationRequests();
        final workoutNotifications =
            pendingNotifications.where((n) => n.id >= 1000).length;

        if (workoutNotifications > 30) {
          _logger.d(
              'Workout notifications already scheduled ($workoutNotifications), skipping');
          return;
        }

        final user = authProvider.userModel!;
        final workoutPlan = workoutProvider.currentWorkoutPlan!;
        final notificationTime = user.preferences.workoutNotificationTime!;

        _logger.d(
            'Scheduling workout notifications in background for user ${user.id} at $notificationTime');

        // Schedule notifications
        await NotificationService.scheduleWorkoutNotifications(
          dailyWorkouts: workoutPlan.dailyWorkouts,
          notificationTime: notificationTime,
          userId: user.id,
        );
      } catch (e) {
        _logger.e('Error scheduling workout notifications in background: $e');
      }
    });
  }

  /// Schedule workout notifications if user has enabled them (blocking version for manual calls)
  Future<void> _scheduleWorkoutNotifications() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);

      // Check if user is authenticated and has workout notifications enabled
      if (!authProvider.isAuthenticated ||
          authProvider.userModel == null ||
          !authProvider.userModel!.preferences.workoutNotificationsEnabled ||
          authProvider.userModel!.preferences.workoutNotificationTime == null) {
        _logger
            .d('Workout notifications not enabled or missing time preference');
        return;
      }

      // Check if workout plan is loaded
      if (workoutProvider.currentWorkoutPlan == null) {
        _logger.d('No workout plan loaded, skipping notification scheduling');
        return;
      }

      final user = authProvider.userModel!;
      final workoutPlan = workoutProvider.currentWorkoutPlan!;
      final notificationTime = user.preferences.workoutNotificationTime!;

      _logger.d(
          'Scheduling workout notifications for user ${user.id} at $notificationTime');

      // Schedule notifications
      await NotificationService.scheduleWorkoutNotifications(
        dailyWorkouts: workoutPlan.dailyWorkouts,
        notificationTime: notificationTime,
        userId: user.id,
      );

      _logger.i('Workout notifications scheduled successfully');
    } catch (e) {
      _logger.e('Error scheduling workout notifications: $e');
    }
  }

  Widget _buildLoadingState() {
    return Consumer<WorkoutProvider>(
      builder: (context, workoutProvider, child) {
        // Use generation loading state if we're generating a new workout plan
        if (workoutProvider.isGenerating) {
          return const WorkoutGenerationLoadingState();
        }
        // Use regular loading state for loading existing workouts
        return const WorkoutLoadingState();
      },
    );
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
    WorkoutMessageGenerator.generateWorkoutMessage(todayWorkout);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshWorkoutPlan,
            child: Column(
              children: [
                const EditModeHeader(),
                Expanded(
                  child: _selectedView == WorkoutViewType.day
                      ? _buildDayView(todayWorkout)
                      : _buildWeekView(workoutPlan, todayWorkout),
                ),
              ],
            ),
          ),
          // Floating toggle (only show when not in edit mode)
          if (!workoutProvider.isEditMode)
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _toggleAnimationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _toggleScaleAnimation.value,
                      child: Opacity(
                        opacity: _toggleOpacityAnimation.value,
                        child: _buildFloatingToggle(),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayView(DailyWorkout? todayWorkout) {
    if (todayWorkout == null) {
      return Consumer<WorkoutProvider>(
        builder: (context, workoutProvider, child) {
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              const WorkoutAppHeader(message: 'No workout scheduled for today'),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    if (!workoutProvider.isEditMode) ...[
                      ViewToggle(
                        selectedView: _selectedView,
                        onViewChanged: (viewType) {
                          setState(() {
                            _selectedView = viewType;
                          });
                        },
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

    return Consumer<WorkoutProvider>(
      builder: (context, workoutProvider, child) {
        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            if (!workoutProvider.isEditMode)
              WorkoutAppHeader(
                  message: WorkoutMessageGenerator.generateWorkoutMessage(
                      todayWorkout)),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  if (!workoutProvider.isEditMode) ...[
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
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeekView(
      WorkoutPlanModel workoutPlan, DailyWorkout? todayWorkout) {
    return Consumer<WorkoutProvider>(
      builder: (context, workoutProvider, child) {
        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            if (!workoutProvider.isEditMode)
              WorkoutAppHeader(
                  message: WorkoutMessageGenerator.generateWorkoutMessage(
                      todayWorkout)),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  if (!workoutProvider.isEditMode) ...[
                    ViewToggle(
                      selectedView: _selectedView,
                      onViewChanged: (viewType) {
                        setState(() {
                          _selectedView = viewType;
                        });
                      },
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (todayWorkout != null &&
                            !workoutProvider.isEditMode) ...[
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
                    final isToday =
                        dailyWorkout.dayName == todayWorkout?.dayName;

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
                    final isToday =
                        dailyWorkout.dayName == todayWorkout?.dayName;

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

  Widget _buildFloatingToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: AppConstants.spacingXS,
      ),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ViewToggle(
        selectedView: _selectedView,
        onViewChanged: (viewType) {
          setState(() {
            _selectedView = viewType;
          });
        },
        isFloating: true,
      ),
    );
  }
}
