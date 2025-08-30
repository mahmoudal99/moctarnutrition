import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/meal_model.dart';
import 'dashed_circle_painter.dart';

class DaySelector extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final MealDay? currentDayMeals;
  final int? targetCalories;
  final Map<DateTime, Map<String, dynamic>>? dailyConsumptionData;

  const DaySelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.currentDayMeals,
    this.targetCalories,
    this.dailyConsumptionData,
  });

  @override
  Widget build(BuildContext context) {
    final days = _generateDays();

    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: days.map((day) {
          final isSelected = _isSameDay(day, selectedDate);
          final isToday = _isSameDay(day, DateTime.now());
          final isPast =
              day.isBefore(DateTime.now().subtract(const Duration(days: 1)));
          final isFuture =
              day.isAfter(DateTime.now().add(const Duration(days: 1)));

          // Check if this day has consumption data
          final normalizedDay = DateTime(day.year, day.month, day.day);
          final hasConsumptionData = dailyConsumptionData?.keys.any((key) =>
                  DateTime(key.year, key.month, key.day)
                      .isAtSameMomentAs(normalizedDay)) ==
              true;
          final dayConsumption = dailyConsumptionData?.entries
              .firstWhere(
                (entry) =>
                    DateTime(entry.key.year, entry.key.month, entry.key.day)
                        .isAtSameMomentAs(normalizedDay),
                orElse: () => MapEntry(day, <String, dynamic>{}),
              )
              .value;
          final hasConsumedCalories =
              dayConsumption?.containsKey('consumedCalories') == true &&
                  (dayConsumption!['consumedCalories'] as num) > 0;

          // Debug logging for each day to see what data we're getting

          return Expanded(
            child: GestureDetector(
              onTap: () => onDateSelected(day),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Day of week
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Progress ring for days with consumed calories (including today)
                        if ((hasConsumedCalories && targetCalories != null) ||
                            (isToday && targetCalories != null))
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              value: _calculateCalorieProgressForDay(day),
                              strokeWidth: 2.0,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _calculateCalorieProgressForDay(day) >= 1.0
                                    ? AppConstants.successColor
                                    : AppConstants.primaryColor,
                              ),
                            ),
                          ),
                        // Dashed circle for days without consumption data (past days or today with no consumption)
                        if ((isPast && !hasConsumedCalories) ||
                            (isToday && !hasConsumedCalories))
                          CustomPaint(
                            painter: DashedCirclePainter(
                              color: Colors.grey.shade400,
                              strokeWidth: 1.0,
                              dashLength: 3.0,
                              gapLength: 2.0,
                            ),
                            size: const Size(32, 32),
                          ),
                        // Empty circle for future days
                        if (!isPast && !isToday)
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1.0,
                              ),
                            ),
                          ),
                        // Day text
                        Text(
                          _getDayAbbreviation(day),
                          style: AppTextStyles.caption.copyWith(
                            color: isSelected
                                ? Colors.black
                                : (isPast && !hasConsumedCalories
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Date
                  Text(
                    day.day.toString(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected
                          ? Colors.black
                          : (isPast && !hasConsumedCalories
                              ? Colors.grey.shade400
                              : Colors.grey.shade600),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<DateTime> _generateDays() {
    // Generate days: 5 previous days + current day (total 6 days)
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 5));

    return List.generate(6, (index) {
      return startDate.add(Duration(days: index));
    });
  }

  String _getDayAbbreviation(DateTime date) {
    switch (date.weekday) {
      case 1:
        return 'M';
      case 2:
        return 'T';
      case 3:
        return 'W';
      case 4:
        return 'T';
      case 5:
        return 'F';
      case 6:
        return 'S';
      case 7:
        return 'S';
      default:
        return '';
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  double _calculateCalorieProgressForDay(DateTime day) {
    if (targetCalories == null || targetCalories! <= 0) {
      return 0.0;
    }

    final normalizedDay = DateTime(day.year, day.month, day.day);

    final dayConsumption = dailyConsumptionData?.entries
        .firstWhere(
          (entry) => DateTime(entry.key.year, entry.key.month, entry.key.day)
              .isAtSameMomentAs(normalizedDay),
          orElse: () => MapEntry(day, <String, dynamic>{}),
        )
        .value;


    if (dayConsumption == null ||
        dayConsumption.containsKey('consumedCalories') == false) {
      return 0.0;
    }

    final consumedCalories = dayConsumption['consumedCalories'] as num;
    final progress =
        targetCalories! > 0 ? consumedCalories / targetCalories! : 0.0;

    // Debug logging to see what's happening

    return progress;
  }

  double _calculateCalorieProgress() {
    if (currentDayMeals == null || targetCalories == null) {
      return 0.0;
    }

    // Calculate consumed calories from the meal day
    currentDayMeals!.calculateConsumedNutrition();
    final consumedCalories = currentDayMeals!.consumedCalories;

    return targetCalories! > 0 ? consumedCalories / targetCalories! : 0.0;
  }
}
