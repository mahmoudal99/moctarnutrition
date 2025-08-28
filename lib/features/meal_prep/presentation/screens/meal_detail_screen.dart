import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/meal_model.dart';
import '../../../../shared/providers/meal_plan_provider.dart';

class MealDetailScreen extends StatefulWidget {
  final Meal meal;
  final String dayTitle;

  const MealDetailScreen({
    super.key,
    required this.meal,
    required this.dayTitle,
  });

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _nutritionAnimationController;
  late Animation<double> _nutritionScaleAnimation;
  late Animation<double> _nutritionOpacityAnimation;
  late Animation<double> _pillOpacityAnimation;
  late Animation<double> _pillScaleAnimation;

  double _scrollOffset = 0.0;
  static const double _scrollThreshold =
      100.0; // Reduced threshold for easier testing

  @override
  void initState() {
    super.initState();
    _loadVerificationResult();

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _nutritionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _nutritionScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _nutritionAnimationController,
      curve: Curves.easeInOut,
    ));

    _nutritionOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _nutritionAnimationController,
      curve: Curves.easeInOut,
    ));

    _pillOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _nutritionAnimationController,
      curve: Curves.easeInOut,
    ));

    _pillScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _nutritionAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nutritionAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });

    if (_scrollOffset > _scrollThreshold &&
        _nutritionAnimationController.value == 0) {
      _nutritionAnimationController.forward();
    } else if (_scrollOffset <= _scrollThreshold &&
        _nutritionAnimationController.value == 1) {
      _nutritionAnimationController.reverse();
    }
  }

  Future<void> _loadVerificationResult() async {
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MealPlanProvider>(
      builder: (context, mealPlanProvider, child) {
        // Get the updated meal from the provider
        Meal? updatedMeal;
        if (mealPlanProvider.mealPlan != null) {
          for (final mealDay in mealPlanProvider.mealPlan!.mealDays) {
            final foundMeal =
                mealDay.meals.where((m) => m.id == widget.meal.id).firstOrNull;
            if (foundMeal != null) {
              updatedMeal = foundMeal;
              break;
            }
          }
        }

        // Use updated meal if available, otherwise use original
        final currentMeal = updatedMeal ?? widget.meal;

        return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppConstants.backgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: AppConstants.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              currentMeal.name,
              style: AppTextStyles.heading5.copyWith(
                color: AppConstants.textPrimary,
              ),
            ),
            actions: [],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMealHeader(currentMeal),
                    const SizedBox(height: AppConstants.spacingM),
                    _buildNutritionOverview(currentMeal),
                    const SizedBox(height: AppConstants.spacingM),
                    _buildIngredientsSection(currentMeal),
                    const SizedBox(height: AppConstants.spacingM),
                    _buildInstructionsSection(currentMeal),
                    const SizedBox(height: AppConstants.spacingM),
                    _buildMealInfo(currentMeal),
                    const SizedBox(height: 128),
                  ],
                ),
              ),
              // Floating pill nutrition overview
              Positioned(
                top: MediaQuery.of(context).padding.top + 20,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _nutritionAnimationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pillScaleAnimation.value,
                        child: Opacity(
                          opacity: _pillOpacityAnimation.value,
                          child: _buildPillNutritionOverview(currentMeal),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPillNutritionOverview(Meal meal) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
        vertical: AppConstants.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPillNutritionItem(
            Icons.local_fire_department,
            '${meal.nutrition.calories}',
            AppConstants.accentColor,
          ),
          const SizedBox(width: AppConstants.spacingM),
          _buildPillNutritionItem(
            Icons.fitness_center,
            '${meal.nutrition.protein.toStringAsFixed(1)}g',
            AppConstants.successColor,
          ),
          const SizedBox(width: AppConstants.spacingM),
          _buildPillNutritionItem(
            Icons.grain,
            '${meal.nutrition.carbs.toStringAsFixed(1)}g',
            AppConstants.warningColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPillNutritionItem(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMealHeader(Meal meal) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getMealTypeColor(meal.type).withOpacity(0.1),
            _getMealTypeColor(meal.type).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: _getMealTypeColor(meal.type).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  style: AppTextStyles.heading5.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingS),
                Text(
                  meal.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingS),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppConstants.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.dayTitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppConstants.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionOverview(Meal meal) {
    return AnimatedBuilder(
      animation: _nutritionAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0,
          child: Opacity(
            opacity: _nutritionOpacityAnimation.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nutrition Overview',
                  style: AppTextStyles.heading5.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceColor,
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    border: Border.all(
                      color: AppConstants.textTertiary.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildNutritionCard(
                              'Calories',
                              '${meal.nutrition.calories}',
                              'cal',
                              AppConstants.accentColor,
                            ),
                          ),
                          const SizedBox(width: AppConstants.spacingS),
                          Expanded(
                            child: _buildNutritionCard(
                              'Protein',
                              meal.nutrition.protein.toStringAsFixed(1),
                              'g',
                              AppConstants.successColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingS),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNutritionCard(
                              'Carbs',
                              meal.nutrition.carbs.toStringAsFixed(1),
                              'g',
                              AppConstants.warningColor,
                            ),
                          ),
                          const SizedBox(width: AppConstants.spacingS),
                          Expanded(
                            child: _buildNutritionCard(
                              'Fat',
                              meal.nutrition.fat.toStringAsFixed(1),
                              'g',
                              AppConstants.errorColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingS),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNutritionCard(
                              'Fiber',
                              widget.meal.nutrition.fiber.toStringAsFixed(1),
                              'g',
                              AppConstants.secondaryColor,
                            ),
                          ),
                          const SizedBox(width: AppConstants.spacingS),
                          Expanded(
                            child: _buildNutritionCard(
                              'Sugar',
                              widget.meal.nutrition.sugar.toStringAsFixed(1),
                              'g',
                              AppConstants.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNutritionCard(
      String label, String value, String unit, Color color) {
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
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.heading4.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: AppTextStyles.caption.copyWith(
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection(Meal meal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingredients',
          style: AppTextStyles.heading5.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Container(
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            border: Border.all(
              color: AppConstants.textTertiary.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: meal.ingredients.map((ingredient) {
              return _buildIngredientTile(ingredient, meal);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientTile(RecipeIngredient ingredient, Meal meal) {
    final hasNutrition = ingredient.nutrition != null;

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppConstants.textTertiary.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ingredient.amount} ${ingredient.unit}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
                if (ingredient.notes != null && ingredient.notes!.isNotEmpty)
                  Text(
                    ingredient.notes!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppConstants.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          if (hasNutrition) _buildIngredientNutrition(ingredient.nutrition!),
        ],
      ),
    );
  }

  Widget _buildIngredientNutrition(NutritionInfo nutrition) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingS),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            '${nutrition.calories} cal',
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'P: ${nutrition.protein.toStringAsFixed(1)}g',
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.textSecondary,
              fontSize: 10,
            ),
          ),
          Text(
            'C: ${nutrition.carbs.toStringAsFixed(1)}g',
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.textSecondary,
              fontSize: 10,
            ),
          ),
          Text(
            'F: ${nutrition.fat.toStringAsFixed(1)}g',
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection(Meal meal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instructions',
          style: AppTextStyles.heading5.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            border: Border.all(
              color: AppConstants.textTertiary.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: meal.instructions.asMap().entries.map((entry) {
              final index = entry.key;
              final instruction = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingM),
                    Expanded(
                      child: Text(
                        instruction,
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMealInfo(Meal meal) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meal Information',
            style: AppTextStyles.heading5.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          _buildInfoRow('Prep Time', '${meal.prepTime} min', Icons.timer),
          _buildInfoRow('Cook Time', '${meal.cookTime} min', Icons.restaurant),
          _buildInfoRow('Servings', '${meal.servings}', Icons.people),
          if (meal.tags.isNotEmpty)
            _buildInfoRow('Tags', meal.tags.join(', '), Icons.label),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppConstants.textSecondary,
          ),
          const SizedBox(width: AppConstants.spacingS),
          Text(
            '$label: ',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppConstants.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(
            width: AppConstants.spacingS,
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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

  String _getCuisineName(CuisineType type) {
    switch (type) {
      case CuisineType.american:
        return 'American';
      case CuisineType.italian:
        return 'Italian';
      case CuisineType.mexican:
        return 'Mexican';
      case CuisineType.asian:
        return 'Asian';
      case CuisineType.mediterranean:
        return 'Mediterranean';
      case CuisineType.indian:
        return 'Indian';
      case CuisineType.other:
        return 'Other';
    }
  }
}
