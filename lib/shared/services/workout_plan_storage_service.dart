import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/workout_plan_model.dart';

class WorkoutPlanStorageService {
  static final _logger = Logger();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'workout_plans';

  /// Save workout plan to Firestore
  static Future<void> saveWorkoutPlan(WorkoutPlanModel workoutPlan) async {
    try {
      _logger.d('Saving workout plan to Firestore: ${workoutPlan.id}');

      await _firestore
          .collection(_collectionName)
          .doc(workoutPlan.id)
          .set(workoutPlan.toJson());

      _logger.i('Workout plan saved successfully: ${workoutPlan.id}');
    } catch (e) {
      _logger.e('Failed to save workout plan: $e');
      rethrow;
    }
  }

  /// Get workout plan for user from Firestore
  static Future<WorkoutPlanModel?> getWorkoutPlan(String userId) async {
    try {
      _logger.d('Fetching workout plan for user: $userId');

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final workoutPlan = WorkoutPlanModel.fromJson(doc.data());
        _logger.i('Workout plan found: ${workoutPlan.id}');
        return workoutPlan;
      } else {
        _logger.i('No active workout plan found for user: $userId');
        return null;
      }
    } catch (e) {
      _logger.e('Failed to fetch workout plan: $e');
      rethrow;
    }
  }

  /// Update workout plan in Firestore
  static Future<void> updateWorkoutPlan(WorkoutPlanModel workoutPlan) async {
    try {
      _logger.d('Updating workout plan: ${workoutPlan.id}');

      await _firestore
          .collection(_collectionName)
          .doc(workoutPlan.id)
          .update(workoutPlan.toJson());

      _logger.i('Workout plan updated successfully: ${workoutPlan.id}');
    } catch (e) {
      _logger.e('Failed to update workout plan: $e');
      rethrow;
    }
  }

  /// Deactivate all workout plans for a user
  static Future<void> deactivateUserWorkoutPlans(String userId) async {
    try {
      _logger.d('Deactivating all workout plans for user: $userId');

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _firestore.batch();

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isActive': false});
      }

      await batch.commit();
      _logger.i(
          'Deactivated ${querySnapshot.docs.length} workout plans for user: $userId');
    } catch (e) {
      _logger.e('Failed to deactivate workout plans: $e');
      rethrow;
    }
  }

  /// Delete workout plan from Firestore
  static Future<void> deleteWorkoutPlan(String workoutPlanId) async {
    try {
      _logger.d('Deleting workout plan: $workoutPlanId');

      await _firestore.collection(_collectionName).doc(workoutPlanId).delete();

      _logger.i('Workout plan deleted successfully: $workoutPlanId');
    } catch (e) {
      _logger.e('Failed to delete workout plan: $e');
      rethrow;
    }
  }

  /// Check if user has an active workout plan
  static Future<bool> hasActiveWorkoutPlan(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      _logger.e('Failed to check active workout plan: $e');
      return false;
    }
  }

  /// Get workout plan history for user
  static Future<List<WorkoutPlanModel>> getWorkoutPlanHistory(
      String userId) async {
    try {
      _logger.d('Fetching workout plan history for user: $userId');

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final workoutPlans = querySnapshot.docs
          .map((doc) => WorkoutPlanModel.fromJson(doc.data()))
          .toList();

      _logger.i('Found ${workoutPlans.length} workout plans in history');
      return workoutPlans;
    } catch (e) {
      _logger.e('Failed to fetch workout plan history: $e');
      rethrow;
    }
  }
}
