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

class _AddTagButton extends StatelessWidget {
  const _AddTagButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppConstants.primaryColor,
      borderRadius: BorderRadius.circular(AppConstants.radiusS),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: const SizedBox(
          height: 36,
          width: 36,
          child: Icon(
            Icons.add_rounded,
            color: AppConstants.surfaceColor,
            size: 20,
          ),
        ),
      ),
    );
  }
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
      });
      FocusScope.of(context).unfocus();
      _markAsChanged();
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
      });
      FocusScope.of(context).unfocus();
      _markAsChanged();
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
      });
      FocusScope.of(context).unfocus();
      _markAsChanged();
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Text(
        title,
        style: AppTextStyles.heading5.copyWith(
          fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
        vertical: AppConstants.spacingS,
      ),
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
            '${calculatedTargets?.dailyTarget ?? "Calculating..."} cal',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppConstants.primaryColor,
            ),
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
                style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }

  Widget _buildPreferredCuisinesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTagInputCard(
          label: 'Add cuisine',
          hintText: 'Type a cuisine and press enter',
          controller: _cuisineController,
          onAdd: _addCuisine,
        ),
        const SizedBox(height: AppConstants.spacingS),
        if (_preferredCuisines.isNotEmpty)
          Wrap(
            spacing: AppConstants.spacingS,
            runSpacing: AppConstants.spacingS,
            children: _preferredCuisines.map((cuisine) {
              return _buildTagChip(
                label: cuisine,
                color: AppConstants.primaryColor,
                onDeleted: () => _removeCuisine(cuisine),
              );
            }).toList(),
          ),
        if (_preferredCuisines.isEmpty)
          Text(
            'Add the cuisines you enjoy to personalize recommendations.',
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.textTertiary,
            ),
          ),
      ],
    );
  }

  Widget _buildFoodsToAvoidSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTagInputCard(
          label: 'Add food to avoid',
          hintText: 'e.g. shellfish',
          controller: _avoidController,
          onAdd: _addFoodToAvoid,
        ),
        const SizedBox(height: AppConstants.spacingS),
        if (_foodsToAvoid.isNotEmpty)
          Wrap(
            spacing: AppConstants.spacingS,
            runSpacing: AppConstants.spacingS,
            children: _foodsToAvoid.map((food) {
              return _buildTagChip(
                label: food,
                color: AppConstants.errorColor,
                onDeleted: () => _removeFoodToAvoid(food),
              );
            }).toList(),
          ),
        if (_foodsToAvoid.isEmpty)
          Text(
            'Highlight ingredients you want us to leave out.',
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.textTertiary,
            ),
          ),
      ],
    );
  }

  Widget _buildFavoriteFoodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTagInputCard(
          label: 'Add favorite food',
          hintText: 'e.g. salmon, quinoa bowl',
          controller: _favoriteController,
          onAdd: _addFavoriteFood,
        ),
        const SizedBox(height: AppConstants.spacingS),
        if (_favoriteFoods.isNotEmpty)
          Wrap(
            spacing: AppConstants.spacingS,
            runSpacing: AppConstants.spacingS,
            children: _favoriteFoods.map((food) {
              return _buildTagChip(
                label: food,
                color: AppConstants.successColor,
                onDeleted: () => _removeFavoriteFood(food),
              );
            }).toList(),
          ),
        if (_favoriteFoods.isEmpty)
          Text(
            'Save the meals you love so we can surface them more often.',
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.textTertiary,
            ),
          ),
      ],
    );
  }

  Widget _buildTagInputCard({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required VoidCallback onAdd,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppConstants.borderColor.withOpacity(0.6),
        ),
        boxShadow: AppConstants.shadowS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            decoration: _buildTagInputDecoration(
              hintText: hintText,
              onAdd: onAdd,
            ),
            onSubmitted: (_) => onAdd(),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildTagInputDecoration({
    required String hintText,
    required VoidCallback onAdd,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.bodySmall.copyWith(
        color: AppConstants.textTertiary,
      ),
      filled: true,
      fillColor: AppConstants.backgroundColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
        vertical: AppConstants.spacingS + 2,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: BorderSide(
          color: AppConstants.borderColor.withOpacity(0.6),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: BorderSide(
          color: AppConstants.borderColor.withOpacity(0.4),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: const BorderSide(
          color: AppConstants.primaryColor,
        ),
      ),
      suffixIcon: Padding(
        padding: const EdgeInsets.only(right: AppConstants.spacingS),
        child: _AddTagButton(onPressed: onAdd),
      ),
      suffixIconConstraints: const BoxConstraints(
        minHeight: 40,
        minWidth: 40,
      ),
    );
  }

  Widget _buildTagChip({
    required String label,
    required Color color,
    required VoidCallback onDeleted,
  }) {
    return Chip(
      label: Text(label),
      onDeleted: onDeleted,
      deleteIcon: Icon(
        Icons.close_rounded,
        size: 16,
        color: Colors.grey.withOpacity(0.8),
      ),
      backgroundColor: Colors.white,
      labelStyle: AppTextStyles.bodySmall,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: AppConstants.spacingXS,
      ),
      visualDensity: VisualDensity.compact,
      side: BorderSide(
        color: Colors.grey.withOpacity(0.18),
      ),
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
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingL,
              vertical: AppConstants.spacingM,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: isSelected
                    ? AppConstants.primaryColor
                    : AppConstants.textTertiary.withOpacity(0.1),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppConstants.primaryColor
                              : AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingXS),
                      Text(subtitle, style: AppTextStyles.caption),
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
