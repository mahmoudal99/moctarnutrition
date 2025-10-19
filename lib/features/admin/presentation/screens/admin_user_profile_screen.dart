import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:champions_gym_app/shared/models/user_model.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:champions_gym_app/features/admin/presentation/widgets/admin_user_header.dart';
import 'package:champions_gym_app/features/admin/presentation/widgets/admin_info_card.dart';
import 'package:champions_gym_app/features/admin/presentation/widgets/admin_create_meal_plan_card.dart';
import 'package:champions_gym_app/shared/services/progress_service.dart';
import 'package:champions_gym_app/shared/widgets/bmi_widget.dart';
import 'package:champions_gym_app/shared/widgets/weight_progress_widget.dart';
import 'package:champions_gym_app/shared/widgets/weight_chart_widget.dart';

class AdminUserProfileScreen extends StatelessWidget {
  final UserModel user;
  final String? mealPlanId;
  final VoidCallback? onMealPlanCreated;

  const AdminUserProfileScreen({
    super.key,
    required this.user,
    this.mealPlanId,
    this.onMealPlanCreated,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 180,
          collapsedHeight: 60,
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_outlined,
              color: Colors.black,
              size: 20,
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: AdminUserHeader(user: user),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(0),
                topRight: Radius.circular(0),
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

                  const SizedBox(height: 16),

                  // Account Status
                  AdminInfoCard(
                    title: 'Account Status',
                    icon: Icons.account_circle_outlined,
                    children: [
                      AdminInfoRow(
                        label: 'Account Created',
                        value: _formatDate(user.createdAt),
                      ),
                      AdminInfoRow(
                        label: 'Last Updated',
                        value: _formatDate(user.updatedAt),
                      ),
                      AdminInfoRow(
                        label: 'Onboarding Completed',
                        value: user.hasSeenOnboarding ? 'Yes' : 'No',
                        valueColor: user.hasSeenOnboarding
                            ? AppConstants.successColor
                            : AppConstants.warningColor,
                      )
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Program Information
                  AdminInfoCard(
                    title: 'Program Information',
                    icon: Icons.fitness_center_outlined,
                    children: [
                      AdminInfoRow(
                        label: 'Training Program',
                        value: _getTrainingProgramStatusLabel(
                            user.trainingProgramStatus),
                      ),
                      if (user.currentProgramId != null)
                        AdminInfoRow(
                          label: 'Current Program ID',
                          value: user.currentProgramId!,
                        ),
                      if (user.programPurchaseDate != null)
                        AdminInfoRow(
                          label: 'Purchase Date',
                          value: _formatDate(user.programPurchaseDate!),
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
                          label: 'Age', value: '${user.preferences.age} years'),
                      AdminInfoRow(
                          label: 'Weight',
                          value: '${user.preferences.weight} kg'),
                      AdminInfoRow(
                          label: 'Height',
                          value: '${user.preferences.height} cm'),
                      AdminInfoRow(
                          label: 'Gender', value: user.preferences.gender),
                      AdminInfoRow(
                        label: 'Desired Weight',
                        value: '${user.preferences.desiredWeight} kg',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // BMI Widget
                  BMIWidget(
                    bmiData: _calculateBMIData(),
                    title: 'BMI Information',
                    weightLabel: 'Weight is',
                  ),

                  const SizedBox(height: 16),

                  // Weight Progress Widget - Using GoalProgressGraph
                  FutureBuilder<WeightProgressData?>(
                    future: _getWeightProgressData(),
                    builder: (context, snapshot) {
                      final weightProgress = snapshot.data;
                      final progressPercentage = weightProgress?.progressPercentage ?? 0.0;

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppConstants.spacingL),
                        decoration: BoxDecoration(
                          color: AppConstants.surfaceColor,
                          borderRadius: BorderRadius.circular(AppConstants.radiusL),
                          boxShadow: AppConstants.shadowM,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Weight Progress',
                                  style: AppTextStyles.body1.copyWith(
                                    color: AppConstants.textPrimary,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.flag,
                                      size: 16,
                                      color: AppConstants.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${progressPercentage.toStringAsFixed(0)}% of goal',
                                      style: AppTextStyles.body2.copyWith(
                                        color: AppConstants.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.spacingL),
                            WeightChartWidget(
                              weightProgress: weightProgress,
                              height: 200,
                            ),
                            const SizedBox(height: AppConstants.spacingM),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Fitness Information
                  AdminInfoCard(
                    title: 'Fitness Profile',
                    icon: Icons.fitness_center_outlined,
                    children: [
                      AdminInfoRow(
                        label: 'Fitness Goal',
                        value: _fitnessGoalLabel(user.preferences.fitnessGoal),
                      ),
                      AdminInfoRow(
                        label: 'Activity Level',
                        value:
                            _activityLevelLabel(user.preferences.activityLevel),
                      ),
                      AdminInfoRow(
                        label: 'Target Calories',
                        value: '${user.preferences.targetCalories} kcal',
                      ),
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
                        value: (user.preferences.dietaryRestrictions).isEmpty
                            ? 'None'
                            : user.preferences.dietaryRestrictions.join(', '),
                      ),
                      AdminInfoRow(
                        label: 'Preferred Workouts',
                        value: (user.preferences.preferredWorkoutStyles).isEmpty
                            ? 'None'
                            : user.preferences.preferredWorkoutStyles
                                .join(', '),
                      ),
                      AdminInfoRow(
                        label: 'Weekly Workout Days',
                        value: '${user.preferences.weeklyWorkoutDays} days',
                      ),
                      if (user.preferences.specificWorkoutDays != null &&
                          user.preferences.specificWorkoutDays!.isNotEmpty)
                        AdminInfoRow(
                          label: 'Workout Days',
                          value: _formatWorkoutDays(
                              user.preferences.specificWorkoutDays!),
                        ),
                      if (user.preferences.timezone != null)
                        AdminInfoRow(
                          label: 'Timezone',
                          value: user.preferences.timezone!,
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Food Preferences
                  if (user.preferences.preferredCuisines.isNotEmpty ||
                      user.preferences.foodsToAvoid.isNotEmpty ||
                      user.preferences.favoriteFoods.isNotEmpty)
                    AdminInfoCard(
                      title: 'Food Preferences',
                      icon: Icons.restaurant_outlined,
                      children: [
                        if (user.preferences.preferredCuisines.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Preferred Cuisines',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: user.preferences.preferredCuisines
                                      .map((cuisine) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppConstants.accentColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppConstants.accentColor
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        cuisine,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppConstants.accentColor,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (user.preferences.favoriteFoods.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Favorite Foods',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: user.preferences.favoriteFoods
                                      .map((food) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppConstants.primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppConstants.primaryColor
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        food,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppConstants.primaryColor,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (user.preferences.foodsToAvoid.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Foods to Avoid',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children:
                                      user.preferences.foodsToAvoid.map((food) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppConstants.errorColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppConstants.errorColor
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        food,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppConstants.errorColor,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                  if (user.preferences.preferredCuisines.isNotEmpty ||
                      user.preferences.foodsToAvoid.isNotEmpty ||
                      user.preferences.favoriteFoods.isNotEmpty)
                    const SizedBox(height: 16),

                  // Allergies & Intolerances
                  if (user.preferences.allergies.isNotEmpty)
                    AdminInfoCard(
                      title: 'Allergies & Intolerances',
                      icon: Icons.warning_amber_outlined,
                      children: user.preferences.allergies.map((allergy) {
                        final severity =
                            allergy['severity'] as String? ?? 'mild';
                        final notes = allergy['notes'] as String?;
                        return AdminInfoRow(
                          label: allergy['name'] as String? ?? 'Unknown',
                          value:
                              '${_getSeverityLabel(severity)}${notes != null ? ' - $notes' : ''}',
                          valueColor: _getSeverityColor(severity),
                        );
                      }).toList(),
                    ),

                  if (user.preferences.allergies.isNotEmpty)
                    const SizedBox(height: 16),

                  // Meal Timing Preferences
                  if (user.preferences.mealTimingPreferences != null)
                    AdminInfoCard(
                      title: 'Meal Timing',
                      icon: Icons.schedule_outlined,
                      children: _buildMealTimingInfo(),
                    ),

                  if (user.preferences.mealTimingPreferences != null)
                    const SizedBox(height: 16),

                  // Batch Cooking Preferences
                  if (user.preferences.batchCookingPreferences != null)
                    AdminInfoCard(
                      title: 'Batch Cooking',
                      icon: Icons.kitchen_outlined,
                      children: _buildBatchCookingInfo(),
                    ),

                  if (user.preferences.batchCookingPreferences != null)
                    const SizedBox(height: 16),

                  // Calculated Calorie Targets
                  if (user.preferences.calculatedCalorieTargets != null)
                    AdminInfoCard(
                      title: 'Calculated Calorie Targets',
                      icon: Icons.calculate_outlined,
                      children: [
                        _buildCalculatedCalorieTargetsInfo(),
                      ],
                    ),

                  if (user.preferences.calculatedCalorieTargets != null)
                    const SizedBox(height: 16),

                  // Nutritional Information
                  if (user.preferences.proteinTargets != null ||
                      user.preferences.calorieTargets != null)
                    AdminInfoCard(
                      title: 'Nutritional Information',
                      icon: Icons.monitor_weight_outlined,
                      children: [
                        if (user.preferences.proteinTargets != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Protein Targets',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildProteinTargetsInfo(),
                              ],
                            ),
                          ),
                        ],
                        if (user.preferences.calorieTargets != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Calorie & Macro Targets',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildCalorieTargetsInfo(),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                  if (user.preferences.proteinTargets != null ||
                      user.preferences.calorieTargets != null)
                    const SizedBox(height: 16),

                  const SizedBox(height: 128),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  /// Calculate BMI data from user model
  BMIData _calculateBMIData() {
    if (user.preferences.height <= 0 || user.preferences.weight <= 0) {
      return BMIData.empty();
    }

    final bmi = user.preferences.weight /
        ((user.preferences.height / 100) * (user.preferences.height / 100));
    final bmiCategory = _getBMICategory(bmi);

    return BMIData(
      currentBMI: bmi,
      bmiCategory: bmiCategory,
      weight: user.preferences.weight,
      height: user.preferences.height,
      isHealthy: bmiCategory == BMICategory.healthy,
    );
  }

  /// Get weight progress data for the user
  Future<WeightProgressData?> _getWeightProgressData() async {
    try {
      final startWeight = user.preferences.weight;
      final goalWeight = user.preferences.desiredWeight;

      // Get current weight from check-ins if available
      double currentWeight = startWeight;
      final checkins = await ProgressService.getUserCheckins(user.id);
      if (checkins.isNotEmpty) {
        final weightData = checkins.where((c) => c.weight != null).toList();
        if (weightData.isNotEmpty) {
          currentWeight = weightData.last.weight!; // Use latest check-in weight
        }
      }

      // Calculate progress percentage
      double progressPercentage = 0.0;
      if (startWeight != goalWeight) {
        final totalDistance = (startWeight - goalWeight).abs();
        final currentDistance = (startWeight - currentWeight).abs();
        progressPercentage = (currentDistance / totalDistance) * 100;
        progressPercentage = progressPercentage.clamp(0.0, 100.0);
      }

      return WeightProgressData(
        currentWeight: currentWeight,
        startWeight: startWeight,
        goalWeight: goalWeight,
        progressPercentage: progressPercentage,
        dataPoints: checkins.isNotEmpty
            ? checkins
                .where((c) => c.weight != null)
                .map((c) => WeightDataPoint(
                      date: c.weekStartDate,
                      weight: c.weight!,
                      weekRange: c.weekRange,
                    ))
                .toList()
            : [],
      );
    } catch (e) {
      return null;
    }
  }

  /// Get BMI category from BMI value
  BMICategory _getBMICategory(double bmi) {
    if (bmi < 18.5) return BMICategory.underweight;
    if (bmi < 25) return BMICategory.healthy;
    if (bmi < 30) return BMICategory.overweight;
    return BMICategory.obese;
  }


  List<AdminInfoRow> _buildMealTimingInfo() {
    final timing = user.preferences.mealTimingPreferences;
    if (timing == null) return [];

    final List<AdminInfoRow> rows = [];

    // Meal frequency
    final frequency = timing['mealFrequency'] as String?;
    if (frequency != null) {
      rows.add(AdminInfoRow(
        label: 'Meal Frequency',
        value: _getMealFrequencyLabel(frequency),
      ));
    }

    // Fasting type
    final fastingType = timing['fastingType'] as String?;
    if (fastingType != null && fastingType != 'none') {
      rows.add(AdminInfoRow(
        label: 'Fasting Type',
        value: _getFastingTypeLabel(fastingType),
      ));
    }

    // Meal times
    if (timing['breakfastTime'] != null) {
      rows.add(AdminInfoRow(
        label: 'Breakfast Time',
        value: timing['breakfastTime'] as String,
      ));
    }

    if (timing['lunchTime'] != null) {
      rows.add(AdminInfoRow(
        label: 'Lunch Time',
        value: timing['lunchTime'] as String,
      ));
    }

    if (timing['dinnerTime'] != null) {
      rows.add(AdminInfoRow(
        label: 'Dinner Time',
        value: timing['dinnerTime'] as String,
      ));
    }

    // Snack times
    final snackTimes = timing['snackTimes'] as List<dynamic>?;
    if (snackTimes != null && snackTimes.isNotEmpty) {
      rows.add(AdminInfoRow(
        label: 'Snack Times',
        value: snackTimes.join(', '),
      ));
    }

    // Custom notes
    final customNotes = timing['customNotes'] as String?;
    if (customNotes != null && customNotes.isNotEmpty) {
      rows.add(AdminInfoRow(
        label: 'Notes',
        value: customNotes,
      ));
    }

    return rows;
  }

  List<AdminInfoRow> _buildBatchCookingInfo() {
    final cooking = user.preferences.batchCookingPreferences;
    if (cooking == null) return [];

    final List<AdminInfoRow> rows = [];

    // Cooking frequency
    final frequency = cooking['frequency'] as String?;
    if (frequency != null) {
      rows.add(AdminInfoRow(
        label: 'Cooking Frequency',
        value: _getBatchCookingFrequencyLabel(frequency),
      ));
    }

    // Batch size
    final batchSize = cooking['batchSize'] as String?;
    if (batchSize != null) {
      rows.add(AdminInfoRow(
        label: 'Batch Size',
        value: _getBatchSizeLabel(batchSize),
      ));
    }

    // Leftovers preference
    final preferLeftovers = cooking['preferLeftovers'] as bool?;
    if (preferLeftovers != null) {
      rows.add(AdminInfoRow(
        label: 'Prefers Leftovers',
        value: preferLeftovers ? 'Yes' : 'No',
      ));
    }

    // Custom notes
    final customNotes = cooking['customNotes'] as String?;
    if (customNotes != null && customNotes.isNotEmpty) {
      rows.add(AdminInfoRow(
        label: 'Notes',
        value: customNotes,
      ));
    }

    return rows;
  }

  String _getMealFrequencyLabel(String frequency) {
    switch (frequency) {
      case 'threeMeals':
        return '3 meals per day';
      case 'threeMealsOneSnack':
        return '3 meals + 1 snack';
      case 'fourMeals':
        return '4 meals per day';
      case 'fourMealsOneSnack':
        return '4 meals + 1 snack';
      case 'fiveMeals':
        return '5 meals per day';
      case 'fiveMealsOneSnack':
        return '5 meals + 1 snack';
      case 'intermittentFasting':
        return 'Intermittent Fasting';
      case 'custom':
        return 'Custom Schedule';
      default:
        return frequency;
    }
  }

  String _getFastingTypeLabel(String fastingType) {
    switch (fastingType) {
      case 'sixteenEight':
        return '16:8 Fasting';
      case 'eighteenSix':
        return '18:6 Fasting';
      case 'twentyFour':
        return '20:4 Fasting';
      case 'alternateDay':
        return 'Alternate Day Fasting';
      case 'fiveTwo':
        return '5:2 Fasting';
      case 'custom':
        return 'Custom Fasting';
      default:
        return fastingType;
    }
  }

  String _getBatchCookingFrequencyLabel(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Daily';
      case 'twiceAWeek':
        return 'Twice a week';
      case 'weekly':
        return 'Weekly';
      case 'biweekly':
        return 'Every 2 weeks';
      case 'monthly':
        return 'Monthly';
      case 'never':
        return 'Never';
      default:
        return frequency;
    }
  }

  String _getBatchSizeLabel(String batchSize) {
    switch (batchSize) {
      case 'singleMeal':
        return 'Single meal';
      case 'twoMeals':
        return '2 meals';
      case 'threeMeals':
        return '3 meals';
      case 'fourMeals':
        return '4 meals';
      case 'fiveMeals':
        return '5 meals';
      case 'weeklyPrep':
        return 'Weekly preparation';
      case 'custom':
        return 'Custom';
      default:
        return batchSize;
    }
  }

  String _getSeverityLabel(String severity) {
    switch (severity) {
      case 'mild':
        return 'Mild';
      case 'moderate':
        return 'Moderate';
      case 'severe':
        return 'Severe';
      case 'anaphylaxis':
        return 'Anaphylaxis';
      default:
        return severity;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'mild':
        return AppConstants.successColor;
      case 'moderate':
        return AppConstants.warningColor;
      case 'severe':
        return AppConstants.errorColor;
      case 'anaphylaxis':
        return Colors.red.shade800;
      default:
        return AppConstants.textSecondary;
    }
  }

  Widget _buildProteinTargetsInfo() {
    final proteinTargets = user.preferences.proteinTargets;
    if (proteinTargets == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Daily protein target
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppConstants.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppConstants.successColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.fitness_center,
                color: AppConstants.successColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Protein Target',
                      style: AppTextStyles.caption.copyWith(
                        color: AppConstants.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${proteinTargets['dailyTarget']}g',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppConstants.successColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Protein per kg/lb
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Text(
                      '${proteinTargets['proteinPerKg']?.toStringAsFixed(1) ?? 'N/A'}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'g/kg',
                      style: AppTextStyles.caption.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Text(
                      '${proteinTargets['proteinPerLb']?.toStringAsFixed(1) ?? 'N/A'}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'g/lb',
                      style: AppTextStyles.caption.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Protein distribution
        if (proteinTargets['mealDistribution'] != null) ...[
          const SizedBox(height: 12),
          Text(
            'Protein Distribution',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          _buildProteinDistribution(
              proteinTargets['mealDistribution'] as List<dynamic>),
        ],

        // Additional info
        if (proteinTargets['weightBase'] != null ||
            proteinTargets['fitnessGoal'] != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (proteinTargets['fitnessGoal'] != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppConstants.accentColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    proteinTargets['fitnessGoal'] as String,
                    style: AppTextStyles.caption.copyWith(
                      color: AppConstants.accentColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
              if (proteinTargets['weightBase'] != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppConstants.secondaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'Based on ${proteinTargets['weightBase']}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppConstants.secondaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ],

        // Recommendations
        if (proteinTargets['recommendations'] != null &&
            (proteinTargets['recommendations'] as List).isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Recommendations',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          ...(proteinTargets['recommendations'] as List).map(
            (recommendation) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 8, right: 8),
                    decoration: BoxDecoration(
                      color: AppConstants.successColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      recommendation as String,
                      style: AppTextStyles.caption.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCalorieTargetsInfo() {
    final calorieTargets = user.preferences.calorieTargets;
    if (calorieTargets == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Daily calorie target
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppConstants.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppConstants.accentColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                color: AppConstants.accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Calorie Target',
                      style: AppTextStyles.caption.copyWith(
                        color: AppConstants.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${calorieTargets['dailyTarget']} kcal',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppConstants.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // RMR and TDEE
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.warningColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Text(
                      'RMR',
                      style: AppTextStyles.caption.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                    Text(
                      '${calorieTargets['rmr']} kcal',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppConstants.warningColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.warningColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Text(
                      'TDEE',
                      style: AppTextStyles.caption.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                    Text(
                      '${calorieTargets['tdee']} kcal',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppConstants.warningColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Macronutrient breakdown
        if (calorieTargets['macros'] != null) ...[
          Text(
            'Macronutrient Breakdown',
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          _buildMacroBreakdown(
              calorieTargets['macros'] as Map<String, dynamic>),
        ],

        // Additional info
        if (calorieTargets['fitnessGoal'] != null ||
            calorieTargets['activityLevel'] != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (calorieTargets['fitnessGoal'] != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppConstants.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    calorieTargets['fitnessGoal'] as String,
                    style: AppTextStyles.caption.copyWith(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
              if (calorieTargets['activityLevel'] != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppConstants.secondaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    calorieTargets['activityLevel'] as String,
                    style: AppTextStyles.caption.copyWith(
                      color: AppConstants.secondaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMacroBreakdown(Map<String, dynamic> macros) {
    return Column(
      children: [
        // Protein
        _buildMacroRow(
          'Protein',
          macros['protein'] as Map<String, dynamic>?,
          AppConstants.successColor,
          Icons.fitness_center,
        ),
        const SizedBox(height: 4),
        // Carbs
        _buildMacroRow(
          'Carbs',
          macros['carbs'] as Map<String, dynamic>?,
          AppConstants.warningColor,
          Icons.grain,
        ),
        const SizedBox(height: 4),
        // Fat
        _buildMacroRow(
          'Fat',
          macros['fat'] as Map<String, dynamic>?,
          AppConstants.errorColor,
          Icons.opacity,
        ),
      ],
    );
  }

  Widget _buildMacroRow(
      String name, Map<String, dynamic>? macro, Color color, IconData icon) {
    if (macro == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.caption.copyWith(
                color: AppConstants.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${macro['grams']}g',
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${macro['percentage']}%',
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getTrainingProgramStatusLabel(TrainingProgramStatus status) {
    switch (status) {
      case TrainingProgramStatus.none:
        return 'No Program';
      case TrainingProgramStatus.winter:
        return 'Winter Program';
      case TrainingProgramStatus.summer:
        return 'Summer Program';
      case TrainingProgramStatus.bodybuilding:
        return 'Bodybuilding Program';
      default:
        return 'Unknown';
    }
  }

  String _formatWorkoutDays(List<int> days) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((day) => dayNames[day - 1]).join(', ');
  }

  Widget _buildCalculatedCalorieTargetsInfo() {
    final calculatedTargets = user.preferences.calculatedCalorieTargets;
    if (calculatedTargets == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Daily calorie target
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppConstants.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calculated Daily Target',
                      style: AppTextStyles.caption.copyWith(
                        color: AppConstants.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${calculatedTargets.dailyTarget} kcal',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // RMR and TDEE
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.warningColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Text(
                      'RMR',
                      style: AppTextStyles.caption.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                    Text(
                      '${calculatedTargets.rmr} kcal',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppConstants.warningColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.warningColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Text(
                      'TDEE',
                      style: AppTextStyles.caption.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                    Text(
                      '${calculatedTargets.tdee} kcal',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppConstants.warningColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Additional info
        if (calculatedTargets.fitnessGoal.isNotEmpty ||
            calculatedTargets.activityLevel.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (calculatedTargets.fitnessGoal.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppConstants.accentColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    calculatedTargets.fitnessGoal,
                    style: AppTextStyles.caption.copyWith(
                      color: AppConstants.accentColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
              if (calculatedTargets.activityLevel.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppConstants.secondaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    calculatedTargets.activityLevel,
                    style: AppTextStyles.caption.copyWith(
                      color: AppConstants.secondaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ],

        // Recommendations
        if (calculatedTargets.recommendations.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Recommendations',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          ...calculatedTargets.recommendations.map(
            (recommendation) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 8, right: 8),
                    decoration: BoxDecoration(
                      color: AppConstants.accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: AppTextStyles.caption.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProteinDistribution(List<dynamic> mealDistribution) {
    return Column(
      children: mealDistribution.map((meal) {
        final mealData = meal as Map<String, dynamic>;
        final mealName = mealData['mealName'] as String? ?? 'Unknown';
        final proteinTarget = mealData['proteinTarget'] as int? ?? 0;
        final mealNumber = mealData['mealNumber'] as int? ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppConstants.successColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppConstants.successColor.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppConstants.successColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '$mealNumber',
                    style: AppTextStyles.caption.copyWith(
                      color: AppConstants.successColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mealName,
                  style: AppTextStyles.caption.copyWith(
                    color: AppConstants.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${proteinTarget}g',
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
