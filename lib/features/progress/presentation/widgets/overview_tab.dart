import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/progress_service.dart';
import '../../../../shared/widgets/bmi_widget.dart';
import '../../../../shared/widgets/weight_progress_widget.dart';
import '../../../../shared/widgets/weight_chart_widget.dart';

class OverviewTab extends StatelessWidget {
  final Future<OverviewData>? dataFuture;
  final Function(int)? onWeekSelected;
  final int selectedWeekOffset;
  final ScrollController? scrollController;

  const OverviewTab({
    super.key,
    this.dataFuture,
    this.onWeekSelected,
    this.selectedWeekOffset = 0,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OverviewData>(
      future: dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppConstants.errorColor),
                const SizedBox(height: AppConstants.spacingM),
                Text(
                  'Failed to load overview data',
                  style: AppTextStyles.body1
                      .copyWith(color: AppConstants.errorColor),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data ?? OverviewData.empty();

        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Streak and Weight cards on same row
              Row(
                children: [
                  Expanded(child: StreakCard(dataFuture: dataFuture)),
                  const SizedBox(width: AppConstants.spacingM),
                  Expanded(
                    child: FutureBuilder<OverviewData>(
                      future: dataFuture,
                      builder: (context, snapshot) {
                        final data = snapshot.data ?? OverviewData.empty();
                        return WeightProgressWidget(
                          weightProgress: data.weightProgress,
                          title: 'My Weight',
                          showCheckinInfo: true,
                          showChart: false,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingM),

              // Goal Progress Line Graph - EXACTLY as shown
              GoalProgressGraph(dataFuture: dataFuture),
              const SizedBox(height: AppConstants.spacingM),

              // BMI Widget - EXACTLY as shown
              TotalCaloriesCard(
                dataFuture: dataFuture,
                selectedWeekOffset: selectedWeekOffset,
                onWeekSelected: onWeekSelected,
              ),
              const SizedBox(height: AppConstants.spacingM),
              // Total Calories Card - EXACTLY as shown
              FutureBuilder<OverviewData>(
                future: dataFuture,
                builder: (context, snapshot) {
                  final data = snapshot.data ?? OverviewData.empty();
                  return BMIWidget(bmiData: data.bmiData);
                },
              ),
              const SizedBox(height: AppConstants.spacingL),
            ],
          ),
        );
      },
    );
  }
}

// Streak Card - EXACTLY matching screenshot
class StreakCard extends StatelessWidget {
  final Future<OverviewData>? dataFuture;

  const StreakCard({super.key, this.dataFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OverviewData>(
      future: dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            height: 200,
            // Fixed height for consistency
            padding: const EdgeInsets.all(AppConstants.spacingL),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
              boxShadow: AppConstants.shadowM,
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data ?? OverviewData.empty();
        final currentStreak = data.streak.currentStreak;
        final isActive = data.streak.isActive;
        final lastCompletedDate = data.streak.lastCompletedDate;

        return Container(
          width: double.infinity,
          height: 200,
          // Fixed height for consistency
          padding: const EdgeInsets.all(AppConstants.spacingL),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            boxShadow: AppConstants.shadowM,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Day Streak',
                    style: AppTextStyles.body1.copyWith(
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(
                    Icons.local_fire_department,
                    color: AppConstants.warningColor,
                    size: 32,
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingS),
              // Reduced spacing
              Text(
                '$currentStreak',
                style: AppTextStyles.heading1.copyWith(
                  color: AppConstants.warningColor,
                ),
              ),
              Text(
                'days',
                style: AppTextStyles.body1.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingS),
              // Reduced spacing
              Expanded(
                  child: WeekProgressIndicator(
                      lastCompletedDate: lastCompletedDate,
                      currentStreak: currentStreak)),
              // Use Expanded to fill remaining space
            ],
          ),
        );
      },
    );
  }
}

// Week progress indicator - EXACTLY as shown
class WeekProgressIndicator extends StatelessWidget {
  final DateTime? lastCompletedDate;
  final int currentStreak;

  const WeekProgressIndicator({
    super.key,
    this.lastCompletedDate,
    required this.currentStreak,
  });

  @override
  Widget build(BuildContext context) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    // Calculate which days should be highlighted based on the streak
    return Row(
      children: days.asMap().entries.map((entry) {
        final index = entry.key;
        final day = entry.value;

        // Calculate if this day should be completed
        // Monday = 0, Tuesday = 1, ..., Sunday = 6
        // For a 2-day streak ending on Monday (today), highlight Monday (index 0) and Sunday (index 6)
        bool isCompleted = false;

        if (currentStreak > 0) {
          // Get today's weekday (1 = Monday, 7 = Sunday)
          final today = DateTime.now();
          final todayWeekday = today.weekday; // 1 = Monday, 7 = Sunday

          // Convert to 0-based index for our array
          final todayIndex = todayWeekday - 1; // Monday = 0, Sunday = 6

          // Calculate which days in the past should be highlighted
          // For a 2-day streak, highlight today and yesterday
          final daysToHighlight = currentStreak;

          // Check if this index represents a day that should be highlighted
          // We need to go back from today by the streak count
          for (int i = 0; i < daysToHighlight; i++) {
            final targetWeekday = todayWeekday - i;
            final targetIndex =
                (targetWeekday - 1 + 7) % 7; // Handle negative numbers

            if (index == targetIndex) {
              isCompleted = true;
              break;
            }
          }
        }

        return Expanded(
          child: Container(
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            // 1px margin between circles
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? AppConstants.warningColor
                  : AppConstants.borderColor,
            ),
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  color: isCompleted
                      ? AppConstants.surfaceColor
                      : AppConstants.textTertiary,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}



// Goal Progress Line Graph - EXACTLY as shown in screenshot
class GoalProgressGraph extends StatelessWidget {
  final Future<OverviewData>? dataFuture;

  const GoalProgressGraph({super.key, this.dataFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OverviewData>(
      future: dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            height: 200,
            padding: const EdgeInsets.all(AppConstants.spacingL),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
              boxShadow: AppConstants.shadowM,
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data ?? OverviewData.empty();
        final weightProgress = data.weightProgress;
        final progressPercentage = weightProgress?.progressPercentage ?? 0.0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.spacingL),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            boxShadow: AppConstants.shadowM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Goal Progress',
                    style: AppTextStyles.body1.copyWith(
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.flag,
                        size: 16,
                        color: AppConstants.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${progressPercentage.toStringAsFixed(0)}% of goal',
                        style: AppTextStyles.body2.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingL),
              WeightChartWidget(
                weightProgress: weightProgress,
                height: 200,
              ),
              const SizedBox(height: AppConstants.spacingM),
            ],
          ),
        );
      },
    );
  }
}




// Total Calories Card - EXACTLY as shown in screenshot
class TotalCaloriesCard extends StatelessWidget {
  final Future<OverviewData>? dataFuture;
  final int selectedWeekOffset;
  final Function(int)? onWeekSelected;

  const TotalCaloriesCard({
    super.key,
    this.dataFuture,
    required this.selectedWeekOffset,
    this.onWeekSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OverviewData>(
      future: dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.spacingL),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
              boxShadow: AppConstants.shadowM,
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data ?? OverviewData.empty();
        final dailyCalories = data.dailyCalories;
        if (dailyCalories.dailyData.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.spacingL),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
              boxShadow: AppConstants.shadowM,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Calories',
                  style: AppTextStyles.body1.copyWith(
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                Text(
                  'No data',
                  style: AppTextStyles.body2.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                Text(
                  'Complete your first check-in to track calories',
                  style: AppTextStyles.caption.copyWith(
                    color: AppConstants.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Weekly Filters
            WeekFilters(
              selectedWeekOffset: selectedWeekOffset,
              onWeekSelected: onWeekSelected,
            ),
            const SizedBox(height: AppConstants.spacingM),
            // Calories Card
            CaloriesCard(dailyCalories: dailyCalories),
          ],
        );
      },
    );
  }
}

class WeekFilters extends StatelessWidget {
  final int selectedWeekOffset;
  final Function(int)? onWeekSelected;

  const WeekFilters({
    super.key,
    required this.selectedWeekOffset,
    this.onWeekSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        color: AppConstants.borderColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Row(
        children: [
          Expanded(
              child: WeekFilter(
                  label: 'This Week',
                  weekOffset: 0,
                  isSelected: selectedWeekOffset == 0,
                  onTap: onWeekSelected)),
          Container(
            width: 1,
            height: 20,
            color: AppConstants.borderColor.withOpacity(0.5),
          ),
          Expanded(
              child: WeekFilter(
                  label: 'Last Week',
                  weekOffset: 1,
                  isSelected: selectedWeekOffset == 1,
                  onTap: onWeekSelected)),
          Container(
            width: 1,
            height: 20,
            color: AppConstants.borderColor.withOpacity(0.5),
          ),
          Expanded(
              child: WeekFilter(
                  label: '2 Wks Ago',
                  weekOffset: 2,
                  isSelected: selectedWeekOffset == 2,
                  onTap: onWeekSelected)),
          Container(
            width: 1,
            height: 20,
            color: AppConstants.borderColor.withOpacity(0.5),
          ),
          Expanded(
              child: WeekFilter(
                  label: '3 Wks Ago',
                  weekOffset: 3,
                  isSelected: selectedWeekOffset == 3,
                  onTap: onWeekSelected)),
        ],
      ),
    );
  }
}

class WeekFilter extends StatelessWidget {
  final String label;
  final int weekOffset;
  final bool isSelected;
  final Function(int)? onTap;

  const WeekFilter({
    super.key,
    required this.label,
    required this.weekOffset,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!(weekOffset);
        }
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.body2.copyWith(
              color: Colors.black,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class CaloriesCard extends StatelessWidget {
  final DailyCaloriesData dailyCalories;

  const CaloriesCard({super.key, required this.dailyCalories});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: AppConstants.shadowM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Calories',
            style: AppTextStyles.body1.copyWith(
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Row(
            children: [
              Text(
                dailyCalories.weeklyTotal.toStringAsFixed(0),
                style: AppTextStyles.heading2.copyWith(
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(width: AppConstants.spacingS),
              Text(
                'cals',
                style: AppTextStyles.body1.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          SizedBox(
            height: 200,
            child: CaloriesChart(dailyData: dailyCalories.dailyData),
          ),
          const SizedBox(height: AppConstants.spacingM),
          const CaloriesLegend(),
        ],
      ),
    );
  }
}

// Calories chart - EXACTLY as shown in screenshot
class CaloriesChart extends StatelessWidget {
  final List<DailyCaloriesPoint> dailyData;

  const CaloriesChart({super.key, required this.dailyData});

  @override
  Widget build(BuildContext context) {
    // Calculate the maximum calories for proper scaling
    final maxCalories = dailyData.isNotEmpty
        ? dailyData
            .map((d) => d.totalCalories)
            .reduce((a, b) => a > b ? a : b)
            .clamp(500.0, 2000.0)
        : 1500.0;

    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${maxCalories.toInt()}', style: AppTextStyles.caption),
              Text('${(maxCalories * 0.67).toInt()}',
                  style: AppTextStyles.caption),
              Text('${(maxCalories * 0.33).toInt()}',
                  style: AppTextStyles.caption),
              Text('0', style: AppTextStyles.caption),
            ],
          ),
        ),
        const SizedBox(width: AppConstants.spacingS),
        Expanded(
          child: Stack(
            children: [
              // Grid lines
              ...List.generate(4, (index) {
                final y = (index / 3) * 200;
                return Positioned(
                  top: y,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      color: AppConstants.borderColor.withOpacity(0.3),
                    ),
                  ),
                );
              }),
              // Bars - Use real consumption data
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: dailyData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final dayData = entry.value;

                  // Get the day abbreviation from the actual date
                  final dayAbbreviation =
                      _getDayAbbreviation(dayData.date.weekday);

                  // DEBUG: Log the date matching

                  if (dayData.totalCalories == 0) {
                    return SizedBox(
                      width: 20,
                      height: 200, // Match the container height
                      child: Column(
                        children: [
                          // Empty bar area (just a line)
                          Expanded(
                            child: SizedBox(
                              width: 20,
                              child: Center(
                                child: Container(
                                  width: 20,
                                  height: 1,
                                  color:
                                      AppConstants.borderColor.withOpacity(0.3),
                                ),
                              ),
                            ),
                          ),
                          // Day label at the bottom
                          Text(
                            dayAbbreviation,
                            style: AppTextStyles.caption,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  // Calculate bar heights based on actual consumed calories
                  final totalHeight =
                      (dayData.totalCalories / maxCalories) * 200;

                  // Calculate individual macro heights (convert from calories to height)
                  final proteinHeight =
                      (dayData.proteinCalories / maxCalories) * 200;
                  final carbsHeight =
                      (dayData.carbsCalories / maxCalories) * 200;
                  final fatsHeight = (dayData.fatsCalories / maxCalories) * 200;

                  return SizedBox(
                    width: 20,
                    height: 200, // Match the container height
                    child: Column(
                      children: [
                        // Stacked nutrition bars using real consumption data with clear divisions
                        Expanded(
                          child: SizedBox(
                            width: 20,
                            child: Stack(
                              children: [
                                // Protein (bottom)
                                if (proteinHeight > 0)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    child: Container(
                                      width: 20,
                                      height: proteinHeight.clamp(0, 200),
                                      decoration: const BoxDecoration(
                                        color: AppConstants.proteinColor,
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(2),
                                          bottomRight: Radius.circular(2),
                                        ),
                                      ),
                                    ),
                                  ),
                                // Carbs (middle)
                                if (carbsHeight > 0)
                                  Positioned(
                                    bottom: proteinHeight.clamp(0, 200),
                                    left: 0,
                                    child: Container(
                                      width: 20,
                                      height: carbsHeight.clamp(0, 200),
                                      decoration: const BoxDecoration(
                                        color: AppConstants.carbsColor,
                                      ),
                                    ),
                                  ),
                                // Fats (top)
                                if (fatsHeight > 0)
                                  Positioned(
                                    bottom: (proteinHeight + carbsHeight)
                                        .clamp(0, 200),
                                    left: 0,
                                    child: Container(
                                      width: 20,
                                      height: fatsHeight.clamp(0, 200),
                                      decoration: const BoxDecoration(
                                        color: AppConstants.fatColor,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(2),
                                          topRight: Radius.circular(2),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // Day label at the bottom
                        Text(
                          dayAbbreviation,
                          style: AppTextStyles.caption,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Get day abbreviation from weekday number
  String _getDayAbbreviation(int weekday) {
    switch (weekday) {
      case 1:
        return 'M'; // Monday
      case 2:
        return 'T'; // Tuesday
      case 3:
        return 'W'; // Wednesday
      case 4:
        return 'T'; // Thursday
      case 5:
        return 'F'; // Friday
      case 6:
        return 'S'; // Saturday
      case 7:
        return 'S'; // Sunday
      default:
        return '?';
    }
  }
}

class CaloriesLegend extends StatelessWidget {
  const CaloriesLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        LegendItem(label: 'Protein', color: AppConstants.proteinColor),
        LegendItem(label: 'Carbs', color: AppConstants.carbsColor),
        LegendItem(label: 'Fats', color: AppConstants.fatColor),
      ],
    );
  }
}
