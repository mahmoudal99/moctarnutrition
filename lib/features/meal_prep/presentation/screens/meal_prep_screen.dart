import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/models/meal_model.dart';
import '../../../../shared/services/ai_meal_service.dart';

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

  // Mock user preferences (in real app, this would come from user profile)
  late UserPreferences _userPreferences;

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
  bool _isPreviewLoading = false;
  Map<String, List<String>> _sampleDayPlan = {
    'Breakfast': ['Scrambled eggs with spinach', '1 slice whole-grain toast'],
    'Snack': ['Greek yogurt with berries'],
    'Lunch': ['Grilled chicken salad'],
    'Snack 2': ['Apple slices with almond butter'],
    'Dinner': ['Baked salmon', 'Quinoa', 'Steamed broccoli'],
  };

  void _regeneratePreview() async {
    setState(() => _isPreviewLoading = true);
    // Simulate AI call delay
    await Future.delayed(const Duration(seconds: 1));
    // For now, just shuffle the plan for demo
    _sampleDayPlan = Map.fromEntries(_sampleDayPlan.entries.toList()..shuffle());
    setState(() => _isPreviewLoading = false);
  }

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
    _initializeUserPreferences();
    // Show setup if no meal plan exists
    _showDietSetup = _currentMealPlan == null;
  }

  void _initializeUserPreferences() {
    // Mock preferences - in real app, load from user profile
    _userPreferences = UserPreferences(
      fitnessGoal: FitnessGoal.maintenance,
      activityLevel: ActivityLevel.moderatelyActive,
      dietaryRestrictions: ['None'],
      preferredWorkoutStyles: ['Strength Training', 'Cardio'],
      targetCalories: _targetCalories,
    );
  }

  void _completeDietSetup() {
    // Here, you would generate and save the actual meal plan based on user selections
    // For now, just simulate saving and show the regular meal prep UI
    final List<MealDay> days = List.generate(7, (i) {
      final date = DateTime.now().add(Duration(days: i));
      final meals = _sampleDayPlan.entries.map((entry) {
        return Meal(
          id: '${entry.key}_${i + 1}',
          name: entry.key,
          description: entry.value.join(', '),
          type: _getMealTypeForName(entry.key),
          cuisineType: CuisineType.other,
          ingredients: entry.value.map((ingredient) => RecipeIngredient(
            name: ingredient,
            amount: 1,
            unit: '',
            notes: null,
          )).toList(),
          instructions: ['See description'],
          prepTime: 10,
          cookTime: 10,
          servings: 1,
          nutrition: NutritionInfo(
            calories: 400,
            protein: 25,
            carbs: 40,
            fat: 12,
            fiber: 5,
            sugar: 5,
            sodium: 200,
          ),
          tags: [],
        );
      }).toList();
      return MealDay(
        id: 'day_${i + 1}',
        date: date,
        meals: meals,
        totalCalories: meals.fold(0, (int sum, m) => sum + m.nutrition.calories),
        totalProtein: meals.fold(0.0, (sum, m) => sum + m.nutrition.protein),
        totalCarbs: meals.fold(0.0, (sum, m) => sum + m.nutrition.carbs),
        totalFat: meals.fold(0.0, (sum, m) => sum + m.nutrition.fat),
      );
    });
    setState(() {
      _showDietSetup = false;
      _currentMealPlan = MealPlanModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'current_user',
        title: 'My AI Meal Plan',
        description: 'Personalized meal plan based on your preferences',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 6)),
        mealDays: days,
        totalCalories: days.fold(0, (int sum, d) => sum + d.totalCalories),
        totalProtein: days.fold(0.0, (sum, d) => sum + d.totalProtein),
        totalCarbs: days.fold(0.0, (sum, d) => sum + d.totalCarbs),
        totalFat: days.fold(0.0, (sum, d) => sum + d.totalFat),
        dietaryTags: _foodsToAvoid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });
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
    if (_showDietSetup) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Set Up My Diet Plan'),
        ),
        body: DietPlanSetupFlow(
          step: _setupStep,
          onNext: _nextSetupStep,
          onBack: _prevSetupStep,
          selectedNutritionGoal: _selectedNutritionGoal,
          onSelectNutritionGoal: (goal) => setState(() => _selectedNutritionGoal = goal),
          preferredCuisines: _preferredCuisines,
          onAddCuisine: (cuisine) => setState(() {
            if (cuisine.isNotEmpty && !_preferredCuisines.contains(cuisine)) {
              _preferredCuisines.add(cuisine);
            }
          }),
          onRemoveCuisine: (cuisine) => setState(() => _preferredCuisines.remove(cuisine)),
          foodsToAvoid: _foodsToAvoid,
          onAddAvoid: (food) => setState(() {
            if (food.isNotEmpty && !_foodsToAvoid.contains(food)) {
              _foodsToAvoid.add(food);
            }
          }),
          onRemoveAvoid: (food) => setState(() => _foodsToAvoid.remove(food)),
          favoriteFoods: _favoriteFoods,
          onAddFavorite: (food) => setState(() {
            if (food.isNotEmpty && !_favoriteFoods.contains(food)) {
              _favoriteFoods.add(food);
            }
          }),
          onRemoveFavorite: (food) => setState(() => _favoriteFoods.remove(food)),
          mealFrequency: _mealFrequency,
          onSelectMealFrequency: (freq) => setState(() => _mealFrequency = freq),
          cuisineController: _cuisineController,
          avoidController: _avoidController,
          favoriteController: _favoriteController,
          isPreviewLoading: _isPreviewLoading,
          sampleDayPlan: _sampleDayPlan,
          onRegeneratePreview: _regeneratePreview,
          onLooksGood: () => _nextSetupStep(),
          onCustomize: () {/* TODO: Implement customization */},
          weeklyRotation: _weeklyRotation,
          onToggleWeeklyRotation: (val) => setState(() => _weeklyRotation = val),
          remindersEnabled: _remindersEnabled,
          onToggleReminders: (val) => setState(() => _remindersEnabled = val),
          onSavePlan: _completeDietSetup,
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Meal Prep'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateNewMealPlan,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _currentMealPlan != null
              ? _buildMealPlanView()
              : _buildWelcomeState(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppConstants.accentGradient,
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
              boxShadow: AppConstants.shadowM,
            ),
            child: const Icon(
              Icons.psychology,
              size: 40,
              color: AppConstants.surfaceColor,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          Text(
            'AI is crafting your meal plan...',
            style: AppTextStyles.heading4,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Analyzing your preferences and creating personalized recipes',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppConstants.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingL),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: AppConstants.spacingL),
          _buildPreferencesCard(),
          const SizedBox(height: AppConstants.spacingM),
          _buildGenerateButton(),
        ],
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

  Widget _buildPreferencesCard() {
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
              _getFitnessGoalText(_userPreferences.fitnessGoal),
              Icons.track_changes,
              null,
            ),
            const SizedBox(height: AppConstants.spacingS),
            _buildSettingRow(
              'Dietary Restrictions',
              _userPreferences.dietaryRestrictions.join(', '),
              Icons.restaurant,
              null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(
    String title,
    String value,
    IconData icon,
    VoidCallback? onTap,
  ) {
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
              Icon(
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
          _buildMealPlanHeader(),
          const SizedBox(height: AppConstants.spacingM),
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

  Widget _buildNutritionCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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
    return Container(
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
              _buildNutritionChip('P', '${meal.nutrition.protein.toStringAsFixed(0)}g'),
              const SizedBox(width: AppConstants.spacingS),
              _buildNutritionChip('C', '${meal.nutrition.carbs.toStringAsFixed(0)}g'),
              const SizedBox(width: AppConstants.spacingS),
              _buildNutritionChip('F', '${meal.nutrition.fat.toStringAsFixed(0)}g'),
              const Spacer(),
              Text(
                '${meal.prepTime + meal.cookTime} min',
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.textTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
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
          color: AppConstants.primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  // Helper methods
  void _generateNewMealPlan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final mealPlan = await AIMealService.generateMealPlan(
        preferences: _userPreferences,
        days: _selectedDays,
        targetCalories: _targetCalories,
      );

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
                _userPreferences = _userPreferences.copyWith(
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

enum MealFrequencyOption { threeMeals, threeMealsTwoSnacks, intermittentFasting }

class DietPlanSetupFlow extends StatelessWidget {
  final int step;
  final VoidCallback onNext;
  final VoidCallback onBack;
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
  final VoidCallback onRegeneratePreview;
  final VoidCallback onLooksGood;
  final VoidCallback onCustomize;
  final bool weeklyRotation;
  final ValueChanged<bool> onToggleWeeklyRotation;
  final bool remindersEnabled;
  final ValueChanged<bool> onToggleReminders;
  final VoidCallback onSavePlan;

  const DietPlanSetupFlow({
    super.key,
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
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (step > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
                tooltip: 'Back',
              ),
            ),
          Expanded(child: _buildStepContent(context)),
        ],
      ),
    );
  }

  Widget _buildStepContent(BuildContext context) {
    switch (step) {
      case 0:
        return _GoalSelectionStep(
          selected: selectedNutritionGoal,
          onSelect: onSelectNutritionGoal,
          onNext: onNext,
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
          onNext: onNext,
        );
      case 2:
        return _MealFrequencyStep(
          selected: mealFrequency,
          onSelect: onSelectMealFrequency,
          onNext: onNext,
        );
      case 3:
        return _AIPreviewStep(
          isLoading: isPreviewLoading,
          sampleDayPlan: sampleDayPlan,
          onRegenerate: onRegeneratePreview,
          onNext: onLooksGood,
          onCustomize: onCustomize,
        );
      case 4:
        return _PersonalizationConfirmationStep(
          onLooksGood: onNext,
          onCustomize: onCustomize,
        );
      case 5:
        return _PlanDurationStep(
          weeklyRotation: weeklyRotation,
          onToggleWeeklyRotation: onToggleWeeklyRotation,
          remindersEnabled: remindersEnabled,
          onToggleReminders: onToggleReminders,
          onNext: onNext,
        );
      case 6:
        return _FinalReviewStep(
          sampleDayPlan: sampleDayPlan,
          onSavePlan: onSavePlan,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _GoalSelectionStep extends StatelessWidget {
  final NutritionGoal? selected;
  final ValueChanged<NutritionGoal> onSelect;
  final VoidCallback onNext;

  const _GoalSelectionStep({
    required this.selected,
    required this.onSelect,
    required this.onNext,
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
                  Icon(goal.icon, size: 18, color: isSelected ? AppConstants.surfaceColor : AppConstants.primaryColor),
                  const SizedBox(width: 8),
                  Text(goal.label),
                ],
              ),
              selected: isSelected,
              selectedColor: AppConstants.primaryColor,
              backgroundColor: AppConstants.primaryColor.withOpacity(0.08),
              labelStyle: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? AppConstants.surfaceColor : AppConstants.primaryColor,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) => onSelect(goal),
            );
          }).toList(),
        ),
        const SizedBox(height: AppConstants.spacingL),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: CustomButton(
            text: 'Next',
            onPressed: selected != null ? onNext : null,
          ),
        ),
      ],
    );
  }
}

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
  final VoidCallback onNext;

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
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tell us what you like and don’t like.', style: AppTextStyles.heading4),
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
          SizedBox(
            width: double.infinity,
            height: 52,
            child: CustomButton(
              text: 'Next',
              onPressed: onNext,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(
    BuildContext context, {
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
        Text(label, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppConstants.spacingS),
        Wrap(
          spacing: AppConstants.spacingS,
          runSpacing: AppConstants.spacingS,
          children: items.map((item) => Chip(
            label: Text(item),
            onDeleted: () => onRemove(item),
            backgroundColor: AppConstants.primaryColor.withOpacity(0.08),
            labelStyle: AppTextStyles.bodyMedium,
          )).toList(),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
  final VoidCallback onNext;

  const _MealFrequencyStep({
    required this.selected,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('How many meals would you like per day?', style: AppTextStyles.heading4),
        const SizedBox(height: AppConstants.spacingL),
        Column(
          children: [
            _buildOptionCard(
              context,
              label: '3 main meals',
              value: MealFrequencyOption.threeMeals,
              selected: selected == MealFrequencyOption.threeMeals,
              onTap: () => onSelect(MealFrequencyOption.threeMeals),
            ),
            const SizedBox(height: AppConstants.spacingM),
            _buildOptionCard(
              context,
              label: '3 meals + 2 snacks',
              value: MealFrequencyOption.threeMealsTwoSnacks,
              selected: selected == MealFrequencyOption.threeMealsTwoSnacks,
              onTap: () => onSelect(MealFrequencyOption.threeMealsTwoSnacks),
            ),
            const SizedBox(height: AppConstants.spacingM),
            _buildOptionCard(
              context,
              label: 'Intermittent fasting (e.g., 16:8)',
              value: MealFrequencyOption.intermittentFasting,
              selected: selected == MealFrequencyOption.intermittentFasting,
              onTap: () => onSelect(MealFrequencyOption.intermittentFasting),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingL),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: CustomButton(
            text: 'Next',
            onPressed: selected != null ? onNext : null,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
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
            color: selected ? AppConstants.primaryColor : AppConstants.textTertiary.withOpacity(0.15),
            width: selected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? AppConstants.surfaceColor : AppConstants.primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: selected ? AppConstants.surfaceColor : AppConstants.textPrimary,
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

class _AIPreviewStep extends StatelessWidget {
  final bool isLoading;
  final Map<String, List<String>> sampleDayPlan;
  final VoidCallback onRegenerate;
  final VoidCallback onNext;
  final VoidCallback onCustomize;

  const _AIPreviewStep({
    required this.isLoading,
    required this.sampleDayPlan,
    required this.onRegenerate,
    required this.onNext,
    required this.onCustomize,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('AI-Generated Preview', style: AppTextStyles.heading4),
          const SizedBox(height: AppConstants.spacingL),
          if (isLoading)
            Center(child: CircularProgressIndicator())
          else
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sampleDayPlan.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                        ...entry.value.map((item) => Text('• $item', style: AppTextStyles.bodyMedium)),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ),
          const SizedBox(height: AppConstants.spacingL),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Regenerate',
                  onPressed: onRegenerate,
                  icon: Icons.refresh,
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
          ),
          const SizedBox(height: AppConstants.spacingL),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: CustomButton(
              text: 'Looks good',
              onPressed: onNext,
              icon: Icons.check_circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalizationConfirmationStep extends StatelessWidget {
  final VoidCallback onLooksGood;
  final VoidCallback onCustomize;

  const _PersonalizationConfirmationStep({
    required this.onLooksGood,
    required this.onCustomize,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Personalization Confirmation', style: AppTextStyles.heading4),
          const SizedBox(height: AppConstants.spacingL),
          Text('Would you like to proceed or further customize your plan?', style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppConstants.spacingL),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Looks good',
                  onPressed: onLooksGood,
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
          ),
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
  final VoidCallback onNext;

  const _PlanDurationStep({
    required this.weeklyRotation,
    required this.onToggleWeeklyRotation,
    required this.remindersEnabled,
    required this.onToggleReminders,
    required this.onNext,
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
                  color: weeklyRotation ? AppConstants.primaryColor : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    side: BorderSide(
                      color: weeklyRotation ? AppConstants.primaryColor : AppConstants.textTertiary.withOpacity(0.15),
                      width: weeklyRotation ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    onTap: () => onToggleWeeklyRotation(true),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      child: Column(
                        children: [
                          Icon(Icons.calendar_month, color: weeklyRotation ? AppConstants.surfaceColor : AppConstants.primaryColor),
                          const SizedBox(height: 8),
                          Text('Weekly rotating plan',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: weeklyRotation ? AppConstants.surfaceColor : AppConstants.textPrimary,
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
                  color: !weeklyRotation ? AppConstants.primaryColor : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    side: BorderSide(
                      color: !weeklyRotation ? AppConstants.primaryColor : AppConstants.textTertiary.withOpacity(0.15),
                      width: !weeklyRotation ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    onTap: () => onToggleWeeklyRotation(false),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      child: Column(
                        children: [
                          Icon(Icons.repeat_one, color: !weeklyRotation ? AppConstants.surfaceColor : AppConstants.primaryColor),
                          const SizedBox(height: 8),
                          Text('Repeat daily plan',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: !weeklyRotation ? AppConstants.surfaceColor : AppConstants.textPrimary,
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
          SizedBox(
            width: double.infinity,
            height: 52,
            child: CustomButton(
              text: 'Next',
              onPressed: onNext,
              icon: Icons.arrow_forward,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinalReviewStep extends StatelessWidget {
  final Map<String, List<String>> sampleDayPlan;
  final VoidCallback onSavePlan;

  const _FinalReviewStep({
    required this.sampleDayPlan,
    required this.onSavePlan,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Final Review', style: AppTextStyles.heading4),
          const SizedBox(height: AppConstants.spacingL),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sampleDayPlan.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                      ...entry.value.map((item) => Text('• $item', style: AppTextStyles.bodyMedium)),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'View Grocery List',
                  onPressed: () {/* TODO: Implement grocery list */},
                  icon: Icons.shopping_cart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Edit Preferences',
                  onPressed: () {/* TODO: Implement edit preferences */},
                  icon: Icons.tune,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: CustomButton(
              text: 'Save Plan',
              onPressed: onSavePlan,
              icon: Icons.save,
            ),
          ),
        ],
      ),
    );
  }
} 