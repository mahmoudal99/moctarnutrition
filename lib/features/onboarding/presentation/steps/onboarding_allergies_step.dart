import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/custom_button.dart';

enum AllergySeverity { mild, moderate, severe, anaphylaxis }

class AllergyItem {
  final String name;
  final AllergySeverity severity;
  final String? notes;

  AllergyItem({
    required this.name,
    required this.severity,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'severity': severity.toString().split('.').last,
      'notes': notes,
    };
  }

  factory AllergyItem.fromJson(Map<String, dynamic> json) {
    return AllergyItem(
      name: json['name'] as String,
      severity: AllergySeverity.values.firstWhere(
        (e) => e.toString() == 'AllergySeverity.${json['severity']}',
        orElse: () => AllergySeverity.mild,
      ),
      notes: json['notes'] as String?,
    );
  }
}

class OnboardingAllergiesStep extends StatefulWidget {
  final List<AllergyItem> selectedAllergies;
  final ValueChanged<List<AllergyItem>> onAllergiesChanged;

  const OnboardingAllergiesStep({
    super.key,
    required this.selectedAllergies,
    required this.onAllergiesChanged,
  });

  @override
  State<OnboardingAllergiesStep> createState() =>
      _OnboardingAllergiesStepState();
}

class _OnboardingAllergiesStepState extends State<OnboardingAllergiesStep> {
  final TextEditingController _allergyController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  AllergySeverity _selectedSeverity = AllergySeverity.mild;

  final List<String> _commonAllergies = [
    'Peanuts',
    'Tree Nuts',
    'Milk',
    'Eggs',
    'Soy',
    'Wheat',
    'Fish',
    'Sesame',
    'Gluten',
    'Lactose',
  ];

  @override
  void dispose() {
    _allergyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select from common allergies or add your own',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingL),

        // Common allergies grid
        Wrap(
          spacing: AppConstants.spacingS,
          runSpacing: AppConstants.spacingS,
          children: _commonAllergies.map((allergy) {
            final isSelected =
                widget.selectedAllergies.any((item) => item.name == allergy);
            return _AllergyChip(
              label: allergy,
              isSelected: isSelected,
              onTap: () => _toggleAllergy(allergy),
            );
          }).toList(),
        ),

        const SizedBox(height: AppConstants.spacingL),

        // Custom allergy input
        _buildCustomAllergyInput(),

        const SizedBox(height: AppConstants.spacingL),

        // Selected allergies list
        if (widget.selectedAllergies.isNotEmpty) ...[
          Text(
            'Your Allergies & Intolerances',
            style: AppTextStyles.heading5,
          ),
          const SizedBox(height: AppConstants.spacingM),
          ...widget.selectedAllergies.map((allergy) => _AllergyCard(
                allergy: allergy,
                onEdit: () => _editAllergy(allergy),
                onDelete: () => _removeAllergy(allergy),
              )),
        ],
      ],
    );
  }

  Widget _buildCustomAllergyInput() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Custom Allergy/Intolerance',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          CustomTextField(
            controller: _allergyController,
            hint: 'e.g., Nuts',
            label: 'Allergy/Intolerance Name',
          ),
          const SizedBox(height: AppConstants.spacingM),

          // Severity selector
          Text(
            'Severity Level',
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Wrap(
            spacing: AppConstants.spacingS,
            children: AllergySeverity.values.map((severity) {
              return ChoiceChip(
                label: Text(_getSeverityLabel(severity)),
                selected: _selectedSeverity == severity,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedSeverity = severity;
                    });
                  }
                },
                backgroundColor: AppConstants.surfaceColor,
                selectedColor: AppConstants.textTertiary.withOpacity(0.2),
                labelStyle: const TextStyle(
                  color: Colors.black,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppConstants.spacingM),
          CustomTextField(
            controller: _notesController,
            hint: 'Optional: Add notes about symptoms or reactions',
            label: 'Notes (Optional)',
            maxLines: 2,
          ),

          const SizedBox(height: AppConstants.spacingM),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Add Allergy/Intolerance',
              onPressed: _allergyController.text.trim().isNotEmpty
                  ? _addCustomAllergy
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  String _getSeverityLabel(AllergySeverity severity) {
    switch (severity) {
      case AllergySeverity.mild:
        return 'Mild';
      case AllergySeverity.moderate:
        return 'Moderate';
      case AllergySeverity.severe:
        return 'Severe';
      case AllergySeverity.anaphylaxis:
        return 'Anaphylaxis';
    }
  }

  void _toggleAllergy(String allergyName) {
    final existingIndex =
        widget.selectedAllergies.indexWhere((item) => item.name == allergyName);

    if (existingIndex != -1) {
      // Remove if already selected
      final newAllergies = List<AllergyItem>.from(widget.selectedAllergies);
      newAllergies.removeAt(existingIndex);
      widget.onAllergiesChanged(newAllergies);
    } else {
      // Add with default mild severity
      final newAllergies = List<AllergyItem>.from(widget.selectedAllergies);
      newAllergies.add(AllergyItem(
        name: allergyName,
        severity: AllergySeverity.mild,
      ));
      widget.onAllergiesChanged(newAllergies);
    }
  }

  void _addCustomAllergy() {
    if (_allergyController.text.trim().isNotEmpty) {
      final newAllergies = List<AllergyItem>.from(widget.selectedAllergies);
      newAllergies.add(AllergyItem(
        name: _allergyController.text.trim(),
        severity: _selectedSeverity,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      ));
      widget.onAllergiesChanged(newAllergies);

      // Reset form
      _allergyController.clear();
      _notesController.clear();
      setState(() {
        _selectedSeverity = AllergySeverity.mild;
      });
    }
  }

  void _editAllergy(AllergyItem allergy) {
    _allergyController.text = allergy.name;
    _notesController.text = allergy.notes ?? '';
    setState(() {
      _selectedSeverity = allergy.severity;
    });

    // Remove the old one and add the new one when user confirms
    _removeAllergy(allergy);
  }

  void _removeAllergy(AllergyItem allergy) {
    final newAllergies = List<AllergyItem>.from(widget.selectedAllergies);
    newAllergies.removeWhere((item) => item.name == allergy.name);
    widget.onAllergiesChanged(newAllergies);
  }
}

class _AllergyChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AllergyChip({
    required this.label,
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

class _AllergyCard extends StatelessWidget {
  final AllergyItem allergy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AllergyCard({
    required this.allergy,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
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
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getSeverityColor(allergy.severity),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allergy.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXS),
                Text(
                  _getSeverityLabel(allergy.severity),
                  style: AppTextStyles.caption.copyWith(
                    color: _getSeverityColor(allergy.severity),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (allergy.notes != null && allergy.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.spacingXS),
                  Text(
                    allergy.notes!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppConstants.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 18),
            color: AppConstants.textSecondary,
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, size: 18),
            color: AppConstants.errorColor,
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(AllergySeverity severity) {
    switch (severity) {
      case AllergySeverity.mild:
        return AppConstants.successColor;
      case AllergySeverity.moderate:
        return AppConstants.copperwoodColor;
      case AllergySeverity.severe:
        return AppConstants.errorColor;
      case AllergySeverity.anaphylaxis:
        return Colors.red.shade800;
    }
  }

  String _getSeverityLabel(AllergySeverity severity) {
    switch (severity) {
      case AllergySeverity.mild:
        return 'Mild';
      case AllergySeverity.moderate:
        return 'Moderate';
      case AllergySeverity.severe:
        return 'Severe';
      case AllergySeverity.anaphylaxis:
        return 'Anaphylaxis';
    }
  }
}
