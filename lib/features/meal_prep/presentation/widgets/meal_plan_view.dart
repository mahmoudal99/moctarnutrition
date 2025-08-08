import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/meal_model.dart';
import 'meal_card.dart';
import 'nutrition_summary_card.dart';

class MealPlanView extends StatefulWidget {
  final MealPlanModel mealPlan;
  final VoidCallback? onMealTap;

  const MealPlanView({
    super.key,
    required this.mealPlan,
    this.onMealTap,
  });

  @override
  State<MealPlanView> createState() => _MealPlanViewState();
}

class _MealPlanViewState extends State<MealPlanView>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late ScrollController _scrollController;
  late AnimationController _nutritionAnimationController;
  late Animation<double> _nutritionScaleAnimation;
  late Animation<double> _nutritionOpacityAnimation;
  late Animation<double> _pillOpacityAnimation;
  late Animation<double> _pillScaleAnimation;
  
  int _currentDayIndex = 0;
  double _scrollOffset = 0.0;
  static const double _scrollThreshold = 50.0;

  @override
  void initState() {
    super.initState();
    _currentDayIndex = _getCurrentDayIndex();
    // Start with the current day index for circular scrolling
    _pageController = PageController(initialPage: _currentDayIndex);
    
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
    _pageController.dispose();
    _scrollController.dispose();
    _nutritionAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
    
    if (_scrollOffset > _scrollThreshold && _nutritionAnimationController.value == 0) {
      _nutritionAnimationController.forward();
    } else if (_scrollOffset <= _scrollThreshold && _nutritionAnimationController.value == 1) {
      _nutritionAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main scrollable content
        SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              // Day indicator
              _buildDayIndicator(),

              // Day-specific nutrition summary
              AnimatedBuilder(
                animation: _nutritionAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 - (_nutritionScaleAnimation.value * 0.1),
                    child: Opacity(
                      opacity: _nutritionOpacityAnimation.value,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingL,
                            vertical: AppConstants.spacingS),
                        child: NutritionSummaryCard(
                          mealDay: widget.mealPlan.mealDays[_currentDayIndex],
                          dayNumber: _currentDayIndex + 1,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Swipeable day content
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 1, // Use 60% of screen height
                ),
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentDayIndex = index;
                    });
                  },
                  itemCount: widget.mealPlan.mealDays.length,
                  itemBuilder: (context, index) {
                    final mealDay = widget.mealPlan.mealDays[index];
                    return SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(), // Disable content scrolling only
                      child: _buildDayContent(mealDay, index + 1),
                    );
                  },
                ),
              ),
              
              // Add bottom padding for scroll space
              const SizedBox(height: 100),
            ],
          ),
        ),
        
        // Floating pill nutrition summary
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
                    child: _buildPillNutritionSummary(),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPillNutritionSummary() {
    final mealDay = widget.mealPlan.mealDays[_currentDayIndex];
    final totalCalories = mealDay.meals.fold<double>(
      0, (sum, meal) => sum + meal.nutrition.calories);
    final totalProtein = mealDay.meals.fold<double>(
      0, (sum, meal) => sum + meal.nutrition.protein);
    final totalCarbs = mealDay.meals.fold<double>(
      0, (sum, meal) => sum + meal.nutrition.carbs);

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
            '${totalCalories.toInt()}',
            AppConstants.accentColor,
          ),
          const SizedBox(width: AppConstants.spacingM),
          _buildPillNutritionItem(
            Icons.fitness_center,
            '${totalProtein.toStringAsFixed(1)}g',
            AppConstants.successColor,
          ),
          const SizedBox(width: AppConstants.spacingM),
          _buildPillNutritionItem(
            Icons.grain,
            '${totalCarbs.toStringAsFixed(1)}g',
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

  Widget _buildDayIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingL,
        vertical: AppConstants.spacingM,
      ),
      child: Column(
        children: [
          // Day title
          Text(
            _getDayTitle(_currentDayIndex),
            style: AppTextStyles.heading4,
          ),
          const SizedBox(height: AppConstants.spacingS),

          // Day dots indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.mealPlan.mealDays.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentDayIndex
                      ? AppConstants.primaryColor
                      : AppConstants.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayContent(MealDay mealDay, int dayNumber) {
    // Group meals by type
    final Map<MealType, List<Meal>> mealsByType = {};
    for (final meal in mealDay.meals) {
      mealsByType.putIfAbsent(meal.type, () => []).add(meal);
    }

    // Define the order of meal types
    const mealTypeOrder = [
      MealType.breakfast,
      MealType.lunch,
      MealType.dinner,
      MealType.snack,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meals grouped by type with section titles in correct order
          ...mealTypeOrder
              .where((mealType) => mealsByType.containsKey(mealType))
              .map((mealType) {
            final meals = mealsByType[mealType]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section title
                _buildMealTypeSection(mealType),
                const SizedBox(height: AppConstants.spacingS),

                // Meals for this type
                ...meals.map((meal) => MealCard(
                      meal: meal,
                      dayTitle: _getDayTitle(dayNumber - 1),
                      onTap: widget.onMealTap,
                    )),

                const SizedBox(height: AppConstants.spacingM),
              ],
            );
          }),
        ],
      ),
    );
  }

  String _getDayTitle(int dayIndex) {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    if (dayIndex < days.length) {
      return days[dayIndex];
    }
    return 'Day ${dayIndex + 1}';
  }

  Widget _buildMealTypeSection(MealType mealType) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppConstants.spacingS,
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            "assets/images/${_getMealTypeIcon(mealType)}",
            colorFilter: ColorFilter.mode(_getMealTypeColor(mealType), BlendMode.srcIn),
            height: 20,
          ),
          const SizedBox(width: AppConstants.spacingS),
          Text(
            _getMealTypeTitle(mealType),
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _getMealTypeTitle(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  Color _getMealTypeColor(MealType mealType) {
    switch (mealType) {
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

  String _getMealTypeIcon(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return "eggs.svg";
      case MealType.lunch:
        return "lunch.svg";
      case MealType.dinner:
        return "dinner.svg";
      case MealType.snack:
        return "lunch.svg";
    }
  }

  int _getCurrentDayIndex() {
    final now = DateTime.now();
    // DateTime.weekday returns 1 (Monday) to 7 (Sunday)
    // We want 0 (Monday) to 6 (Sunday)
    final currentDayIndex = now.weekday - 1;

    // Ensure the day index is within the bounds of available meal days
    if (currentDayIndex < widget.mealPlan.mealDays.length) {
      return currentDayIndex;
    }

    // If current day is beyond available meal days, show the first day
    return 0;
  }
}
