import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';

class OnboardingAgeStep extends StatefulWidget {
  final int age;
  final ValueChanged<int> onAgeChanged;

  const OnboardingAgeStep({
    super.key,
    required this.age,
    required this.onAgeChanged,
  });

  @override
  State<OnboardingAgeStep> createState() => _OnboardingAgeStepState();
}

class _OnboardingAgeStepState extends State<OnboardingAgeStep> {
  late int _selectedDay;
  late int _selectedMonth;
  late int _selectedYear;
  late int _calculatedAge;

  @override
  void initState() {
    super.initState();
    _initializeDateFromAge();
  }

  void _initializeDateFromAge() {
    final now = DateTime.now();
    final birthYear = now.year - widget.age;
    _selectedYear = birthYear;
    _selectedMonth = now.month;
    _selectedDay = now.day;
    _calculatedAge = widget.age;
  }

  void _updateAge() {
    final birthDate = DateTime(_selectedYear, _selectedMonth, _selectedDay);
    final now = DateTime.now();
    int age = now.year - birthDate.year;

    // Adjust age if birthday hasn't occurred this year
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    // Ensure age is within reasonable bounds (16-100)
    age = age.clamp(16, 100);

    setState(() {
      _calculatedAge = age;
    });

    widget.onAgeChanged(age);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Day, Month, Year Selection
        Row(
          children: [
            // Day Picker
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Day',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  _buildDayPicker(),
                ],
              ),
            ),

            const SizedBox(width: AppConstants.spacingL),

            // Month Picker
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Month',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  _buildMonthPicker(),
                ],
              ),
            ),

            const SizedBox(width: AppConstants.spacingL),

            // Year Picker
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Year',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  _buildYearPicker(),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppConstants.spacingXL),

        // Age Display
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cake,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: AppConstants.spacingS),
              Text(
                '$_calculatedAge years old',
                style: AppTextStyles.heading4.copyWith(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayPicker() {
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Stack(
        children: [
          // Fade overlay at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppConstants.surfaceColor,
                    AppConstants.surfaceColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Fade overlay at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppConstants.surfaceColor,
                    AppConstants.surfaceColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Selection indicator
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          ListWheelScrollView(
            itemExtent: 40,
            diameterRatio: 1.5,
            controller:
                FixedExtentScrollController(initialItem: _selectedDay - 1),
            onSelectedItemChanged: (index) {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedDay = index + 1;
                // Ensure day doesn't exceed days in month
                if (_selectedDay > daysInMonth) {
                  _selectedDay = daysInMonth;
                }
              });
              _updateAge();
            },
            children: List.generate(daysInMonth, (index) {
              final day = index + 1;
              final isSelected = _selectedDay == day;
              return Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    day.toString(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? AppConstants.primaryColor
                          : AppConstants.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthPicker() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Stack(
        children: [
          // Fade overlay at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppConstants.surfaceColor,
                    AppConstants.surfaceColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Fade overlay at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppConstants.surfaceColor,
                    AppConstants.surfaceColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Selection indicator
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          ListWheelScrollView(
            itemExtent: 40,
            diameterRatio: 1.5,
            controller:
                FixedExtentScrollController(initialItem: _selectedMonth - 1),
            onSelectedItemChanged: (index) {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedMonth = index + 1;
                // Adjust day if it exceeds days in new month
                final daysInNewMonth =
                    DateTime(_selectedYear, _selectedMonth + 1, 0).day;
                if (_selectedDay > daysInNewMonth) {
                  _selectedDay = daysInNewMonth;
                }
              });
              _updateAge();
            },
            children: List.generate(12, (index) {
              final month = index + 1;
              final isSelected = _selectedMonth == month;
              return Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    months[index],
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? AppConstants.primaryColor
                          : AppConstants.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildYearPicker() {
    final currentYear = DateTime.now().year;
    final startYear = currentYear - 100; // 100 years ago
    final endYear = currentYear - 16; // 16 years ago (minimum age)

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Stack(
        children: [
          // Fade overlay at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppConstants.surfaceColor,
                    AppConstants.surfaceColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Fade overlay at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppConstants.surfaceColor,
                    AppConstants.surfaceColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Selection indicator
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          ListWheelScrollView(
            itemExtent: 40,
            diameterRatio: 1.5,
            controller: FixedExtentScrollController(
                initialItem: endYear - _selectedYear),
            onSelectedItemChanged: (index) {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedYear = endYear - index;
                // Adjust day if it exceeds days in month for new year
                final daysInMonth =
                    DateTime(_selectedYear, _selectedMonth + 1, 0).day;
                if (_selectedDay > daysInMonth) {
                  _selectedDay = daysInMonth;
                }
              });
              _updateAge();
            },
            children: List.generate(endYear - startYear + 1, (index) {
              final year = endYear - index;
              final isSelected = _selectedYear == year;
              return Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    year.toString(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? AppConstants.primaryColor
                          : AppConstants.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
