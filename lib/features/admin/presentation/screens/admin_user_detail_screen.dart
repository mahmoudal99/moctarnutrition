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
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _mealPlanId = widget.user.mealPlanId;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final handle =
        '@${user.name?.toLowerCase().replaceAll(' ', '') ?? user.email.split('@').first}';

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Client Details',
          style: AppTextStyles.heading4.copyWith(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
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
        ],
      ),
      body: _buildCurrentScreen(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildUserProfileHeader(UserModel user, String handle) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor.withOpacity(0.1),
            AppConstants.accentColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
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
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: AvatarUtils.buildAvatar(
              photoUrl: user.photoUrl,
              name: user.name,
              email: user.email,
              radius: 40,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Row(
                  children: [
                    _buildBadge(_roleLabel(user.role), _roleColor(user.role)),
                    const SizedBox(width: 8),
                    _buildBadge(_subscriptionLabel(user.subscriptionStatus),
                        _subscriptionColor(user.subscriptionStatus)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return const SizedBox.shrink();
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildBottomNavItem(0, 'Profile'),
              _buildBottomNavItem(1, 'Check-ins'),
              _buildBottomNavItem(2, 'Meal Plan'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(int index, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _currentIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.primaryColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isSelected ? AppConstants.primaryColor : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildProfileScreen();
      case 1:
        return _buildCheckInsScreen();
      case 2:
        return _buildMealPlanScreen();
      default:
        return _buildProfileScreen();
    }
  }

  Widget _buildProfileScreen() {
    final user = widget.user;
    final prefs = user.preferences;
    final handle =
        '@${user.name?.toLowerCase().replaceAll(' ', '') ?? user.email.split('@').first}';

    return SingleChildScrollView(
      child: Column(
        children: [
          // User profile header
          _buildUserProfileHeader(user, handle),

          // Quick stats cards
          _buildQuickStats(),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Create Meal Plan button (if needed)
                if (_mealPlanId == null) _buildCreateMealPlanCard(),

                if (_mealPlanId == null) const SizedBox(height: 24),

                // Contact Information
                _buildInfoCard(
                  'Contact Information',
                  Icons.contact_mail_outlined,
                  [
                    _buildInfoRow('Name', user.name ?? user.email),
                    _buildInfoRow('Email', user.email),
                  ],
                ),

                const SizedBox(height: 16),

                // Fitness Information
                _buildInfoCard(
                  'Fitness Profile',
                  Icons.fitness_center_outlined,
                  [
                    _buildInfoRow(
                        'Fitness Goal', _fitnessGoalLabel(prefs.fitnessGoal)),
                    _buildInfoRow(
                        'Activity Level', _activityLevelLabel(prefs.activityLevel)),
                    _buildInfoRow('Target Calories', '${prefs.targetCalories} kcal'),
                  ],
                ),

                const SizedBox(height: 16),

                // Physical Information
                _buildInfoCard(
                  'Physical Information',
                  Icons.person_outline,
                  [
                    _buildInfoRow('Age', '${prefs.age} years'),
                    _buildInfoRow('Weight', '${prefs.weight} kg'),
                    _buildInfoRow('Height', '${prefs.height} cm'),
                    _buildInfoRow('Gender', prefs.gender),
                  ],
                ),

                const SizedBox(height: 16),

                // Preferences
                _buildInfoCard(
                  'Preferences',
                  Icons.settings_outlined,
                  [
                    _buildInfoRow(
                      'Dietary Restrictions',
                      prefs.dietaryRestrictions.isEmpty
                          ? 'None'
                          : prefs.dietaryRestrictions.join(', '),
                    ),
                    _buildInfoRow(
                      'Preferred Workouts',
                      prefs.preferredWorkoutStyles.isEmpty
                          ? 'None'
                          : prefs.preferredWorkoutStyles.join(', '),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInsScreen() {
    return FutureBuilder<List<CheckinModel>>(
      future: _fetchCheckins(widget.user.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading check-ins',
                  style:
                      AppTextStyles.bodyLarge.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final checkins = snapshot.data ?? [];
        final checkinCount = checkins.length;
        final activeWeeks = checkins.map((c) => c.weekStartDate).toSet().length;

        if (checkins.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 32, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No check-ins found',
                  style:
                      AppTextStyles.bodyLarge.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'This user hasn\'t checked in yet',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Check-in stats
            Container(
              margin: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '$checkinCount',
                      'Check-ins',
                      Icons.check_circle_outline,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '$activeWeeks',
                      'Active Weeks',
                      Icons.calendar_today_outlined,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            
            // Check-ins list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: checkins.length,
                itemBuilder: (context, index) {
                  final checkin = checkins[index];
                  return _buildCheckinCard(checkin);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMealPlanScreen() {
    return FutureBuilder<MealPlanModel?>(
      future: _fetchMealPlan(_mealPlanId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading meal plan',
                  style:
                      AppTextStyles.bodyLarge.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final mealPlan = snapshot.data;

        if (mealPlan == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_outlined,
                    size: 32, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No meal plan found',
                  style:
                      AppTextStyles.bodyLarge.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a meal plan for this user',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AdminMealPlanSetupScreen(user: widget.user),
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
                  icon: const Icon(Icons.add),
                  label: const Text('Create Meal Plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Meal plan overview card
              _buildMealPlanOverviewCard(mealPlan),

              const SizedBox(height: 24),

              // Daily meal cards
              ...mealPlan.mealDays.asMap().entries.map((entry) {
                final index = entry.key;
                final day = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildMealDayCard(day, index + 1),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreateMealPlanCard() {
    return Container(
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
                  'Generate personalized meal plan for ${widget.user.name?.split(' ').first ?? 'this user'}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AdminMealPlanSetupScreen(user: widget.user),
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
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: AppConstants.primaryColor,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
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

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
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
            Row(
              children: [
                Icon(icon, color: AppConstants.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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

  Widget _buildCheckinCard(CheckinModel checkin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: checkin.photoThumbnailUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  checkin.photoThumbnailUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: 28,
                  color: Colors.grey[400],
                ),
              ),
        title: Text(
          _formatDate(checkin.createdAt),
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (checkin.weight != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.monitor_weight_outlined,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${checkin.weight} kg',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            if (checkin.mood != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.emoji_emotions_outlined,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      checkin.mood!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            if (checkin.energyLevel != null)
              Row(
                children: [
                  Icon(Icons.bolt_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Energy: ${checkin.energyLevel}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
          ],
        ),
        trailing: _buildBadge(
          checkin.status.toString().split('.').last,
          _statusColor(checkin.status),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CheckinDetailsScreen(checkin: checkin),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMealPlanOverviewCard(MealPlanModel mealPlan) {
    final duration = mealPlan.endDate.difference(mealPlan.startDate).inDays + 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor.withOpacity(0.1),
            AppConstants.accentColor.withOpacity(0.05),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_menu,
                  color: AppConstants.primaryColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  mealPlan.title,
                  style: AppTextStyles.heading4.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mealPlan.description,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMealPlanStat('$duration', 'Days'),
              const SizedBox(width: 24),
              _buildMealPlanStat(
                  '${mealPlan.totalCalories.toStringAsFixed(0)}', 'Calories'),
              const SizedBox(width: 24),
              _buildMealPlanStat('${mealPlan.mealDays.length}', 'Meals'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealPlanStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.heading4.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMealDayCard(MealDay day, int dayNumber) {
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Day $dayNumber',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${day.totalCalories.toStringAsFixed(0)} kcal',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...day.meals.map((meal) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.restaurant,
                        size: 16,
                        color: AppConstants.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          meal.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        '${meal.nutrition.calories.toStringAsFixed(0)} kcal',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )),
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

  // Helper methods
  Future<List<CheckinModel>> _fetchCheckins(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('checkins')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
