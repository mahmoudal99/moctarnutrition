import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/checkin_model.dart';

class CheckinDetailsScreen extends StatelessWidget {
  final CheckinModel checkin;

  const CheckinDetailsScreen({
    super.key,
    required this.checkin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          checkin.weekRangeWithYear,
          style: AppTextStyles.heading4.copyWith(color: AppConstants.textPrimary),
        ),
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppConstants.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotoSection(),
            const SizedBox(height: 24),
            _buildStatusSection(),
            const SizedBox(height: 24),
            if (checkin.notes?.isNotEmpty == true) ...[
              _buildNotesSection(),
              const SizedBox(height: 24),
            ],
            if (checkin.weight != null) ...[
              _buildMetricsSection(),
              const SizedBox(height: 24),
            ],
            if (checkin.measurements?.isNotEmpty == true) ...[
              _buildMeasurementsSection(),
              const SizedBox(height: 24),
            ],
            if (checkin.mood != null || checkin.energyLevel != null || checkin.motivationLevel != null) ...[
              _buildMoodSection(),
              const SizedBox(height: 24),
            ],
            _buildTimelineSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress Photo',
          style: AppTextStyles.heading4,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppConstants.textTertiary.withOpacity(0.2),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: checkin.photoUrl != null
                ? CachedNetworkImage(
                    imageUrl: checkin.photoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppConstants.textTertiary.withOpacity(0.1),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppConstants.textTertiary.withOpacity(0.1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppConstants.errorColor,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load image',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppConstants.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    color: AppConstants.textTertiary.withOpacity(0.1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          color: AppConstants.textTertiary,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No photo available',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (checkin.status) {
      case CheckinStatus.completed:
        statusColor = AppConstants.successColor;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      case CheckinStatus.missed:
        statusColor = AppConstants.errorColor;
        statusIcon = Icons.cancel;
        statusText = 'Missed';
        break;
      case CheckinStatus.pending:
        statusColor = AppConstants.warningColor;
        statusIcon = Icons.schedule;
        statusText = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (checkin.submittedAt != null)
                  Text(
                    'Submitted ${_formatDate(checkin.submittedAt!)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: AppTextStyles.heading4,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.textTertiary.withOpacity(0.2),
            ),
          ),
          child: Text(
            checkin.notes!,
            style: AppTextStyles.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metrics',
          style: AppTextStyles.heading4,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          label: 'Weight',
          value: '${checkin.weight!.toStringAsFixed(1)} kg',
          icon: Icons.monitor_weight,
          color: AppConstants.primaryColor,
        ),
      ],
    );
  }

  Widget _buildMeasurementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Measurements',
          style: AppTextStyles.heading4,
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: checkin.measurements!.length,
          itemBuilder: (context, index) {
            final measurement = checkin.measurements!.entries.elementAt(index);
            return _buildMeasurementCard(
              label: measurement.key,
              value: '${measurement.value.toStringAsFixed(1)} cm',
            );
          },
        ),
      ],
    );
  }

  Widget _buildMoodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mood & Energy',
          style: AppTextStyles.heading4,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (checkin.mood != null)
              Expanded(
                child: _buildMoodCard(),
              ),
            if (checkin.mood != null && checkin.energyLevel != null)
              const SizedBox(width: 12),
            if (checkin.energyLevel != null)
              Expanded(
                child: _buildEnergyCard(),
              ),
          ],
        ),
        if (checkin.motivationLevel != null) ...[
          const SizedBox(height: 12),
          _buildMotivationCard(),
        ],
      ],
    );
  }

  Widget _buildTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timeline',
          style: AppTextStyles.heading4,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.textTertiary.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              _buildTimelineItem(
                label: 'Created',
                date: checkin.createdAt,
                icon: Icons.add_circle_outline,
              ),
              if (checkin.submittedAt != null) ...[
                const SizedBox(height: 12),
                _buildTimelineItem(
                  label: 'Submitted',
                  date: checkin.submittedAt!,
                  icon: Icons.check_circle_outline,
                ),
              ],
              const SizedBox(height: 12),
              _buildTimelineItem(
                label: 'Last Updated',
                date: checkin.updatedAt,
                icon: Icons.update,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading4.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementCard({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            _getMoodEmoji(checkin.mood!),
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            checkin.mood!,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.warningColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.flash_on,
            color: AppConstants.warningColor,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            '${checkin.energyLevel}/10',
            style: AppTextStyles.heading4.copyWith(
              color: AppConstants.warningColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Energy',
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.successColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.psychology,
            color: AppConstants.successColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${checkin.motivationLevel}/10',
                  style: AppTextStyles.heading4.copyWith(
                    color: AppConstants.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Motivation',
                  style: AppTextStyles.caption.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String label,
    required DateTime date,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppConstants.textSecondary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _formatDate(date),
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'calm':
        return '😌';
      case 'motivated':
        return '😤';
      case 'tired':
        return '😴';
      case 'stressed':
        return '😔';
      case 'frustrated':
        return '😡';
      default:
        return '😐';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today at ${_formatTime(date)}';
    } else if (difference == 1) {
      return 'Yesterday at ${_formatTime(date)}';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
} 