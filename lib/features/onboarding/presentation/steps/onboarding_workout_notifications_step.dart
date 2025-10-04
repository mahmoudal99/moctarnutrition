import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_button.dart';

class OnboardingWorkoutNotificationsStep extends StatefulWidget {
  final TimeOfDay? selectedTime;
  final bool notificationsEnabled;
  final ValueChanged<TimeOfDay?> onTimeChanged;
  final ValueChanged<bool> onNotificationsChanged;

  const OnboardingWorkoutNotificationsStep({
    super.key,
    this.selectedTime,
    required this.notificationsEnabled,
    required this.onTimeChanged,
    required this.onNotificationsChanged,
  });

  @override
  State<OnboardingWorkoutNotificationsStep> createState() =>
      _OnboardingWorkoutNotificationsStepState();
}

class _OnboardingWorkoutNotificationsStepState
    extends State<OnboardingWorkoutNotificationsStep> {
  late TimeOfDay _selectedTime;
  late bool _notificationsEnabled;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.selectedTime ?? const TimeOfDay(hour: 9, minute: 0);
    _notificationsEnabled = widget.notificationsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight =
        screenHeight * 0.5; // Use 50% of screen for centering

    return SizedBox(
      height: availableHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Notification preview card
          _buildNotificationPreview(),
          const SizedBox(height: AppConstants.spacingL),

          // Time selection
          _buildTimeSelection(),
          const SizedBox(height: AppConstants.spacingM),

          // Hint text
          Text(
            'You can easily change this later in the app',
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPreview() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingS),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Example:',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppConstants.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          _buildNotificationCard(),
        ],
      ),
    );
  }

  Widget _buildNotificationCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: Colors.grey[200]!,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Notification content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  children: [
                    Text(
                      'TODAY\'S WORKOUT IS READY',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Push Day: Barbell Bench Press, Dumbbell Shoulder Press, Lateral Raise, and 3 more.',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose a time to receive your preview:',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        Row(
          children: [
            Text(
              'Time',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _selectTime,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                  vertical: AppConstants.spacingS,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  border: Border.all(
                    color: AppConstants.borderColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedTime.format(context),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppConstants.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppConstants.surfaceColor,
              hourMinuteTextColor: AppConstants.textPrimary,
              hourMinuteColor: AppConstants.primaryColor.withOpacity(0.1),
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              dialBackgroundColor: AppConstants.surfaceColor,
              dialHandColor: AppConstants.primaryColor,
              dialTextColor: AppConstants.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      widget.onTimeChanged(picked);
    }
  }
}
