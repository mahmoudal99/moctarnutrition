import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/models/user_model.dart';

class NutritionPreferencesScreen extends StatefulWidget {
  const NutritionPreferencesScreen({super.key});

  @override
  State<NutritionPreferencesScreen> createState() =>
      _NutritionPreferencesScreenState();
}

class _NutritionPreferencesScreenState
    extends State<NutritionPreferencesScreen> {
  late UserModel _user;
  late UserPreferences _preferences;

  // Controllers for text fields
  Widget _buildMetricCard({
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXS),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(width: AppConstants.spacingXS),
              Text(
                unit,
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  final TextEditingController _cuisineController = TextEditingController();
  final TextEditingController _avoidController = TextEditingController();
  final TextEditingController _favoriteController = TextEditingController();

  // Lists for multi-select items
  late List<String> _selectedDietaryRestrictions;
  late List<String> _preferredCuisines;
  late List<String> _foodsToAvoid;
  late List<String> _favoriteFoods;

  bool _isLoading = false;
  bool _hasChanges = false;

  // Available options
  static const List<String> _dietaryRestrictions = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Dairy-Free',
    'Keto',
    'Paleo',
    'Low-Carb',
    'None',
  ];

  static const List<String> _cuisineOptions = [
    'Italian',
    'Mexican',
    'Chinese',
    'Indian',
    'Japanese',
    'Thai',
    'Mediterranean',
    'American',
    'French',
    'Greek',
    'Spanish',
    'Korean',
    'Vietnamese',
    'Lebanese',
    'Turkish',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _user = authProvider.userModel!;
    _preferences = _user.preferences;

    // Initialize lists
    _selectedDietaryRestrictions = List.from(_preferences.dietaryRestrictions);
    _preferredCuisines = List.from(_preferences.preferredCuisines);
    _foodsToAvoid = List.from(_preferences.foodsToAvoid);
    _favoriteFoods = List.from(_preferences.favoriteFoods);
  }

  @override
  void dispose() {
    _cuisineController.dispose();
    _avoidController.dispose();
    _favoriteController.dispose();
    super.dispose();
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _toggleDietaryRestriction(String restriction) {
    setState(() {
      if (_selectedDietaryRestrictions.contains(restriction)) {
        _selectedDietaryRestrictions.remove(restriction);
      } else {
        // If "None" is selected, remove it when selecting other options
        if (restriction != 'None') {
          _selectedDietaryRestrictions.remove('None');
        }
        // If selecting "None", remove all other restrictions
        if (restriction == 'None') {
          _selectedDietaryRestrictions.clear();
        }
        _selectedDietaryRestrictions.add(restriction);
      }
      _markAsChanged();
    });
  }

  void _addCuisine() {
    final cuisine = _cuisineController.text.trim();
    if (cuisine.isNotEmpty && !_preferredCuisines.contains(cuisine)) {
      setState(() {
        _preferredCuisines.add(cuisine);
        _cuisineController.clear();
        _markAsChanged();
      });
    }
  }

  void _removeCuisine(String cuisine) {
    setState(() {
      _preferredCuisines.remove(cuisine);
      _markAsChanged();
    });
  }

  void _addFoodToAvoid() {
    final food = _avoidController.text.trim();
    if (food.isNotEmpty && !_foodsToAvoid.contains(food)) {
      setState(() {
        _foodsToAvoid.add(food);
        _avoidController.clear();
        _markAsChanged();
      });
    }
  }

  void _removeFoodToAvoid(String food) {
    setState(() {
      _foodsToAvoid.remove(food);
      _markAsChanged();
    });
  }

  void _addFavoriteFood() {
    final food = _favoriteController.text.trim();
    if (food.isNotEmpty && !_favoriteFoods.contains(food)) {
      setState(() {
        _favoriteFoods.add(food);
        _favoriteController.clear();
        _markAsChanged();
      });
    }
  }

  void _removeFavoriteFood(String food) {
    setState(() {
      _favoriteFoods.remove(food);
      _markAsChanged();
    });
  }

  Future<void> _savePreferences() async {
    if (!_hasChanges) return;

    setState(() => _isLoading = true);

    try {
      // Create updated preferences
      final updatedPreferences = _preferences.copyWith(
        dietaryRestrictions: _selectedDietaryRestrictions,
        preferredCuisines: _preferredCuisines,
        foodsToAvoid: _foodsToAvoid,
        favoriteFoods: _favoriteFoods,
      );

      // Create updated user
      final updatedUser = _user.copyWith(
        preferences: updatedPreferences,
        updatedAt: DateTime.now(),
      );

      // Update in Firebase and local storage
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updateUserProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nutrition preferences updated successfully'),
            backgroundColor: AppConstants.successColor,
          ),
        );

        setState(() {
          _hasChanges = false;
        });

        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update preferences: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Nutrition Preferences'),
        backgroundColor: AppConstants.surfaceColor,
        elevation: 0,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _savePreferences,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dietary Restrictions Section
            _buildSectionHeader('Dietary Restrictions'),
            _buildDietaryRestrictionsSection(),

            const SizedBox(height: AppConstants.spacingL),

            // Target Calories Section
            _buildSectionHeader('Target Calories'),
            _buildTargetCaloriesSection(),

            const SizedBox(height: AppConstants.spacingL),

            // Preferred Cuisines Section
            _buildSectionHeader('Preferred Cuisines'),
            _buildPreferredCuisinesSection(),

            const SizedBox(height: AppConstants.spacingL),

            // Foods to Avoid Section
            _buildSectionHeader('Foods to Avoid'),
            _buildFoodsToAvoidSection(),

            const SizedBox(height: AppConstants.spacingL),

            // Favorite Foods Section
            _buildSectionHeader('Favorite Foods'),
            _buildFavoriteFoodsSection(),

            const SizedBox(height: 128),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXS),
          Container(
            width: 32,
            height: 2,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietaryRestrictionsSection() {
    return Column(
      children: _dietaryRestrictions.map((restriction) {
        final isSelected = _selectedDietaryRestrictions.contains(restriction);
        return _buildSelectionCard(
          title: restriction,
          subtitle: _getDietaryRestrictionDescription(restriction),
          icon: Icons.restaurant,
          isSelected: isSelected,
          onTap: () => _toggleDietaryRestriction(restriction),
        );
      }).toList(),
    );
  }

  Widget _buildTargetCaloriesSection() {
    final calculatedTargets = _preferences.calculatedCalorieTargets;
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Target Calories',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                  vertical: AppConstants.spacingS,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: Text(
                  '${calculatedTargets?.dailyTarget ?? "Calculating..."} cal',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          if (calculatedTargets != null) ...[
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    label: 'BMR',
                    value: '${calculatedTargets.rmr}',
                    unit: 'cal',
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: _buildMetricCard(
                    label: 'TDEE',
                    value: '${calculatedTargets.tdee}',
                    unit: 'cal',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Your daily calorie target is automatically calculated based on your metrics, activity level, and fitness goals.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreferredCuisinesSection() {
    return Column(
      children: [
        // Add new cuisine
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            border: Border.all(
              color: AppConstants.textTertiary.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Cuisine',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingS),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cuisineController,
                      decoration: InputDecoration(
                        hintText: 'Enter cuisine name',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppConstants.textTertiary,
                        ),
                        filled: true,
                        fillColor: AppConstants.backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusM),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingM,
                          vertical: AppConstants.spacingM,
                        ),
                      ),
                      onSubmitted: (_) => _addCuisine(),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingM),
                  ElevatedButton(
                    onPressed: _addCuisine,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingL,
                        vertical: AppConstants.spacingM,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      ),
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        // Selected cuisines
        if (_preferredCuisines.isNotEmpty)
          Wrap(
            spacing: AppConstants.spacingS,
            runSpacing: AppConstants.spacingS,
            children: _preferredCuisines.map((cuisine) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                  vertical: AppConstants.spacingS,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  border: Border.all(
                    color: AppConstants.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cuisine,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    InkWell(
                      onTap: () => _removeCuisine(cuisine),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        if (_preferredCuisines.isEmpty)
          Text(
            'No preferred cuisines added',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppConstants.textTertiary,
            ),
          ),
      ],
    );
  }

  Widget _buildFoodsToAvoidSection() {
    return Column(
      children: [
        // Add new food to avoid
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _avoidController,
                              decoration: InputDecoration(
                hintText: 'Enter food to avoid',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppConstants.textTertiary,
                ),
                filled: true,
                fillColor: AppConstants.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                  vertical: AppConstants.spacingM,
                ),
              ),
                onSubmitted: (_) => _addFoodToAvoid(),
              ),
            ),
            const SizedBox(width: AppConstants.spacingS),
            ElevatedButton(
              onPressed: _addFoodToAvoid,
              child: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingM),
        // Selected foods to avoid
        if (_foodsToAvoid.isNotEmpty)
          Wrap(
            spacing: AppConstants.spacingS,
            runSpacing: AppConstants.spacingS,
            children: _foodsToAvoid.map((food) {
              return Chip(
                label: Text(food),
                onDeleted: () => _removeFoodToAvoid(food),
                deleteIcon: const Icon(Icons.close, size: 18),
                backgroundColor: AppConstants.errorColor.withOpacity(0.1),
              );
            }).toList(),
          ),
        if (_foodsToAvoid.isEmpty)
          Text(
            'No foods to avoid added',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppConstants.textTertiary,
            ),
          ),
      ],
    );
  }

  Widget _buildFavoriteFoodsSection() {
    return Column(
      children: [
        // Add new favorite food
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _favoriteController,
                              decoration: InputDecoration(
                hintText: 'Enter favorite food',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppConstants.textTertiary,
                ),
                filled: true,
                fillColor: AppConstants.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                  vertical: AppConstants.spacingM,
                ),
              ),
                onSubmitted: (_) => _addFavoriteFood(),
              ),
            ),
            const SizedBox(width: AppConstants.spacingS),
            ElevatedButton(
              onPressed: _addFavoriteFood,
              child: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingM),
        // Selected favorite foods
        if (_favoriteFoods.isNotEmpty)
          Wrap(
            spacing: AppConstants.spacingS,
            runSpacing: AppConstants.spacingS,
            children: _favoriteFoods.map((food) {
              return Chip(
                label: Text(food),
                onDeleted: () => _removeFavoriteFood(food),
                deleteIcon: const Icon(Icons.close, size: 18),
                backgroundColor: AppConstants.successColor.withOpacity(0.1),
              );
            }).toList(),
          ),
        if (_favoriteFoods.isEmpty)
          Text(
            'No favorite foods added',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppConstants.textTertiary,
            ),
          ),
      ],
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingL,
              vertical: AppConstants.spacingM,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppConstants.primaryColor.withOpacity(0.05)
                  : AppConstants.surfaceColor,
              border: Border.all(
                color: isSelected
                    ? AppConstants.primaryColor
                    : AppConstants.textTertiary.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppConstants.primaryColor
                        : AppConstants.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? AppConstants.surfaceColor
                        : AppConstants.primaryColor,
                    size: 24,
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
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppConstants.primaryColor
                              : AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingXS),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isSelected
                      ? AppConstants.primaryColor
                      : AppConstants.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDietaryRestrictionDescription(String restriction) {
    switch (restriction) {
      case 'Vegetarian':
        return 'No meat, but includes dairy and eggs';
      case 'Vegan':
        return 'No animal products';
      case 'Gluten-Free':
        return 'No gluten-containing foods';
      case 'Dairy-Free':
        return 'No dairy products';
      case 'Keto':
        return 'Low-carb, high-fat diet';
      case 'Paleo':
        return 'Whole foods, no processed foods';
      case 'Low-Carb':
        return 'Reduced carbohydrate intake';
      case 'None':
        return 'No dietary restrictions';
      default:
        return '';
    }
  }
}
