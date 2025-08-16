import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/models/user_model.dart';

class WorkoutPreferencesScreen extends StatefulWidget {
  const WorkoutPreferencesScreen({super.key});

  @override
  State<WorkoutPreferencesScreen> createState() =>
      _WorkoutPreferencesScreenState();
}

class _WorkoutPreferencesScreenState extends State<WorkoutPreferencesScreen> {
  late UserModel _user;
  late UserPreferences _preferences;

  // Selected preferences
  late FitnessGoal _selectedFitnessGoal;
  late ActivityLevel _selectedActivityLevel;
  late List<String> _selectedWorkoutStyles;

  // Controllers for text fields
  final TextEditingController _workoutStyleController = TextEditingController();

  bool _isLoading = false;
  bool _hasChanges = false;

  // Available workout styles
  static const List<String> _workoutStyles = [
    'Strength Training',
    'Body Building',
    'Cardio',
    'HIIT',
    'Running',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _user = authProvider.userModel!;
    _preferences = _user.preferences;

    // Initialize selected preferences
    _selectedFitnessGoal = _preferences.fitnessGoal;
    _selectedActivityLevel = _preferences.activityLevel;
    _selectedWorkoutStyles = List.from(_preferences.preferredWorkoutStyles);
  }

  @override
  void dispose() {
    _workoutStyleController.dispose();
    super.dispose();
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _selectFitnessGoal(FitnessGoal goal) {
    setState(() {
      _selectedFitnessGoal = goal;
      _markAsChanged();
    });
  }

  void _selectActivityLevel(ActivityLevel level) {
    setState(() {
      _selectedActivityLevel = level;
      _markAsChanged();
    });
  }

  void _toggleWorkoutStyle(String style) {
    setState(() {
      if (_selectedWorkoutStyles.contains(style)) {
        _selectedWorkoutStyles.remove(style);
      } else {
        _selectedWorkoutStyles.add(style);
      }
      _markAsChanged();
    });
  }

  void _addCustomWorkoutStyle() {
    final style = _workoutStyleController.text.trim();
    if (style.isNotEmpty && !_selectedWorkoutStyles.contains(style)) {
      setState(() {
        _selectedWorkoutStyles.add(style);
        _workoutStyleController.clear();
        _markAsChanged();
      });
    }
  }

  void _removeWorkoutStyle(String style) {
    setState(() {
      _selectedWorkoutStyles.remove(style);
      _markAsChanged();
    });
  }

  Future<void> _savePreferences() async {
    if (!_hasChanges) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create updated preferences
      final updatedPreferences = _preferences.copyWith(
        fitnessGoal: _selectedFitnessGoal,
        activityLevel: _selectedActivityLevel,
        preferredWorkoutStyles: _selectedWorkoutStyles,
      );

      // Create updated user
      final updatedUser = _user.copyWith(
        preferences: updatedPreferences,
        updatedAt: DateTime.now(),
      );

      // Update in Firebase and local storage
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updateUserProfile(updatedUser);

      if (mounted) {
        setState(() {
          _hasChanges = false;
        });

        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update preferences: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Workout Preferences'),
        backgroundColor: AppConstants.surfaceColor,
        elevation: 0,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _savePreferences,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Fitness Goal'),
            _buildFitnessGoalSection(),
            const SizedBox(height: AppConstants.spacingL),
            _buildSectionHeader('Activity Level'),
            _buildActivityLevelSection(),
            const SizedBox(height: AppConstants.spacingL),
            _buildSectionHeader('Preferred Workout Styles'),
            _buildWorkoutStylesSection(),
            const SizedBox(height: 128),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: Text(
        title,
        style: AppTextStyles.heading5.copyWith(
          color: AppConstants.textPrimary,
        ),
      ),
    );
  }

  Widget _buildFitnessGoalSection() {
    return Column(
      children: FitnessGoal.values.map((goal) {
        final isSelected = _selectedFitnessGoal == goal;
        return _buildSelectionCard(
          title: _getFitnessGoalLabel(goal),
          subtitle: _getFitnessGoalDescription(goal),
          icon: _getFitnessGoalIcon(goal),
          isSelected: isSelected,
          onTap: () => _selectFitnessGoal(goal),
        );
      }).toList(),
    );
  }

  Widget _buildActivityLevelSection() {
    return Column(
      children: ActivityLevel.values.map((level) {
        final isSelected = _selectedActivityLevel == level;
        return _buildSelectionCard(
          title: _getActivityLevelLabel(level),
          subtitle: _getActivityLevelDescription(level),
          icon: _getActivityLevelIcon(level),
          isSelected: isSelected,
          onTap: () => _selectActivityLevel(level),
        );
      }).toList(),
    );
  }

  Widget _buildWorkoutStylesSection() {
    return Column(
      children: [
        // Add custom workout style
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _workoutStyleController,
                decoration: const InputDecoration(
                  hintText: 'Add a custom workout style',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _addCustomWorkoutStyle(),
              ),
            ),
            const SizedBox(width: AppConstants.spacingS),
            ElevatedButton(
              onPressed: _addCustomWorkoutStyle,
              child: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingM),

        // Predefined workout styles
        ..._workoutStyles.map((style) {
          final isSelected = _selectedWorkoutStyles.contains(style);
          return _buildSelectionCard(
            title: style,
            subtitle: _getWorkoutStyleDescription(style),
            icon: _getWorkoutStyleIcon(style),
            isSelected: isSelected,
            isMultiSelect: true,
            onTap: () => _toggleWorkoutStyle(style),
          );
        }).toList(),

        const SizedBox(height: AppConstants.spacingM),

        // Custom workout styles
        if (_selectedWorkoutStyles
            .any((style) => !_workoutStyles.contains(style)))
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Custom Workout Styles',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingS),
              Wrap(
                spacing: AppConstants.spacingS,
                runSpacing: AppConstants.spacingS,
                children: _selectedWorkoutStyles
                    .where((style) => !_workoutStyles.contains(style))
                    .map((style) {
                  return Chip(
                    label: Text(style),
                    onDeleted: () => _removeWorkoutStyle(style),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                  );
                }).toList(),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    bool isMultiSelect = false,
    required VoidCallback onTap,
  }) {
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppConstants.primaryColor
                        : AppConstants.textTertiary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? AppConstants.surfaceColor
                        : AppConstants.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
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
                  isMultiSelect
                      ? (isSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank)
                      : (isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked),
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

  String _getFitnessGoalLabel(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return 'Weight Loss';
      case FitnessGoal.muscleGain:
        return 'Muscle Gain';
      case FitnessGoal.maintenance:
        return 'Maintenance';
      case FitnessGoal.endurance:
        return 'Endurance';
      case FitnessGoal.strength:
        return 'Strength';
    }
  }

  String _getFitnessGoalDescription(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return 'Reduce body fat and lose weight';
      case FitnessGoal.muscleGain:
        return 'Build muscle mass and strength';
      case FitnessGoal.maintenance:
        return 'Maintain current fitness level';
      case FitnessGoal.endurance:
        return 'Improve cardiovascular endurance';
      case FitnessGoal.strength:
        return 'Focus on strength and power';
    }
  }

  IconData _getFitnessGoalIcon(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return Icons.trending_down;
      case FitnessGoal.muscleGain:
        return Icons.fitness_center;
      case FitnessGoal.maintenance:
        return Icons.balance;
      case FitnessGoal.endurance:
        return Icons.favorite;
      case FitnessGoal.strength:
        return Icons.sports_gymnastics;
    }
  }

  String _getActivityLevelLabel(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
      case ActivityLevel.extremelyActive:
        return 'Extremely Active';
    }
  }

  String _getActivityLevelDescription(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Little to no exercise';
      case ActivityLevel.lightlyActive:
        return 'Light exercise 1-3 days/week';
      case ActivityLevel.moderatelyActive:
        return 'Moderate exercise 3-5 days/week';
      case ActivityLevel.veryActive:
        return 'Hard exercise 6-7 days/week';
      case ActivityLevel.extremelyActive:
        return 'Very hard exercise, physical job';
    }
  }

  IconData _getActivityLevelIcon(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return Icons.weekend;
      case ActivityLevel.lightlyActive:
        return Icons.directions_walk;
      case ActivityLevel.moderatelyActive:
        return Icons.directions_run;
      case ActivityLevel.veryActive:
        return Icons.sports_soccer;
      case ActivityLevel.extremelyActive:
        return Icons.fitness_center;
    }
  }

  String _getWorkoutStyleDescription(String style) {
    switch (style) {
      case 'Strength Training':
        return 'Build muscle and strength';
      case 'Body Building':
        return 'Focus on muscle hypertrophy and definition';
      case 'Cardio':
        return 'Boost heart health and overall fitness';
      case 'HIIT':
        return 'High-intensity interval training';
      case 'Running':
        return 'Endurance and cardiovascular';
      default:
        return 'Custom workout style';
    }
  }

  IconData _getWorkoutStyleIcon(String style) {
    switch (style) {
      case 'Strength Training':
        return Icons.fitness_center;
      case 'Body Building':
        return Icons.sports_gymnastics;
      case 'Cardio':
        return Icons.favorite;
      case 'HIIT':
        return Icons.timer;
      case 'Running':
        return Icons.directions_run;
      case 'Yoga':
        return Icons.self_improvement;
      case 'Pilates':
        return Icons.accessibility_new;
      case 'CrossFit':
        return Icons.sports_martial_arts;
      case 'Swimming':
        return Icons.pool;
      case 'Cycling':
        return Icons.directions_bike;
      case 'Boxing':
        return Icons.sports_kabaddi;
      case 'Martial Arts':
        return Icons.sports_kabaddi;
      default:
        return Icons.fitness_center;
    }
  }
}
