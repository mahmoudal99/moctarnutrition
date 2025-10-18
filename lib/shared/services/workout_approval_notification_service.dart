import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'notification_service.dart';

class WorkoutApprovalNotificationService {
  static final _logger = Logger();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send notification when workout plan is approved
  static Future<void> notifyWorkoutPlanApproved(
    String userId,
    String workoutPlanTitle,
    String trainerName,
  ) async {
    try {
      _logger.i('Sending workout plan approval notification to user: $userId');
      
      // Store notification in Firestore for the user
      await _storeNotification(
        userId: userId,
        title: 'Workout Plan Approved! 🎉',
        body: 'Your workout plan "$workoutPlanTitle" has been approved by $trainerName. You can now start your training!',
        type: 'workout_approved',
        data: {
          'workoutPlanTitle': workoutPlanTitle,
          'trainerName': trainerName,
          'action': 'view_workout',
        },
      );
      
      _logger.i('Workout plan approval notification sent successfully');
    } catch (e) {
      _logger.e('Error sending workout plan approval notification: $e');
    }
  }

  /// Send notification when workout plan is rejected
  static Future<void> notifyWorkoutPlanRejected(
    String userId,
    String workoutPlanTitle,
    String trainerName,
    String rejectionReason,
  ) async {
    try {
      _logger.i('Sending workout plan rejection notification to user: $userId');
      
      // Store notification in Firestore for the user
      await _storeNotification(
        userId: userId,
        title: 'Workout Plan Needs Revision',
        body: 'Your workout plan "$workoutPlanTitle" was rejected by $trainerName. Reason: $rejectionReason',
        type: 'workout_rejected',
        data: {
          'workoutPlanTitle': workoutPlanTitle,
          'trainerName': trainerName,
          'rejectionReason': rejectionReason,
          'action': 'generate_new_workout',
        },
      );
      
      _logger.i('Workout plan rejection notification sent successfully');
    } catch (e) {
      _logger.e('Error sending workout plan rejection notification: $e');
    }
  }

  /// Send notification to trainers when new workout plan needs approval
  static Future<void> notifyTrainersNewWorkoutPlan(
    String userId,
    String workoutPlanTitle,
  ) async {
    try {
      _logger.i('Notifying trainers about new workout plan from user: $userId');
      
      // Get all trainers
      final trainersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'trainer')
          .get();

      for (final trainerDoc in trainersSnapshot.docs) {
        final trainerId = trainerDoc.id;
        
        await _storeNotification(
          userId: trainerId,
          title: 'New Workout Plan Needs Approval',
          body: 'A new workout plan "$workoutPlanTitle" from user $userId is waiting for your approval.',
          type: 'workout_pending_approval',
          data: {
            'workoutPlanTitle': workoutPlanTitle,
            'requesterUserId': userId,
            'action': 'review_workout',
          },
        );
      }
      
      _logger.i('Trainer notifications sent successfully');
    } catch (e) {
      _logger.e('Error sending trainer notifications: $e');
    }
  }

  /// Send notification to admins when new workout plan needs approval
  static Future<void> notifyAdminsNewWorkoutPlan(
    String userId,
    String workoutPlanTitle,
  ) async {
    try {
      _logger.i('Notifying admins about new workout plan from user: $userId');
      
      // Get all admins
      final adminsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      for (final adminDoc in adminsSnapshot.docs) {
        final adminId = adminDoc.id;
        
        await _storeNotification(
          userId: adminId,
          title: 'New Workout Plan Needs Approval',
          body: 'A new workout plan "$workoutPlanTitle" from user $userId is waiting for approval.',
          type: 'workout_pending_approval',
          data: {
            'workoutPlanTitle': workoutPlanTitle,
            'requesterUserId': userId,
            'action': 'review_workout',
          },
        );
      }
      
      _logger.i('Admin notifications sent successfully');
    } catch (e) {
      _logger.e('Error sending admin notifications: $e');
    }
  }

  /// Send notification when workout plan is generated and pending approval
  static Future<void> notifyWorkoutPlanPending(
    String userId,
    String workoutPlanTitle,
  ) async {
    try {
      _logger.i('Sending workout plan pending notification to user: $userId');
      
      // Store notification in Firestore for the user
      await _storeNotification(
        userId: userId,
        title: 'Workout Plan Generated! ⏳',
        body: 'Your personalized workout plan "$workoutPlanTitle" has been generated and is being reviewed by our trainers.',
        type: 'workout_pending',
        data: {
          'workoutPlanTitle': workoutPlanTitle,
          'action': 'view_status',
        },
      );
      
      _logger.i('Workout plan pending notification sent successfully');
    } catch (e) {
      _logger.e('Error sending workout plan pending notification: $e');
    }
  }

  /// Store notification in Firestore
  static Future<void> _storeNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      _logger.d('Notification stored for user: $userId');
    } catch (e) {
      _logger.e('Error storing notification: $e');
      rethrow;
    }
  }

  /// Get notification count for pending workout plans
  static Future<int> getPendingWorkoutPlansNotificationCount() async {
    try {
      final querySnapshot = await _firestore
          .collection('workout_plans')
          .where('approvalStatus', isEqualTo: 'pending')
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      _logger.e('Error getting pending workout plans count: $e');
      return 0;
    }
  }

  /// Get notifications for a user
  static Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      _logger.e('Error getting user notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      _logger.d('Notification marked as read: $notificationId');
    } catch (e) {
      _logger.e('Error marking notification as read: $e');
    }
  }

  /// Get unread notification count for a user
  static Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      _logger.e('Error getting unread notification count: $e');
      return 0;
    }
  }
}