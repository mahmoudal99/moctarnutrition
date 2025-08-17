import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/meal_model.dart';

class MealPlanFirestoreService {
  static final _logger = Logger();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'meal_plans';

  /// Get meal plan for user from Firestore
  static Future<MealPlanModel?> getMealPlan(String userId) async {
    try {
      _logger.d('Fetching meal plan for user: $userId');
      
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final mealPlan = MealPlanModel.fromJson(doc.data());
        _logger.i('Meal plan found: ${mealPlan.id}');
        return mealPlan;
      } else {
        _logger.i('No meal plan found for user: $userId');
        return null;
      }
    } catch (e) {
      _logger.e('Failed to fetch meal plan: $e');
      rethrow;
    }
  }

  /// Get meal plan by ID from Firestore
  static Future<MealPlanModel?> getMealPlanById(String mealPlanId) async {
    try {
      _logger.d('Fetching meal plan by ID: $mealPlanId');
      
      final doc = await _firestore
          .collection(_collectionName)
          .doc(mealPlanId)
          .get();

      if (doc.exists) {
        final mealPlan = MealPlanModel.fromJson(doc.data()!);
        _logger.i('Meal plan found: ${mealPlan.id}');
        return mealPlan;
      } else {
        _logger.i('No meal plan found with ID: $mealPlanId');
        return null;
      }
    } catch (e) {
      _logger.e('Failed to fetch meal plan by ID: $e');
      rethrow;
    }
  }

  /// Save meal plan to Firestore
  static Future<void> saveMealPlan(MealPlanModel mealPlan) async {
    try {
      _logger.d('Saving meal plan to Firestore: ${mealPlan.id}');
      
      await _firestore
          .collection(_collectionName)
          .doc(mealPlan.id)
          .set(mealPlan.toJson());
      
      _logger.i('Meal plan saved successfully: ${mealPlan.id}');
    } catch (e) {
      _logger.e('Failed to save meal plan: $e');
      rethrow;
    }
  }

  /// Update meal plan in Firestore
  static Future<void> updateMealPlan(MealPlanModel mealPlan) async {
    try {
      _logger.d('Updating meal plan in Firestore: ${mealPlan.id}');
      
      await _firestore
          .collection(_collectionName)
          .doc(mealPlan.id)
          .update(mealPlan.toJson());
      
      _logger.i('Meal plan updated successfully: ${mealPlan.id}');
    } catch (e) {
      _logger.e('Failed to update meal plan: $e');
      rethrow;
    }
  }

  /// Delete meal plan from Firestore
  static Future<void> deleteMealPlan(String mealPlanId) async {
    try {
      _logger.d('Deleting meal plan from Firestore: $mealPlanId');
      
      await _firestore
          .collection(_collectionName)
          .doc(mealPlanId)
          .delete();
      
      _logger.i('Meal plan deleted successfully: $mealPlanId');
    } catch (e) {
      _logger.e('Failed to delete meal plan: $e');
      rethrow;
    }
  }

  /// Check if user has a meal plan
  static Future<bool> hasMealPlan(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      _logger.e('Failed to check meal plan existence: $e');
      return false;
    }
  }

  /// Get meal plan history for user
  static Future<List<MealPlanModel>> getMealPlanHistory(String userId) async {
    try {
      _logger.d('Fetching meal plan history for user: $userId');
      
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final mealPlans = querySnapshot.docs
          .map((doc) => MealPlanModel.fromJson(doc.data()))
          .toList();
      
      _logger.i('Found ${mealPlans.length} meal plans in history');
      return mealPlans;
    } catch (e) {
      _logger.e('Failed to fetch meal plan history: $e');
      rethrow;
    }
  }
} 