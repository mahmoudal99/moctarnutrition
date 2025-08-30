import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

enum BatchCookingFrequency {
  daily,
  twiceAWeek,
  weekly,
  biweekly,
  monthly,
  never,
}

enum BatchSize {
  singleMeal,
  twoMeals,
  threeMeals,
  fourMeals,
  fiveMeals,
  weeklyPrep,
  custom,
}

class BatchCookingPreferences {
  final BatchCookingFrequency frequency;
  final BatchSize batchSize;
  final bool preferLeftovers;
  final String? customNotes;

  BatchCookingPreferences({
    required this.frequency,
    required this.batchSize,
    this.preferLeftovers = true,
    this.customNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency.toString().split('.').last,
      'batchSize': batchSize.toString().split('.').last,
      'preferLeftovers': preferLeftovers,
      'customNotes': customNotes,
    };
  }

  factory BatchCookingPreferences.fromJson(Map<String, dynamic> json) {
    return BatchCookingPreferences(
      frequency: BatchCookingFrequency.values.firstWhere(
        (e) => e.toString() == 'BatchCookingFrequency.${json['frequency']}',
        orElse: () => BatchCookingFrequency.weekly,
      ),
      batchSize: BatchSize.values.firstWhere(
        (e) => e.toString() == 'BatchSize.${json['batchSize']}',
        orElse: () => BatchSize.threeMeals,
      ),
      preferLeftovers: json['preferLeftovers'] as bool? ?? true,
      customNotes: json['customNotes'] as String?,
    );
  }
}

class OnboardingBatchCookingStep extends StatefulWidget {
  final BatchCookingPreferences? selectedPreferences;
  final ValueChanged<BatchCookingPreferences> onPreferencesChanged;

  const OnboardingBatchCookingStep({
    super.key,
    this.selectedPreferences,
    required this.onPreferencesChanged,
  });

  @override
  State<OnboardingBatchCookingStep> createState() =>
      _OnboardingBatchCookingStepState();
}

class _OnboardingBatchCookingStepState
    extends State<OnboardingBatchCookingStep> {
  BatchCookingFrequency _selectedFrequency = BatchCookingFrequency.weekly;
  BatchSize _selectedBatchSize = BatchSize.threeMeals;
  bool _preferLeftovers = true;
  final TextEditingController _customNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.selectedPreferences != null) {
      _selectedFrequency = widget.selectedPreferences!.frequency;
      _selectedBatchSize = widget.selectedPreferences!.batchSize;
      _preferLeftovers = widget.selectedPreferences!.preferLeftovers;
      _customNotesController.text =
          widget.selectedPreferences!.customNotes ?? '';
    }
  }

  @override
  void dispose() {
    _customNotesController.dispose();
    super.dispose();
  }

  void _updatePreferences() {
    widget.onPreferencesChanged(BatchCookingPreferences(
      frequency: _selectedFrequency,
      batchSize: _selectedBatchSize,
      preferLeftovers: _preferLeftovers,
      customNotes: _customNotesController.text.isNotEmpty
          ? _customNotesController.text
          : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Batch Cooking Preferences',
            style: AppTextStyles.heading4,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Tell us about your meal preparation habits',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),

          // Cooking Frequency Section
          _buildFrequencySection(),
          const SizedBox(height: AppConstants.spacingL),

          // Batch Size Section
          _buildBatchSizeSection(),
          const SizedBox(height: AppConstants.spacingL),

          // Leftovers Preference Section
          _buildLeftoversSection(),
          const SizedBox(height: AppConstants.spacingL),

          // Custom Notes Section
          _buildCustomNotesSection(),
        ],
      ),
    );
  }

  Widget _buildFrequencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How often do you like to cook?',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Wrap(
          spacing: AppConstants.spacingS,
          runSpacing: AppConstants.spacingS,
          children: [
            _FrequencyChip(
              label: 'Daily',
              value: BatchCookingFrequency.daily,
              isSelected: _selectedFrequency == BatchCookingFrequency.daily,
              onTap: () {
                setState(() {
                  _selectedFrequency = BatchCookingFrequency.daily;
                });
                _updatePreferences();
              },
            ),
            _FrequencyChip(
              label: 'Twice a week',
              value: BatchCookingFrequency.twiceAWeek,
              isSelected:
                  _selectedFrequency == BatchCookingFrequency.twiceAWeek,
              onTap: () {
                setState(() {
                  _selectedFrequency = BatchCookingFrequency.twiceAWeek;
                });
                _updatePreferences();
              },
            ),
            _FrequencyChip(
              label: 'Weekly',
              value: BatchCookingFrequency.weekly,
              isSelected: _selectedFrequency == BatchCookingFrequency.weekly,
              onTap: () {
                setState(() {
                  _selectedFrequency = BatchCookingFrequency.weekly;
                });
                _updatePreferences();
              },
            ),
            _FrequencyChip(
              label: 'Every 2 weeks',
              value: BatchCookingFrequency.biweekly,
              isSelected: _selectedFrequency == BatchCookingFrequency.biweekly,
              onTap: () {
                setState(() {
                  _selectedFrequency = BatchCookingFrequency.biweekly;
                });
                _updatePreferences();
              },
            ),
            _FrequencyChip(
              label: 'Monthly',
              value: BatchCookingFrequency.monthly,
              isSelected: _selectedFrequency == BatchCookingFrequency.monthly,
              onTap: () {
                setState(() {
                  _selectedFrequency = BatchCookingFrequency.monthly;
                });
                _updatePreferences();
              },
            ),
            _FrequencyChip(
              label: 'I don\'t cook',
              value: BatchCookingFrequency.never,
              isSelected: _selectedFrequency == BatchCookingFrequency.never,
              onTap: () {
                setState(() {
                  _selectedFrequency = BatchCookingFrequency.never;
                });
                _updatePreferences();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBatchSizeSection() {
    if (_selectedFrequency == BatchCookingFrequency.never) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How many meals do you like to prepare at once?',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Wrap(
          spacing: AppConstants.spacingS,
          runSpacing: AppConstants.spacingS,
          children: [
            _BatchSizeChip(
              label: '1 meal',
              value: BatchSize.singleMeal,
              isSelected: _selectedBatchSize == BatchSize.singleMeal,
              onTap: () {
                setState(() {
                  _selectedBatchSize = BatchSize.singleMeal;
                });
                _updatePreferences();
              },
            ),
            _BatchSizeChip(
              label: '2 meals',
              value: BatchSize.twoMeals,
              isSelected: _selectedBatchSize == BatchSize.twoMeals,
              onTap: () {
                setState(() {
                  _selectedBatchSize = BatchSize.twoMeals;
                });
                _updatePreferences();
              },
            ),
            _BatchSizeChip(
              label: '3 meals',
              value: BatchSize.threeMeals,
              isSelected: _selectedBatchSize == BatchSize.threeMeals,
              onTap: () {
                setState(() {
                  _selectedBatchSize = BatchSize.threeMeals;
                });
                _updatePreferences();
              },
            ),
            _BatchSizeChip(
              label: '4 meals',
              value: BatchSize.fourMeals,
              isSelected: _selectedBatchSize == BatchSize.fourMeals,
              onTap: () {
                setState(() {
                  _selectedBatchSize = BatchSize.fourMeals;
                });
                _updatePreferences();
              },
            ),
            _BatchSizeChip(
              label: '5 meals',
              value: BatchSize.fiveMeals,
              isSelected: _selectedBatchSize == BatchSize.fiveMeals,
              onTap: () {
                setState(() {
                  _selectedBatchSize = BatchSize.fiveMeals;
                });
                _updatePreferences();
              },
            ),
            _BatchSizeChip(
              label: 'Weekly prep',
              value: BatchSize.weeklyPrep,
              isSelected: _selectedBatchSize == BatchSize.weeklyPrep,
              onTap: () {
                setState(() {
                  _selectedBatchSize = BatchSize.weeklyPrep;
                });
                _updatePreferences();
              },
            ),
            _BatchSizeChip(
              label: 'Custom',
              value: BatchSize.custom,
              isSelected: _selectedBatchSize == BatchSize.custom,
              onTap: () {
                setState(() {
                  _selectedBatchSize = BatchSize.custom;
                });
                _updatePreferences();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLeftoversSection() {
    if (_selectedFrequency == BatchCookingFrequency.never) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Do you enjoy eating leftovers?',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Row(
          children: [
            Expanded(
              child: _LeftoverChip(
                label: 'Yes, I love leftovers!',
                isSelected: _preferLeftovers,
                onTap: () {
                  setState(() {
                    _preferLeftovers = true;
                  });
                  _updatePreferences();
                },
              ),
            ),
            const SizedBox(width: AppConstants.spacingS),
            Expanded(
              child: _LeftoverChip(
                label: 'No, I prefer fresh meals',
                isSelected: !_preferLeftovers,
                onTap: () {
                  setState(() {
                    _preferLeftovers = false;
                  });
                  _updatePreferences();
                },
              ),
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
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            border: Border.all(
              color: AppConstants.textTertiary.withOpacity(0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          child: TextField(
            controller: _customNotesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'e.g., I prefer quick 15-minute recipes, I have limited kitchen space...',
              border: InputBorder.none,
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: AppConstants.textTertiary,
              ),
            ),
            style: AppTextStyles.bodySmall,
            onChanged: (value) => _updatePreferences(),
          ),
        ),
      ],
    );
  }
}

class _FrequencyChip extends StatelessWidget {
  final String label;
  final BatchCookingFrequency value;
  final bool isSelected;
  final VoidCallback onTap;

  const _FrequencyChip({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor
              : AppConstants.surfaceColor,
          border: Border.all(
            color: isSelected
                ? AppConstants.primaryColor
                : AppConstants.textTertiary.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected
                ? AppConstants.surfaceColor
                : AppConstants.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _BatchSizeChip extends StatelessWidget {
  final String label;
  final BatchSize value;
  final bool isSelected;
  final VoidCallback onTap;

  const _BatchSizeChip({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor
              : AppConstants.surfaceColor,
          border: Border.all(
            color: isSelected
                ? AppConstants.primaryColor
                : AppConstants.textTertiary.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected
                ? AppConstants.surfaceColor
                : AppConstants.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _LeftoverChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LeftoverChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor
              : AppConstants.surfaceColor,
          border: Border.all(
            color: isSelected
                ? AppConstants.primaryColor
                : AppConstants.textTertiary.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected
                ? AppConstants.surfaceColor
                : AppConstants.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
