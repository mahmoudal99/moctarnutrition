import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/progress_service.dart';
import '../../../../shared/services/streak_service.dart';
import 'package:google_fonts/google_fonts.dart';

class OverviewTab extends StatelessWidget {
  final Future<OverviewData>? dataFuture;
  final Function(int)? onWeekSelected;
  final int selectedWeekOffset;

  const OverviewTab({
    super.key, 
    this.dataFuture,
    this.onWeekSelected,
    this.selectedWeekOffset = 0,
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
                Icon(Icons.error_outline,
                    size: 48, color: AppConstants.errorColor),
                const SizedBox(height: 16),
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
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Streak and Weight cards on same row
              Row(
                children: [
                  Expanded(child: _buildStreakCard()),
                  const SizedBox(width: AppConstants.spacingM),
                  Expanded(child: _buildWeightProgressCard()),
                ],
              ),
              const SizedBox(height: AppConstants.spacingM),

              // Goal Progress Line Graph - EXACTLY as shown
              _buildGoalProgressGraph(),
              const SizedBox(height: AppConstants.spacingM),

              // BMI Widget - EXACTLY as shown
              _buildBMIWidget(),
              const SizedBox(height: AppConstants.spacingM),
              // Total Calories Card - EXACTLY as shown
              _buildTotalCaloriesCard(),
              const SizedBox(height: AppConstants.spacingL),
            ],
          ),
        );
      },
    );
  }

  // Streak Card - EXACTLY matching screenshot
  Widget _buildStreakCard() {
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
              Expanded(child: _buildWeekProgressIndicator(lastCompletedDate, currentStreak)),
              // Use Expanded to fill remaining space
            ],
          ),
        );
      },
    );
  }

  // Week progress indicator - EXACTLY as shown
  Widget _buildWeekProgressIndicator(DateTime? lastCompletedDate, int currentStreak) {
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
            final targetIndex = (targetWeekday - 1 + 7) % 7; // Handle negative numbers
            
            if (index == targetIndex) {
              isCompleted = true;
              break;
            }
          }
        }
        
        return Expanded(
          child: Container(
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 1), // 1px margin between circles
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

  // Weight Progress Card - EXACTLY as shown in screenshot
  Widget _buildWeightProgressCard() {
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
        final weightProgress = data.weightProgress;

        if (weightProgress == null) {
          // No weight data available
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
              mainAxisAlignment: MainAxisAlignment.center,
              // Center content vertically
              children: [
                Text(
                  'My Weight',
                  style: AppTextStyles.body1.copyWith(
                    color: AppConstants.textPrimary,
                    fontWeight: FontWeight.w600,
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
                  'Complete your first check-in to track weight progress',
                  style: AppTextStyles.caption.copyWith(
                    color: AppConstants.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Calculate days until next Sunday check-in
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final daysUntilSunday = _calculateDaysUntilSunday(today);
        final nextCheckinText = daysUntilSunday == 0
            ? 'Check-in today'
            : 'Next check-in: ${daysUntilSunday}d';

        // Calculate progress percentage (capped at 100%)
        final progressPercentage = _calculateWeightProgress(
          weightProgress.startWeight,
          weightProgress.currentWeight,
          weightProgress.goalWeight,
        );

        return Container(
          width: double.infinity,
          height: 200, // Fixed height for consistency
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            boxShadow: AppConstants.shadowM,
          ),
          child: Stack(
            children: [
              // Main content
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title - centered
                    Center(
                      child: Text(
                        'My Weight',
                        style: AppTextStyles.body1.copyWith(
                          color: AppConstants.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    // Current Weight - large and bold
                    Text(
                      '${weightProgress.currentWeight.toStringAsFixed(1)} kg',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppConstants.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    // Progress Bar - with proper calculation
                    LinearProgressIndicator(
                      value: (progressPercentage / 100).clamp(0.0, 1.0),
                      backgroundColor: AppConstants.borderColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppConstants.primaryColor),
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    // Goal Weight
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Goal ',
                            style: AppTextStyles.body2.copyWith(
                              color: AppConstants.textSecondary,
                            ),
                          ),
                          TextSpan(
                            text:
                                '${weightProgress.goalWeight.toStringAsFixed(1)} kg',
                            style: AppTextStyles.body2.copyWith(
                              color: AppConstants.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Grey background section at bottom - fills corners
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 40, // Fixed height for the grey section
                  decoration: BoxDecoration(
                    color: AppConstants.borderColor.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppConstants.radiusL),
                      bottomRight: Radius.circular(AppConstants.radiusL),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      nextCheckinText,
                      style: AppTextStyles.body2.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Calculate days until next Sunday (0 if today is Sunday)
  int _calculateDaysUntilSunday(DateTime today) {
    final weekday = today.weekday; // 1 = Monday, 7 = Sunday
    if (weekday == 7) return 0; // Today is Sunday
    return 7 - weekday; // Days until next Sunday
  }

  /// Calculate weight progress percentage from starting weight to goal
  double _calculateWeightProgress(
      double startWeight, double currentWeight, double goalWeight) {
    if (startWeight == goalWeight) return 0.0; // No goal difference

    final totalDistance = (startWeight - goalWeight).abs();
    final currentDistance = (startWeight - currentWeight).abs();

    // Calculate progress as percentage of total distance
    final progress = (currentDistance / totalDistance) * 100;

    // Cap at 100% maximum
    return progress.clamp(0.0, 100.0);
  }

  // Goal Progress Line Graph - EXACTLY as shown in screenshot
  Widget _buildGoalProgressGraph() {
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
                    '0% of goal', // EXACTLY as shown
                    style: AppTextStyles.body2.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),
          SizedBox(
            height: 200,
            child: _buildWeightChart(),
          ),
          const SizedBox(height: AppConstants.spacingM),
        ],
      ),
    );
  }

  // Weight chart - EXACTLY as shown in screenshot
  Widget _buildWeightChart() {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          // Y-axis labels
          SizedBox(
            width: 40,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('78', style: AppTextStyles.caption),
                Text('76', style: AppTextStyles.caption),
                Text('74', style: AppTextStyles.caption),
                Text('72', style: AppTextStyles.caption),
                Text('70', style: AppTextStyles.caption),
                Text('68', style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingS),
          // Chart area
          Expanded(
            child: Container(
              height: 200,
              child: CustomPaint(
                size: Size.infinite,
                painter: WeightChartPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // BMI Widget - EXACTLY as shown in screenshot
  Widget _buildBMIWidget() {
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
        final bmiData = data.bmiData;

        if (bmiData.currentBMI == 0.0) {
          // No BMI data available
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
                  'Your BMI',
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
                  'Complete onboarding to calculate your BMI',
                  style: AppTextStyles.caption.copyWith(
                    color: AppConstants.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }

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
                    'Your BMI',
                    style: AppTextStyles.body1.copyWith(
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  Icon(
                    Icons.help_outline,
                    color: AppConstants.textSecondary,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingM),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    bmiData.currentBMI.toStringAsFixed(1), // Use real BMI value
                    style: AppTextStyles.heading2.copyWith(
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(
                    width: AppConstants.spacingS,
                  ),
                  Text(
                    'Your weight is',
                    style: AppTextStyles.body1.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(
                    width: AppConstants.spacingS,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingM,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: bmiData.categoryColor, // Use real category color
                      borderRadius: BorderRadius.circular(AppConstants.radiusL),
                    ),
                    child: Text(
                      bmiData.categoryText, // Use real category text
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppConstants.surfaceColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingM),
              _buildBMIScale(bmiData.currentBMI), // Pass real BMI value
            ],
          ),
        );
      },
    );
  }

  // BMI scale - EXACTLY as shown in screenshot
  Widget _buildBMIScale(double currentBMI) {
    return Column(
      children: [
        // Container to hold the bar and indicator
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            final indicatorPosition = _getBMIPosition(currentBMI, barWidth);

            return SizedBox(
              height: 20,
              child: Stack(
                children: [
                  // Bar graph positioned in the middle
                  Positioned(
                    top: 6, // Center the bar vertically
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusS),
                        gradient: const LinearGradient(
                          colors: [
                            Colors.blue,
                            Colors.green,
                            Colors.orange,
                            Colors.red
                          ],
                          stops: [0.0, 0.25, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // BMI indicator line OVER the bar graph
                  Positioned(
                    top: 0,
                    left: indicatorPosition,
                    child: Container(
                      width: 2,
                      height: 20,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppConstants.spacingS),
        // Legend below
        _buildBMILegend(),
      ],
    );
  }

  /// Calculate the position for the BMI indicator line in pixels
  double _getBMIPosition(double bmi, double barWidth) {
    // Normalize BMI to 0-1 range for the scale
    // The scale goes from roughly 15 to 40+ BMI
    const minBMI = 15.0;
    const maxBMI = 40.0;

    // Clamp BMI to scale range
    final clampedBMI = bmi.clamp(minBMI, maxBMI);

    // Calculate position as percentage (0.0 = left edge, 1.0 = right edge)
    final position = (clampedBMI - minBMI) / (maxBMI - minBMI);

    // Convert to pixel position on the bar
    return position * barWidth;
  }

  Widget _buildBMILegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('Underweight', Colors.blue),
        _buildLegendItem('Healthy', Colors.green),
        _buildLegendItem('Overweight', Colors.orange),
        _buildLegendItem('Obese', Colors.red),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
      ],
    );
  }

  // Total Calories Card - EXACTLY as shown in screenshot
  Widget _buildTotalCaloriesCard() {
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
        
        // DEBUG: Log what data we're getting
        print('=== OVERVIEW TAB DEBUG ===');
        print('Daily calories data length: ${dailyCalories.dailyData.length}');
        print('Weekly total: ${dailyCalories.weeklyTotal}');
        print('Weekly average: ${dailyCalories.weeklyAverage}');
        for (final dayData in dailyCalories.dailyData) {
          print('Date: ${dayData.date.toIso8601String()}, Weekday: ${dayData.date.weekday}, Calories: ${dayData.totalCalories}');
        }
        print('========================');
        
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
            Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: AppConstants.borderColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildWeekFilter('This Week', 0, selectedWeekOffset == 0)),
                  Container(
                    width: 1,
                    height: 20,
                    color: AppConstants.borderColor.withOpacity(0.5),
                  ),
                  Expanded(child: _buildWeekFilter('Last Week', 1, selectedWeekOffset == 1)),
                  Container(
                    width: 1,
                    height: 20,
                    color: AppConstants.borderColor.withOpacity(0.5),
                  ),
                  Expanded(child: _buildWeekFilter('2 Wks Ago', 2, selectedWeekOffset == 2)),
                  Container(
                    width: 1,
                    height: 20,
                    color: AppConstants.borderColor.withOpacity(0.5),
                  ),
                  Expanded(child: _buildWeekFilter('3 Wks Ago', 3, selectedWeekOffset == 3)),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            // Calories Card
            Container(
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
                    child: _buildCaloriesChart(dailyCalories.dailyData),
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  _buildCaloriesLegend(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeekFilter(String label, int weekOffset, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (onWeekSelected != null) {
          onWeekSelected!(weekOffset);
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

  // Calories chart - EXACTLY as shown in screenshot
  Widget _buildCaloriesChart(List<DailyCaloriesPoint> dailyData) {
    // Calculate the maximum calories for proper scaling
    final maxCalories = dailyData.isNotEmpty 
        ? dailyData.map((d) => d.totalCalories).reduce((a, b) => a > b ? a : b).clamp(500.0, 2000.0)
        : 1500.0;
    
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${maxCalories.toInt()}', style: AppTextStyles.caption),
              Text('${(maxCalories * 0.67).toInt()}', style: AppTextStyles.caption),
              Text('${(maxCalories * 0.33).toInt()}', style: AppTextStyles.caption),
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
                  final dayAbbreviation = _getDayAbbreviation(dayData.date.weekday);
                  
                  // DEBUG: Log the date matching
                  print('Chart - Index $index (${dayAbbreviation}): Date ${dayData.date.toIso8601String()}, Calories: ${dayData.totalCalories}');
                  
                  if (dayData.totalCalories == 0) {
                    return SizedBox(
                      width: 20,
                      height: 220, // Total height for chart + label
                      child: Stack(
                        children: [
                          // Empty bar (just a line)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: Container(
                              width: 20,
                              height: 200,
                              child: Center(
                                child: Container(
                                  width: 20,
                                  height: 1,
                                  color: AppConstants.borderColor.withOpacity(0.3),
                                ),
                              ),
                            ),
                          ),
                          // Day label at the bottom
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Text(
                              dayAbbreviation, 
                              style: AppTextStyles.caption,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  // Calculate bar heights based on actual consumed calories
                  final totalHeight = (dayData.totalCalories / maxCalories) * 200;
                  
                  // Calculate individual macro heights (convert from calories to height)
                  final proteinHeight = (dayData.proteinCalories / maxCalories) * 200;
                  final carbsHeight = (dayData.carbsCalories / maxCalories) * 200;
                  final fatsHeight = (dayData.fatsCalories / maxCalories) * 200;
                  
                  return SizedBox(
                    width: 20,
                    height: 220, // Total height for chart + label
                    child: Stack(
                      children: [
                        // Stacked nutrition bars using real consumption data with clear divisions
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            width: 20,
                            height: 200,
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
                                      decoration: BoxDecoration(
                                        color: AppConstants.proteinColor,
                                        borderRadius: const BorderRadius.only(
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
                                      decoration: BoxDecoration(
                                        color: AppConstants.carbsColor,
                                      ),
                                    ),
                                  ),
                                // Fats (top)
                                if (fatsHeight > 0)
                                  Positioned(
                                    bottom: (proteinHeight + carbsHeight).clamp(0, 200),
                                    left: 0,
                                    child: Container(
                                      width: 20,
                                      height: fatsHeight.clamp(0, 200),
                                      decoration: BoxDecoration(
                                        color: AppConstants.fatColor,
                                        borderRadius: const BorderRadius.only(
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
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Text(
                            dayAbbreviation, 
                            style: AppTextStyles.caption,
                            textAlign: TextAlign.center,
                          ),
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

  Widget _buildCaloriesLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('Protein', AppConstants.proteinColor),
        _buildLegendItem('Carbs', AppConstants.carbsColor),
        _buildLegendItem('Fats', AppConstants.fatColor),
      ],
    );
  }

  /// Get day abbreviation from weekday number
  String _getDayAbbreviation(int weekday) {
    switch (weekday) {
      case 1: return 'M'; // Monday
      case 2: return 'T'; // Tuesday
      case 3: return 'W'; // Wednesday
      case 4: return 'T'; // Thursday
      case 5: return 'F'; // Friday
      case 6: return 'S'; // Saturday
      case 7: return 'S'; // Sunday
      default: return '?';
    }
  }
}

// Weight chart painter - EXACTLY as shown in screenshot
class WeightChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppConstants.borderColor.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final width = size.width;
    final height = size.height;
    final padding = 20.0;

    // Draw horizontal grid lines
    for (int i = 0; i < 6; i++) {
      final y = padding + (i / 5) * (height - 2 * padding);
      canvas.drawLine(
        Offset(padding, y),
        Offset(width - padding, y),
        paint,
      );
    }

    // Draw current weight line at 73 (between 72 and 74)
    final currentPaint = Paint()
      ..color = AppConstants.textPrimary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final currentY =
        padding + (2.5 / 5) * (height - 2 * padding); // Between 72 and 74
    canvas.drawLine(
      Offset(padding, currentY),
      Offset(width - padding, currentY),
      currentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
