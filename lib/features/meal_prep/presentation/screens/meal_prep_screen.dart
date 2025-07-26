import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/models/meal_model.dart';
import '../../../../shared/services/ai_meal_service.dart';
import '../../../../shared/services/meal_plan_storage_service.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/providers/meal_plan_provider.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'meal_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MealPrepScreen extends StatefulWidget {
  const MealPrepScreen({super.key});

  @override
  State<MealPrepScreen> createState() => _MealPrepScreenState();
}

class _MealPrepScreenState extends State<MealPrepScreen> {
  bool _isLoading = false;
  MealPlanModel? _currentMealPlan;
  int _selectedDays = 7;
  int _targetCalories = 2000;

  // Progress tracking
  int _completedDays = 0;
  int _totalDays = 0;

  UserPreferences? _userPreferences;

  // Add a field to hold DietPlanPreferences
  DietPlanPreferences? _dietPlanPreferences;

  // Diet Plan Setup Flow State
  bool _showDietSetup = false;
  int _setupStep = 0;
  NutritionGoal? _selectedNutritionGoal;
  final List<String> _preferredCuisines = [];
  final List<String> _foodsToAvoid = [];
  final List<String> _favoriteFoods = [];
  MealFrequencyOption? _mealFrequency;
  bool _weeklyRotation = true;
  bool _remindersEnabled = false;

  // Controllers for text input
  final TextEditingController _cuisineController = TextEditingController();
  final TextEditingController _avoidController = TextEditingController();
  final TextEditingController _favoriteController = TextEditingController();

  // For AI preview step
  // bool _isPreviewLoading = false;
  // Map<String, List<String>>? _sampleDayPlan; // Make nullable, no default

  @override
  void dispose() {
    _cuisineController.dispose();
    _avoidController.dispose();
    _favoriteController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  /// Load saved meal plan and diet preferences from storage
  Future<void> _loadSavedData() async {
    try {
      // Fetch the current user from Firestore to get the latest mealPlanId
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      String? mealPlanId = user?.mealPlanId;
      MealPlanModel? firestoreMealPlan;
      if (mealPlanId != null) {
        // Try to fetch the meal plan from Firestore
        final doc = await FirebaseFirestore.instance
            .collection('meal_plans')
            .doc(mealPlanId)
            .get();
        if (doc.exists) {
          firestoreMealPlan = MealPlanModel.fromJson(doc.data()!);
        }
      }
      if (firestoreMealPlan != null) {
        setState(() {
          _currentMealPlan = firestoreMealPlan;
          _showDietSetup = false;
        });
        // Optionally cache to local storage
        await MealPlanStorageService.saveMealPlan(firestoreMealPlan);
        final mealPlanProvider =
        Provider.of<MealPlanProvider>(context, listen: false);
        mealPlanProvider.setMealPlan(firestoreMealPlan);
        print(
            'Loaded meal plan from Firestore:  [32m${firestoreMealPlan
                .title} [0m');
        return;
      }
      // Fallback: Load saved meal plan from local storage
      final savedMealPlan = await MealPlanStorageService.loadMealPlan();
      if (savedMealPlan != null) {
        setState(() {
          _currentMealPlan = savedMealPlan;
          _showDietSetup = false;
        });
        final mealPlanProvider =
        Provider.of<MealPlanProvider>(context, listen: false);
        mealPlanProvider.setMealPlan(savedMealPlan);
        print(
            'Loaded saved meal plan from local storage: ${savedMealPlan
                .title}');
      }
      // Load saved diet preferences
      final savedDietPreferences =
      await MealPlanStorageService.loadDietPreferences();
      if (savedDietPreferences != null) {
        setState(() {
          _dietPlanPreferences = savedDietPreferences;
        });
        print('Loaded saved diet preferences');
      }
      // Show setup if no meal plan exists
      if (_currentMealPlan == null) {
        setState(() {
          _showDietSetup = true;
        });
      }
    } catch (e) {
      print('Error loading saved data: $e');
      setState(() {
        _showDietSetup = true;
      });
    }
  }

  void _completeDietSetup() async {
    final userPrefs = _userPreferences ??
        Provider
            .of<UserProvider>(context, listen: false)
            .user
            ?.preferences;
    if (userPrefs == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('User preferences not found.'),
            backgroundColor: AppConstants.errorColor),
      );
      return;
    }
    _dietPlanPreferences = DietPlanPreferences(
      age: userPrefs.age,
      gender: userPrefs.gender,
      weight: userPrefs.weight,
      height: userPrefs.height,
      fitnessGoal: userPrefs.fitnessGoal,
      activityLevel: userPrefs.activityLevel,
      dietaryRestrictions: userPrefs.dietaryRestrictions,
      preferredWorkoutStyles: userPrefs.preferredWorkoutStyles,
      nutritionGoal: _selectedNutritionGoal?.label ?? '',
      preferredCuisines: List<String>.from(_preferredCuisines),
      foodsToAvoid: List<String>.from(_foodsToAvoid),
      favoriteFoods: List<String>.from(_favoriteFoods),
      mealFrequency: _mealFrequency
          ?.toString()
          .split('.')
          .last ?? '',
      weeklyRotation: _weeklyRotation,
      remindersEnabled: _remindersEnabled,
      targetCalories: userPrefs.targetCalories,
    );
    // Generate the actual meal plan using AI
    setState(() {
      _isLoading = true;
      _completedDays = 0;
      _totalDays = _selectedDays;
    });

    try {
      print(
          'Generating meal plan with preferences: ${_dietPlanPreferences!
              .targetCalories} calories');
      final mealPlan = await AIMealService.generateMealPlan(
        preferences: _dietPlanPreferences!,
        days: _selectedDays, // Use the user's selected duration
        onProgress: (completedDays, totalDays) {
          setState(() {
            _completedDays = completedDays;
            _totalDays = totalDays;
          });
        },
      );

      print('Meal plan generated successfully: ${mealPlan.title}');
      // Save meal plan and diet preferences to storage
      await MealPlanStorageService.saveMealPlan(mealPlan);
      await MealPlanStorageService.saveDietPreferences(_dietPlanPreferences!);

      setState(() {
        _showDietSetup = false;
        _currentMealPlan = mealPlan;
        _isLoading = false;
        _completedDays = 0;
        _totalDays = 0;
      });
    } catch (e) {
      print('Error generating meal plan: $e');
      setState(() {
        _isLoading = false;
        _completedDays = 0;
        _totalDays = 0;
      });
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate meal plan: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  String _getLoadingMessage() {
    if (_totalDays == 0) {
      return 'We are cooking up your personalized meal plan…';
    }

    final progress = _completedDays / _totalDays;

    if (progress < 0.25) {
      return 'Analyzing your preferences and dietary needs…';
    } else if (progress < 0.5) {
      return 'Crafting delicious, healthy recipes…';
    } else if (progress < 0.75) {
      return 'Optimizing nutrition and meal timing…';
    } else if (progress < 1.0) {
      return 'Finalizing your personalized meal plan…';
    } else {
      return 'Your meal plan is ready!';
    }
  }

  MealType _getMealTypeForName(String name) {
    switch (name.toLowerCase()) {
      case 'breakfast':
        return MealType.breakfast;
      case 'lunch':
        return MealType.lunch;
      case 'dinner':
        return MealType.dinner;
      case 'snack':
      case 'snack 2':
        return MealType.snack;
      default:
        return MealType.snack;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Do not block meal prep onboarding on userPrefs
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final safeUserPrefs = _userPreferences ?? userProvider.user?.preferences;

    // If loading, show loading state (for legacy, but should not trigger now)
    if (_isLoading) {
      return _buildLoadingState();
    }
    // If a meal plan exists, show it as before
    if (_currentMealPlan != null) {
      return _buildMealPlanView();
    }
    // If no meal plan exists, show static message (admin will generate it)
    return _buildWaitingForMealPlanState();
  }

  Widget _buildLoadingState() {
    return Container(
      color: AppConstants.surfaceColor,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: Lottie.asset(
              'assets/animations/loading.json',
              // Make sure this file exists or use another fun animation
              repeat: true,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
            child: Text(
              _getLoadingMessage(),
              style: AppTextStyles.heading4,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
            child: Text(
              'Hang tight while we craft delicious, healthy recipes just for you!',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppConstants.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          // Progress bar and status
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
            child: Column(
              children: [
                // Progress bar
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  tween: Tween<double>(
                    begin: 0.0,
                    end: _totalDays > 0 ? _completedDays / _totalDays : 0.0,
                  ),
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      backgroundColor:
                      AppConstants.textTertiary.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppConstants.primaryColor),
                      minHeight: 8,
                    );
                  },
                ),
                const SizedBox(height: AppConstants.spacingS),
                // Progress text
                Text(
                  _totalDays > 0
                      ? 'Generated $_completedDays of $_totalDays days (${((_completedDays /
                      _totalDays) * 100).toInt()}%)'
                      : 'Preparing your meal plan...',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppConstants.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                // Loading indicator
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // New: Static message for users waiting for admin to generate meal plan
  Widget _buildWaitingForMealPlanState() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plan'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_empty,
                  size: 64, color: AppConstants.primaryColor),
              const SizedBox(height: AppConstants.spacingL),
              Text(
                'Your meal plan will be ready shortly!',
                style: AppTextStyles.heading4,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingM),
              Text(
                'Your personal trainer will prepare your AI-powered meal plan. You will receive a message when it is ready.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppConstants.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        gradient: AppConstants.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: AppConstants.shadowS,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.psychology,
            size: 40,
            color: AppConstants.surfaceColor,
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'AI-Powered Meal Planning',
            style: AppTextStyles.heading4.copyWith(
              color: AppConstants.surfaceColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingXS),
          Text(
            'Get personalized meal plans tailored to your fitness goals, dietary restrictions, and preferences',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppConstants.surfaceColor.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(UserPreferences? userPrefs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meal Plan Settings',
              style: AppTextStyles.heading4,
            ),
            const SizedBox(height: AppConstants.spacingM),
            _buildSettingRow(
              'Plan Duration',
              '$_selectedDays days',
              Icons.calendar_today,
                  () => _showDaysSelector(),
            ),
            const SizedBox(height: AppConstants.spacingS),
            _buildSettingRow(
              'Target Calories',
              '$_targetCalories cal/day',
              Icons.local_fire_department,
                  () => _showCaloriesSelector(),
            ),
            const SizedBox(height: AppConstants.spacingS),
            _buildSettingRow(
              'Fitness Goal',
              _getFitnessGoalText(
                  userPrefs?.fitnessGoal ?? FitnessGoal.maintenance),
              Icons.track_changes,
              null,
            ),
            const SizedBox(height: AppConstants.spacingS),
            _buildSettingRow(
              'Dietary Restrictions',
              userPrefs?.dietaryRestrictions.join(', ') ?? 'None',
              Icons.restaurant,
              null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(String title,
      String value,
      IconData icon,
      VoidCallback? onTap,) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusS),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.spacingS,
          horizontal: AppConstants.spacingS,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Icon(
                icon,
                color: AppConstants.primaryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.caption.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right,
                color: AppConstants.textTertiary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: GradientButton(
        text: 'Generate AI Meal Plan',
        icon: Icons.psychology,
        onPressed: _generateNewMealPlan,
      ),
    );
  }

  Widget _buildMealPlanView() {
    if (_currentMealPlan == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // _buildMealPlanHeader(),
          // const SizedBox(height: AppConstants.spacingM),
          _buildNutritionSummary(),
          const SizedBox(height: AppConstants.spacingM),
          _buildMealDaysList(),
        ],
      ),
    );
  }

  Widget _buildMealPlanHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        gradient: AppConstants.accentGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: AppConstants.shadowS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology,
                color: AppConstants.surfaceColor,
                size: 24,
              ),
              const SizedBox(width: AppConstants.spacingS),
              Text(
                'AI Generated',
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.surfaceColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            _currentMealPlan!.title,
            style: AppTextStyles.heading4.copyWith(
              color: AppConstants.surfaceColor,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXS),
          Text(
            _currentMealPlan!.description,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppConstants.surfaceColor.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutrition Summary',
              style: AppTextStyles.heading4,
            ),
            const SizedBox(height: AppConstants.spacingS),
            Row(
              children: [
                Expanded(
                  child: _buildNutritionCard(
                    'Calories',
                    '${_currentMealPlan!.totalCalories}',
                    Icons.local_fire_department,
                    AppConstants.warningColor,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingS),
                Expanded(
                  child: _buildNutritionCard(
                    'Protein',
                    '${_currentMealPlan!.totalProtein.toStringAsFixed(0)}g',
                    Icons.fitness_center,
                    AppConstants.accentColor,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingS),
                Expanded(
                  child: _buildNutritionCard(
                    'Carbs',
                    '${_currentMealPlan!.totalCarbs.toStringAsFixed(0)}g',
                    Icons.grain,
                    AppConstants.secondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCard(String label,
      String value,
      IconData icon,
      Color color,) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingS),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppConstants.spacingXS),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealDaysList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Meal Plan',
          style: AppTextStyles.heading4,
        ),
        const SizedBox(height: AppConstants.spacingS),
        ..._currentMealPlan!.mealDays.map((mealDay) {
          return _buildMealDayCard(mealDay);
        }).toList(),
      ],
    );
  }

  Widget _buildMealDayCard(MealDay mealDay) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: ExpansionTile(
        title: Text(
          'Day ${_currentMealPlan!.mealDays.indexOf(mealDay) + 1}',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${mealDay.totalCalories} calories',
          style: AppTextStyles.caption.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
        children: mealDay.meals.map((meal) {
          return _buildMealCard(meal);
        }).toList(),
      ),
    );
  }

  Widget _buildMealCard(Meal meal) {
    final dayIndex = _currentMealPlan!.mealDays
        .indexWhere((day) => day.meals.contains(meal));
    final dayTitle = dayIndex >= 0 ? 'Day ${dayIndex + 1}' : 'Unknown Day';

    return InkWell(
      onTap: () => _navigateToMealDetail(meal, dayTitle),
      borderRadius: BorderRadius.circular(AppConstants.radiusS),
      child: Container(
        margin: const EdgeInsets.all(AppConstants.spacingS),
        padding: const EdgeInsets.all(AppConstants.spacingS),
        decoration: BoxDecoration(
          color: AppConstants.backgroundColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
          border: Border.all(
            color: AppConstants.textTertiary.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _getMealTypeColor(meal.type).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                  child: Icon(
                    _getMealTypeIcon(meal.type),
                    color: _getMealTypeColor(meal.type),
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        meal.description,
                        style: AppTextStyles.caption.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${meal.nutrition.calories} cal',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppConstants.accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingS),
            Row(
              children: [
                _buildNutritionChip(
                    'P', '${meal.nutrition.protein.toStringAsFixed(0)}g'),
                const SizedBox(width: AppConstants.spacingS),
                _buildNutritionChip(
                    'C', '${meal.nutrition.carbs.toStringAsFixed(0)}g'),
                const SizedBox(width: AppConstants.spacingS),
                _buildNutritionChip(
                    'F', '${meal.nutrition.fat.toStringAsFixed(0)}g'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppConstants.primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility,
                        size: 12,
                        color: AppConstants.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'View Recipe',
                        style: AppTextStyles.caption.copyWith(
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingXS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusXS),
      ),
      child: Text(
        '$label: $value',
        style: AppTextStyles.caption.copyWith(
          color: AppConstants.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  // Helper methods
  void _generateNewMealPlan() async {
    if (_dietPlanPreferences == null) {
      // If no diet plan preferences are set, show the setup flow
      setState(() {
        _showDietSetup = true;
        _setupStep = 0;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Generate meal plan using the diet plan preferences
      final mealPlan = await AIMealService.generateMealPlan(
        preferences: _dietPlanPreferences!,
        days: _selectedDays,
      );

      // Save the new meal plan to storage
      await MealPlanStorageService.saveMealPlan(mealPlan);

      setState(() {
        _currentMealPlan = mealPlan;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate meal plan: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  void _showDaysSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildDaysSelector(),
    );
  }

  void _showCaloriesSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildCaloriesSelector(),
    );
  }

  Widget _buildDaysSelector() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Plan Duration',
            style: AppTextStyles.heading4,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Wrap(
            spacing: AppConstants.spacingS,
            children: [3, 5, 7, 10, 14].map((days) {
              return ChoiceChip(
                label: Text('$days days'),
                selected: _selectedDays == days,
                onSelected: (selected) {
                  setState(() {
                    _selectedDays = days;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesSelector() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Target Calories',
            style: AppTextStyles.heading4,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Slider(
            value: _targetCalories.toDouble(),
            min: 1200,
            max: 3000,
            divisions: 18,
            label: '$_targetCalories cal',
            onChanged: (value) {
              setState(() {
                _targetCalories = value.round();
                // Update user preferences with new target calories
                _userPreferences = _userPreferences?.copyWith(
                  targetCalories: _targetCalories,
                );
              });
            },
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            '$_targetCalories calories per day',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: CustomButton(
              text: 'Confirm',
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  String _getFitnessGoalText(FitnessGoal goal) {
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

  Color _getMealTypeColor(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return AppConstants.warningColor;
      case MealType.lunch:
        return AppConstants.accentColor;
      case MealType.dinner:
        return AppConstants.primaryColor;
      case MealType.snack:
        return AppConstants.secondaryColor;
    }
  }

  IconData _getMealTypeIcon(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return Icons.wb_sunny;
      case MealType.lunch:
        return Icons.restaurant;
      case MealType.dinner:
        return Icons.dinner_dining;
      case MealType.snack:
        return Icons.coffee;
    }
  }

  void _navigateToMealDetail(Meal meal, String dayTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MealDetailScreen(
              meal: meal,
              dayTitle: dayTitle,
            ),
      ),
    );
  }

  // Diet Plan Setup Flow Methods
  void _nextSetupStep() {
    setState(() {
      _setupStep++;
    });
  }

  void _prevSetupStep() {
    setState(() {
      _setupStep--;
    });
  }
}

// --- Diet Plan Setup Flow ---

enum NutritionGoal { loseFat, buildMuscle, improveEnergy, maintainWeight }

extension NutritionGoalExt on NutritionGoal {
  String get label {
    switch (this) {
      case NutritionGoal.loseFat:
        return 'Lose fat';
      case NutritionGoal.buildMuscle:
        return 'Build muscle';
      case NutritionGoal.improveEnergy:
        return 'Improve energy';
      case NutritionGoal.maintainWeight:
        return 'Maintain weight';
    }
  }

  IconData get icon {
    switch (this) {
      case NutritionGoal.loseFat:
        return Icons.trending_down;
      case NutritionGoal.buildMuscle:
        return Icons.fitness_center;
      case NutritionGoal.improveEnergy:
        return Icons.bolt;
      case NutritionGoal.maintainWeight:
        return Icons.track_changes;
    }
  }
}

enum MealFrequencyOption {
  threeMeals,
  threeMealsOneSnack,
  fourMeals,
  fourMealsOneSnack,
  fiveMeals,
  fiveMealsOneSnack
}

// 1. Add a new CaloriesStep widget
class _CaloriesStep extends StatelessWidget {
  final int targetCalories;
  final ValueChanged<int> onChanged;
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const _CaloriesStep({
    required this.targetCalories,
    required this.onChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Set Your Daily Calorie Target', style: AppTextStyles.heading4),
        const SizedBox(height: AppConstants.spacingL),
        Slider(
          value: targetCalories.toDouble(),
          min: 1200,
          max: 4000,
          divisions: 28,
          label: '$targetCalories cal',
          onChanged: (value) => onChanged(value.round()),
        ),
        const SizedBox(height: AppConstants.spacingS),
        Text('$targetCalories calories per day',
            style:
            AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: AppConstants.spacingL),
      ],
    );
  }
}

// 1. Refactor DietPlanSetupFlow to use Scaffold and bottomNavigationBar
class DietPlanSetupFlow extends StatelessWidget {
  final int step;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final NutritionGoal? selectedNutritionGoal;
  final ValueChanged<NutritionGoal> onSelectNutritionGoal;
  final List<String> preferredCuisines;
  final ValueChanged<String> onAddCuisine;
  final ValueChanged<String> onRemoveCuisine;
  final List<String> foodsToAvoid;
  final ValueChanged<String> onAddAvoid;
  final ValueChanged<String> onRemoveAvoid;
  final List<String> favoriteFoods;
  final ValueChanged<String> onAddFavorite;
  final ValueChanged<String> onRemoveFavorite;
  final MealFrequencyOption? mealFrequency;
  final ValueChanged<MealFrequencyOption> onSelectMealFrequency;
  final TextEditingController cuisineController;
  final TextEditingController avoidController;
  final TextEditingController favoriteController;
  final bool isPreviewLoading;
  final Map<String, List<String>> sampleDayPlan;
  final VoidCallback? onRegeneratePreview;
  final VoidCallback? onLooksGood;
  final VoidCallback? onCustomize;
  final bool weeklyRotation;
  final ValueChanged<bool> onToggleWeeklyRotation;
  final bool remindersEnabled;
  final ValueChanged<bool> onToggleReminders;
  final VoidCallback? onSavePlan;
  final UserPreferences? userPreferences;
  final int selectedDays;
  final int targetCalories;
  final ValueChanged<int> onTargetCaloriesChanged;

  const DietPlanSetupFlow({
    required this.step,
    required this.onNext,
    required this.onBack,
    required this.selectedNutritionGoal,
    required this.onSelectNutritionGoal,
    required this.preferredCuisines,
    required this.onAddCuisine,
    required this.onRemoveCuisine,
    required this.foodsToAvoid,
    required this.onAddAvoid,
    required this.onRemoveAvoid,
    required this.favoriteFoods,
    required this.onAddFavorite,
    required this.onRemoveFavorite,
    required this.mealFrequency,
    required this.onSelectMealFrequency,
    required this.cuisineController,
    required this.avoidController,
    required this.favoriteController,
    required this.isPreviewLoading,
    required this.sampleDayPlan,
    required this.onRegeneratePreview,
    required this.onLooksGood,
    required this.onCustomize,
    required this.weeklyRotation,
    required this.onToggleWeeklyRotation,
    required this.remindersEnabled,
    required this.onToggleReminders,
    required this.onSavePlan,
    required this.userPreferences,
    required this.selectedDays,
    required this.targetCalories,
    required this.onTargetCaloriesChanged,
  });

  static const int totalSteps = 7; // Increased by 1

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppConstants.spacingL),
            _ProgressDots(current: step, total: totalSteps),
            const SizedBox(height: AppConstants.spacingL),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spacingL),
                child: _buildStepContent(context, withButtons: false),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: _buildNavBar(context),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, {bool withButtons = false}) {
    if (userPreferences == null) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (step) {
      case 0:
        return _GoalSelectionStep(
          selected: selectedNutritionGoal,
          onSelect: onSelectNutritionGoal,
        );
      case 1:
        return _FoodPreferencesStep(
          preferredCuisines: preferredCuisines,
          onAddCuisine: onAddCuisine,
          onRemoveCuisine: onRemoveCuisine,
          foodsToAvoid: foodsToAvoid,
          onAddAvoid: onAddAvoid,
          onRemoveAvoid: onRemoveAvoid,
          favoriteFoods: favoriteFoods,
          onAddFavorite: onAddFavorite,
          onRemoveFavorite: onRemoveFavorite,
          cuisineController: cuisineController,
          avoidController: avoidController,
          favoriteController: favoriteController,
        );
      case 2:
        return _MealFrequencyStep(
          selected: mealFrequency,
          onSelect: onSelectMealFrequency,
        );
      case 3:
        return _CaloriesStep(
          targetCalories: targetCalories,
          onChanged: onTargetCaloriesChanged,
          onNext: null,
          onBack: null,
        );
      case 4:
        return _PersonalizationConfirmationStep();
      case 5:
        return _PlanDurationStep(
          weeklyRotation: weeklyRotation,
          onToggleWeeklyRotation: onToggleWeeklyRotation,
          remindersEnabled: remindersEnabled,
          onToggleReminders: onToggleReminders,
        );
      case 6:
        return _FinalReviewStep(
          userPreferences: userPreferences!,
          selectedDays: selectedDays,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavBar(BuildContext context) {
    switch (step) {
      case 0:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: CustomButton(
            text: 'Next',
            onPressed: selectedNutritionGoal != null ? onNext : null,
          ),
        );
      case 1:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: CustomButton(
            text: 'Next',
            onPressed: onNext,
          ),
        );
      case 2:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: CustomButton(
            text: 'Next',
            onPressed: mealFrequency != null ? onNext : null,
          ),
        );
      case 3:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onNext,
                child: const Text('Next'),
              ),
            ),
          ],
        );
      case 4:
        return Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Looks good',
                onPressed: onNext,
                icon: Icons.check_circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Customize',
                onPressed: onCustomize,
                icon: Icons.edit,
              ),
            ),
          ],
        );
      case 5:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: CustomButton(
            text: 'Next',
            onPressed: onNext,
            icon: Icons.arrow_forward,
          ),
        );
      case 6:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: CustomButton(
            text: 'Save Plan',
            onPressed: onSavePlan,
            icon: Icons.save,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ProgressDots extends StatelessWidget {
  final int current;
  final int total;

  const _ProgressDots({required this.current, required this.total});

  static const List<Color> _stepColors = [
    AppConstants.primaryColor,
    AppConstants.secondaryColor,
    AppConstants.accentColor,
    AppConstants.warningColor,
    AppConstants.successColor,
    AppConstants.primaryColor, // Repeat or adjust as needed for total steps
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final color = i <= current
            ? _stepColors[i % _stepColors.length]
            : AppConstants.textTertiary.withOpacity(0.2);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == current ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
}

// 1. Remove navigation buttons from step widgets
class _GoalSelectionStep extends StatelessWidget {
  final NutritionGoal? selected;
  final ValueChanged<NutritionGoal> onSelect;

  const _GoalSelectionStep({
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "What's your primary nutrition goal?",
          style: AppTextStyles.heading4,
        ),
        const SizedBox(height: AppConstants.spacingL),
        Wrap(
          spacing: AppConstants.spacingM,
          runSpacing: AppConstants.spacingM,
          children: NutritionGoal.values.map((goal) {
            final isSelected = selected == goal;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(goal.icon,
                      size: 18,
                      color: isSelected
                          ? AppConstants.surfaceColor
                          : AppConstants.primaryColor),
                  const SizedBox(width: 8),
                  Text(goal.label),
                ],
              ),
              selected: isSelected,
              selectedColor: AppConstants.primaryColor,
              backgroundColor: AppConstants.primaryColor.withOpacity(0.08),
              labelStyle: AppTextStyles.bodyMedium.copyWith(
                color: isSelected
                    ? AppConstants.surfaceColor
                    : AppConstants.primaryColor,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) => onSelect(goal),
            );
          }).toList(),
        ),
        const SizedBox(height: AppConstants.spacingL),
      ],
    );
  }
}

// _FoodPreferencesStep
class _FoodPreferencesStep extends StatelessWidget {
  final List<String> preferredCuisines;
  final ValueChanged<String> onAddCuisine;
  final ValueChanged<String> onRemoveCuisine;
  final List<String> foodsToAvoid;
  final ValueChanged<String> onAddAvoid;
  final ValueChanged<String> onRemoveAvoid;
  final List<String> favoriteFoods;
  final ValueChanged<String> onAddFavorite;
  final ValueChanged<String> onRemoveFavorite;
  final TextEditingController cuisineController;
  final TextEditingController avoidController;
  final TextEditingController favoriteController;
  final VoidCallback? onNext;

  const _FoodPreferencesStep({
    required this.preferredCuisines,
    required this.onAddCuisine,
    required this.onRemoveCuisine,
    required this.foodsToAvoid,
    required this.onAddAvoid,
    required this.onRemoveAvoid,
    required this.favoriteFoods,
    required this.onAddFavorite,
    required this.onRemoveFavorite,
    required this.cuisineController,
    required this.avoidController,
    required this.favoriteController,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tell us what you like and don’t like.',
              style: AppTextStyles.heading4),
          const SizedBox(height: AppConstants.spacingL),
          _buildInputSection(
            context,
            label: 'Preferred Cuisines',
            hint: 'e.g. Mediterranean, Asian',
            items: preferredCuisines,
            controller: cuisineController,
            onAdd: onAddCuisine,
            onRemove: onRemoveCuisine,
          ),
          const SizedBox(height: AppConstants.spacingM),
          _buildInputSection(
            context,
            label: 'Foods to Avoid',
            hint: 'e.g. pork, dairy, spicy',
            items: foodsToAvoid,
            controller: avoidController,
            onAdd: onAddAvoid,
            onRemove: onRemoveAvoid,
          ),
          const SizedBox(height: AppConstants.spacingM),
          _buildInputSection(
            context,
            label: 'Favorites',
            hint: 'e.g. oats, chicken, tofu',
            items: favoriteFoods,
            controller: favoriteController,
            onAdd: onAddFavorite,
            onRemove: onRemoveFavorite,
          ),
          const SizedBox(height: AppConstants.spacingL),
        ],
      ),
    );
  }

  Widget _buildInputSection(BuildContext context, {
    required String label,
    required String hint,
    required List<String> items,
    required TextEditingController controller,
    required ValueChanged<String> onAdd,
    required ValueChanged<String> onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
            AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppConstants.spacingS),
        Wrap(
          spacing: AppConstants.spacingS,
          runSpacing: AppConstants.spacingS,
          children: items
              .map((item) =>
              Chip(
                label: Text(item),
                onDeleted: () => onRemove(item),
                backgroundColor:
                AppConstants.primaryColor.withOpacity(0.08),
                labelStyle: AppTextStyles.bodyMedium,
              ))
              .toList(),
        ),
        const SizedBox(height: AppConstants.spacingS),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onSubmitted: (value) {
                  onAdd(value.trim());
                  controller.clear();
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                onAdd(controller.text.trim());
                controller.clear();
              },
              tooltip: 'Add',
            ),
          ],
        ),
      ],
    );
  }
}

class _MealFrequencyStep extends StatelessWidget {
  final MealFrequencyOption? selected;
  final ValueChanged<MealFrequencyOption> onSelect;
  final VoidCallback? onNext;

  const _MealFrequencyStep({
    required this.selected,
    required this.onSelect,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('How many meals would you like per day?',
            style: AppTextStyles.heading4),
        const SizedBox(height: AppConstants.spacingL),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildOptionCard(
                  context,
                  label: '3 meals',
                  value: MealFrequencyOption.threeMeals,
                  selected: selected == MealFrequencyOption.threeMeals,
                  onTap: () => onSelect(MealFrequencyOption.threeMeals),
                ),
                const SizedBox(height: AppConstants.spacingM),
                _buildOptionCard(
                  context,
                  label: '3 meals + 1 snack',
                  value: MealFrequencyOption.threeMealsOneSnack,
                  selected: selected == MealFrequencyOption.threeMealsOneSnack,
                  onTap: () => onSelect(MealFrequencyOption.threeMealsOneSnack),
                ),
                const SizedBox(height: AppConstants.spacingM),
                _buildOptionCard(
                  context,
                  label: '4 meals',
                  value: MealFrequencyOption.fourMeals,
                  selected: selected == MealFrequencyOption.fourMeals,
                  onTap: () => onSelect(MealFrequencyOption.fourMeals),
                ),
                const SizedBox(height: AppConstants.spacingM),
                _buildOptionCard(
                  context,
                  label: '4 meals + 1 snack',
                  value: MealFrequencyOption.fourMealsOneSnack,
                  selected: selected == MealFrequencyOption.fourMealsOneSnack,
                  onTap: () => onSelect(MealFrequencyOption.fourMealsOneSnack),
                ),
                const SizedBox(height: AppConstants.spacingM),
                _buildOptionCard(
                  context,
                  label: '5 meals',
                  value: MealFrequencyOption.fiveMeals,
                  selected: selected == MealFrequencyOption.fiveMeals,
                  onTap: () => onSelect(MealFrequencyOption.fiveMeals),
                ),
                const SizedBox(height: AppConstants.spacingM),
                _buildOptionCard(
                  context,
                  label: '5 meals + 1 snack',
                  value: MealFrequencyOption.fiveMealsOneSnack,
                  selected: selected == MealFrequencyOption.fiveMealsOneSnack,
                  onTap: () => onSelect(MealFrequencyOption.fiveMealsOneSnack),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard(BuildContext context, {
    required String label,
    required MealFrequencyOption value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: selected ? AppConstants.primaryColor : Colors.white,
        elevation: selected ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          side: BorderSide(
            color: selected
                ? AppConstants.primaryColor
                : AppConstants.textTertiary.withOpacity(0.15),
            width: selected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected
                    ? AppConstants.surfaceColor
                    : AppConstants.primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: selected
                        ? AppConstants.surfaceColor
                        : AppConstants.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonalizationConfirmationStep extends StatelessWidget {
  final VoidCallback? onLooksGood;
  final VoidCallback? onCustomize;

  const _PersonalizationConfirmationStep({
    this.onLooksGood,
    this.onCustomize,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Personalization Confirmation', style: AppTextStyles.heading4),
          const SizedBox(height: AppConstants.spacingL),
          Text('Would you like to proceed or further customize your plan?',
              style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppConstants.spacingL),
        ],
      ),
    );
  }
}

class _PlanDurationStep extends StatelessWidget {
  final bool weeklyRotation;
  final ValueChanged<bool> onToggleWeeklyRotation;
  final bool remindersEnabled;
  final ValueChanged<bool> onToggleReminders;
  final VoidCallback? onNext;

  const _PlanDurationStep({
    required this.weeklyRotation,
    required this.onToggleWeeklyRotation,
    required this.remindersEnabled,
    required this.onToggleReminders,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Plan Duration & Reminders', style: AppTextStyles.heading4),
          const SizedBox(height: AppConstants.spacingL),
          Row(
            children: [
              Expanded(
                child: Card(
                  color:
                  weeklyRotation ? AppConstants.primaryColor : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    side: BorderSide(
                      color: weeklyRotation
                          ? AppConstants.primaryColor
                          : AppConstants.textTertiary.withOpacity(0.15),
                      width: weeklyRotation ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    onTap: () => onToggleWeeklyRotation(true),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 16),
                      child: Column(
                        children: [
                          Icon(Icons.calendar_month,
                              color: weeklyRotation
                                  ? AppConstants.surfaceColor
                                  : AppConstants.primaryColor),
                          const SizedBox(height: 8),
                          Text(
                            'Weekly rotating plan',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: weeklyRotation
                                  ? AppConstants.surfaceColor
                                  : AppConstants.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  color: !weeklyRotation
                      ? AppConstants.primaryColor
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    side: BorderSide(
                      color: !weeklyRotation
                          ? AppConstants.primaryColor
                          : AppConstants.textTertiary.withOpacity(0.15),
                      width: !weeklyRotation ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    onTap: () => onToggleWeeklyRotation(false),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 16),
                      child: Column(
                        children: [
                          Icon(Icons.repeat_one,
                              color: !weeklyRotation
                                  ? AppConstants.surfaceColor
                                  : AppConstants.primaryColor),
                          const SizedBox(height: 8),
                          Text(
                            'Repeat daily plan',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: !weeklyRotation
                                  ? AppConstants.surfaceColor
                                  : AppConstants.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),
          Row(
            children: [
              Switch(
                value: remindersEnabled,
                onChanged: onToggleReminders,
                activeColor: AppConstants.primaryColor,
              ),
              const SizedBox(width: 8),
              Text('Enable reminders', style: AppTextStyles.bodyMedium),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),
        ],
      ),
    );
  }
}

class _FinalReviewStep extends StatelessWidget {
  final UserPreferences userPreferences;
  final int selectedDays;
  final VoidCallback? onSavePlan;

  const _FinalReviewStep({
    required this.userPreferences,
    required this.selectedDays,
    this.onSavePlan,
  });

  String _fitnessGoalName(FitnessGoal goal) {
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

  IconData _iconFor(String key) {
    switch (key) {
      case 'days':
        return Icons.calendar_today;
      case 'calories':
        return Icons.local_fire_department;
      case 'goal':
        return Icons.flag;
      case 'restrictions':
        return Icons.no_food;
      case 'workout':
        return Icons.fitness_center;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppConstants.surfaceColor.withOpacity(0.98),
      child: SingleChildScrollView(
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppConstants.spacingL),
              Text('Final Review',
                  style: AppTextStyles.heading3
                      .copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppConstants.spacingL),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _reviewRow(
                        icon: _iconFor('days'),
                        label: 'Plan Duration',
                        value: '$selectedDays days',
                      ),
                      const SizedBox(height: 16),
                      _reviewRow(
                        icon: _iconFor('goal'),
                        label: 'Fitness Goal',
                        value: _fitnessGoalName(userPreferences.fitnessGoal),
                      ),
                      const SizedBox(height: 16),
                      _reviewRow(
                        icon: _iconFor('restrictions'),
                        label: 'Dietary Restrictions',
                        value: (userPreferences.dietaryRestrictions.isEmpty ||
                            (userPreferences.dietaryRestrictions.length ==
                                1 &&
                                userPreferences.dietaryRestrictions.first ==
                                    'None'))
                            ? 'None'
                            : userPreferences.dietaryRestrictions.join(', '),
                      ),
                      const SizedBox(height: 16),
                      _reviewRow(
                        icon: _iconFor('workout'),
                        label: 'Preferred Workouts',
                        value:
                        userPreferences.preferredWorkoutStyles.join(', '),
                      ),
                      // Add more fields as needed
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reviewRow(
      {required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppConstants.primaryColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppConstants.textSecondary)),
              const SizedBox(height: 2),
              Text(value,
                  style: AppTextStyles.bodyLarge
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
