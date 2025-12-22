import 'package:champions_gym_app/shared/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

enum MealFrequency {
  threeMeals,
  threeMealsOneSnack,
  fourMeals,
  fourMealsOneSnack,
  fiveMeals,
  fiveMealsOneSnack,
  intermittentFasting,
  custom,
}

enum FastingType {
  none,
  sixteenEight, // 16:8
  eighteenSix, // 18:6
  twentyFour, // 20:4
  alternateDay, // Alternate day fasting
  fiveTwo, // 5:2 fasting
  custom,
}

class MealTimingPreferences {
  final MealFrequency mealFrequency;
  final FastingType? fastingType;
  final TimeOfDay? breakfastTime;
  final TimeOfDay? lunchTime;
  final TimeOfDay? dinnerTime;
  final List<TimeOfDay>? snackTimes;
  final String? customNotes;

  MealTimingPreferences({
    required this.mealFrequency,
    this.fastingType,
    this.breakfastTime,
    this.lunchTime,
    this.dinnerTime,
    this.snackTimes,
    this.customNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'mealFrequency': mealFrequency.toString().split('.').last,
      'fastingType': fastingType?.toString().split('.').last,
      'breakfastTime': breakfastTime != null
          ? '${breakfastTime!.hour}:${breakfastTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'lunchTime': lunchTime != null
          ? '${lunchTime!.hour}:${lunchTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'dinnerTime': dinnerTime != null
          ? '${dinnerTime!.hour}:${dinnerTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'snackTimes': snackTimes
          ?.map((time) =>
              '${time.hour}:${time.minute.toString().padLeft(2, '0')}')
          .toList(),
      'customNotes': customNotes,
    };
  }

  factory MealTimingPreferences.fromJson(Map<String, dynamic> json) {
    return MealTimingPreferences(
      mealFrequency: MealFrequency.values.firstWhere(
        (e) => e.toString() == 'MealFrequency.${json['mealFrequency']}',
        orElse: () => MealFrequency.threeMeals,
      ),
      fastingType: json['fastingType'] != null
          ? FastingType.values.firstWhere(
              (e) => e.toString() == 'FastingType.${json['fastingType']}',
              orElse: () => FastingType.none,
            )
          : null,
      breakfastTime: json['breakfastTime'] != null
          ? _parseTimeOfDay(json['breakfastTime'])
          : null,
      lunchTime:
          json['lunchTime'] != null ? _parseTimeOfDay(json['lunchTime']) : null,
      dinnerTime: json['dinnerTime'] != null
          ? _parseTimeOfDay(json['dinnerTime'])
          : null,
      snackTimes: json['snackTimes'] != null
          ? (json['snackTimes'] as List)
              .map((time) => _parseTimeOfDay(time))
              .toList()
          : null,
      customNotes: json['customNotes'] as String?,
    );
  }

  static TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}

class OnboardingMealTimingStep extends StatefulWidget {
  final MealTimingPreferences? selectedPreferences;
  final ValueChanged<MealTimingPreferences> onPreferencesChanged;

  const OnboardingMealTimingStep({
    super.key,
    this.selectedPreferences,
    required this.onPreferencesChanged,
  });

  @override
  State<OnboardingMealTimingStep> createState() =>
      _OnboardingMealTimingStepState();
}

class _OnboardingMealTimingStepState extends State<OnboardingMealTimingStep> {
  MealFrequency _selectedMealFrequency = MealFrequency.threeMeals;
  FastingType? _selectedFastingType;
  TimeOfDay? _breakfastTime;
  TimeOfDay? _lunchTime;
  TimeOfDay? _dinnerTime;
  List<TimeOfDay> _snackTimes = [];
  final TextEditingController _customNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.selectedPreferences != null) {
      _selectedMealFrequency = widget.selectedPreferences!.mealFrequency;
      _selectedFastingType = widget.selectedPreferences!.fastingType;
      _breakfastTime = widget.selectedPreferences!.breakfastTime;
      _lunchTime = widget.selectedPreferences!.lunchTime;
      _dinnerTime = widget.selectedPreferences!.dinnerTime;
      _snackTimes = widget.selectedPreferences!.snackTimes ?? [];
      _customNotesController.text =
          widget.selectedPreferences!.customNotes ?? '';
    }
  }

  @override
  void dispose() {
    _customNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal Frequency Section
          _buildMealFrequencySection(),
          const SizedBox(height: AppConstants.spacingL),

          // Fasting Section
          _buildFastingSection(),
          const SizedBox(height: AppConstants.spacingL),

          // Meal Timing Section (only show if not fasting)
          if (_selectedFastingType == null ||
              _selectedFastingType == FastingType.none) ...[
            _buildMealTimingSection(),
            const SizedBox(height: AppConstants.spacingL),
          ],

          // Custom Notes Section
          _buildCustomNotesSection(),
        ],
      ),
    );
  }

  Widget _buildMealFrequencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How many meals per day?',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: AppConstants.textSecondary,
            ),
            const SizedBox(width: AppConstants.spacingS),
            Expanded(
              child: Text(
                'Note: This count does not include breakfast.',
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingM),
        Wrap(
          spacing: AppConstants.spacingS,
          runSpacing: AppConstants.spacingS,
          children: [
            _MealFrequencyChip(
              label: '3 meals',
              value: MealFrequency.threeMeals,
              isSelected: _selectedMealFrequency == MealFrequency.threeMeals,
              onTap: () => _updateMealFrequency(MealFrequency.threeMeals),
            ),
            _MealFrequencyChip(
              label: '3 meals + 1 snack',
              value: MealFrequency.threeMealsOneSnack,
              isSelected:
                  _selectedMealFrequency == MealFrequency.threeMealsOneSnack,
              onTap: () =>
                  _updateMealFrequency(MealFrequency.threeMealsOneSnack),
            ),
            _MealFrequencyChip(
              label: '4 meals',
              value: MealFrequency.fourMeals,
              isSelected: _selectedMealFrequency == MealFrequency.fourMeals,
              onTap: () => _updateMealFrequency(MealFrequency.fourMeals),
            ),
            _MealFrequencyChip(
              label: '4 meals + 1 snack',
              value: MealFrequency.fourMealsOneSnack,
              isSelected:
                  _selectedMealFrequency == MealFrequency.fourMealsOneSnack,
              onTap: () =>
                  _updateMealFrequency(MealFrequency.fourMealsOneSnack),
            ),
            _MealFrequencyChip(
              label: '5 meals',
              value: MealFrequency.fiveMeals,
              isSelected: _selectedMealFrequency == MealFrequency.fiveMeals,
              onTap: () => _updateMealFrequency(MealFrequency.fiveMeals),
            ),
            _MealFrequencyChip(
              label: '5 meals + 1 snack',
              value: MealFrequency.fiveMealsOneSnack,
              isSelected:
                  _selectedMealFrequency == MealFrequency.fiveMealsOneSnack,
              onTap: () =>
                  _updateMealFrequency(MealFrequency.fiveMealsOneSnack),
            ),
            _MealFrequencyChip(
              label: 'Intermittent Fasting',
              value: MealFrequency.intermittentFasting,
              isSelected:
                  _selectedMealFrequency == MealFrequency.intermittentFasting,
              onTap: () =>
                  _updateMealFrequency(MealFrequency.intermittentFasting),
            ),
            _MealFrequencyChip(
              label: 'Custom',
              value: MealFrequency.custom,
              isSelected: _selectedMealFrequency == MealFrequency.custom,
              onTap: () => _updateMealFrequency(MealFrequency.custom),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFastingSection() {
    if (_selectedMealFrequency != MealFrequency.intermittentFasting) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fasting Type',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Wrap(
          spacing: AppConstants.spacingS,
          runSpacing: AppConstants.spacingS,
          children: [
            _FastingChip(
              label: '16:8 (8-hour eating window)',
              value: FastingType.sixteenEight,
              isSelected: _selectedFastingType == FastingType.sixteenEight,
              onTap: () => _updateFastingType(FastingType.sixteenEight),
            ),
            _FastingChip(
              label: '18:6 (6-hour eating window)',
              value: FastingType.eighteenSix,
              isSelected: _selectedFastingType == FastingType.eighteenSix,
              onTap: () => _updateFastingType(FastingType.eighteenSix),
            ),
            _FastingChip(
              label: '20:4 (4-hour eating window)',
              value: FastingType.twentyFour,
              isSelected: _selectedFastingType == FastingType.twentyFour,
              onTap: () => _updateFastingType(FastingType.twentyFour),
            ),
            _FastingChip(
              label: 'Alternate Day Fasting',
              value: FastingType.alternateDay,
              isSelected: _selectedFastingType == FastingType.alternateDay,
              onTap: () => _updateFastingType(FastingType.alternateDay),
            ),
            _FastingChip(
              label: '5:2 Fasting',
              value: FastingType.fiveTwo,
              isSelected: _selectedFastingType == FastingType.fiveTwo,
              onTap: () => _updateFastingType(FastingType.fiveTwo),
            ),
            _FastingChip(
              label: 'Custom',
              value: FastingType.custom,
              isSelected: _selectedFastingType == FastingType.custom,
              onTap: () => _updateFastingType(FastingType.custom),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMealTimingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferred Meal Times',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Text(
          'Set your preferred meal times (optional)',
          style: AppTextStyles.caption.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),

        // Breakfast
        _buildTimeSelector(
          'Breakfast',
          _breakfastTime,
          (time) => setState(() => _breakfastTime = time),
        ),

        // Lunch
        _buildTimeSelector(
          'Lunch',
          _lunchTime,
          (time) => setState(() => _lunchTime = time),
        ),

        // Dinner
        _buildTimeSelector(
          'Dinner',
          _dinnerTime,
          (time) => setState(() => _dinnerTime = time),
        ),

        // Snack times (if applicable)
        if (_selectedMealFrequency == MealFrequency.threeMealsOneSnack ||
            _selectedMealFrequency == MealFrequency.fourMealsOneSnack ||
            _selectedMealFrequency == MealFrequency.fiveMealsOneSnack) ...[
          const SizedBox(height: AppConstants.spacingM),
          _buildSnackTimeSelector(),
        ],
      ],
    );
  }

  Widget _buildTimeSelector(
    String label,
    TimeOfDay? selectedTime,
    ValueChanged<TimeOfDay?> onTimeChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: selectedTime ?? const TimeOfDay(hour: 8, minute: 0),
            );
            if (time != null) {
              onTimeChanged(time);
              _updatePreferences();
            }
          },
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              border: Border.all(
                color: AppConstants.textTertiary.withOpacity(0.2),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.caption.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                      ),
                      Text(
                        selectedTime?.format(context) ?? 'Not set',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: selectedTime != null
                              ? AppConstants.textPrimary
                              : AppConstants.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppConstants.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSnackTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Snack Time',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        Wrap(
          spacing: AppConstants.spacingS,
          children: [
            _SnackTimeChip(
              label: 'Morning (10 AM)',
              time: const TimeOfDay(hour: 10, minute: 0),
              isSelected:
                  _snackTimes.contains(const TimeOfDay(hour: 10, minute: 0)),
              onTap: () =>
                  _toggleSnackTime(const TimeOfDay(hour: 10, minute: 0)),
            ),
            _SnackTimeChip(
              label: 'Afternoon (3 PM)',
              time: const TimeOfDay(hour: 15, minute: 0),
              isSelected:
                  _snackTimes.contains(const TimeOfDay(hour: 15, minute: 0)),
              onTap: () =>
                  _toggleSnackTime(const TimeOfDay(hour: 15, minute: 0)),
            ),
            _SnackTimeChip(
              label: 'Evening (8 PM)',
              time: const TimeOfDay(hour: 20, minute: 0),
              isSelected:
                  _snackTimes.contains(const TimeOfDay(hour: 20, minute: 0)),
              onTap: () =>
                  _toggleSnackTime(const TimeOfDay(hour: 20, minute: 0)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Notes (Optional)',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        CustomTextField(
          controller: _customNotesController,
          hint: 'e.g., I prefer to eat dinner early, I work night shifts...',
          label: 'Custom Notes',
          maxLines: 3,
          onChanged: (value) => _updatePreferences(),
        ),
      ],
    );
  }

  void _updateMealFrequency(MealFrequency frequency) {
    setState(() {
      _selectedMealFrequency = frequency;
      if (frequency != MealFrequency.intermittentFasting) {
        _selectedFastingType = null;
      }
      // Reset snack times if not applicable
      if (frequency != MealFrequency.threeMealsOneSnack &&
          frequency != MealFrequency.fourMealsOneSnack &&
          frequency != MealFrequency.fiveMealsOneSnack) {
        _snackTimes.clear();
      }
    });
    _updatePreferences();
  }

  void _updateFastingType(FastingType? fastingType) {
    setState(() {
      _selectedFastingType = fastingType;
    });
    _updatePreferences();
  }

  void _toggleSnackTime(TimeOfDay time) {
    setState(() {
      if (_snackTimes.contains(time)) {
        _snackTimes.remove(time);
      } else {
        _snackTimes.add(time);
      }
    });
    _updatePreferences();
  }

  void _updatePreferences() {
    final preferences = MealTimingPreferences(
      mealFrequency: _selectedMealFrequency,
      fastingType: _selectedFastingType,
      breakfastTime: _breakfastTime,
      lunchTime: _lunchTime,
      dinnerTime: _dinnerTime,
      snackTimes: _snackTimes.isNotEmpty ? _snackTimes : null,
      customNotes: _customNotesController.text.trim().isNotEmpty
          ? _customNotesController.text.trim()
          : null,
    );
    widget.onPreferencesChanged(preferences);
  }
}

class _MealFrequencyChip extends StatelessWidget {
  final String label;
  final MealFrequency value;
  final bool isSelected;
  final VoidCallback onTap;

  const _MealFrequencyChip({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingS,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppConstants.primaryColor.withOpacity(0.1)
                : AppConstants.surfaceColor,
            border: Border.all(
              color: isSelected
                  ? AppConstants.primaryColor
                  : AppConstants.textTertiary.withOpacity(0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isSelected
                  ? AppConstants.primaryColor
                  : AppConstants.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _FastingChip extends StatelessWidget {
  final String label;
  final FastingType value;
  final bool isSelected;
  final VoidCallback onTap;

  const _FastingChip({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingS,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppConstants.copperwoodColor.withOpacity(0.1)
                : AppConstants.surfaceColor,
            border: Border.all(
              color: isSelected
                  ? AppConstants.copperwoodColor
                  : AppConstants.textTertiary.withOpacity(0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isSelected
                  ? AppConstants.copperwoodColor
                  : AppConstants.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _SnackTimeChip extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final bool isSelected;
  final VoidCallback onTap;

  const _SnackTimeChip({
    required this.label,
    required this.time,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingS,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppConstants.secondaryColor.withOpacity(0.1)
                : AppConstants.surfaceColor,
            border: Border.all(
              color: isSelected
                  ? AppConstants.secondaryColor
                  : AppConstants.textTertiary.withOpacity(0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isSelected
                  ? AppConstants.secondaryColor
                  : AppConstants.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
