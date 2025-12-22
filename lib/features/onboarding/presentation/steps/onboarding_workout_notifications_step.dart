import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/notification_service.dart';

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
    _selectedTime = widget.selectedTime ?? const TimeOfDay(hour: 18, minute: 0);
    _notificationsEnabled = widget.notificationsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Main Heading
          _buildMainHeading(),
          const SizedBox(height: AppConstants.spacingM),

          // Supporting Text
          _buildSupportingText(),
          const SizedBox(height: AppConstants.spacingM),

          // Notification Preview Card
          _buildNotificationPreview(),
          const SizedBox(height: AppConstants.spacingXL),

          // Notification Toggle
          _buildNotificationToggle(),
          const SizedBox(height: AppConstants.spacingL),

          // Helper Text with Arrow
          _buildHelperText(),
        ],
      ),
    );
  }

  Widget _buildMainHeading() {
    return Text(
      'Build a habit easily.',
      textAlign: TextAlign.center,
      style: GoogleFonts.merriweather(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppConstants.textPrimary,
        height: 1.2,
      ),
    );
  }

  Widget _buildSupportingText() {
    return Text(
      'Turn on notifications to never miss a workout!',
      textAlign: TextAlign.center,
      style: AppTextStyles.bodySmall.copyWith(
        color: AppConstants.textSecondary,
      ),
    );
  }

  Widget _buildNotificationPreview() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: Colors.grey[200]!,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TIME SENSITIVE label and timestamp row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TIME SENSITIVE',
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                _selectedTime.format(context),
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  color: AppConstants.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingS),
          // Notification content with icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon - green square with white feather/dumbbell
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              // Notification text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Your Daily Workout Awaits',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Small decorative icon
                        const Icon(
                          Icons.star_outline,
                          size: 16,
                          color: Colors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Text(
                      'Consistency is the key to achieving your fitness goals.',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingS),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: AppConstants.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Turn on notifications',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          else
            Switch(
              value: _notificationsEnabled,
              onChanged: _handleToggleChange,
              activeColor: AppConstants.primaryColor,
            ),
        ],
      ),
    );
  }

  Future<void> _handleToggleChange(bool value) async {
    if (value) {
      // User wants to enable notifications - request permission
      setState(() {
        _isLoading = true;
      });

      try {
        final permissionResult =
            await NotificationService.requestNotificationPermission();

        if (permissionResult.isGranted) {
          setState(() {
            _notificationsEnabled = true;
            _isLoading = false;
          });
          widget.onNotificationsChanged(true);
          // Optionally show a test notification
          await NotificationService.showTestNotification();
        } else {
          // Permission denied - revert toggle
          setState(() {
            _notificationsEnabled = false;
            _isLoading = false;
          });
          widget.onNotificationsChanged(false);

          // Show message to user if permission was denied
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  permissionResult.isPermanentlyDenied
                      ? 'Notification permission is required. Please enable it in settings.'
                      : 'Notification permission was denied.',
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        setState(() {
          _notificationsEnabled = false;
          _isLoading = false;
        });
        widget.onNotificationsChanged(false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to request notification permission.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      // User wants to disable notifications
      setState(() {
        _notificationsEnabled = false;
      });
      widget.onNotificationsChanged(false);
    }
  }

  Widget _buildHelperText() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Helper text
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: AppConstants.spacingM),
            child: Text(
              "We'll remind you\naround the time you\nusually do workouts",
              textAlign: TextAlign.right,
              style: GoogleFonts.caveat(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppConstants.textSecondary,
                height: 1.3,
              ),
            ),
          ),
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

// Custom painter for curved arrow
class CurvedArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppConstants.textSecondary.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    // Draw curved line from bottom-right to top-left
    path.moveTo(size.width * 0.8, size.height * 0.9);
    path.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.5,
      size.width * 0.1,
      size.height * 0.1,
    );

    canvas.drawPath(path, paint);

    // Draw arrowhead
    final arrowPath = Path();
    arrowPath.moveTo(size.width * 0.1, size.height * 0.1);
    arrowPath.lineTo(size.width * 0.15, size.height * 0.15);
    arrowPath.lineTo(size.width * 0.05, size.height * 0.15);
    arrowPath.close();

    canvas.drawPath(arrowPath, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
