import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/checkin_model.dart';
import '../../../../shared/services/background_upload_service.dart';

class CheckinHistoryItem extends StatelessWidget {
  static const double _thumbnailSize = 60;
  static const double _thumbnailIconSize = 24;
  static const BorderRadius _thumbnailBorderRadius =
      BorderRadius.all(Radius.circular(8));
  final CheckinModel checkin;
  final VoidCallback onTap;

  const CheckinHistoryItem({
    super.key,
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
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              _buildPhotoThumbnail(),
              const SizedBox(width: 16),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail() {
    final borderColor = AppConstants.textTertiary.withOpacity(0.2);
    return Container(
      width: _thumbnailSize,
      height: _thumbnailSize,
      decoration: BoxDecoration(
        borderRadius: _thumbnailBorderRadius,
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: _thumbnailBorderRadius,
        child: FutureBuilder<String?>(
          future: BackgroundUploadService.getLocalImagePath(checkin.id),
          builder: (context, snapshot) {
            final placeholder = _buildThumbnailPlaceholder();
            if (snapshot.hasData && snapshot.data != null) {
              return Image.file(
                File(snapshot.data!),
                width: _thumbnailSize,
                height: _thumbnailSize,
                errorBuilder: (context, error, stackTrace) {
                  if (checkin.photoThumbnailUrl != null) {
                    return _buildNetworkThumbnail(checkin.photoThumbnailUrl!);
                  }
                  return placeholder;
                },
              );
            }

            if (checkin.photoThumbnailUrl != null) {
              return _buildNetworkThumbnail(checkin.photoThumbnailUrl!);
            }

            return placeholder;
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          "Check in week ${checkin.weekNumber.toString()}",
          style: AppTextStyles.heading5.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          _formatDate(checkin.weekStartDate),
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkThumbnail(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, _) => _buildThumbnailPlaceholder(),
      errorWidget: (context, __, ___) => _buildThumbnailPlaceholder(
        icon: Icons.error_outline,
        color: AppConstants.errorColor,
      ),
    );
  }

  Widget _buildThumbnailPlaceholder({
    IconData icon = Icons.camera_alt_outlined,
    Color color = AppConstants.textTertiary,
  }) {
    return Container(
      color: AppConstants.textTertiary.withOpacity(0.1),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: color,
        size: _thumbnailIconSize,
      ),
    );
  }

  String _formatDate(DateTime date) {
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
}
