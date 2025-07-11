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

  @override
  void initState() {
    super.initState();
    _initializeUserPreferences();
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

  @override
  Widget build(BuildContext context) {
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
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppConstants.accentGradient,
              borderRadius: BorderRadius.circular(AppConstants.radiusXL),
              boxShadow: AppConstants.shadowL,
            ),
            child: const Icon(
              Icons.psychology,
              size: 60,
              color: AppConstants.surfaceColor,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXL),
          Text(
            'AI is crafting your meal plan...',
            style: AppTextStyles.heading3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Analyzing your preferences and creating personalized recipes',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppConstants.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingXL),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.accentColor),
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
          const SizedBox(height: AppConstants.spacingXL),
          _buildPreferencesCard(),
          const SizedBox(height: AppConstants.spacingL),
          _buildGenerateButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        gradient: AppConstants.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: AppConstants.shadowM,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.psychology,
            size: 60,
            color: AppConstants.surfaceColor,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'AI-Powered Meal Planning',
            style: AppTextStyles.heading3.copyWith(
              color: AppConstants.surfaceColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Get personalized meal plans tailored to your fitness goals, dietary restrictions, and preferences',
            style: AppTextStyles.bodyMedium.copyWith(
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
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meal Plan Settings',
              style: AppTextStyles.heading4,
            ),
            const SizedBox(height: AppConstants.spacingL),
            _buildSettingRow(
              'Plan Duration',
              '$_selectedDays days',
              Icons.calendar_today,
              () => _showDaysSelector(),
            ),
            const SizedBox(height: AppConstants.spacingM),
            _buildSettingRow(
              'Target Calories',
              '$_targetCalories cal/day',
              Icons.local_fire_department,
              () => _showCaloriesSelector(),
            ),
            const SizedBox(height: AppConstants.spacingM),
            _buildSettingRow(
              'Fitness Goal',
              _getFitnessGoalText(_userPreferences.fitnessGoal),
              Icons.track_changes,
              null,
            ),
            const SizedBox(height: AppConstants.spacingM),
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
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.spacingS,
          horizontal: AppConstants.spacingS,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              child: Icon(
                icon,
                color: AppConstants.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: AppTextStyles.bodyLarge.copyWith(
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return GradientButton(
      text: 'Generate AI Meal Plan',
      icon: Icons.psychology,
      onPressed: _generateNewMealPlan,
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
          const SizedBox(height: AppConstants.spacingL),
          _buildNutritionSummary(),
          const SizedBox(height: AppConstants.spacingL),
          _buildMealDaysList(),
        ],
      ),
    );
  }

  Widget _buildMealPlanHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        gradient: AppConstants.accentGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: AppConstants.shadowM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology,
                color: AppConstants.surfaceColor,
                size: 30,
              ),
              const SizedBox(width: AppConstants.spacingS),
              Text(
                'AI Generated',
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.surfaceColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            _currentMealPlan!.title,
            style: AppTextStyles.heading3.copyWith(
              color: AppConstants.surfaceColor,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            _currentMealPlan!.description,
            style: AppTextStyles.bodyMedium.copyWith(
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
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutrition Summary',
              style: AppTextStyles.heading4,
            ),
            const SizedBox(height: AppConstants.spacingM),
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
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: _buildNutritionCard(
                    'Protein',
                    '${_currentMealPlan!.totalProtein.toStringAsFixed(0)}g',
                    Icons.fitness_center,
                    AppConstants.accentColor,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
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
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.textSecondary,
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
        const SizedBox(height: AppConstants.spacingM),
        ..._currentMealPlan!.mealDays.map((mealDay) {
          return _buildMealDayCard(mealDay);
        }).toList(),
      ],
    );
  }

  Widget _buildMealDayCard(MealDay mealDay) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: ExpansionTile(
        title: Text(
          'Day ${_currentMealPlan!.mealDays.indexOf(mealDay) + 1}',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${mealDay.totalCalories} calories',
          style: AppTextStyles.bodySmall.copyWith(
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
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getMealTypeColor(meal.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: Icon(
                  _getMealTypeIcon(meal.type),
                  color: _getMealTypeColor(meal.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      meal.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${meal.nutrition.calories} cal',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppConstants.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
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
        horizontal: AppConstants.spacingS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Text(
        '$label: $value',
        style: AppTextStyles.caption.copyWith(
          color: AppConstants.primaryColor,
          fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Plan Duration',
            style: AppTextStyles.heading4,
          ),
          const SizedBox(height: AppConstants.spacingL),
          Wrap(
            spacing: AppConstants.spacingM,
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
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Target Calories',
            style: AppTextStyles.heading4,
          ),
          const SizedBox(height: AppConstants.spacingL),
          Slider(
            value: _targetCalories.toDouble(),
            min: 1200,
            max: 3000,
            divisions: 18,
            label: '$_targetCalories cal',
            onChanged: (value) {
              setState(() {
                _targetCalories = value.round();
              });
            },
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            '$_targetCalories calories per day',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          CustomButton(
            text: 'Confirm',
            onPressed: () => Navigator.pop(context),
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
} 