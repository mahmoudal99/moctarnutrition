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
  final TextEditingController _targetCaloriesController =
      TextEditingController();
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

    // Initialize controllers
    _targetCaloriesController.text = _preferences.targetCalories.toString();

    // Initialize lists
    _selectedDietaryRestrictions = List.from(_preferences.dietaryRestrictions);
    _preferredCuisines = List.from(_preferences.preferredCuisines);
    _foodsToAvoid = List.from(_preferences.foodsToAvoid);
    _favoriteFoods = List.from(_preferences.favoriteFoods);
  }

  @override
  void dispose() {
    _targetCaloriesController.dispose();
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
      // Validate target calories
      final targetCalories = int.tryParse(_targetCaloriesController.text);
      if (targetCalories == null ||
          targetCalories < 1000 ||
          targetCalories > 5000) {
        throw Exception('Target calories must be between 1000 and 5000');
      }

      // Create updated preferences
      final updatedPreferences = _preferences.copyWith(
        dietaryRestrictions: _selectedDietaryRestrictions,
        targetCalories: targetCalories,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: Text(
        title,
        style: AppTextStyles.heading5.copyWith(
          color: AppConstants.textPrimary,
        ),
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
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Target Calories',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          if (calculatedTargets != null) ...[
            Text(
              'Calculated Target: ${calculatedTargets.dailyTarget} calories',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
            Text(
              'Based on your metrics (BMR: ${calculatedTargets.rmr}, TDEE: ${calculatedTargets.tdee})',
              style: AppTextStyles.caption.copyWith(
                color: AppConstants.textTertiary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
          ],
          TextField(
            controller: _targetCaloriesController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: calculatedTargets != null 
                ? 'Override calculated target (1000-5000)'
                : 'Enter target calories (1000-5000)',
              border: const OutlineInputBorder(),
              helperText: 'Leave empty to use calculated target',
            ),
            onChanged: (value) {
              if (value.isEmpty && calculatedTargets != null) {
                _targetCaloriesController.text = calculatedTargets.dailyTarget.toString();
              }
              _markAsChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreferredCuisinesSection() {
    return Column(
      children: [
        // Add new cuisine
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cuisineController,
                decoration: const InputDecoration(
                  hintText: 'Add a cuisine',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _addCuisine(),
              ),
            ),
            const SizedBox(width: AppConstants.spacingS),
            ElevatedButton(
              onPressed: _addCuisine,
              child: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingM),
        // Selected cuisines
        if (_preferredCuisines.isNotEmpty)
          Wrap(
            spacing: AppConstants.spacingS,
            runSpacing: AppConstants.spacingS,
            children: _preferredCuisines.map((cuisine) {
              return Chip(
                label: Text(cuisine),
                onDeleted: () => _removeCuisine(cuisine),
                deleteIcon: const Icon(Icons.close, size: 18),
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
                decoration: const InputDecoration(
                  hintText: 'Add a food to avoid',
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  hintText: 'Add a favorite food',
                  border: OutlineInputBorder(),
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
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppConstants.primaryColor.withOpacity(0.08)
                  : AppConstants.surfaceColor,
              border: Border.all(
                color: isSelected
                    ? AppConstants.primaryColor.withOpacity(0.3)
                    : AppConstants.textTertiary.withOpacity(0.2),
                width: isSelected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              boxShadow: isSelected ? AppConstants.shadowS : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppConstants.primaryColor
                        : AppConstants.textTertiary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? AppConstants.surfaceColor
                        : AppConstants.textSecondary,
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
