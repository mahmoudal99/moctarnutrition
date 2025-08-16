import 'package:champions_gym_app/shared/models/workout_plan_model.dart';
import 'package:champions_gym_app/shared/models/workout_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/workout_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/providers/profile_photo_provider.dart';
import '../../../../shared/utils/avatar_utils.dart';
import '../widgets/daily_workout_card.dart';
import '../widgets/workout_plan_header.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  static final _logger = Logger();

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
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: AppConstants.surfaceColor,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              child: _getUserProfileIcon(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppConstants.surfaceColor,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.spacingM,
                    AppConstants.spacingXL,
                    AppConstants.spacingM,
                    AppConstants.spacingM,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Hi ${_getUserName()}!',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppConstants.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingXS),
                      Text(
                        'Preparing your workout plan...',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceColor,
                      borderRadius: BorderRadius.circular(AppConstants.radiusL),
                      boxShadow: AppConstants.shadowM,
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: AppConstants.primaryColor,
                          strokeWidth: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXL),
                  Text(
                    'Creating Your Perfect Workout',
                    style: AppTextStyles.heading4.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  Text(
                    'We\'re analyzing your preferences and fitness goals to create a personalized workout plan just for you.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.spacingXL),
                  // Loading steps
                  _buildLoadingStep(
                    'Analyzing your fitness goals',
                    Icons.track_changes,
                    true,
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  _buildLoadingStep(
                    'Designing workout routines',
                    Icons.fitness_center,
                    true,
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  _buildLoadingStep(
                    'Optimizing for your schedule',
                    Icons.schedule,
                    false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStep(String text, IconData icon, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: isCompleted
              ? AppConstants.primaryColor.withOpacity(0.3)
              : AppConstants.textTertiary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppConstants.primaryColor
                  : AppConstants.textTertiary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
            ),
            child: Icon(
              icon,
              color: isCompleted
                  ? AppConstants.surfaceColor
                  : AppConstants.textTertiary,
              size: 16,
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isCompleted
                    ? AppConstants.textPrimary
                    : AppConstants.textSecondary,
                fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (isCompleted)
            const Icon(
              Icons.check_circle,
              color: AppConstants.primaryColor,
              size: 20,
            ),
        ],
      ),
    );
  }

  String _getUserName() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final name = authProvider.userModel?.name;
    if (name != null && name.isNotEmpty) {
      // Return first name only
      return name.split(' ').first;
    }
    return 'there';
  }

  String _getWorkoutMessage(DailyWorkout? todayWorkout) {
    if (todayWorkout == null) {
      return 'Ready for your workout?';
    }

    if (todayWorkout.isRestDay) {
      return 'Time to rest and recover!';
    }

    // Check if it's a specific type of workout day
    final workoutCount = todayWorkout.workouts.length;
    final estimatedDuration = todayWorkout.estimatedDuration;

    if (workoutCount == 1) {
      final workout = todayWorkout.workouts.first;
      final category =
          workout.category.toString().split('.').last.toLowerCase();

      // Provide more specific messages based on workout category
      switch (workout.category) {
        case WorkoutCategory.strength:
          return 'Ready to build strength?';
        case WorkoutCategory.cardio:
          return 'Ready to boost your cardio?';
        case WorkoutCategory.hiit:
          return 'Ready for an intense HIIT session?';
        case WorkoutCategory.flexibility:
          return 'Ready to improve flexibility?';
        case WorkoutCategory.yoga:
          return 'Ready for your yoga practice?';
        case WorkoutCategory.pilates:
          return 'Ready for your Pilates session?';
        default:
          return 'Ready for your $category workout?';
      }
    } else if (workoutCount > 1) {
      return 'Ready for your ${workoutCount}-workout session?';
    } else {
      return 'Ready for your workout?';
    }
  }

  Widget _getUserProfileIcon() {
    return Consumer<ProfilePhotoProvider>(
      builder: (context, profilePhotoProvider, child) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.userModel;

        if (profilePhotoProvider.hasProfilePhoto) {
          return CircleAvatar(
            radius: 24,
            backgroundImage: profilePhotoProvider.getProfilePhotoImage(),
          );
        }

        if (user != null) {
          return AvatarUtils.buildAvatar(
            photoUrl: user.photoUrl,
            name: user.name,
            email: user.email,
            radius: 24,
            fontSize: 12,
          );
        }

        return _buildDefaultAvatar();
      },
    );
  }

  Widget _buildDefaultAvatar() {
    return Center(
      child: Icon(
        Icons.person,
        color: AppConstants.primaryColor,
        size: 24,
      ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppConstants.errorColor,
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Oops!',
              style: AppTextStyles.heading3.copyWith(
                color: AppConstants.errorColor,
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              error,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingL),
            ElevatedButton(
              onPressed: _loadWorkoutPlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: AppConstants.surfaceColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingL,
                  vertical: AppConstants.spacingM,
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoWorkoutPlanState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No Workout Plan',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              'Complete your onboarding to get a personalized workout plan.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingL),
            ElevatedButton(
              onPressed: () {
                // Navigate to onboarding or profile to update workout preferences
                Navigator.pushNamed(context, '/profile');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: AppConstants.surfaceColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingL,
                  vertical: AppConstants.spacingM,
                ),
              ),
              child: const Text('Update Preferences'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutPlanView(WorkoutProvider workoutProvider) {
    final workoutPlan = workoutProvider.currentWorkoutPlan!;
    final todayWorkout = workoutProvider.getTodayWorkout();

    return RefreshIndicator(
      onRefresh: _refreshWorkoutPlan,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: AppConstants.surfaceColor,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              child: _getUserProfileIcon(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppConstants.surfaceColor,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.spacingM,
                    AppConstants.spacingXL,
                    AppConstants.spacingM,
                    AppConstants.spacingM,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Hi ${_getUserName()}!',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppConstants.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingXS),
                      Text(
                        _getWorkoutMessage(todayWorkout),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
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
      ),
    );
  }
}
