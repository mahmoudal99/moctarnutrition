import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import 'dashed_circle_painter.dart';

class DaySelector extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const DaySelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
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
          final isPast = day.isBefore(DateTime.now().subtract(const Duration(days: 1)));
          final isFuture = day.isAfter(DateTime.now().add(const Duration(days: 1)));
          
          return Expanded(
            child: GestureDetector(
              onTap: () => onDateSelected(day),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Day of week
                  Container(
                    width: 32,
                    height: 32,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Dashed circle for past days
                        if (isPast)
                          CustomPaint(
                            painter: DashedCirclePainter(
                              color: Colors.grey.shade400,
                              strokeWidth: 1.0,
                              dashLength: 3.0,
                              gapLength: 2.0,
                            ),
                            size: const Size(32, 32),
                          ),
                        // Day text
                        Text(
                          _getDayAbbreviation(day),
                          style: AppTextStyles.caption.copyWith(
                            color: isSelected
                                ? Colors.black 
                                : (isPast ? Colors.grey.shade400 : Colors.grey.shade600),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                          : (isPast ? Colors.grey.shade400 : Colors.grey.shade600),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
    // Generate days: 5 previous days + current day + 1 future day
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 5));
    
    return List.generate(7, (index) {
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
}
