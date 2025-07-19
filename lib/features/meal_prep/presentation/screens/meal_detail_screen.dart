import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/meal_model.dart';
import '../../../../shared/services/nutrition_verification_service.dart';
import '../../../../shared/services/config_service.dart';
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

class _MealDetailScreenState extends State<MealDetailScreen> {
  MealVerificationResult? _verificationResult;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _loadVerificationResult();
  }

  Future<void> _loadVerificationResult() async {
    if (!ConfigService.isUsdaApiEnabled) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      final mealPlanProvider = Provider.of<MealPlanProvider>(context, listen: false);
      final verificationResult = await mealPlanProvider.getMealVerification(widget.meal);
      setState(() {
        _verificationResult = verificationResult;
        _isVerifying = false;
      });
    } catch (e) {
      setState(() {
        _isVerifying = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load verification result: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MealPlanProvider>(
      builder: (context, mealPlanProvider, child) {
        // Get the updated meal from the provider
        Meal? updatedMeal;
        if (mealPlanProvider.mealPlan != null) {
          for (final mealDay in mealPlanProvider.mealPlan!.mealDays) {
            final foundMeal = mealDay.meals.where((m) => m.id == widget.meal.id).firstOrNull;
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
              icon: Icon(Icons.arrow_back, color: AppConstants.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              currentMeal.name,
              style: AppTextStyles.heading4.copyWith(
                color: AppConstants.textPrimary,
              ),
            ),
            actions: [
              if (_isVerifying)
                Container(
                  margin: const EdgeInsets.only(right: AppConstants.spacingM),
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMealHeader(currentMeal),
                const SizedBox(height: AppConstants.spacingL),
                _buildNutritionOverview(currentMeal),
                const SizedBox(height: AppConstants.spacingL),
                _buildIngredientsSection(currentMeal),
                const SizedBox(height: AppConstants.spacingL),
                _buildInstructionsSection(currentMeal),
                const SizedBox(height: AppConstants.spacingL),
                _buildMealInfo(currentMeal),
              ],
            ),
          ),
        );
      },
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
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getMealTypeColor(meal.type).withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: Icon(
              _getMealTypeIcon(meal.type),
              color: _getMealTypeColor(meal.type),
              size: 28,
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  style: AppTextStyles.heading4.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXS),
                Text(
                  meal.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXS),
                Row(
                  children: [
                    Icon(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nutrition Overview',
          style: AppTextStyles.heading4.copyWith(
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
                      '${meal.nutrition.protein.toStringAsFixed(1)}',
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
                      '${meal.nutrition.carbs.toStringAsFixed(1)}',
                      'g',
                      AppConstants.warningColor,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: _buildNutritionCard(
                      'Fat',
                      '${meal.nutrition.fat.toStringAsFixed(1)}',
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
                      '${widget.meal.nutrition.fiber.toStringAsFixed(1)}',
                      'g',
                      AppConstants.secondaryColor,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: _buildNutritionCard(
                      'Sugar',
                      '${widget.meal.nutrition.sugar.toStringAsFixed(1)}',
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
    );
  }

  Widget _buildNutritionCard(String label, String value, String unit, Color color) {
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
        Row(
          children: [
            Text(
              'Ingredients',
              style: AppTextStyles.heading4.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (_verificationResult != null)
              _buildVerificationBadge(),
          ],
        ),
        const SizedBox(height: AppConstants.spacingM),
        
        // Automatic correction summary
        if (_verificationResult != null)
          _buildAutomaticCorrectionSummary(),
        
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

  Widget _buildVerificationBadge() {
    if (_verificationResult == null) return const SizedBox.shrink();

    final isVerified = _verificationResult!.isVerified;
    final confidence = _verificationResult!.confidence;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isVerified 
            ? AppConstants.successColor.withOpacity(0.1)
            : AppConstants.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        border: Border.all(
          color: isVerified 
              ? AppConstants.successColor.withOpacity(0.3)
              : AppConstants.warningColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified : Icons.warning,
            size: 14,
            color: isVerified 
                ? AppConstants.successColor
                : AppConstants.warningColor,
          ),
          const SizedBox(width: 4),
          Text(
            '${(confidence * 100).toInt()}% verified',
            style: AppTextStyles.caption.copyWith(
              color: isVerified 
                  ? AppConstants.successColor
                  : AppConstants.warningColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientTile(RecipeIngredient ingredient, Meal meal) {
    final hasNutrition = ingredient.nutrition != null;
    final verificationDetail = _verificationResult?.ingredientVerifications
        .firstWhere(
          (v) => v.ingredientName == ingredient.name,
          orElse: () => IngredientVerificationDetail(
            ingredientName: ingredient.name,
            mealName: meal.name,
            dayIndex: 'unknown',
            isVerified: false,
            confidence: 0.0,
            message: 'Not verified',
          ),
        );

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppConstants.textTertiary.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              if (hasNutrition)
                _buildIngredientNutrition(ingredient.nutrition!),
            ],
          ),
          if (verificationDetail != null && ConfigService.isUsdaApiEnabled)
            _buildIngredientVerification(verificationDetail),
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

  Widget _buildIngredientVerification(IngredientVerificationDetail detail) {
    return Container(
      margin: const EdgeInsets.only(top: AppConstants.spacingS),
      padding: const EdgeInsets.all(AppConstants.spacingS),
      decoration: BoxDecoration(
        color: detail.isVerified 
            ? AppConstants.successColor.withOpacity(0.05)
            : AppConstants.warningColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        border: Border.all(
          color: detail.isVerified 
              ? AppConstants.successColor.withOpacity(0.2)
              : AppConstants.warningColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                detail.isVerified ? Icons.check_circle : Icons.info,
                size: 16,
                color: detail.isVerified 
                    ? AppConstants.successColor
                    : AppConstants.warningColor,
              ),
              const SizedBox(width: AppConstants.spacingS),
              Expanded(
                child: Text(
                  detail.message,
                  style: AppTextStyles.caption.copyWith(
                    color: detail.isVerified 
                        ? AppConstants.successColor
                        : AppConstants.warningColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          // Show correction buttons for non-verified ingredients
          if (!detail.isVerified && (detail.suggestedCorrection != null || detail.suggestedReplacement != null))
            Padding(
              padding: const EdgeInsets.only(top: AppConstants.spacingS),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show automatic application status
                  if (detail.suggestedCorrection != null && detail.confidence > 0.6)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppConstants.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppConstants.radiusS),
                        border: Border.all(
                          color: AppConstants.successColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: AppConstants.successColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Auto-applied USDA data',
                            style: AppTextStyles.caption.copyWith(
                              color: AppConstants.successColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (detail.suggestedCorrection != null && detail.confidence <= 0.6)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppConstants.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppConstants.radiusS),
                        border: Border.all(
                          color: AppConstants.warningColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: AppConstants.warningColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Manual review needed',
                            style: AppTextStyles.caption.copyWith(
                              color: AppConstants.warningColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppConstants.spacingS),
                  // Keep manual replacement button for dietary restrictions
                  if (detail.suggestedReplacement != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _replaceIngredient(detail),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusS),
                          ),
                        ),
                        child: Text(
                          'Replace Ingredient',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
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
          style: AppTextStyles.heading4.copyWith(
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
                        style: AppTextStyles.bodyMedium,
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
            style: AppTextStyles.heading4.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          _buildInfoRow('Prep Time', '${meal.prepTime} min', Icons.timer),
          _buildInfoRow('Cook Time', '${meal.cookTime} min', Icons.restaurant),
          _buildInfoRow('Servings', '${meal.servings}', Icons.people),
          _buildInfoRow('Cuisine', _getCuisineName(meal.cuisineType), Icons.flag),
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
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
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

  Widget _buildAutomaticCorrectionSummary() {
    // Calculate automatic correction stats
    final autoAppliedCount = _verificationResult!.ingredientVerifications
        .where((v) => v.suggestedCorrection != null && v.confidence > 0.6)
        .length;
    final manualReviewCount = _verificationResult!.ingredientVerifications
        .where((v) => v.suggestedCorrection != null && v.confidence <= 0.6)
        .length;

    if (autoAppliedCount == 0 && manualReviewCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: AppConstants.primaryColor,
              ),
              const SizedBox(width: AppConstants.spacingS),
              Text(
                'Automatic Verification Summary',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingS),
          if (autoAppliedCount > 0)
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: AppConstants.successColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '$autoAppliedCount ingredients auto-corrected with USDA data',
                  style: AppTextStyles.caption.copyWith(
                    color: AppConstants.successColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          if (manualReviewCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppConstants.warningColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$manualReviewCount ingredients need manual review',
                    style: AppTextStyles.caption.copyWith(
                      color: AppConstants.warningColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _applyNutritionCorrection(IngredientVerificationDetail detail) async {
    try {
      final mealPlanProvider = Provider.of<MealPlanProvider>(context, listen: false);
      
      // Create a verification result with just this correction
      final correctionResult = MealVerificationResult(
        isVerified: false,
        confidence: detail.confidence,
        message: 'Applied USDA correction for ${detail.ingredientName}',
        ingredientVerifications: [detail],
      );

      await mealPlanProvider.applyMealCorrections(widget.meal.id, correctionResult);
      
      // Re-verify the meal after applying corrections
      setState(() {
        _isVerifying = true;
      });
      
      try {
        // Get the updated meal from the provider
        Meal? updatedMeal;
        if (mealPlanProvider.mealPlan != null) {
          for (final mealDay in mealPlanProvider.mealPlan!.mealDays) {
            final foundMeal = mealDay.meals.where((m) => m.id == widget.meal.id).firstOrNull;
            if (foundMeal != null) {
              updatedMeal = foundMeal;
              break;
            }
          }
        }
        
        if (updatedMeal != null) {
          final newVerificationResult = await mealPlanProvider.getMealVerification(updatedMeal);
          setState(() {
            _verificationResult = newVerificationResult;
            _isVerifying = false;
          });
        }
      } catch (e) {
        setState(() {
          _isVerifying = false;
        });
        print('Error re-verifying meal: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nutrition data updated for ${detail.ingredientName}'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to apply correction: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  void _replaceIngredient(IngredientVerificationDetail detail) async {
    if (detail.suggestedReplacement == null) return;

    try {
      final mealPlanProvider = Provider.of<MealPlanProvider>(context, listen: false);
      
      await mealPlanProvider.replaceNonCompliantIngredient(
        widget.meal.id,
        detail.ingredientName,
        detail.suggestedReplacement!,
      );
      
      // Re-verify the meal after replacing ingredient
      setState(() {
        _isVerifying = true;
      });
      
      try {
        // Get the updated meal from the provider
        Meal? updatedMeal;
        if (mealPlanProvider.mealPlan != null) {
          for (final mealDay in mealPlanProvider.mealPlan!.mealDays) {
            final foundMeal = mealDay.meals.where((m) => m.id == widget.meal.id).firstOrNull;
            if (foundMeal != null) {
              updatedMeal = foundMeal;
              break;
            }
          }
        }
        
        if (updatedMeal != null) {
          final newVerificationResult = await mealPlanProvider.getMealVerification(updatedMeal);
          setState(() {
            _verificationResult = newVerificationResult;
            _isVerifying = false;
          });
        }
      } catch (e) {
        setState(() {
          _isVerifying = false;
        });
        print('Error re-verifying meal: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Replaced ${detail.ingredientName} with ${detail.suggestedReplacement!.name}'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to replace ingredient: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }
} 