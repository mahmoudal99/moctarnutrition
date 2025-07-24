import 'package:flutter/material.dart';
import 'package:champions_gym_app/shared/models/user_model.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';

class AdminUserDetailScreen extends StatelessWidget {
  final UserModel user;
  const AdminUserDetailScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final prefs = user.preferences;
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(user.name ?? user.email),
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    user.photoUrl != null
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(user.photoUrl!),
                            radius: 36,
                          )
                        : CircleAvatar(
                            radius: 36,
                            backgroundColor: AppConstants.primaryColor.withOpacity(0.08),
                            child: Icon(Icons.person, color: AppConstants.primaryColor, size: 36),
                          ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name ?? user.email, style: AppTextStyles.heading4),
                          const SizedBox(height: 4),
                          Text(user.email, style: AppTextStyles.bodyMedium.copyWith(color: AppConstants.textSecondary)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildBadge(_roleLabel(user.role), _roleColor(user.role)),
                              const SizedBox(width: 8),
                              _buildBadge(_subscriptionLabel(user.subscriptionStatus), _subscriptionColor(user.subscriptionStatus)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Preferences', style: AppTextStyles.heading4),
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _prefRow('Fitness Goal', _fitnessGoalLabel(prefs.fitnessGoal)),
                    _prefRow('Activity Level', _activityLevelLabel(prefs.activityLevel)),
                    _prefRow('Dietary Restrictions', prefs.dietaryRestrictions.isEmpty ? 'None' : prefs.dietaryRestrictions.join(', ')),
                    _prefRow('Preferred Workouts', prefs.preferredWorkoutStyles.isEmpty ? 'None' : prefs.preferredWorkoutStyles.join(', ')),
                    _prefRow('Target Calories', '${prefs.targetCalories} kcal'),
                    _prefRow('Age', prefs.age.toString()),
                    _prefRow('Weight', '${prefs.weight} kg'),
                    _prefRow('Height', '${prefs.height} cm'),
                    _prefRow('Gender', prefs.gender),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // TODO: Add Check-ins section
            // TODO: Add Meal Plan section
            // TODO: Add Admin actions (generate meal plan, etc)
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _prefRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppConstants.textSecondary))),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppConstants.primaryColor;
      case UserRole.trainer:
        return AppConstants.accentColor;
      case UserRole.user:
      default:
        return AppConstants.textTertiary;
    }
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.trainer:
        return 'Trainer';
      case UserRole.user:
      default:
        return 'User';
    }
  }

  Color _subscriptionColor(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.premium:
        return AppConstants.successColor;
      case SubscriptionStatus.basic:
        return AppConstants.secondaryColor;
      case SubscriptionStatus.cancelled:
        return AppConstants.errorColor;
      case SubscriptionStatus.free:
      default:
        return AppConstants.textTertiary;
    }
  }

  String _subscriptionLabel(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.premium:
        return 'Premium';
      case SubscriptionStatus.basic:
        return 'Basic';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
      case SubscriptionStatus.free:
      default:
        return 'Free';
    }
  }

  String _fitnessGoalLabel(FitnessGoal goal) {
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
    }
  }

  String _activityLevelLabel(ActivityLevel level) {
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
    }
  }
} 