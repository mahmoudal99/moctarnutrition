import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:champions_gym_app/shared/models/user_model.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:champions_gym_app/shared/utils/avatar_utils.dart';
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
    final checkInsFuture = _fetchCheckins(user.id);
    final mealPlanFuture = _fetchMealPlan(user.mealPlanId);
    
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // Gradient header with centered profile
              Stack(
                children: [
                  Container(
                    height: 180,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFe8f5e8), // soft mint green
                          Color(0xFFd4f4ff), // soft blue
                          Color(0xFFf8f9fa), // clean white
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
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _roleColor(user.role).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _subscriptionLabel(user.subscriptionStatus),
                        style: AppTextStyles.caption.copyWith(
                          color: _roleColor(user.role),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                            const SizedBox(height: 20), // Added padding above avatar
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
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: AvatarUtils.buildAvatar(
                                photoUrl: user.photoUrl,
                                name: user.name,
                                email: user.email,
                                radius: 32,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user.name ?? user.email,
                              style: AppTextStyles.heading4.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              handle,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.black54,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Generate Meal Plan button (if needed)
              if (_mealPlanId == null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: InkWell(
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminMealPlanSetupScreen(user: widget.user),
                        ),
                      );
                      if (result == true) {
                        final userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.user.id)
                            .get();
                        setState(() {
                          _mealPlanId = userDoc.data()?['mealPlanId'] as String?;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppConstants.primaryColor.withOpacity(0.1),
                            AppConstants.primaryColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppConstants.primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.restaurant_menu,
                              color: AppConstants.primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create Meal Plan',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Generate personalized meal plan for ${user.name?.split(' ').first ?? 'this user'}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: AppConstants.primaryColor,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Clean stats section
              FutureBuilder<List<CheckinModel>>(
                future: checkInsFuture,
                builder: (context, checkinSnap) {
                  final checkins = checkinSnap.data ?? [];
                  final checkinCount = checkins.length;
                  final activeWeeks = checkins.map((c) => c.weekStartDate).toSet().length;
                  
                  return FutureBuilder<MealPlanModel?>(
                    future: _fetchMealPlan(_mealPlanId),
                    builder: (context, mealSnap) {
                      final mealPlan = mealSnap.data;
                      final mealPlanDays = mealPlan?.mealDays.length ?? 0;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildModernStatCard(
                                '$checkinCount',
                                'Check-ins',
                                Icons.check_circle_outline,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildModernStatCard(
                                '$activeWeeks',
                                'Weeks',
                                Icons.calendar_today_outlined,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildModernStatCard(
                                mealPlan != null ? '$mealPlanDays' : '0',
                                'Meal Days',
                                Icons.restaurant_outlined,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Clean tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  labelColor: AppConstants.primaryColor,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: AppConstants.primaryColor,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorWeight: 3,
                  labelStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  unselectedLabelStyle: AppTextStyles.bodyMedium,
                  tabs: const [
                    Tab(text: 'Profile'),
                    Tab(text: 'Check-ins'),
                    Tab(text: 'Meal Plan'),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Tab content
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

  Widget _buildStatExpanded(String value, String label,
      {bool isLeft = false, bool isRight = false}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: AppTextStyles.heading4
                    .copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppConstants.textSecondary)),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Contact Information
          _buildProfileSection(
            'Contact Information',
            [
              _buildProfileRow('Name', user.name ?? user.email),
              _buildProfileRow('Email', user.email),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Fitness Information
          _buildProfileSection(
            'Fitness Profile',
            [
              _buildProfileRow('Fitness Goal', _fitnessGoalLabel(prefs.fitnessGoal)),
              _buildProfileRow('Activity Level', _activityLevelLabel(prefs.activityLevel)),
              _buildProfileRow('Target Calories', '${prefs.targetCalories} kcal'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Physical Information
          _buildProfileSection(
            'Physical Information',
            [
              _buildProfileRow('Age', '${prefs.age} years'),
              _buildProfileRow('Weight', '${prefs.weight} kg'),
              _buildProfileRow('Height', '${prefs.height} cm'),
              _buildProfileRow('Gender', prefs.gender),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Preferences
          _buildProfileSection(
            'Preferences',
            [
              _buildProfileRow(
                'Dietary Restrictions',
                prefs.dietaryRestrictions.isEmpty ? 'None' : prefs.dietaryRestrictions.join(', '),
              ),
              _buildProfileRow(
                'Preferred Workouts',
                prefs.preferredWorkoutStyles.isEmpty ? 'None' : prefs.preferredWorkoutStyles.join(', '),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
        ],
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
              left: 12,
              right: 12,
              top: 12,
              bottom: kBottomNavigationBarHeight + 16),
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
              left: 12,
              right: 12,
              top: 12,
              bottom: kBottomNavigationBarHeight + 16),
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

  Widget _buildModernStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.heading4.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanDivider() {
    return Container(
      width: 1,
      height: 36,
      color: AppConstants.textTertiary.withOpacity(0.12),
    );
  }

  Widget _buildProfileSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
