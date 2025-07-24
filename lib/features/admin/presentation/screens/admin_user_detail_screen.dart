import 'package:flutter/material.dart';
import 'package:champions_gym_app/shared/models/user_model.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:champions_gym_app/shared/models/checkin_model.dart';
import 'package:champions_gym_app/shared/models/meal_model.dart';

class AdminUserDetailScreen extends StatelessWidget {
  final UserModel user;
  const AdminUserDetailScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final prefs = user.preferences;
    // DEBUG: Print the user id being viewed
    print('AdminUserDetailScreen: user.id = ${user.id}');
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
            // --- Check-ins Section ---
            Text('Check-ins', style: AppTextStyles.heading4),
            const SizedBox(height: 12),
            FutureBuilder<List<CheckinModel>>(
              future: _fetchCheckins(user.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Check-in fetch error: ${snapshot.error}');
                  return Center(child: Text('Error loading check-ins: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final checkins = snapshot.data ?? [];
                if (checkins.isEmpty) {
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('No check-ins found.', style: AppTextStyles.bodyMedium),
                    ),
                  );
                }
                return Column(
                  children: checkins.map((c) => _checkinCard(c)).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            // --- Meal Plan Section ---
            Text('Meal Plan', style: AppTextStyles.heading4),
            const SizedBox(height: 12),
            FutureBuilder<MealPlanModel?>(
              future: _fetchMealPlan(user.mealPlanId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading meal plan'));
                }
                final mealPlan = snapshot.data;
                if (mealPlan == null) {
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('No meal plan found.', style: AppTextStyles.bodyMedium),
                    ),
                  );
                }
                return _mealPlanCard(mealPlan);
              },
            ),
            const SizedBox(height: 24),
            // TODO: Add Admin actions (generate meal plan, etc)
          ],
        ),
      ),
    );
  }

  Future<List<CheckinModel>> _fetchCheckins(String userId) async {
    print('Fetching check-ins for userId: ${userId}');
    final snapshot = await FirebaseFirestore.instance
        .collection('checkins')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    print('Fetched check-ins: ${snapshot.docs.length}');
    for (var doc in snapshot.docs) {
      print('Check-in doc: ${doc.data()}');
    }
    return snapshot.docs.map((doc) => CheckinModel.fromJson(doc.data())).toList();
  }

  Future<MealPlanModel?> _fetchMealPlan(String? mealPlanId) async {
    if (mealPlanId == null) return null;
    final doc = await FirebaseFirestore.instance.collection('meal_plans').doc(mealPlanId).get();
    if (!doc.exists) return null;
    return MealPlanModel.fromJson(doc.data()!);
  }

  Widget _checkinCard(CheckinModel c) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppConstants.primaryColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(c.createdAt),
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Weight: ', style: AppTextStyles.caption),
                      Text(c.weight != null ? '${c.weight} kg' : '-', style: AppTextStyles.caption),
                      const SizedBox(width: 12),
                      Text('Status: ', style: AppTextStyles.caption),
                      Text(c.status.toString().split('.').last, style: AppTextStyles.caption),
                    ],
                  ),
                  if (c.mood != null || c.energyLevel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          if (c.mood != null) ...[
                            Icon(Icons.emoji_emotions, size: 16, color: AppConstants.accentColor),
                            const SizedBox(width: 4),
                            Text(c.mood!, style: AppTextStyles.caption),
                            const SizedBox(width: 12),
                          ],
                          if (c.energyLevel != null) ...[
                            Icon(Icons.bolt, size: 16, color: AppConstants.warningColor),
                            const SizedBox(width: 4),
                            Text('Energy: ${c.energyLevel}', style: AppTextStyles.caption),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mealPlanCard(MealPlanModel plan) {
    final duration = plan.endDate.difference(plan.startDate).inDays + 1;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(plan.description, style: AppTextStyles.bodySmall.copyWith(color: AppConstants.textSecondary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppConstants.textTertiary),
                const SizedBox(width: 4),
                Text('$duration days', style: AppTextStyles.caption),
                const SizedBox(width: 16),
                Icon(Icons.local_fire_department, size: 16, color: AppConstants.warningColor),
                const SizedBox(width: 4),
                Text('${plan.totalCalories.toStringAsFixed(0)} kcal', style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 8),
            Text('Created: ${_formatDate(plan.createdAt)}', style: AppTextStyles.caption),
            // TODO: Add button to view full meal plan details
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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