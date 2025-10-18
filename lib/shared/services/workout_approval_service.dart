import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/workout_plan_model.dart';
import '../models/user_model.dart';
import 'workout_approval_notification_service.dart';

class WorkoutApprovalService {
  static final _logger = Logger();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all pending workout plans for trainer approval
  static Future<List<WorkoutPlanModel>> getPendingWorkoutPlans() async {
    try {
      _logger.i('Fetching pending workout plans for approval');
      
      final querySnapshot = await _firestore
          .collection('workout_plans')
          .where('approvalStatus', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      final pendingPlans = querySnapshot.docs
          .map((doc) => WorkoutPlanModel.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      _logger.i('Found ${pendingPlans.length} pending workout plans');
      return pendingPlans;
    } catch (e) {
      _logger.e('Error fetching pending workout plans: $e');
      rethrow;
    }
  }

  /// Get pending workout plans for a specific user
  static Future<List<WorkoutPlanModel>> getPendingWorkoutPlansForUser(String userId) async {
    try {
      _logger.i('Fetching pending workout plans for user: $userId');
      
      final querySnapshot = await _firestore
          .collection('workout_plans')
          .where('userId', isEqualTo: userId)
          .where('approvalStatus', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      final pendingPlans = querySnapshot.docs
          .map((doc) => WorkoutPlanModel.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      _logger.i('Found ${pendingPlans.length} pending workout plans for user $userId');
      return pendingPlans;
    } catch (e) {
      _logger.e('Error fetching pending workout plans for user: $e');
      rethrow;
    }
  }

  /// Approve a workout plan
  static Future<void> approveWorkoutPlan(
    String workoutPlanId,
    String trainerId,
    String trainerName,
  ) async {
    try {
      _logger.i('Approving workout plan: $workoutPlanId by trainer: $trainerId');
      
      // Get the workout plan to send notification
      final workoutPlanDoc = await _firestore.collection('workout_plans').doc(workoutPlanId).get();
      final workoutPlan = WorkoutPlanModel.fromJson({
        'id': workoutPlanDoc.id,
        ...workoutPlanDoc.data()!,
      });

      await _firestore.collection('workout_plans').doc(workoutPlanId).update({
        'approvalStatus': 'approved',
        'approvedBy': trainerId,
        'approvedByTrainerName': trainerName,
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to user
      await WorkoutApprovalNotificationService.notifyWorkoutPlanApproved(
        workoutPlan.userId,
        workoutPlan.title,
        trainerName,
      );

      _logger.i('Successfully approved workout plan: $workoutPlanId');
    } catch (e) {
      _logger.e('Error approving workout plan: $e');
      rethrow;
    }
  }

  /// Reject a workout plan
  static Future<void> rejectWorkoutPlan(
    String workoutPlanId,
    String trainerId,
    String trainerName,
    String rejectionReason,
  ) async {
    try {
      _logger.i('Rejecting workout plan: $workoutPlanId by trainer: $trainerId');
      
      // Get the workout plan to send notification
      final workoutPlanDoc = await _firestore.collection('workout_plans').doc(workoutPlanId).get();
      final workoutPlan = WorkoutPlanModel.fromJson({
        'id': workoutPlanDoc.id,
        ...workoutPlanDoc.data()!,
      });

      await _firestore.collection('workout_plans').doc(workoutPlanId).update({
        'approvalStatus': 'rejected',
        'approvedBy': trainerId,
        'approvedByTrainerName': trainerName,
        'rejectionReason': rejectionReason,
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to user
      await WorkoutApprovalNotificationService.notifyWorkoutPlanRejected(
        workoutPlan.userId,
        workoutPlan.title,
        trainerName,
        rejectionReason,
      );

      _logger.i('Successfully rejected workout plan: $workoutPlanId');
    } catch (e) {
      _logger.e('Error rejecting workout plan: $e');
      rethrow;
    }
  }

  /// Get workout plan approval history for a user
  static Future<List<WorkoutPlanModel>> getWorkoutPlanHistory(String userId) async {
    try {
      _logger.i('Fetching workout plan history for user: $userId');
      
      final querySnapshot = await _firestore
          .collection('workout_plans')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final history = querySnapshot.docs
          .map((doc) => WorkoutPlanModel.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      _logger.i('Found ${history.length} workout plans in history for user $userId');
      return history;
    } catch (e) {
      _logger.e('Error fetching workout plan history: $e');
      rethrow;
    }
  }

  /// Get approved workout plans for a user
  static Future<List<WorkoutPlanModel>> getApprovedWorkoutPlans(String userId) async {
    try {
      _logger.i('Fetching approved workout plans for user: $userId');
      
      final querySnapshot = await _firestore
          .collection('workout_plans')
          .where('userId', isEqualTo: userId)
          .where('approvalStatus', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .get();

      final approvedPlans = querySnapshot.docs
          .map((doc) => WorkoutPlanModel.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      _logger.i('Found ${approvedPlans.length} approved workout plans for user $userId');
      return approvedPlans;
    } catch (e) {
      _logger.e('Error fetching approved workout plans: $e');
      rethrow;
    }
  }

  /// Check if user has any pending workout plans
  static Future<bool> hasPendingWorkoutPlans(String userId) async {
    try {
      final pendingPlans = await getPendingWorkoutPlansForUser(userId);
      return pendingPlans.isNotEmpty;
    } catch (e) {
      _logger.e('Error checking pending workout plans: $e');
      return false;
    }
  }

  /// Get count of pending workout plans for admin dashboard
  static Future<int> getPendingWorkoutPlansCount() async {
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

  /// Stream of pending workout plans for real-time updates
  static Stream<List<WorkoutPlanModel>> getPendingWorkoutPlansStream() {
    return _firestore
        .collection('workout_plans')
        .where('approvalStatus', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutPlanModel.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  /// Stream of user's workout plan status for real-time updates
  static Stream<List<WorkoutPlanModel>> getUserWorkoutPlansStream(String userId) {
    return _firestore
        .collection('workout_plans')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutPlanModel.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }
}
