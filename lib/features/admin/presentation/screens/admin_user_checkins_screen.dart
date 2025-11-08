import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:champions_gym_app/shared/models/user_model.dart';
import 'package:champions_gym_app/shared/models/checkin_model.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:champions_gym_app/features/checkin/presentation/screens/checkin_details_screen.dart';
import 'package:champions_gym_app/shared/services/background_upload_service.dart';
import 'package:champions_gym_app/features/admin/presentation/widgets/admin_user_app_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AdminUserCheckinsScreen extends StatelessWidget {
  final UserModel user;

  const AdminUserCheckinsScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CheckinModel>>(
      future: _fetchCheckins(user.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading check-ins',
                  style:
                      AppTextStyles.bodyLarge.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final checkins = snapshot.data ?? [];

        return Scaffold(
          appBar: AdminUserAppBar(
            user: user,
            title: 'Check-ins',
          ),
          body: checkins.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._buildStatsSection(checkins),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    "assets/images/image-delete-02-stroke-rounded.svg",
                                    height: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'No check-ins yet',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.heading4.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppConstants.spacingS),
                              Text(
                                'This user hasn\'t checked in yet',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 96),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._buildStatsSection(checkins),
                      ...checkins.map(
                        (checkin) => _buildCheckinCard(context, checkin),
                      ),
                      const SizedBox(height: 96),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Future<List<CheckinModel>> _fetchCheckins(String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('checkins')
          .where('userId', isEqualTo: userId)
          .orderBy('submittedAt', descending: true) // Sort by latest first
          .limit(50)
          .get();

      final checkins = querySnapshot.docs
          .map((doc) {
            try {
              return CheckinModel.fromJson(doc.data());
            } catch (e) {
              return null;
            }
          })
          .where((checkin) => checkin != null)
          .cast<CheckinModel>()
          .toList();

      // Additional sorting to ensure proper order (in case some don't have submittedAt)
      checkins.sort((a, b) {
        final aDate = a.submittedAt ?? a.createdAt;
        final bDate = b.submittedAt ?? b.createdAt;
        return bDate.compareTo(aDate); // Latest first
      });

      return checkins;
    } catch (e) {
      return [];
    }
  }

  List<Widget> _buildStatsSection(List<CheckinModel> checkins) {
    return [
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
                '${checkins.length}',
                'Check-ins',
                "image-done-02-stroke-rounded.svg",
                AppConstants.primaryColor,
                "uploads"),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
                '${_calculateActiveWeeks(checkins)}',
                'Active Weeks',
                "tick-double-03-stroke-rounded.svg",
                Colors.orange,
                "weeks"),
          ),
        ],
      ),
      const SizedBox(height: AppConstants.spacingM),
      Text('Recent Check-ins', style: AppTextStyles.heading5),
      const SizedBox(height: 16),
    ];
  }

  Widget _buildStatCard(
      String value, String label, String icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SvgPicture.asset(
                "assets/images/$icon",
                height: 20,
              ),
              SizedBox(
                width: AppConstants.spacingS,
              ),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.black,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: AppTextStyles.heading4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckinCard(BuildContext context, CheckinModel checkin) {
    final submissionDate = checkin.submittedAt ?? checkin.createdAt;

    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.spacingS),
      child: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CheckinDetailsScreen(checkin: checkin),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: AppConstants.radiusS),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Content area with image and details
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Image thumbnail
                      Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildPhotoThumbnail(checkin),
                        ),
                      ),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Week of ${checkin.weekRange}',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatRelativeTime(submissionDate),
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                            if (checkin.notes != null &&
                                checkin.notes!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                checkin.notes!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Header with status and date
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getStatusColor(checkin.status).withOpacity(0.1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(checkin.status),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getStatusIcon(checkin.status),
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getStatusText(checkin.status),
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Submitted: ${_formatDate(submissionDate)}',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
    );
  }

  Color _getStatusColor(CheckinStatus status) {
    switch (status) {
      case CheckinStatus.completed:
        return Colors.green;
      case CheckinStatus.missed:
        return Colors.red;
      case CheckinStatus.pending:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(CheckinStatus status) {
    switch (status) {
      case CheckinStatus.completed:
        return Icons.check_circle;
      case CheckinStatus.missed:
        return Icons.cancel;
      case CheckinStatus.pending:
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(CheckinStatus status) {
    switch (status) {
      case CheckinStatus.completed:
        return 'Check-in Completed';
      case CheckinStatus.missed:
        return 'Workout Missed';
      case CheckinStatus.pending:
        return 'Workout Pending';
      default:
        return 'Unknown Status';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkinDate = DateTime(date.year, date.month, date.day);

    if (checkinDate == today) {
      return 'Today at ${_formatTime(date)}';
    } else if (checkinDate == yesterday) {
      return 'Yesterday at ${_formatTime(date)}';
    } else {
      return '${_getMonthName(date.month)} ${date.day}, ${date.year} at ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  String _formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  int _calculateActiveWeeks(List<CheckinModel> checkins) {
    if (checkins.isEmpty) return 0;

    final weeks = <int>{};
    for (final checkin in checkins) {
      final weekStart = checkin.createdAt.subtract(
        Duration(days: checkin.createdAt.weekday - 1),
      );
      weeks.add(weekStart.millisecondsSinceEpoch);
    }

    return weeks.length;
  }

  Widget _buildPhotoThumbnail(CheckinModel checkin) {
    return FutureBuilder<String?>(
      future: BackgroundUploadService.getLocalImagePath(checkin.id),
      builder: (context, snapshot) {
        // First priority: Show local image if it exists
        if (snapshot.hasData && snapshot.data != null) {
          return Image.file(
            File(snapshot.data!),
            fit: BoxFit.cover,
            width: 80,
            height: 80,
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
    );
  }
}
