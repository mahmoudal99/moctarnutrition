import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/models/meal_model.dart';
import '../../../../shared/services/meal_logging_service.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/meal_plan_provider.dart';
import '../../../../shared/services/daily_consumption_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/food_search_service.dart';
import '../widgets/add_food_dialog.dart';

class FoodDetailsScreen extends StatefulWidget {
  final FoodProduct food;

  const FoodDetailsScreen({
    super.key,
    required this.food,
  });

  @override
  State<FoodDetailsScreen> createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  bool _isAddingToMeal = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: AppConstants.backgroundColor,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Scan Another',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image and Basic Info
            _buildProductHeader(),
            
            const SizedBox(height: AppConstants.spacingL),
            
            // Nutrition Information
            _buildNutritionSection(),
            
            const SizedBox(height: AppConstants.spacingL),
            
            // Additional Information
            _buildAdditionalInfoSection(),
            
            const SizedBox(height: AppConstants.spacingL),
            
            // Action Button
            _buildActionButton(),
            
            const SizedBox(height: AppConstants.spacingL),
          ],
        ),
      ),
    );
  }

  Widget _buildProductHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Product Image
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: widget.food.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      widget.food.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.fastfood,
                          color: AppConstants.textTertiary,
                          size: 40,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.fastfood,
                    color: AppConstants.textTertiary,
                    size: 40,
                  ),
          ),
          
          const SizedBox(height: AppConstants.spacingM),
          
          // Product Name
          Text(
            widget.food.name,
            style: AppTextStyles.heading4.copyWith(
              color: AppConstants.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          if (widget.food.brand.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spacingS),
            Text(
              widget.food.brand,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppConstants.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          
          const SizedBox(height: AppConstants.spacingS),
          
          // Barcode
          Text(
            'Barcode: ${widget.food.barcode}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppConstants.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutrition Information',
            style: AppTextStyles.heading5.copyWith(
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimary,
            ),
          ),
          
          const SizedBox(height: AppConstants.spacingM),
          
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppConstants.borderColor,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Serving Size
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Serving Size:',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                    Text(
                      widget.food.servingSize,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppConstants.spacingM),
                
                // Nutrition Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildNutritionItem(
                        'Calories',
                        '${widget.food.nutrition.calories.toStringAsFixed(0)}',
                        'cal',
                        AppConstants.primaryColor,
                      ),
                    ),
                    Expanded(
                      child: _buildNutritionItem(
                        'Protein',
                        '${widget.food.nutrition.protein.toStringAsFixed(1)}',
                        'g',
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppConstants.spacingS),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildNutritionItem(
                        'Carbs',
                        '${widget.food.nutrition.carbs.toStringAsFixed(1)}',
                        'g',
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildNutritionItem(
                        'Fat',
                        '${widget.food.nutrition.fat.toStringAsFixed(1)}',
                        'g',
                        Colors.red,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppConstants.spacingS),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildNutritionItem(
                        'Fiber',
                        '${widget.food.nutrition.fiber.toStringAsFixed(1)}',
                        'g',
                        Colors.brown,
                      ),
                    ),
                    Expanded(
                      child: _buildNutritionItem(
                        'Sugar',
                        '${widget.food.nutrition.sugar.toStringAsFixed(1)}',
                        'g',
                        Colors.pink,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppConstants.spacingS),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildNutritionItem(
                        'Sodium',
                        '${widget.food.nutrition.sodium.toStringAsFixed(0)}',
                        'mg',
                        Colors.blue,
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingS),
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$value$unit',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppConstants.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Information',
            style: AppTextStyles.heading5.copyWith(
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimary,
            ),
          ),
          
          const SizedBox(height: AppConstants.spacingM),
          
          // Nutri-Score
          if (widget.food.nutriscore != null) ...[
            _buildInfoRow('Nutri-Score', widget.food.nutriscore!),
            const SizedBox(height: AppConstants.spacingS),
          ],
          
          // Eco-Score
          if (widget.food.ecoscore != null) ...[
            _buildInfoRow('Eco-Score', widget.food.ecoscore!),
            const SizedBox(height: AppConstants.spacingS),
          ],
          
          // Allergens
          if (widget.food.allergens.isNotEmpty) ...[
            _buildInfoRow('Allergens', widget.food.allergens.join(', ')),
            const SizedBox(height: AppConstants.spacingS),
          ],
          
          // Ingredients
          if (widget.food.ingredients.isNotEmpty) ...[
            _buildInfoRow('Ingredients', widget.food.ingredients),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isAddingToMeal ? null : _showAddFoodDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isAddingToMeal
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Add to Meal Plan',
                  style: AppTextStyles.heading5.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }

  void _showAddFoodDialog() {
    showDialog(
      context: context,
      builder: (context) => AddFoodDialog(food: widget.food),
    ).then((result) {
      if (result == true) {
        // Food was successfully added
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Food added to your meal plan successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to the previous screen
        Navigator.of(context).pop();
      }
    });
  }
}
