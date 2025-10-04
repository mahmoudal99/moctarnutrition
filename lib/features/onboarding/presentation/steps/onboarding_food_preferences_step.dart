import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class OnboardingFoodPreferencesStep extends StatelessWidget {
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

  const OnboardingFoodPreferencesStep({
    super.key,
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
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            hint: 'e.g. pork, dairy, mushrooms',
            items: foodsToAvoid,
            controller: avoidController,
            onAdd: onAddAvoid,
            onRemove: onRemoveAvoid,
          ),
          const SizedBox(height: AppConstants.spacingM),
          _buildInputSection(
            context,
            label: 'Favorite Foods',
            hint: 'e.g. oats, chicken, tofu',
            items: favoriteFoods,
            controller: favoriteController,
            onAdd: onAddFavorite,
            onRemove: onRemoveFavorite,
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
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppConstants.spacingS),
        if (items.isNotEmpty) ...[
          Wrap(
            spacing: AppConstants.spacingS,
            runSpacing: AppConstants.spacingS,
            children: items
                .map((item) => Chip(
                      label: Text(item),
                      onDeleted: () => onRemove(item),
                      backgroundColor:
                          AppConstants.primaryColor.withOpacity(0.08),
                      labelStyle: AppTextStyles.bodyMedium,
                    ))
                .toList(),
          ),
          const SizedBox(height: AppConstants.spacingS),
        ],
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    onAdd(value.trim());
                    controller.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  onAdd(controller.text.trim());
                  controller.clear();
                }
              },
              tooltip: 'Add',
            ),
          ],
        ),
      ],
    );
  }
}
