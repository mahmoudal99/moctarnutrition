import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../shared/models/meal_model.dart';
import '../../../../shared/services/meal_logging_service.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/meal_plan_provider.dart';
import '../../../../shared/services/daily_consumption_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/food_search_service.dart';

class AddFoodDialog extends StatefulWidget {
  final FoodProduct food;

  const AddFoodDialog({
    super.key,
    required this.food,
  });

  @override
  State<AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<AddFoodDialog> {
  MealType _selectedMealType = MealType.snack;
  double _servingMultiplier = 1.0;
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    final adjustedNutrition = NutritionInfo(
      calories: widget.food.nutrition.calories * _servingMultiplier,
      protein: widget.food.nutrition.protein * _servingMultiplier,
      carbs: widget.food.nutrition.carbs * _servingMultiplier,
      fat: widget.food.nutrition.fat * _servingMultiplier,
      fiber: widget.food.nutrition.fiber * _servingMultiplier,
      sugar: widget.food.nutrition.sugar * _servingMultiplier,
      sodium: widget.food.nutrition.sodium * _servingMultiplier,
    );

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Food Image
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppConstants.backgroundColor,
                  ),
                  child: widget.food.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.food.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.fastfood,
                                color: AppConstants.textTertiary,
                                size: 20,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.fastfood,
                          color: AppConstants.textTertiary,
                          size: 20,
                        ),
                ),

                const SizedBox(width: AppConstants.spacingM),

                // Food Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.food.name,
                        style: AppTextStyles.heading5.copyWith(
                          color: AppConstants.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.food.brand.isNotEmpty)
                        Text(
                          widget.food.brand,
                          style: AppTextStyles.bodySmall.copyWith(),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.spacingL),

            // Meal Type Selection
            Text(
              'Meal Type',
              style: AppTextStyles.heading5.copyWith(
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),

            const SizedBox(height: AppConstants.spacingS),

            Wrap(
              spacing: AppConstants.spacingS,
              children: MealType.values.map((type) {
                final isSelected = _selectedMealType == type;
                return ChoiceChip(
                  label: Text(
                    type.name.toUpperCase(),
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    // style: TextStyle(
                    //   color: isSelected
                    //       ? Colors.white
                    //       : AppConstants.textSecondary,
                    // ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedMealType = type;
                      });
                    }
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: AppConstants.primaryColor,
                );
              }).toList(),
            ),

            const SizedBox(height: AppConstants.spacingL),

            // Serving Size
            Text(
              'Serving Size',
              style: AppTextStyles.heading5.copyWith(
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),

            const SizedBox(height: AppConstants.spacingS),

            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _servingMultiplier,
                    min: 0.5,
                    max: 3.0,
                    divisions: 25,
                    label: '${_servingMultiplier.toStringAsFixed(1)}x',
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _servingMultiplier = value;
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    '${_servingMultiplier.toStringAsFixed(1)}x',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppConstants.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.spacingL),

            // Nutrition Summary
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: AppConstants.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Nutrition (${(_servingMultiplier * 100).toStringAsFixed(0)}g)',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNutritionItem('Calories',
                          adjustedNutrition.calories.toStringAsFixed(0), 'cal'),
                      _buildNutritionItem('Protein',
                          adjustedNutrition.protein.toStringAsFixed(1), 'g'),
                      _buildNutritionItem('Carbs',
                          adjustedNutrition.carbs.toStringAsFixed(1), 'g'),
                      _buildNutritionItem(
                          'Fat', adjustedNutrition.fat.toStringAsFixed(1), 'g'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            // Action Buttons
            Row(
              children: [
                // Expanded(
                //   child: TextButton(
                //     onPressed:
                //         _isAdding ? null : () => Navigator.of(context).pop(),
                //     child: Text(
                //       'Cancel',
                //       style: AppTextStyles.heading5
                //           .copyWith(color: Colors.black87, fontSize: 14),
                //     ),
                //   ),
                // ),
                // const SizedBox(width: AppConstants.spacingS),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isAdding
                        ? null
                        : () => _addFoodToDailyIntake(adjustedNutrition),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isAdding
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Add to ${_selectedMealType.name}',
                            style: AppTextStyles.heading5
                                .copyWith(color: Colors.white, fontSize: 15),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Add the food to daily intake and log it as consumed
  Future<void> _addFoodToDailyIntake(NutritionInfo adjustedNutrition) async {
    setState(() {
      _isAdding = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final mealPlanProvider =
          Provider.of<MealPlanProvider>(context, listen: false);

      if (authProvider.userModel == null || mealPlanProvider.mealPlan == null) {
        throw Exception('User or meal plan not available');
      }

      final userId = authProvider.userModel!.id;
      final today = DateTime.now();

      // Create a meal from the food product
      final meal = widget.food.toMeal(_selectedMealType);

      // Update the meal's nutrition with the adjusted serving size
      meal.nutrition = adjustedNutrition;

      // Mark the meal as consumed
      meal.isConsumed = true;

      // Get the current meal day for today
      final weekdayIndex = today.weekday - 1; // Monday = 0, Sunday = 6
      final mealDay = mealPlanProvider.mealPlan!.mealDays[weekdayIndex];

      // Add the new meal to the meal day
      mealDay.meals.add(meal);

      // Recalculate the meal day's nutrition totals
      mealDay.calculateConsumedNutrition();

      // Log the meal as consumed using the MealLoggingService
      await MealLoggingService.markMealAsConsumed(
        meal,
        mealDay,
        userId,
        today,
      );

      // Update the daily consumption service to persist the data
      await DailyConsumptionService.updateMealConsumption(
        userId,
        today,
        meal.id,
        true, // isConsumed
        nutritionInfo: adjustedNutrition, // Pass the nutrition info
      );

      // Update the meal plan provider to trigger UI refresh
      // We need to trigger a rebuild by calling setState or using a different approach
      // Since this is a dialog, we'll just close it and let the parent screen refresh

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${widget.food.name} added to ${_selectedMealType.name} and logged as consumed!'),
            backgroundColor: AppConstants.primaryColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding food: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  Widget _buildNutritionItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          "$value$unit",
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppConstants.primaryColor,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
      ],
    );
  }
}
