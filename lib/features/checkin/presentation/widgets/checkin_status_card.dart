import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/checkin_model.dart';

class CheckinStatusCard extends StatelessWidget {
  final CheckinModel? currentCheckin;
  final VoidCallback onCheckinNow;
  final VoidCallback onViewCheckin;

  const CheckinStatusCard({
    super.key,
    required this.currentCheckin,
    required this.onCheckinNow,
    required this.onViewCheckin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: _getStatusGradient(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildStatusContent(),
              const SizedBox(height: 20),
              _buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getStatusIcon(),
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getStatusTitle(),
                style: AppTextStyles.heading4.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _getStatusSubtitle(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusContent() {
    if (currentCheckin?.status == CheckinStatus.completed) {
      return _buildCompletedContent();
    } else if (currentCheckin?.isOverdue == true) {
      return _buildOverdueContent();
    } else {
      return _buildPendingContent();
    }
  }

  Widget _buildCompletedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Check-in completed!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Great job staying consistent with your progress tracking',
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        if (currentCheckin?.submittedAt != null) ...[
          const SizedBox(height: 12),
          Text(
            'Submitted ${_formatDate(currentCheckin!.submittedAt!)}',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOverdueContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Check-in overdue',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'You missed last week\'s check-in. Don\'t worry, you can still catch up!',
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${currentCheckin?.daysSinceSubmitted ?? 0} days overdue',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingContent() {
    final now = DateTime.now();
    final isSunday = now.weekday == 7;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isSunday ? Icons.schedule : Icons.event,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isSunday ? 'Time for your weekly check-in' : 'Check-in day is Sunday',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isSunday 
              ? 'Take a progress photo to track your fitness journey'
              : 'Come back on Sunday to submit your weekly check-in.',
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    if (currentCheckin?.status == CheckinStatus.completed) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onViewCheckin,
          icon: const Icon(Icons.visibility, color: Colors.white),
          label: const Text(
            'View Check-in',
            style: TextStyle(color: Colors.white),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    } else {
      final now = DateTime.now();
      final isSunday = now.weekday == 7;
      
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: isSunday ? onCheckinNow : null,
          icon: Icon(isSunday ? Icons.camera_alt : Icons.schedule),
          label: Text(isSunday ? 'Take Progress Photo' : 'Check-in on Sunday'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSunday ? Colors.white : Colors.white.withOpacity(0.3),
            foregroundColor: isSunday ? _getPrimaryColor() : Colors.white.withOpacity(0.7),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      );
    }
  }

  LinearGradient _getStatusGradient() {
    if (currentCheckin?.status == CheckinStatus.completed) {
      return const LinearGradient(
        colors: [AppConstants.successColor, Color(0xFF34D399)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (currentCheckin?.isOverdue == true) {
      return const LinearGradient(
        colors: [AppConstants.errorColor, Color(0xFFF87171)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return const LinearGradient(
        colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  IconData _getStatusIcon() {
    if (currentCheckin?.status == CheckinStatus.completed) {
      return Icons.check_circle_outline;
    } else if (currentCheckin?.isOverdue == true) {
      return Icons.warning_amber_outlined;
    } else {
      return Icons.camera_alt_outlined;
    }
  }

  String _getStatusTitle() {
    if (currentCheckin?.status == CheckinStatus.completed) {
      return 'Check-in Complete';
    } else if (currentCheckin?.isOverdue == true) {
      return 'Check-in Overdue';
    } else {
      return 'Weekly Check-in';
    }
  }

  String _getStatusSubtitle() {
    if (currentCheckin?.status == CheckinStatus.completed) {
      return 'Great job this week!';
    } else if (currentCheckin?.isOverdue == true) {
      return 'Time to catch up';
    } else {
      return 'Track your progress';
    }
  }

  Color _getPrimaryColor() {
    if (currentCheckin?.status == CheckinStatus.completed) {
      return AppConstants.successColor;
    } else if (currentCheckin?.isOverdue == true) {
      return AppConstants.errorColor;
    } else {
      return AppConstants.primaryColor;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}';
    }
  }

  int _getDaysUntilSunday() {
    final now = DateTime.now();
    final daysUntilSunday = (7 - now.weekday) % 7;
    return daysUntilSunday == 0 ? 7 : daysUntilSunday;
  }
} 