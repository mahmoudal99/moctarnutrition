import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:champions_gym_app/shared/models/user_model.dart';
import 'package:champions_gym_app/shared/models/meal_model.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:champions_gym_app/features/admin/presentation/widgets/admin_user_app_bar.dart';
import 'package:champions_gym_app/features/admin/presentation/screens/admin_meal_plan_setup_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class AdminUserMealPlanScreen extends StatelessWidget {
  final UserModel user;
  final String? mealPlanId;
  final VoidCallback? onMealPlanCreated;
  static final _logger = Logger();

  const AdminUserMealPlanScreen({
    super.key,
    required this.user,
    this.mealPlanId,
    this.onMealPlanCreated,
  });

  @override
  Widget build(BuildContext context) {
    _logger.i('AdminUserMealPlanScreen - Building screen for user: ${user.id}');
    _logger.i(
        'AdminUserMealPlanScreen - User mealPlanId from model: ${user.mealPlanId}');

    if (mealPlanId == null) {
      return Scaffold(
        appBar: AdminUserAppBar(
          user: user,
          title: 'Meal Plan',
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // No meal plan content
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            "assets/images/add-to-list-stroke-rounded.svg",
                            height: 20,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'No Meal Plan Yet',
                            style: AppTextStyles.heading4.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingS),
                      Text(
                          'Create a personalized meal plan for ${user.name?.split(' ').first ?? 'this user'}\nto get started.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall),
                      const SizedBox(height: AppConstants.spacingS + 5),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdminMealPlanSetupScreen(user: user),
                            ),
                          );
                          if (result == true) {
                            onMealPlanCreated?.call();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create Meal Plan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
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
                ),
              ),
            ],
          ),
        ),
      );
    }

    _logger
        .i('AdminUserMealPlanScreen - Fetching meal plan with ID: $mealPlanId');

    return FutureBuilder<MealPlanModel?>(
      future: _fetchMealPlan(mealPlanId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          _logger.e(
              'AdminUserMealPlanScreen - Error loading meal plan: ${snapshot.error}');
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

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final mealPlan = snapshot.data;
        if (mealPlan == null) {
          _logger.w(
              'AdminUserMealPlanScreen - Meal plan is null after fetch, showing create screen');
          return Scaffold(
            appBar: AdminUserAppBar(
              user: user,
              title: 'Meal Plan',
            ),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),

                  // No meal plan content
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu_outlined,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Meal Plan Yet',
                            style: AppTextStyles.heading4.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a personalized meal plan for ${user.name?.split(' ').first ?? 'this user'} to help them achieve their fitness goals',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AdminMealPlanSetupScreen(user: user),
                                ),
                              );
                              if (result == true) {
                                onMealPlanCreated?.call();
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
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        _logger.i(
            'AdminUserMealPlanScreen - Successfully loaded meal plan: ${mealPlan.title}');
        _logger.i('AdminUserMealPlanScreen - Meal plan ID: ${mealPlan.id}');
        _logger.i(
            'AdminUserMealPlanScreen - Meal plan userId: ${mealPlan.userId}');
        _logger.i('AdminUserMealPlanScreen - Current user ID: ${user.id}');
        _logger.i(
            'AdminUserMealPlanScreen - User IDs match: ${mealPlan.userId == user.id}');
        _logger.i(
            'AdminUserMealPlanScreen - Meal plan created: ${mealPlan.createdAt}');
        _logger.i(
            'AdminUserMealPlanScreen - Number of meal days: ${mealPlan.mealDays.length}');

        return Scaffold(
          appBar: AdminUserAppBar(
            user: user,
            title: 'Meal Plan',
            actions: [
              // Debug delete button for testing
              IconButton(
                onPressed: () => _showDeleteConfirmation(context, mealPlanId!),
                icon: SvgPicture.asset(
                  "assets/images/delete-03-stroke-rounded.svg",
                  color: AppConstants.textTertiary,
                  height: 20,
                ),
                tooltip: 'Delete Meal Plan (Debug)',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Daily meal cards
                ...mealPlan.mealDays.asMap().entries.map((entry) {
                  final index = entry.key;
                  final day = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _buildMealDayCard(day, index),
                  );
                }),
                const SizedBox(
                  height: 96,
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<MealPlanModel?> _fetchMealPlan(String mealPlanId) async {
    _logger.d(
        'AdminUserMealPlanScreen - _fetchMealPlan called with ID: $mealPlanId');

    try {
      _logger.d(
          'AdminUserMealPlanScreen - Starting Firestore fetch for document: $mealPlanId');

      // Test Firestore connection first
      _logger.d('AdminUserMealPlanScreen - Testing Firestore connection...');
      final testQuery = await FirebaseFirestore.instance
          .collection('meal_plans')
          .limit(1)
          .get();
      _logger.d(
          'AdminUserMealPlanScreen - Firestore connection test: ${testQuery.docs.length} documents found');

      final doc = await FirebaseFirestore.instance
          .collection('meal_plans')
          .doc(mealPlanId)
          .get();

      _logger.d('AdminUserMealPlanScreen - Document fetch completed');

      _logger.d('AdminUserMealPlanScreen - Document exists: ${doc.exists}');

      if (doc.exists) {
        final data = doc.data()!;
        _logger.d(
            'AdminUserMealPlanScreen - Document data keys: ${data.keys.toList()}');
        _logger
            .d('AdminUserMealPlanScreen - Document userId: ${data['userId']}');
        _logger.d('AdminUserMealPlanScreen - Document title: ${data['title']}');
        _logger.d(
            'AdminUserMealPlanScreen - Document createdAt: ${data['createdAt']}');

        final mealPlan = MealPlanModel.fromJson(data, documentId: doc.id);
        _logger.i(
            'AdminUserMealPlanScreen - Successfully parsed meal plan: ${mealPlan.title}');

        // Additional debug: Check if this user actually has this mealPlanId in their user document
        _logger.d(
            'AdminUserMealPlanScreen - Verifying user document has this mealPlanId...');
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.id)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data()!;
            final userMealPlanId = userData['mealPlanId'];
            _logger.d(
                'AdminUserMealPlanScreen - User document mealPlanId: $userMealPlanId');
            _logger
                .d('AdminUserMealPlanScreen - Fetched mealPlanId: $mealPlanId');
            _logger.d(
                'AdminUserMealPlanScreen - IDs match: ${userMealPlanId == mealPlanId}');

            if (userMealPlanId != mealPlanId) {
              _logger.w(
                  'AdminUserMealPlanScreen - ⚠️ MISMATCH: User document has different mealPlanId!');
              _logger.w(
                  'AdminUserMealPlanScreen - This could be why the user app can\'t find the meal plan');
            }
          } else {
            _logger.e(
                'AdminUserMealPlanScreen - User document not found: ${user.id}');
          }
        } catch (userDocError) {
          _logger.e(
              'AdminUserMealPlanScreen - Error checking user document: $userDocError');
        }

        return mealPlan;
      } else {
        _logger.w(
            'AdminUserMealPlanScreen - Meal plan document does not exist: $mealPlanId');

        // Additional debug: Search for meal plans by userId
        _logger.d(
            'AdminUserMealPlanScreen - Searching for meal plans by userId: ${user.id}');
        try {
          final querySnapshot = await FirebaseFirestore.instance
              .collection('meal_plans')
              .where('userId', isEqualTo: user.id)
              .get();

          _logger.d(
              'AdminUserMealPlanScreen - Found ${querySnapshot.docs.length} meal plans for user ${user.id}');
          for (var doc in querySnapshot.docs) {
            final data = doc.data();
            _logger.d(
                'AdminUserMealPlanScreen - Found plan: ${doc.id}, title: ${data['title']}, userId: ${data['userId']}');
          }
        } catch (searchError) {
          _logger.e(
              'AdminUserMealPlanScreen - Error searching meal plans by userId: $searchError');
        }

        return null;
      }
    } catch (e, stackTrace) {
      _logger.e('AdminUserMealPlanScreen - Error fetching meal plan: $e');
      _logger.e('AdminUserMealPlanScreen - Stack trace: $stackTrace');
      return null;
    }
  }

  Widget _buildMealPlanOverviewCard(MealPlanModel mealPlan) {
    mealPlan.mealDays.fold<double>(
      0,
      (sum, day) => sum + day.totalCalories,
    );

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
                  'Meal Plan Overview',
                  style: AppTextStyles.heading4.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealDayCard(MealDay day, int dayIndex) {
    // Group meals by type
    final Map<MealType, List<Meal>> mealsByType = {};
    for (final meal in day.meals) {
      mealsByType.putIfAbsent(meal.type, () => []).add(meal);
    }

    // Define the order of meal types
    const mealTypeOrder = [
      MealType.breakfast,
      MealType.lunch,
      MealType.dinner,
      MealType.snack,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_getDayName(dayIndex), style: AppTextStyles.heading5),
        SizedBox(
          height: AppConstants.spacingS,
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: mealTypeOrder
                      .where((mealType) => mealsByType.containsKey(mealType))
                      .map((mealType) {
                    final meals = mealsByType[mealType]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Meal type section header
                        _buildMealTypeSection(mealType, meals),
                        const SizedBox(height: AppConstants.spacingS),

                        // Meals for this type
                        ...meals.map((meal) => _buildMealItem(meal)),

                        if (mealType != mealTypeOrder.last) ...[
                          const SizedBox(height: 16),
                          Divider(
                            color: Colors.grey.withOpacity(0.2),
                            height: 1,
                            thickness: 1,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealItem(Meal meal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildNutritionChip(
                        'P', '${meal.nutrition.protein.toStringAsFixed(0)}g'),
                    const SizedBox(width: 8),
                    _buildNutritionChip(
                        'C', '${meal.nutrition.carbs.toStringAsFixed(0)}g'),
                    const SizedBox(width: 8),
                    _buildNutritionChip(
                        'F', '${meal.nutrition.fat.toStringAsFixed(0)}g'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTypeSection(MealType mealType, List<Meal> meals) {
    final totalCalories = meals.fold<double>(
      0,
      (sum, meal) => sum + meal.nutrition.calories,
    );

    return Row(
      children: [
        Text(
          _getMealTypeTitle(mealType),
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppConstants.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.accentColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            '${totalCalories.round()} kcal',
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.accentColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  String _getMealTypeTitle(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  Color _getMealTypeColor(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return AppConstants.warningColor.withOpacity(0.6);
      case MealType.lunch:
        return AppConstants.proteinColor.withOpacity(0.6);
      case MealType.dinner:
        return AppConstants.primaryColor.withOpacity(0.6);
      case MealType.snack:
        return AppConstants.secondaryColor;
    }
  }

  String _getMealTypeIcon(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return "eggs.svg";
      case MealType.lunch:
        return "lunch.svg";
      case MealType.dinner:
        return "dinner.svg";
      case MealType.snack:
        return "snack.svg";
    }
  }

  Widget _buildNutritionChip(String label, String value) {
    Color chipColor;
    switch (label) {
      case 'P':
        chipColor = AppConstants.proteinColor;
        break;
      case 'C':
        chipColor = AppConstants.carbsColor;
        break;
      case 'F':
        chipColor = AppConstants.fatColor;
        break;
      default:
        chipColor = AppConstants.primaryColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: AppTextStyles.caption.copyWith(
          color: chipColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String mealPlanId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Delete Meal Plan'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bug_report, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'DEBUG ACTION',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Are you sure you want to delete this meal plan? This action cannot be undone.',
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('meal_plans')
                      .doc(mealPlanId)
                      .delete();

                  // Also remove the mealPlanId from the user document
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.id)
                      .update({
                    'mealPlanId': FieldValue.delete(),
                  });

                  Navigator.of(context).pop();

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Meal plan deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  onMealPlanCreated?.call(); // Refresh the screen
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete meal plan: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  String _getDayName(int dayIndex) {
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    // Handle cases where there might be more than 7 days
    if (dayIndex < dayNames.length) {
      return dayNames[dayIndex];
    } else {
      // For plans longer than a week, cycle through the days
      return dayNames[dayIndex % 7];
    }
  }
}
