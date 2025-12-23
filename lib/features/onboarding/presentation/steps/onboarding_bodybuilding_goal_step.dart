import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';

enum BodybuildingGoal {
  newToBodybuilding,
  photoshootPrep,
  winterTransformation,
  sixMonthPlan,
  couplePlan
}

class OnboardingBodybuildingGoalStep extends StatefulWidget {
  final BodybuildingGoal? selectedGoal;
  final ValueChanged<BodybuildingGoal> onSelect;

  const OnboardingBodybuildingGoalStep({
    super.key,
    this.selectedGoal,
    required this.onSelect,
  });

  @override
  State<OnboardingBodybuildingGoalStep> createState() =>
      _OnboardingBodybuildingGoalStepState();
}

class _OnboardingBodybuildingGoalStepState
    extends State<OnboardingBodybuildingGoalStep> {
  BodybuildingGoal? _selectedGoal;
  final Map<BodybuildingGoal, bool> _optionVisibility = {};

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.selectedGoal;

    // Animate options in with staggered delays
    int delay = 200;
    for (var goal in BodybuildingGoal.values) {
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) {
          setState(() {
            _optionVisibility[goal] = true;
          });
        }
      });
      delay += 100;
    }
  }

  @override
  void didUpdateWidget(OnboardingBodybuildingGoalStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedGoal != widget.selectedGoal) {
      _selectedGoal = widget.selectedGoal;
    }
  }

  void _handleSelection(BodybuildingGoal goal) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedGoal = goal;
    });
    widget.onSelect(goal);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: BodybuildingGoal.values.map((goal) {
        final isSelected = _selectedGoal == goal;
        final isVisible = _optionVisibility[goal] ?? false;

        return AnimatedOpacity(
          opacity: isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: AnimatedSlide(
            offset: isVisible ? Offset.zero : const Offset(0, 0.2),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: _SelectionCard(
              title: _getGoalTitle(goal),
              subtitle: _getGoalDescription(goal),
              isSelected: isSelected,
              onTap: () => _handleSelection(goal),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getGoalTitle(BodybuildingGoal goal) {
    switch (goal) {
      case BodybuildingGoal.newToBodybuilding:
        return 'I\'m new to bodybuilding';
      case BodybuildingGoal.photoshootPrep:
        return 'Prepare for a photoshoot';
      case BodybuildingGoal.winterTransformation:
        return 'Winter transformation';
      case BodybuildingGoal.sixMonthPlan:
        return '6 month transformation plan';
      case BodybuildingGoal.couplePlan:
        return 'Couple transformation plan';
    }
  }

  String _getGoalDescription(BodybuildingGoal goal) {
    switch (goal) {
      case BodybuildingGoal.newToBodybuilding:
        return 'Start your bodybuilding journey with fundamentals';
      case BodybuildingGoal.photoshootPrep:
        return 'Get shredded and stage-ready';
      case BodybuildingGoal.winterTransformation:
        return 'Build mass during the off-season';
      case BodybuildingGoal.sixMonthPlan:
        return 'Long-term structured transformation';
      case BodybuildingGoal.couplePlan:
        return 'Fitness is better with your partner';
    }
  }
}

class _SelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppConstants.primaryColor.withOpacity(0.08)
                  : AppConstants.surfaceColor,
              border: Border.all(
                color: isSelected
                    ? AppConstants.primaryColor.withOpacity(0.3)
                    : AppConstants.textTertiary.withOpacity(0.2),
                width: isSelected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              boxShadow: isSelected ? AppConstants.shadowS : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppConstants.primaryColor
                              : AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingXS),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.radio_button_checked,
                  color: isSelected
                      ? AppConstants.primaryColor
                      : AppConstants.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
