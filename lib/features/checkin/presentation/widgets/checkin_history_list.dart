import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/checkin_model.dart';
import '../../../../shared/services/background_upload_service.dart';

class CheckinHistoryList extends StatelessWidget {
  final List<CheckinModel> checkins;
  final Function(CheckinModel) onCheckinTap;
  final bool showLoadMore;
  final VoidCallback? onLoadMore;

  const CheckinHistoryList({
    super.key,
    required this.checkins,
    required this.onCheckinTap,
    this.showLoadMore = false,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (checkins.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        ...checkins.map((checkin) => _CheckinHistoryItem(
              checkin: checkin,
              onTap: () => onCheckinTap(checkin),
            )),
        if (showLoadMore && onLoadMore != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onLoadMore,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppConstants.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Load More',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CheckinHistoryItem extends StatelessWidget {
  final CheckinModel checkin;
  final VoidCallback onTap;

  const _CheckinHistoryItem({
    required this.checkin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildPhotoThumbnail(),
              const SizedBox(width: 16),
              Expanded(
                child: _buildContent(),
              ),
              _buildStatusIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FutureBuilder<String?>(
          future: BackgroundUploadService.getLocalImagePath(checkin.id),
          builder: (context, snapshot) {
            // First priority: Show local image if it exists
            if (snapshot.hasData && snapshot.data != null) {
              return Image.file(
                File(snapshot.data!),
                fit: BoxFit.cover,
                width: 60,
                height: 60,
                errorBuilder: (context, error, stackTrace) {
                  // If local image fails, fall back to Firebase URL
                  if (checkin.photoThumbnailUrl != null) {
                    return CachedNetworkImage(
                      imageUrl: checkin.photoThumbnailUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppConstants.textTertiary.withOpacity(0.1),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: AppConstants.textTertiary,
                          size: 24,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppConstants.textTertiary.withOpacity(0.1),
                        child: const Icon(
                          Icons.error_outline,
                          color: AppConstants.errorColor,
                          size: 24,
                        ),
                      ),
                    );
                  }
                  return Container(
                    color: AppConstants.textTertiary.withOpacity(0.1),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: AppConstants.textTertiary,
                      size: 24,
                    ),
                  );
                },
              );
            }

            // Second priority: Show Firebase URL if available
            if (checkin.photoThumbnailUrl != null) {
              return CachedNetworkImage(
                imageUrl: checkin.photoThumbnailUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppConstants.textTertiary.withOpacity(0.1),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppConstants.textTertiary,
                    size: 24,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppConstants.textTertiary.withOpacity(0.1),
                  child: const Icon(
                    Icons.error_outline,
                    color: AppConstants.errorColor,
                    size: 24,
                  ),
                ),
              );
            }

            // Last resort: No photo available
            return Container(
              color: AppConstants.textTertiary.withOpacity(0.1),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: AppConstants.textTertiary,
                size: 24,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                checkin.weekRangeWithYear,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (checkin.weight != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${checkin.weight!.toStringAsFixed(1)} kg',
                  style: AppTextStyles.caption.copyWith(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (checkin.notes?.isNotEmpty == true) ...[
          Text(
            checkin.notes!,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppConstants.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            const Icon(
              Icons.schedule,
              size: 14,
              color: AppConstants.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDate(checkin.submittedAt ?? checkin.createdAt),
              style: AppTextStyles.caption.copyWith(
                color: AppConstants.textTertiary,
              ),
            ),
            if (checkin.energyLevel != null) ...[
              const SizedBox(width: 16),
              const Icon(
                Icons.flash_on,
                size: 14,
                color: AppConstants.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                '${checkin.energyLevel}/10',
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
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

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            statusIcon,
            color: statusColor,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          statusText,
          style: AppTextStyles.caption.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
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
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
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
      return '${months[date.month - 1]} ${date.day}';
    }
  }
}
