import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io'; // Added for File
import 'dart:async'; // Added for Timer
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/checkin_model.dart';
import '../../../../shared/providers/checkin_provider.dart';
import '../../../../shared/services/background_upload_service.dart';

class CheckinDetailsScreen extends StatefulWidget {
  final CheckinModel checkin;

  const CheckinDetailsScreen({
    super.key,
    required this.checkin,
  });

  @override
  State<CheckinDetailsScreen> createState() => _CheckinDetailsScreenState();
}

class _CheckinDetailsScreenState extends State<CheckinDetailsScreen> {
  CheckinModel? _currentCheckin;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _currentCheckin = widget.checkin;
  }


  void _refreshCheckinDataIfNeeded() {
    // Only refresh once to avoid infinite loops
    if (!_isRefreshing) {
      _isRefreshing = true;
      _refreshCheckinData();
    }
  }

  Future<void> _refreshCheckinData() async {
    try {
      final checkinProvider =
          Provider.of<CheckinProvider>(context, listen: false);
      await checkinProvider.refresh();

      // Find the updated checkin
      final updatedCheckin = checkinProvider.userCheckins.firstWhere(
        (checkin) => checkin.id == _currentCheckin!.id,
        orElse: () => _currentCheckin!,
      );

      if (updatedCheckin.photoUrl != null &&
          updatedCheckin.photoUrl != _currentCheckin?.photoUrl) {
        setState(() {
          _currentCheckin = updatedCheckin;
        });
      }
    } catch (e) {
      // Ignore errors
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkin = _currentCheckin ?? widget.checkin;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          _formatCheckinTitleDate(checkin),
          style:
              AppTextStyles.heading4.copyWith(color: AppConstants.textPrimary),
        ),
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios, color: AppConstants.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (checkin.photoUrl == null)
            IconButton(
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, color: AppConstants.textPrimary),
              onPressed: _isRefreshing ? null : _refreshCheckinData,
              tooltip: 'Refresh photo',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotoSection(checkin),
            const SizedBox(height: 24),
            _buildStatusSection(checkin),
            const SizedBox(height: 24),
            if (checkin.notes?.isNotEmpty == true) ...[
              _buildNotesSection(checkin),
              const SizedBox(height: 24),
            ],
            if (checkin.weight != null) ...[
              _buildMetricsSection(checkin),
              const SizedBox(height: 24),
            ],
            if (checkin.measurements?.isNotEmpty == true) ...[
              _buildMeasurementsSection(checkin),
              const SizedBox(height: 24),
            ],
            if (checkin.mood != null ||
                checkin.energyLevel != null ||
                checkin.motivationLevel != null) ...[
              _buildMoodSection(checkin),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection(CheckinModel checkin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress Photo',
          style: AppTextStyles.heading5,
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
            child: _buildPhotoContent(checkin),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoContent(CheckinModel checkin) {
    // First priority: Show local image if it exists (regardless of Firebase URLs)
    return FutureBuilder<String?>(
      future: _getLocalImagePath(checkin.id),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          // Show local image immediately - this is the priority
          return Image.file(
            File(snapshot.data!),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              // If local image fails, fall back to Firebase URL
              if (checkin.photoUrl != null && checkin.photoUrl!.isNotEmpty) {
                return CachedNetworkImage(
                  imageUrl: checkin.photoUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppConstants.textTertiary.withOpacity(0.1),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) =>
                      _buildNoPhotoPlaceholder(checkin),
                );
              }
              return _buildNoPhotoPlaceholder(checkin);
            },
          );
        }

        // Second priority: If no local image, check if we need to refresh data for Firebase URL
        if (checkin.photoUrl == null &&
            checkin.status == CheckinStatus.completed) {
          // Try to refresh the checkin data to get the Firebase URL
          _refreshCheckinDataIfNeeded();
        }

        // Third priority: Show Firebase URL if available
        if (checkin.photoUrl != null && checkin.photoUrl!.isNotEmpty) {
          return CachedNetworkImage(
            imageUrl: checkin.photoUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppConstants.textTertiary.withOpacity(0.1),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) =>
                _buildNoPhotoPlaceholder(checkin),
          );
        }

        // Last resort: No photo available
        return _buildNoPhotoPlaceholder(checkin);
      },
    );
  }

  Widget _buildNoPhotoPlaceholder(CheckinModel checkin) {
    return Container(
      color: AppConstants.textTertiary.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            "assets/images/weight-scale-stroke-rounded.svg",
            color: AppConstants.textTertiary,
            height: 48,
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
    );
  }

  Future<String?> _getLocalImagePath(String checkinId) async {
    return BackgroundUploadService.getLocalImagePath(checkinId);
  }

  Widget _buildStatusSection(CheckinModel checkin) {
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            "assets/images/tick-double-03-stroke-rounded.svg",
            color: statusColor,
            height: 24,
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

  Widget _buildNotesSection(CheckinModel checkin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: AppTextStyles.heading5,
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

  Widget _buildMetricsSection(CheckinModel checkin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metrics',
          style: AppTextStyles.heading5,
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

  Widget _buildMeasurementsSection(CheckinModel checkin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Measurements',
          style: AppTextStyles.heading5,
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

  Widget _buildMoodSection(CheckinModel checkin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mood & Energy',
          style: AppTextStyles.heading5,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (checkin.mood != null)
              Expanded(
                child: _buildMoodCard(checkin),
              ),
            if (checkin.mood != null && checkin.energyLevel != null)
              const SizedBox(width: 12),
            if (checkin.energyLevel != null)
              Expanded(
                child: _buildEnergyCard(checkin),
              ),
          ],
        ),
        if (checkin.motivationLevel != null) ...[
          const SizedBox(height: 12),
          _buildMotivationCard(checkin),
        ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                "assets/images/weight-scale-stroke-rounded.svg",
                color: Colors.black,
                height: 20,
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

  Widget _buildMoodCard(CheckinModel checkin) {
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

  Widget _buildEnergyCard(CheckinModel checkin) {
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
          const Icon(
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

  Widget _buildMotivationCard(CheckinModel checkin) {
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
          const Icon(
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

  String _formatCheckinTitleDate(CheckinModel checkin) {
    final date = checkin.submittedAt ?? checkin.weekStartDate;
    return _formatDateWithOrdinal(date);
  }

  String _formatDateWithOrdinal(DateTime date) {
    final formatted = DateFormat('EEEE d MMMM yyyy').format(date);
    final day = date.day;
    final suffix = _getOrdinalSuffix(day);
    return formatted.replaceFirst('$day', '$day$suffix');
  }

  String _getOrdinalSuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
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
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
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
