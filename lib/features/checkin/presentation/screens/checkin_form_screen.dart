import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/checkin_provider.dart';
import '../../../../shared/models/checkin_model.dart';
import '../widgets/photo_capture_widget.dart';
import '../widgets/progress_metrics_form.dart';
import '../widgets/mood_energy_form.dart';

class CheckinFormScreen extends StatefulWidget {
  const CheckinFormScreen({super.key});

  @override
  State<CheckinFormScreen> createState() => _CheckinFormScreenState();
}

class _CheckinFormScreenState extends State<CheckinFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _weightController = TextEditingController();

  String? _selectedPhotoPath;
  String? _selectedMood;
  int? _selectedEnergyLevel;
  int? _selectedMotivationLevel;
  Map<String, double> _measurements = {};

  bool _isSubmitting = false;
  int _currentStep = 0;
  final int _totalSteps = 3;

  @override
  void dispose() {
    _notesController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Weekly Check-in',
          style:
              AppTextStyles.heading4.copyWith(color: AppConstants.textPrimary),
        ),
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppConstants.textPrimary),
          onPressed: () => _showExitDialog(),
        ),
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _previousStep,
              child: Text(
                'Back',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: _buildCurrentStep(),
          ),
          const SizedBox(
            height: 128,
          )
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;

              return Expanded(
                child: Container(
                  margin:
                      EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppConstants.successColor
                              : isCurrent
                                  ? AppConstants.primaryColor
                                  : AppConstants.textTertiary.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check : _getStepIcon(index),
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getStepTitle(index),
                        style: AppTextStyles.caption.copyWith(
                          color: isCurrent
                              ? AppConstants.primaryColor
                              : AppConstants.textSecondary,
                          fontWeight:
                              isCurrent ? FontWeight.w600 : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildPhotoStep();
      case 1:
        return _buildMetricsStep();
      case 2:
        return _buildMoodStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPhotoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Take Progress Photo',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 8),
          Text(
            'Capture your progress with a clear, consistent photo. This helps track your fitness journey over time.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          PhotoCaptureWidget(
            selectedPhotoPath: _selectedPhotoPath,
            onPhotoSelected: (path) {
              setState(() {
                _selectedPhotoPath = path;
              });
            },
          ),
          const SizedBox(height: 24),
          _buildPhotoTips(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedPhotoPath != null ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Continue',
                style: AppTextStyles.button,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress Metrics',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),
            Text(
              'Track your physical progress with these optional metrics.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ProgressMetricsForm(
              weightController: _weightController,
              measurements: _measurements,
              onMeasurementsChanged: (measurements) {
                setState(() {
                  _measurements = measurements;
                });
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Notes (Optional)',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'How are you feeling about your progress? Any challenges or achievements?',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppConstants.textTertiary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppConstants.textTertiary.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppConstants.textTertiary.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppConstants.primaryColor,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousStep,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppConstants.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Back',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: AppTextStyles.button,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How are you feeling?',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 8),
          Text(
            'Track your mental and emotional state to get a complete picture of your fitness journey.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          MoodEnergyForm(
            selectedMood: _selectedMood,
            selectedEnergyLevel: _selectedEnergyLevel,
            selectedMotivationLevel: _selectedMotivationLevel,
            onMoodChanged: (mood) {
              setState(() {
                _selectedMood = mood;
              });
            },
            onEnergyLevelChanged: (level) {
              setState(() {
                _selectedEnergyLevel = level;
              });
            },
            onMotivationLevelChanged: (level) {
              setState(() {
                _selectedMotivationLevel = level;
              });
            },
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppConstants.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitCheckin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Submit Check-in',
                          style: AppTextStyles.button,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Photo Tips',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTipItem('• Use consistent lighting and background'),
          _buildTipItem('• Wear similar clothing each time'),
          _buildTipItem('• Take photos from the same angle'),
          _buildTipItem('• Include full body shots for best tracking'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        tip,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppConstants.textSecondary,
        ),
      ),
    );
  }

  IconData _getStepIcon(int step) {
    switch (step) {
      case 0:
        return Icons.camera_alt;
      case 1:
        return Icons.analytics;
      case 2:
        return Icons.psychology;
      default:
        return Icons.circle;
    }
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Photo';
      case 1:
        return 'Metrics';
      case 2:
        return 'Mood';
      default:
        return '';
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _submitCheckin() async {
    if (_selectedPhotoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take a progress photo'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    // Check if it's Sunday (weekday 7)
    final now = DateTime.now();
    if (now.weekday != 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Check-ins can only be submitted on Sundays. Today is ${_getDayName(now.weekday)}.'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    // Check if there's already a check-in for this week
    final checkinProvider =
        Provider.of<CheckinProvider>(context, listen: false);
    final currentWeekCheckin = checkinProvider.currentWeekCheckin;

    if (currentWeekCheckin != null &&
        currentWeekCheckin.status == CheckinStatus.completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already submitted a check-in for this week.'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await checkinProvider.submitCheckin(
        photoPath: _selectedPhotoPath!,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        weight: _weightController.text.isNotEmpty
            ? double.tryParse(_weightController.text)
            : null,
        measurements: _measurements.isNotEmpty ? _measurements : null,
        mood: _selectedMood,
        energyLevel: _selectedEnergyLevel,
        motivationLevel: _selectedMotivationLevel,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Check-in submitted successfully! Your photo is being uploaded in the background.'),
            backgroundColor: AppConstants.successColor,
            duration: Duration(seconds: 4),
          ),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(checkinProvider.error ?? 'Failed to submit check-in'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Check-in'),
        content: const Text(
            'Are you sure you want to exit? Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
