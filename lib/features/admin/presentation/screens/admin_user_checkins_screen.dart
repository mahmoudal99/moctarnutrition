import 'package:flutter/material.dart';
import 'package:champions_gym_app/shared/models/user_model.dart';
import 'package:champions_gym_app/shared/models/checkin_model.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:champions_gym_app/features/checkin/presentation/screens/checkin_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserCheckinsScreen extends StatelessWidget {
  final UserModel user;

  const AdminUserCheckinsScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('AdminUserCheckinsScreen - Building with user: ${user.id}');
    return FutureBuilder<List<CheckinModel>>(
      future: _fetchCheckins(user.id),
      builder: (context, snapshot) {
        print('AdminUserCheckinsScreen - FutureBuilder state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}');
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
        print('AdminUserCheckinsScreen - Rendering with ${checkins.length} checkins');

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats section
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        '${checkins.length}',
                        'Check-ins',
                        Icons.check_circle_outline,
                        AppConstants.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        '${_calculateActiveWeeks(checkins)}',
                        'Active Weeks',
                        Icons.calendar_today_outlined,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
          
                const SizedBox(height: 32),
          
                // Check-ins list
                Text(
                  'Recent Check-ins',
                  style: AppTextStyles.heading4.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
          
                const SizedBox(height: 16),
          
                if (checkins.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.fitness_center_outlined,
                            size: 32, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No check-ins yet',
                          style: AppTextStyles.bodyLarge
                              .copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This user hasn\'t checked in yet',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                else
                  ...checkins
                      .map((checkin) => _buildCheckinCard(context, checkin)),
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
          .limit(50)
          .get();

      final checkins = querySnapshot.docs
          .map((doc) {
            try {
              return CheckinModel.fromJson(doc.data());
            } catch (e) {
              print('Error processing checkin doc ${doc.id}: $e');
              return null;
            }
          })
          .where((checkin) => checkin != null)
          .cast<CheckinModel>()
          .toList();
      
      return checkins;
    } catch (e) {
      print('Error fetching checkins: $e');
      return [];
    }
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading4.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckinCard(BuildContext context, CheckinModel checkin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor(checkin.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getStatusIcon(checkin.status),
            color: _getStatusColor(checkin.status),
            size: 20,
          ),
        ),
        title: Text(
          _getStatusText(checkin.status),
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        subtitle: Text(
          _formatTimestamp(checkin.createdAt),
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 16,
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CheckinDetailsScreen(checkin: checkin),
            ),
          );
        },
      ),
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
        return 'Workout Completed';
      case CheckinStatus.missed:
        return 'Workout Missed';
      case CheckinStatus.pending:
        return 'Workout Pending';
      default:
        return 'Unknown Status';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
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
}
