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

class _MealPlanViewState extends State<MealPlanView> {
  late PageController _pageController;
  int _currentDayIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentDayIndex = _getCurrentDayIndex();
    // Start with the current day index for circular scrolling
    _pageController = PageController(initialPage: _currentDayIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Day indicator
        _buildDayIndicator(),

        // Day-specific nutrition summary
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingL,
              vertical: AppConstants.spacingS),
          child: NutritionSummaryCard(
            mealDay: widget.mealPlan.mealDays[_currentDayIndex],
            dayNumber: _currentDayIndex + 1,
          ),
        ),

        // Swipeable day content
        Expanded(
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
              return _buildDayContent(mealDay, index + 1);
            },
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

    return SingleChildScrollView(
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

          // Add some bottom padding
          const SizedBox(height: 128),
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
