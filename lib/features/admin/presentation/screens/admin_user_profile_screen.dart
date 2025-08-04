import 'package:flutter/material.dart';
import 'package:champions_gym_app/shared/models/user_model.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:champions_gym_app/features/admin/presentation/widgets/admin_user_header.dart';
import 'package:champions_gym_app/features/admin/presentation/widgets/admin_info_card.dart';
import 'package:champions_gym_app/features/admin/presentation/widgets/admin_create_meal_plan_card.dart';

class AdminUserProfileScreen extends StatelessWidget {
  final UserModel user;
  final String? mealPlanId;
  final VoidCallback? onMealPlanCreated;

  const AdminUserProfileScreen({
    Key? key,
    required this.user,
    this.mealPlanId,
    this.onMealPlanCreated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 180,
          collapsedHeight: 80,
          pinned: true,
          backgroundColor: Colors.transparent,
          title: Text(
            'Client Details',
            style: AppTextStyles.heading4.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppConstants.primaryColor.withOpacity(0.2),
                    AppConstants.accentColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: AdminUserHeader(user: user),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Create Meal Plan button (if needed)
                  if (mealPlanId == null)
                    AdminCreateMealPlanCard(
                      user: user,
                      onMealPlanCreated: onMealPlanCreated,
                    ),

                  if (mealPlanId == null) const SizedBox(height: 24),

                  // Contact Information
                  AdminInfoCard(
                    title: 'Contact Information',
                    icon: Icons.contact_mail_outlined,
                    children: [
                      AdminInfoRow(
                          label: 'Name', value: user.name ?? user.email),
                      AdminInfoRow(label: 'Email', value: user.email),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Fitness Information
                  AdminInfoCard(
                    title: 'Fitness Profile',
                    icon: Icons.fitness_center_outlined,
                    children: [
                      AdminInfoRow(
                        label: 'Fitness Goal',
                        value: _fitnessGoalLabel(user.preferences?.fitnessGoal),
                      ),
                      AdminInfoRow(
                        label: 'Activity Level',
                        value: _activityLevelLabel(
                            user.preferences?.activityLevel),
                      ),
                      AdminInfoRow(
                        label: 'Target Calories',
                        value: '${user.preferences?.targetCalories ?? 0} kcal',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Physical Information
                  AdminInfoCard(
                    title: 'Physical Information',
                    icon: Icons.person_outline,
                    children: [
                      AdminInfoRow(
                          label: 'Age',
                          value: '${user.preferences?.age ?? 0} years'),
                      AdminInfoRow(
                          label: 'Weight',
                          value: '${user.preferences?.weight ?? 0} kg'),
                      AdminInfoRow(
                          label: 'Height',
                          value: '${user.preferences?.height ?? 0} cm'),
                      AdminInfoRow(
                          label: 'Gender',
                          value: user.preferences?.gender ?? 'Not specified'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Preferences
                  AdminInfoCard(
                    title: 'Preferences',
                    icon: Icons.settings_outlined,
                    children: [
                      AdminInfoRow(
                        label: 'Dietary Restrictions',
                        value: (user.preferences?.dietaryRestrictions ?? [])
                                .isEmpty
                            ? 'None'
                            : user.preferences?.dietaryRestrictions
                                    .join(', ') ??
                                'None',
                      ),
                      AdminInfoRow(
                        label: 'Preferred Workouts',
                        value: (user.preferences?.preferredWorkoutStyles ?? [])
                                .isEmpty
                            ? 'None'
                            : user.preferences?.preferredWorkoutStyles
                                    .join(', ') ??
                                'None',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  String _fitnessGoalLabel(FitnessGoal? goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return 'Weight Loss';
      case FitnessGoal.muscleGain:
        return 'Muscle Gain';
      case FitnessGoal.maintenance:
        return 'Maintenance';
      case FitnessGoal.endurance:
        return 'Endurance';
      case FitnessGoal.strength:
        return 'Strength';
      default:
        return 'Not specified';
    }
  }

  String _activityLevelLabel(ActivityLevel? level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
      case ActivityLevel.extremelyActive:
        return 'Extremely Active';
      default:
        return 'Not specified';
    }
  }
}
