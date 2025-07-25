import 'package:flutter/material.dart';
import 'package:champions_gym_app/shared/models/user_model.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:champions_gym_app/shared/models/checkin_model.dart';
import 'package:champions_gym_app/shared/models/meal_model.dart';
import 'package:champions_gym_app/features/checkin/presentation/screens/checkin_details_screen.dart';
import 'package:champions_gym_app/features/admin/presentation/screens/admin_meal_plan_setup_screen.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final UserModel user;

  const AdminUserDetailScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  String? _mealPlanId;

  @override
  void initState() {
    super.initState();
    _mealPlanId = widget.user.mealPlanId;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final prefs = user.preferences;
    final handle =
        '@${user.name?.toLowerCase().replaceAll(' ', '') ?? user.email.split('@').first}';
    final subtitle =
        '${_roleLabel(user.role)} • ${_subscriptionLabel(user.subscriptionStatus)}';
    final checkInsFuture = _fetchCheckins(user.id);
    final mealPlanFuture = _fetchMealPlan(user.mealPlanId);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // Modern header
              Stack(
                children: [
                  Container(
                    height: 200, // Increased height
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFe0c3fc), // pastel purple
                          Color(0xFF8ec5fc), // pastel blue
                          Color(0xFFf9f9f9), // white
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    left: 16,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.black87),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 16,
                    child: IconButton(
                      icon: const Icon(Icons.info_outline_rounded,
                          color: Colors.black54),
                      onPressed: () {},
                    ),
                  ),
                  // Centered profile content
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border:
                                    Border.all(color: Colors.white, width: 4),
                              ),
                              child: CircleAvatar(
                                radius: 35,
                                backgroundColor: Colors.white,
                                backgroundImage: user.photoUrl != null
                                    ? NetworkImage(user.photoUrl!)
                                    : null,
                                child: user.photoUrl == null
                                    ? const Icon(Icons.person,
                                        size: 35,
                                        color: AppConstants.primaryColor)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(user.name ?? user.email,
                                style: AppTextStyles.heading4
                                    .copyWith(color: Colors.black87)),
                            const SizedBox(height: 4),
                            Text(handle,
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: Colors.black54)),
                            const SizedBox(height: 4),
                            Text(subtitle,
                                style: AppTextStyles.caption
                                    .copyWith(color: Colors.black45)),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Show Generate Meal Plan button only if no meal plan exists
              if (_mealPlanId == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.psychology),
                      label: const Text('Generate Meal Plan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdminMealPlanSetupScreen(user: widget.user),
                          ),
                        );
                        if (result == true) {
                          // Refetch the user document to get the new mealPlanId
                          final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.user.id).get();
                          setState(() {
                            _mealPlanId = userDoc.data()?['mealPlanId'] as String?;
                          });
                        }
                      },
                    ),
                  ),
                ),
              SizedBox(
                height: 10,
              ),
              // Stats row
              FutureBuilder<List<CheckinModel>>(
                future: checkInsFuture,
                builder: (context, checkinSnap) {
                  final checkins = checkinSnap.data ?? [];
                  final checkinCount = checkins.length;
                  final activeWeeks =
                      checkins.map((c) => c.weekStartDate).toSet().length;
                  return FutureBuilder<MealPlanModel?>(
                    future: _fetchMealPlan(_mealPlanId),
                    builder: (context, mealSnap) {
                      final mealPlan = mealSnap.data;
                      final mealPlanDays = mealPlan?.mealDays.length ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppConstants.surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              _buildStatExpanded('$checkinCount', 'Check-ins', isLeft: true),
                              _verticalDivider(),
                              _buildStatExpanded('$activeWeeks', 'Active Weeks'),
                              _verticalDivider(),
                              _buildStatExpanded(mealPlan != null ? '$mealPlanDays' : 'N/A', 'Meal Plan Days', isRight: true),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 22),
              // Tabs
              TabBar(
                labelColor: AppConstants.primaryColor,
                unselectedLabelColor: AppConstants.textTertiary,
                indicatorColor: AppConstants.primaryColor,
                tabs: const [
                  Tab(text: 'Profile'),
                  Tab(text: 'Check-ins'),
                  Tab(text: 'Meal Plan'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _profileTab(prefs, user),
                    _checkInsTab(user.id),
                    _mealPlanTab(_mealPlanId),
                  ],
                ),
              ),
            ],
          ),
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
    return snapshot.docs
        .map((doc) => CheckinModel.fromJson(doc.data()))
        .toList();
  }

  Future<MealPlanModel?> _fetchMealPlan(String? mealPlanId) async {
    if (mealPlanId == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('meal_plans')
        .doc(mealPlanId)
        .get();
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
            Icon(Icons.check_circle,
                color: AppConstants.primaryColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(c.createdAt),
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Weight: ', style: AppTextStyles.caption),
                      Text(c.weight != null ? '${c.weight} kg' : '-',
                          style: AppTextStyles.caption),
                      const SizedBox(width: 12),
                      Text('Status: ', style: AppTextStyles.caption),
                      Text(c.status.toString().split('.').last,
                          style: AppTextStyles.caption),
                    ],
                  ),
                  if (c.mood != null || c.energyLevel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          if (c.mood != null) ...[
                            Icon(Icons.emoji_emotions,
                                size: 16, color: AppConstants.accentColor),
                            const SizedBox(width: 4),
                            Text(c.mood!, style: AppTextStyles.caption),
                            const SizedBox(width: 12),
                          ],
                          if (c.energyLevel != null) ...[
                            Icon(Icons.bolt,
                                size: 16, color: AppConstants.warningColor),
                            const SizedBox(width: 4),
                            Text('Energy: ${c.energyLevel}',
                                style: AppTextStyles.caption),
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
            Text(plan.title,
                style: AppTextStyles.bodyLarge
                    .copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(plan.description,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppConstants.textSecondary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 16, color: AppConstants.textTertiary),
                const SizedBox(width: 4),
                Text('$duration days', style: AppTextStyles.caption),
                const SizedBox(width: 16),
                Icon(Icons.local_fire_department,
                    size: 16, color: AppConstants.warningColor),
                const SizedBox(width: 4),
                Text('${plan.totalCalories.toStringAsFixed(0)} kcal',
                    style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 8),
            Text('Created: ${_formatDate(plan.createdAt)}',
                style: AppTextStyles.caption),
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
          SizedBox(
              width: 120,
              child: Text(label,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppConstants.textSecondary))),
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

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style:
                AppTextStyles.heading4.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppConstants.textSecondary)),
      ],
    );
  }

  Widget _buildStatExpanded(String value, String label, {bool isLeft = false, bool isRight = false}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: AppTextStyles.heading4.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption.copyWith(color: AppConstants.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 36,
      color: AppConstants.textTertiary.withOpacity(0.12),
    );
  }

  Widget _profileTab(UserPreferences prefs, UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _prefRow('Name', user.name ?? user.email),
              _prefRow('Email', user.email),
              _prefRow('Role', _roleLabel(user.role)),
              _prefRow(
                  'Subscription', _subscriptionLabel(user.subscriptionStatus)),
              _prefRow('Fitness Goal', _fitnessGoalLabel(prefs.fitnessGoal)),
              _prefRow(
                  'Activity Level', _activityLevelLabel(prefs.activityLevel)),
              _prefRow(
                  'Dietary Restrictions',
                  prefs.dietaryRestrictions.isEmpty
                      ? 'None'
                      : prefs.dietaryRestrictions.join(', ')),
              _prefRow(
                  'Preferred Workouts',
                  prefs.preferredWorkoutStyles.isEmpty
                      ? 'None'
                      : prefs.preferredWorkoutStyles.join(', ')),
              _prefRow('Target Calories', '${prefs.targetCalories} kcal'),
              _prefRow('Age', prefs.age.toString()),
              _prefRow('Weight', '${prefs.weight} kg'),
              _prefRow('Height', '${prefs.height} cm'),
              _prefRow('Gender', prefs.gender),
            ],
          ),
        ),
      ),
    );
  }

  Widget _checkInsTab(String userId) {
    return FutureBuilder<List<CheckinModel>>(
      future: _fetchCheckins(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Error loading check-ins: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final checkins = snapshot.data ?? [];
        if (checkins.isEmpty) {
          return Center(
              child:
                  Text('No check-ins found.', style: AppTextStyles.bodyMedium));
        }
        return ListView.builder(
          padding: EdgeInsets.only(
            left: 12, right: 12, top: 12, bottom: kBottomNavigationBarHeight + 16),
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: checkins.length,
          itemBuilder: (context, index) {
            final c = checkins[index];
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: c.photoThumbnailUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(c.photoThumbnailUrl!,
                            width: 48, height: 48, fit: BoxFit.cover),
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppConstants.surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.camera_alt,
                            size: 28, color: AppConstants.textTertiary),
                      ),
                title: Text(_formatDate(c.createdAt),
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (c.mood != null)
                      Text('Mood: ${c.mood!}', style: AppTextStyles.bodySmall),
                    if (c.weight != null)
                      Text('Weight: ${c.weight} kg',
                          style: AppTextStyles.bodySmall),
                  ],
                ),
                trailing: _buildBadge(c.status.toString().split('.').last,
                    _statusColor(c.status)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckinDetailsScreen(checkin: c),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _mealPlanTab(String? mealPlanId) {
    return FutureBuilder<MealPlanModel?>(
      future: _fetchMealPlan(mealPlanId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading meal plan'));
        }
        final mealPlan = snapshot.data;
        if (mealPlan == null) {
          return Center(
              child:
                  Text('No meal plan found.', style: AppTextStyles.bodyMedium));
        }
        return ListView.builder(
          padding: EdgeInsets.only(
            left: 12, right: 12, top: 12, bottom: kBottomNavigationBarHeight + 16),
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: mealPlan.mealDays.length,
          itemBuilder: (context, index) {
            final day = mealPlan.mealDays[index];
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Day ${index + 1}',
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${day.totalCalories.toStringAsFixed(0)} kcal',
                        style: AppTextStyles.caption),
                    const SizedBox(height: 8),
                    ...day.meals.map((meal) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(Icons.restaurant,
                                  size: 14, color: AppConstants.primaryColor),
                              const SizedBox(width: 4),
                              Expanded(
                                  child: Text(meal.name,
                                      style: AppTextStyles.bodySmall)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _statusColor(CheckinStatus status) {
    switch (status) {
      case CheckinStatus.completed:
        return AppConstants.successColor;
      case CheckinStatus.missed:
        return AppConstants.errorColor;
      case CheckinStatus.pending:
      default:
        return AppConstants.warningColor;
    }
  }
}
