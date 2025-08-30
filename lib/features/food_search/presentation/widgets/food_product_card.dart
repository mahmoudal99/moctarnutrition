import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/food_search_service.dart';

class FoodProductCard extends StatelessWidget {
  final FoodProduct food;
  final VoidCallback onTap;

  const FoodProductCard({
    super.key,
    required this.food,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Row(
            children: [
              // Food Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppConstants.backgroundColor,
                ),
                child: food.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          food.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.fastfood,
                              color: AppConstants.textTertiary,
                              size: 24,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.fastfood,
                        color: AppConstants.textTertiary,
                        size: 24,
                      ),
              ),
              
              const SizedBox(width: AppConstants.spacingM),
              
              // Food Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food Name
                    Text(
                      food.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: AppConstants.spacingXS),
                    
                    // Brand
                    if (food.brand.isNotEmpty)
                      Text(
                        food.brand,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppConstants.textSecondary,
                          fontFamily: 'Inter',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    const SizedBox(height: AppConstants.spacingXS),
                    
                    // Serving Size
                    Text(
                      'Serving: ${food.servingSize}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppConstants.textTertiary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: AppConstants.spacingM),
              
              // Nutrition Info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Calories
                  Text(
                    '${food.nutrition.calories.toStringAsFixed(0)} cal',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.spacingXS),
                  
                  // Protein
                  Text(
                    '${food.nutrition.protein.toStringAsFixed(1)}g protein',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppConstants.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  
                  // Add Icon
                  const SizedBox(height: AppConstants.spacingXS),
                  const Icon(
                    Icons.add_circle_outline,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
