import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/workout_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/user_provider.dart';
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
      _loadWorkoutPlan();
    });
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
          'Loading workout plan for user ${authProvider.userModel!.id} with styles: $workoutStyles');
      await workoutProvider.loadWorkoutPlan(
          authProvider.userModel!.id, workoutStyles);
    } else {
      _logger.w(
          'Cannot load workout plan: user not authenticated or userModel is null');
    }
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

  Widget _getUserProfileIcon() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final photoUrl = authProvider.userModel?.photoUrl;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.network(
          photoUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        ),
      );
    }

    return _buildDefaultAvatar();
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
      body: Consumer<WorkoutProvider>(
        builder: (context, workoutProvider, child) {
          if (workoutProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppConstants.primaryColor,
              ),
            );
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

    return CustomScrollView(
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
                      'Ready for your workout?',
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
                const SizedBox(height: AppConstants.spacingM),
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
    );
  }
}
