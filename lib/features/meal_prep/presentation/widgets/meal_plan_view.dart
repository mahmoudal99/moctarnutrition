import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/meal_model.dart';
import '../../../../shared/models/user_model.dart';
import 'meal_card.dart';
import 'nutrition_summary_card.dart';
import 'package:provider/provider.dart';
import '../../../../shared/providers/meal_plan_provider.dart';
import '../../../../shared/services/streak_service.dart';
import '../../../../shared/services/daily_consumption_service.dart';
import '../../../../shared/providers/auth_provider.dart';

class MealPlanView extends StatefulWidget {
  final MealPlanModel mealPlan;
  final VoidCallback? onMealTap;
  final UserModel? user; // Add user parameter for cheat day info
  final String? cheatDay; // Add cheat day parameter
  final DateTime?
      selectedDate; // Add selected date parameter for consumption tracking

  const MealPlanView({
    super.key,
    required this.mealPlan,
    this.onMealTap,
    this.user, // Add user parameter
    this.cheatDay, // Add cheat day parameter
    this.selectedDate, // Add selected date parameter
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
  late List<MealDay?> _weeklyMealDays;
  int? _cheatDayIndex;
  DateTime? _planAnchorDate;

  @override
  void initState() {
    super.initState();
    _cheatDayIndex = _convertCheatDayToIndex(widget.cheatDay);
    debugPrint(
        'MealPlanView - cheatDay: ${widget.cheatDay}, _cheatDayIndex: $_cheatDayIndex');
    _planAnchorDate = _determinePlanAnchorDate(widget.mealPlan);
    _weeklyMealDays = _generateWeeklySchedule(widget.mealPlan);
    debugPrint(
        'MealPlanView - Generated schedule: ${_weeklyMealDays.map((day) => day != null ? "hasMeals" : "null").toList()}');
    _currentDayIndex = _getCurrentDayIndex();
    _currentDayIndex = _ensureValidInitialIndex(_currentDayIndex);
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

    // Load consumption data for the initial day
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConsumptionData();
    });

    // Add page change listener to load consumption data when switching days
    _pageController.addListener(() {
      if (_pageController.page != null) {
        final newIndex = _pageController.page!.round();
        if (newIndex != _currentDayIndex) {
          _currentDayIndex = newIndex;
          _loadConsumptionData();
        }
      }
    });
  }

  @override
  void didUpdateWidget(MealPlanView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update cheat day if it changed
    if (oldWidget.cheatDay != widget.cheatDay) {
      _cheatDayIndex = _convertCheatDayToIndex(widget.cheatDay);
      debugPrint(
          'MealPlanView - cheatDay updated: ${widget.cheatDay}, _cheatDayIndex: $_cheatDayIndex');
      // Regenerate schedule with new cheat day
      _weeklyMealDays = _generateWeeklySchedule(widget.mealPlan);
      debugPrint(
          'MealPlanView - Regenerated schedule: ${_weeklyMealDays.map((day) => day != null ? "hasMeals" : "null").toList()}');
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    _nutritionAnimationController.dispose();
    super.dispose();
  }

  /// Load consumption data for the current day and apply it to meals
  Future<void> _loadConsumptionData() async {
    if (_weeklyMealDays.isEmpty) return;

    final currentMealDay = _weeklyMealDays.length > _currentDayIndex
        ? _weeklyMealDays[_currentDayIndex]
        : null;
    if (currentMealDay == null) {
      return;
    }

    final targetDate = widget.selectedDate ?? _dateForIndex(_currentDayIndex);
    if (targetDate == null) {
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userModel?.id;

      if (userId != null) {
        final consumptionData =
            await DailyConsumptionService.getDailyConsumptionSummary(
          userId,
          targetDate,
        );

        if (consumptionData != null) {
          final mealConsumption =
              Map<String, bool>.from(consumptionData['mealConsumption'] ?? {});

          // Apply consumption data to the current day's meals
          for (final meal in currentMealDay.meals) {
            if (mealConsumption.containsKey(meal.id)) {
              meal.isConsumed = mealConsumption[meal.id]!;
            }
          }

          // Recalculate nutrition
          currentMealDay.calculateConsumedNutrition();

          // Trigger rebuild
          setState(() {});
        }
      }
    } catch (e) {}
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });

    if (_scrollOffset > _scrollThreshold &&
        _nutritionAnimationController.value == 0) {
      _nutritionAnimationController.forward();
    } else if (_scrollOffset <= _scrollThreshold &&
        _nutritionAnimationController.value == 1) {
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
                  final mealDay = (_weeklyMealDays.length > _currentDayIndex)
                      ? _weeklyMealDays[_currentDayIndex]
                      : null;
                  // Don't show nutrition summary on cheat days
                  final isCheatDay = _isCheatDay(_currentDayIndex);
                  if (isCheatDay || mealDay == null) {
                    return const SizedBox.shrink();
                  }
                  return Transform.scale(
                    scale: 1.0 - (_nutritionScaleAnimation.value * 0.1),
                    child: Opacity(
                      opacity: _nutritionOpacityAnimation.value,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingS,
                            vertical: AppConstants.spacingS),
                        child: NutritionSummaryCard(
                          mealDay: mealDay,
                          dayNumber: _currentDayIndex + 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 1.2,
                ),
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentDayIndex = index;
                    });
                  },
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final mealDay = index < _weeklyMealDays.length
                        ? _weeklyMealDays[index]
                        : null;
                    return SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      // Disable content scrolling only
                      child: _buildDayContent(mealDay, index),
                    );
                  },
                ),
              ),

              // Add bottom padding for scroll space
              const SizedBox(height: 128),
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
    if (_weeklyMealDays.isEmpty) return const SizedBox();

    final mealDay = _weeklyMealDays[_currentDayIndex];
    // Show cheat day pill if this is a cheat day, regardless of mealDay
    if (_isCheatDay(_currentDayIndex) || mealDay == null) {
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
            const Icon(
              Icons.celebration,
              size: 16,
              color: AppConstants.warningColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Cheat Day',
              style: AppTextStyles.caption.copyWith(
                color: AppConstants.warningColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final totalCalories = mealDay.meals
        .fold<double>(0, (sum, meal) => sum + meal.nutrition.calories);
    final totalProtein = mealDay.meals
        .fold<double>(0, (sum, meal) => sum + meal.nutrition.protein);
    final totalCarbs = mealDay.meals
        .fold<double>(0, (sum, meal) => sum + meal.nutrition.carbs);

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
            "fire-stroke-rounded.svg",
            '${totalCalories.toInt()}',
            AppConstants.accentColor,
          ),
          const SizedBox(width: AppConstants.spacingM),
          _buildPillNutritionItem(
            "fish-food-stroke.svg",
            '${totalProtein.toStringAsFixed(1)}g',
            AppConstants.successColor,
          ),
          const SizedBox(width: AppConstants.spacingM),
          _buildPillNutritionItem(
            "bread-stroke-rounded.svg",
            '${totalCarbs.toStringAsFixed(1)}g',
            AppConstants.warningColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPillNutritionItem(String icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          "assets/images/$icon",
          height: 16,
          width: 16,
          color: Colors.black,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            color: Colors.black,
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
      ),
      child: Column(
        children: [
          // Day title
          // Text(
          //   _getDayTitle(_currentDayIndex),
          //   style: AppTextStyles.heading4,
          // ),
          const SizedBox(height: AppConstants.spacingM),
          // Day dots indicator with letters
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              7,
              (index) => GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      // Day letter
                      Text(
                        _getDayLetter(index),
                        style: AppTextStyles.caption.copyWith(
                          color: index == _currentDayIndex
                              ? AppConstants.primaryColor
                              : AppConstants.textSecondary,
                          fontWeight: index == _currentDayIndex
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Enhanced dot
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: index == _currentDayIndex ? 12 : 8,
                        height: index == _currentDayIndex ? 12 : 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentDayIndex
                              ? AppConstants.primaryColor
                              : AppConstants.textTertiary.withOpacity(0.3),
                          boxShadow: index == _currentDayIndex
                              ? [
                                  BoxShadow(
                                    color: AppConstants.primaryColor
                                        .withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayContent(MealDay? mealDay, int dayIndex) {
    // Show cheat day content if this is a cheat day, regardless of mealDay
    if (_isCheatDay(dayIndex) || mealDay == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingL,
          vertical: AppConstants.spacingL,
        ),
        child: _buildCheatDayContent(),
      );
    }

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
                _buildMealTypeSection(mealType, meals, dayIndex),
                const SizedBox(height: AppConstants.spacingS),

                // Meals for this type
                ...meals.map((meal) => MealCard(
                      meal: meal,
                      dayTitle: _getDayTitle(dayIndex),
                      onTap: widget.onMealTap,
                      mealDay: mealDay, // Pass the mealDay
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

  String _getDayLetter(int dayIndex) {
    final dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    if (dayIndex < dayLetters.length) {
      return dayLetters[dayIndex];
    }
    // For plans longer than a week, cycle through the letters
    return dayLetters[dayIndex % 7];
  }

  Widget _buildMealTypeSection(
      MealType mealType, List<Meal> meals, int dayIndex) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppConstants.spacingS,
      ),
      child: Row(
        children: [
          Text(
            _getMealTypeTitle(mealType),
            style: AppTextStyles.heading5.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Mark Eaten button for the entire meal type section
          _buildMealTypeConsumptionButton(mealType, meals, dayIndex),
        ],
      ),
    );
  }

  Widget _buildMealTypeConsumptionButton(
      MealType mealType, List<Meal> meals, int dayIndex) {
    // Check if all meals of this type are consumed
    final allConsumed = meals.every((meal) => meal.isConsumed);
    final targetDate = widget.selectedDate ?? _dateForIndex(dayIndex);

    return GestureDetector(
      onTap: () async {
        if (targetDate == null) {
          return;
        }

        // Toggle consumption for all meals of this type
        final newStatus = !allConsumed;
        final mealPlanProvider =
            Provider.of<MealPlanProvider>(context, listen: false);

        for (final meal in meals) {
          mealPlanProvider.updateMealConsumption(
              meal.id, newStatus, targetDate);
        }

        // Increment streak when marking meals as done (only if not already done)
        if (newStatus && !allConsumed) {
          try {
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            final userId = authProvider.userModel?.id;

            if (userId != null) {
              // Use the selected date if available, otherwise use current date
              await StreakService.incrementStreak(userId);

              await StreakService.getCurrentStreak(userId);

              // Refresh consumption data to update the UI
              await _loadConsumptionData();
            }
          } catch (e) {}
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: allConsumed
              ? AppConstants.successColor.withOpacity(0.1)
              : AppConstants.warningColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: allConsumed
                ? AppConstants.successColor.withOpacity(0.3)
                : AppConstants.warningColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              allConsumed ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 12,
              color: allConsumed
                  ? AppConstants.successColor
                  : AppConstants.warningColor,
            ),
            const SizedBox(width: 4),
            Text(
              allConsumed ? 'Done' : 'Mark as Done',
              style: AppTextStyles.caption.copyWith(
                color: allConsumed
                    ? AppConstants.successColor
                    : AppConstants.warningColor,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
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

  Widget _buildCheatDayContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset("assets/images/pizza-02-stroke-rounded.svg"),
            const SizedBox(width: 10),
            Text(
              'Cheat Day',
              style: AppTextStyles.heading4.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingS),
        Text(
          'You’ve earned this enjoy your favorites guilt-free. Tomorrow, we get back on track stronger than ever!',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
      ],
    );
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
        return "snack.svg";
    }
  }

  int _getCurrentDayIndex() {
    final anchor = _planAnchorDate;
    final referenceDate = _normalizeDate(widget.selectedDate ?? DateTime.now());

    if (anchor == null) {
      final fallbackIndex = referenceDate.weekday - 1;
      return (fallbackIndex >= 0 && fallbackIndex < 7) ? fallbackIndex : 0;
    }

    final daysDifference = referenceDate.difference(anchor).inDays;
    final normalizedDiff = _positiveModulo(daysDifference, 7);
    final anchorIndex = anchor.weekday - 1;
    return (anchorIndex + normalizedDiff) % 7;
  }

  int _ensureValidInitialIndex(int index) {
    if (_weeklyMealDays.isEmpty) return index;

    final normalizedIndex = _positiveModulo(index, _weeklyMealDays.length);

    if (_weeklyMealDays[normalizedIndex] != null ||
        _isCheatDay(normalizedIndex)) {
      return normalizedIndex;
    }

    for (int i = 1; i < _weeklyMealDays.length; i++) {
      final candidate = (normalizedIndex + i) % _weeklyMealDays.length;
      if (_weeklyMealDays[candidate] != null || _isCheatDay(candidate)) {
        return candidate;
      }
    }

    return normalizedIndex;
  }

  List<MealDay?> _generateWeeklySchedule(MealPlanModel mealPlan) {
    final schedule = List<MealDay?>.filled(7, null);
    final sourceDays = mealPlan.mealDays;
    if (sourceDays.isEmpty) {
      return schedule;
    }

    final anchor = _planAnchorDate ?? _normalizeDate(mealPlan.startDate);
    final startIndex = anchor.weekday - 1;
    final nonCheatCount = _cheatDayIndex == null ? 7 : 6;
    final orderedIndices = <int>[];
    int pointer = startIndex;
    while (orderedIndices.length < nonCheatCount) {
      if (_cheatDayIndex == null || pointer != _cheatDayIndex) {
        if (!orderedIndices.contains(pointer)) {
          orderedIndices.add(pointer);
        }
      }
      pointer = (pointer + 1) % 7;
    }

    int sourceIndex = 0;
    for (final dayIndex in orderedIndices) {
      schedule[dayIndex] = sourceDays[sourceIndex % sourceDays.length];
      sourceIndex++;
    }

    // Explicitly ensure cheat day index is null
    if (_cheatDayIndex != null && _cheatDayIndex! >= 0 && _cheatDayIndex! < 7) {
      schedule[_cheatDayIndex!] = null;
    }

    return schedule;
  }

  int? _convertCheatDayToIndex(String? cheatDay) {
    if (cheatDay == null) return null;
    switch (cheatDay.toLowerCase()) {
      case 'monday':
        return 0;
      case 'tuesday':
        return 1;
      case 'wednesday':
        return 2;
      case 'thursday':
        return 3;
      case 'friday':
        return 4;
      case 'saturday':
        return 5;
      case 'sunday':
        return 6;
      default:
        return null;
    }
  }

  DateTime? _determinePlanAnchorDate(MealPlanModel mealPlan) {
    if (mealPlan.mealDays.isEmpty) return _normalizeDate(mealPlan.startDate);

    final sortedDates = mealPlan.mealDays
        .map((day) => _normalizeDate(day.date))
        .toList()
      ..sort();
    return sortedDates.first;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  int _positiveModulo(int value, int modulo) {
    final result = value % modulo;
    return result < 0 ? result + modulo : result;
  }

  DateTime? _dateForIndex(int index) {
    final anchor = _planAnchorDate;
    if (anchor == null) {
      return null;
    }
    final anchorIndex = anchor.weekday - 1;
    int diff = (index - anchorIndex) % 7;
    if (diff < 0) diff += 7;
    return anchor.add(Duration(days: diff));
  }

  /// Check if a given day index is a cheat day
  bool _isCheatDay(int dayIndex) {
    if (_cheatDayIndex == null) return false;
    final normalizedIndex = dayIndex % 7;
    final isCheat = normalizedIndex == _cheatDayIndex;
    if (isCheat) {
      debugPrint(
          'MealPlanView - Day index $dayIndex (normalized: $normalizedIndex) is a cheat day (cheatDayIndex: $_cheatDayIndex)');
    }
    return isCheat;
  }

  /// Get the cheat day icon widget
  Widget _buildCheatDayIcon() {
    return Tooltip(
      message: 'Cheat Day - Indulge a little!',
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppConstants.warningColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppConstants.warningColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.celebration,
          size: 16,
          color: AppConstants.warningColor,
        ),
      ),
    );
  }
}
