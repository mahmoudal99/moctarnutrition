import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'logging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'user_local_storage_service.dart';
import 'meal_plan_storage_service.dart';
import 'meal_plan_local_storage_service.dart';
import 'workout_plan_local_storage_service.dart';

class AuthService {
  // Remove old logger instance
  // static final _logger = Logger();
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final UserLocalStorageService _storageService =
      UserLocalStorageService();

  // Auth state stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  static User? get currentUser => _auth.currentUser;

  // Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Sign up with email and password
  static Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      LoggingService.logAuthEvent('Sign up attempt', metadata: {'email': email});

      // Create user with Firebase Auth
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to create user account');
      }

      // Update display name
      await user.updateDisplayName(name);

      // Try to use onboarding data from SharedPreferences
      final localUser = await _storageService.loadUser();
      UserModel userModel;
      if (localUser != null) {
        // Also try to get calculated nutrition targets
        final prefs = await SharedPreferences.getInstance();
        final proteinTargetsJson = prefs.getString('temp_protein_targets');
        final calorieTargetsJson = prefs.getString('temp_calorie_targets');

        UserPreferences updatedPreferences = localUser.preferences;

        // Add calculated nutrition targets if available
        if (proteinTargetsJson != null) {
          try {
            final proteinTargets = jsonDecode(proteinTargetsJson);
            updatedPreferences = updatedPreferences.copyWith(
              proteinTargets: proteinTargets,
            );
          } catch (e) {
          }
        }

        if (calorieTargetsJson != null) {
          try {
            final calorieTargets = jsonDecode(calorieTargetsJson);
            updatedPreferences = updatedPreferences.copyWith(
              calorieTargets: calorieTargets,
              targetCalories: calorieTargets['dailyTarget'] ??
                  updatedPreferences.targetCalories,
            );
          } catch (e) {
          }
        }

        userModel = localUser.copyWith(
          id: user.uid,
          email: email,
          name: name,
          photoUrl: user.photoURL ?? localUser.photoUrl,
          hasSeenOnboarding: localUser.hasSeenOnboarding,
          hasSeenGetStarted: localUser.hasSeenGetStarted,
          preferences: updatedPreferences,
          updatedAt: DateTime.now(),
        );

        // Clear temporary nutrition targets
        await prefs.remove('temp_protein_targets');
        await prefs.remove('temp_calorie_targets');
        await _storageService.clearUser();
      } else {
        userModel = UserModel(
          id: user.uid,
          email: email,
          name: name,
          photoUrl: user.photoURL,
          role: UserRole.user,
          trainingProgramStatus: TrainingProgramStatus.none,
          preferences: UserPreferences.defaultPreferences(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      await _createUserDocument(userModel);

      LoggingService.logAuthEvent(
        'User signed up successfully',
        userId: user.uid,
        metadata: {'email': email, 'name': name},
      );
      return userModel;
    } on FirebaseAuthException catch (e) {
      LoggingService.logError(
        'Firebase Auth error during sign up',
        error: e,
        context: 'AuthService.signUpWithEmailAndPassword',
        metadata: {'code': e.code, 'message': e.message},
      );
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      LoggingService.logError(
        'Unexpected error during sign up',
        error: e,
        context: 'AuthService.signUpWithEmailAndPassword',
      );
      throw Exception('Failed to create account: $e');
    }
  }

  /// Sign in with email and password
  static Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      LoggingService.logAuthEvent(
        'Sign in attempt',
        metadata: {'email': email},
      );
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to sign in');
      }
      // Get user data from Firestore
      UserModel? userModel = await _getUserDocument(user.uid);
      if (userModel == null) {
        // Migration: Try to load from SharedPreferences and upload to Firestore
        final localUser = await _storageService.loadUser();
        if (localUser != null) {
          final migratedUser = localUser.copyWith(
            id: user.uid,
            email: user.email ?? localUser.email,
            name: user.displayName ?? localUser.name,
            photoUrl: user.photoURL ?? localUser.photoUrl,
            hasSeenOnboarding: localUser.hasSeenOnboarding,
            hasSeenGetStarted: localUser.hasSeenGetStarted,
            preferences: localUser.preferences,
            updatedAt: DateTime.now(),
          );
          await _createUserDocument(migratedUser);
          userModel = migratedUser;
          await _storageService.clearUser(); // Clear local user after migration
          LoggingService.auth.i(
              'Migrated user from SharedPreferences to Firestore: ${user.uid}');
        } else {
          throw Exception('User profile not found');
        }
      }
      LoggingService.auth.i('User signed in successfully: ${user.uid}');
      return userModel;
    } on FirebaseAuthException catch (e) {
      LoggingService.auth.e('Firebase Auth error during sign in: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      LoggingService.auth.e('Unexpected error during sign in: $e');
      throw Exception('Failed to sign in: $e');
    }
  }

  /// Sign in with Google
  static Future<UserModel> signInWithGoogle() async {
    try {
      LoggingService.auth.i('Attempting Google sign in');
      
      // Check if Google Play Services are available (Android only)
      LoggingService.auth.i('Checking Google Sign In configuration');
      if (!await _googleSignIn.isSignedIn()) {
        LoggingService.auth.i('User is not signed in with Google, showing sign-in UI');
      }
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to sign in with Google');
      }
      await Future.delayed(const Duration(milliseconds: 500));
      UserModel? userModel = await _getUserDocument(user.uid);
      if (userModel == null) {
        final localUser = await _storageService.loadUser();
        if (localUser != null) {
          // Also try to get calculated nutrition targets
          final prefs = await SharedPreferences.getInstance();
          final proteinTargetsJson = prefs.getString('temp_protein_targets');
          final calorieTargetsJson = prefs.getString('temp_calorie_targets');

          UserPreferences updatedPreferences = localUser.preferences;

          // Add calculated nutrition targets if available
          if (proteinTargetsJson != null) {
            try {
              final proteinTargets = jsonDecode(proteinTargetsJson);
              updatedPreferences = updatedPreferences.copyWith(
                proteinTargets: proteinTargets,
              );
            } catch (e) {
            }
          }

          if (calorieTargetsJson != null) {
            try {
              final calorieTargets = jsonDecode(calorieTargetsJson);
              updatedPreferences = updatedPreferences.copyWith(
                calorieTargets: calorieTargets,
                targetCalories: calorieTargets['dailyTarget'] ??
                    updatedPreferences.targetCalories,
              );
            } catch (e) {
            }
          }

          final migratedUser = localUser.copyWith(
            id: user.uid,
            email: user.email ?? localUser.email,
            name: user.displayName ?? localUser.name,
            photoUrl: user.photoURL ?? localUser.photoUrl,
            hasSeenOnboarding: localUser.hasSeenOnboarding,
            hasSeenGetStarted: localUser.hasSeenGetStarted,
            preferences: updatedPreferences,
            updatedAt: DateTime.now(),
          );
          await _createUserDocument(migratedUser);
          userModel = migratedUser;

          // Clear temporary nutrition targets
          await prefs.remove('temp_protein_targets');
          await prefs.remove('temp_calorie_targets');
          await _storageService.clearUser(); // Clear local user after migration
          LoggingService.auth.i(
              'Migrated user from SharedPreferences to Firestore: ${user.uid}');
        } else {
          // Create new user document for first-time Google sign in
          userModel = UserModel(
            id: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? 'User',
            photoUrl: user.photoURL,
            role: UserRole.user,
            trainingProgramStatus: TrainingProgramStatus.none,
            preferences: UserPreferences.defaultPreferences(),
            hasSeenOnboarding: false,
            hasSeenGetStarted: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _createUserDocument(userModel);
          LoggingService.auth.i('Created new user document for Google sign in: ${user.uid}');
        }
      }
      LoggingService.auth.i('Google sign in successful: ${user.uid}');
      return userModel;
    } on FirebaseAuthException catch (e) {
      LoggingService.auth.e(
          'Firebase Auth error during Google sign in: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      LoggingService.auth.e('Unexpected error during Google sign in: $e');
      if (e.toString().contains('cloud_firestore/unavailable')) {
        throw Exception(
            'Firebase service is temporarily unavailable. Please try again in a few moments.');
      } else if (e.toString().contains('cloud_firestore/permission-denied')) {
        throw Exception(
            'Permission denied. Please ensure you are properly authenticated.');
      } else if (e.toString().contains('network')) {
        throw Exception(
            'Network error. Please check your internet connection and try again.');
      } else {
        throw Exception('Failed to sign in with Google: $e');
      }
    }
  }

  /// Sign in with Apple
  static Future<UserModel> signInWithApple() async {
    try {
      LoggingService.auth.i('Attempting Apple sign in');
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('Apple Sign-In is not available on this device');
      }
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final UserCredential userCredential =
          await _auth.signInWithCredential(oauthCredential);
      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to sign in with Apple');
      }
      await Future.delayed(const Duration(milliseconds: 500));
      UserModel? userModel = await _getUserDocument(user.uid);
      if (userModel == null) {
        final localUser = await _storageService.loadUser();
        if (localUser != null) {
          // Also try to get calculated nutrition targets
          final prefs = await SharedPreferences.getInstance();
          final proteinTargetsJson = prefs.getString('temp_protein_targets');
          final calorieTargetsJson = prefs.getString('temp_calorie_targets');

          UserPreferences updatedPreferences = localUser.preferences;

          // Add calculated nutrition targets if available
          if (proteinTargetsJson != null) {
            try {
              final proteinTargets = jsonDecode(proteinTargetsJson);
              updatedPreferences = updatedPreferences.copyWith(
                proteinTargets: proteinTargets,
              );
            } catch (e) {
            }
          }

          if (calorieTargetsJson != null) {
            try {
              final calorieTargets = jsonDecode(calorieTargetsJson);
              updatedPreferences = updatedPreferences.copyWith(
                calorieTargets: calorieTargets,
                targetCalories: calorieTargets['dailyTarget'] ??
                    updatedPreferences.targetCalories,
              );
            } catch (e) {
            }
          }

          final displayName =
              '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                  .trim();
          final migratedUser = localUser.copyWith(
            id: user.uid,
            email: user.email ?? appleCredential.email ?? localUser.email,
            name: displayName.isNotEmpty ? displayName : localUser.name,
            hasSeenOnboarding: localUser.hasSeenOnboarding,
            hasSeenGetStarted: localUser.hasSeenGetStarted,
            preferences: updatedPreferences,
            updatedAt: DateTime.now(),
          );
          await _createUserDocument(migratedUser);
          userModel = migratedUser;

          // Clear temporary nutrition targets
          await prefs.remove('temp_protein_targets');
          await prefs.remove('temp_calorie_targets');
          await _storageService.clearUser(); // Clear local user after migration
          LoggingService.auth.i(
              'Migrated user from SharedPreferences to Firestore: ${user.uid}');
        } else {
          final displayName =
              '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                  .trim();
          userModel = UserModel(
            id: user.uid,
            email: user.email ?? appleCredential.email ?? '',
            name: displayName.isNotEmpty ? displayName : 'User',
            photoUrl: user.photoURL,
            role: UserRole.user,
            trainingProgramStatus: TrainingProgramStatus.none,
            preferences: UserPreferences.defaultPreferences(),
            hasSeenOnboarding: false,
            hasSeenGetStarted: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _createUserDocument(userModel);
          LoggingService.auth.i(
              'Created new user document for Apple sign in: ${user.uid} with name: $displayName');
        }
      }
      LoggingService.auth.i('Apple sign in successful: ${user.uid}');
      return userModel;
    } on FirebaseAuthException catch (e) {
      LoggingService.auth.e(
          'Firebase Auth error during Apple sign in: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      LoggingService.auth.e('Unexpected error during Apple sign in: $e');
      if (e.toString().contains('cloud_firestore/unavailable')) {
        throw Exception(
            'Firebase service is temporarily unavailable. Please try again in a few moments.');
      } else if (e.toString().contains('cloud_firestore/permission-denied')) {
        throw Exception(
            'Permission denied. Please ensure you are properly authenticated.');
      } else if (e.toString().contains('network')) {
        throw Exception(
            'Network error. Please check your internet connection and try again.');
      } else {
        throw Exception('Failed to sign in with Apple: $e');
      }
    }
  }

  /// Sign in anonymously (guest mode)
  static Future<UserModel> signInAnonymously() async {
    try {
      LoggingService.auth.i('Attempting anonymous sign in');
      final UserCredential userCredential = await _auth.signInAnonymously();
      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to sign in anonymously');
      }
      await Future.delayed(const Duration(milliseconds: 500));
      UserModel? userModel = await _getUserDocument(user.uid);
      if (userModel == null) {
        final localUser = await _storageService.loadUser();
        if (localUser != null) {
          // Also try to get calculated nutrition targets
          final prefs = await SharedPreferences.getInstance();
          final proteinTargetsJson = prefs.getString('temp_protein_targets');
          final calorieTargetsJson = prefs.getString('temp_calorie_targets');

          UserPreferences updatedPreferences = localUser.preferences;

          // Add calculated nutrition targets if available
          if (proteinTargetsJson != null) {
            try {
              final proteinTargets = jsonDecode(proteinTargetsJson);
              updatedPreferences = updatedPreferences.copyWith(
                proteinTargets: proteinTargets,
              );
            } catch (e) {
            }
          }

          if (calorieTargetsJson != null) {
            try {
              final calorieTargets = jsonDecode(calorieTargetsJson);
              updatedPreferences = updatedPreferences.copyWith(
                calorieTargets: calorieTargets,
                targetCalories: calorieTargets['dailyTarget'] ??
                    updatedPreferences.targetCalories,
              );
            } catch (e) {
            }
          }

          final migratedUser = localUser.copyWith(
            id: user.uid,
            email: 'guest@championsgym.com',
            name: 'Guest User',
            hasSeenOnboarding: localUser.hasSeenOnboarding,
            hasSeenGetStarted: localUser.hasSeenGetStarted,
            preferences: updatedPreferences,
            updatedAt: DateTime.now(),
          );
          await _createUserDocument(migratedUser);
          userModel = migratedUser;

          // Clear temporary nutrition targets
          await prefs.remove('temp_protein_targets');
          await prefs.remove('temp_calorie_targets');
          await _storageService.clearUser(); // Clear local user after migration
          LoggingService.auth.i(
              'Migrated anonymous user from SharedPreferences to Firestore: ${user.uid}');
        } else {
          userModel = UserModel(
            id: user.uid,
            email: 'guest@championsgym.com',
            name: 'Guest User',
            photoUrl: null,
            role: UserRole.user,
            trainingProgramStatus: TrainingProgramStatus.none,
            preferences: UserPreferences.defaultPreferences(),
            hasSeenOnboarding: false,
            hasSeenGetStarted: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _createUserDocument(userModel);
        }
      }
      LoggingService.auth.i('Anonymous sign in successful: ${user.uid}');
      return userModel;
    } on FirebaseAuthException catch (e) {
      LoggingService.auth.e(
          'Firebase Auth error during anonymous sign in: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      LoggingService.auth.e('Unexpected error during anonymous sign in: $e');
      if (e.toString().contains('cloud_firestore/unavailable')) {
        throw Exception(
            'Firebase service is temporarily unavailable. Please try again in a few moments.');
      } else if (e.toString().contains('cloud_firestore/permission-denied')) {
        throw Exception(
            'Permission denied. Please ensure you are properly authenticated.');
      } else if (e.toString().contains('network')) {
        throw Exception(
            'Network error. Please check your internet connection and try again.');
      } else {
        throw Exception('Failed to sign in anonymously: $e');
      }
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      LoggingService.auth.i('Signing out user');

      // Clear local storage first to prevent data leakage
      LoggingService.auth.i('Clearing all local storage data during sign out');
      await Future.wait([
        MealPlanLocalStorageService.clearMealPlan(),
        WorkoutPlanLocalStorageService.clearWorkoutPlan(),
      ]);

      // Then sign out from auth services
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
        _storageService.clearUser(),
      ]);

      LoggingService.auth.i('User signed out successfully');
    } catch (e) {
      LoggingService.auth.e('Error during sign out: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Reset password
  static Future<void> resetPassword(String email) async {
    try {
      LoggingService.auth.i('Attempting to reset password for: $email');

      // Validate email format before sending
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw Exception('Please enter a valid email address.');
      }

      await _auth.sendPasswordResetEmail(email: email);

      LoggingService.auth.i('Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      LoggingService.auth.e(
          'Firebase Auth error during password reset: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      LoggingService.auth.e('Unexpected error during password reset: $e');
      throw Exception('Failed to send password reset email: $e');
    }
  }

  /// Update user profile
  static Future<void> updateUserProfile(UserModel userModel) async {
    try {
      LoggingService.auth.i('AuthService - Updating user profile: ${userModel.id}');
      LoggingService.auth.d('AuthService - New name: "${userModel.name}"');

      await _updateUserDocument(userModel);
      LoggingService.auth.i('AuthService - Firestore document updated');

      // Update Firebase Auth display name if it changed
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.displayName != userModel.name) {
        LoggingService.auth.d(
            'AuthService - Updating Firebase Auth display name from "${currentUser.displayName}" to "${userModel.name}"');
        await currentUser.updateDisplayName(userModel.name);
        LoggingService.auth.i('AuthService - Firebase Auth display name updated');
      } else {
        LoggingService.auth.d(
            'AuthService - Firebase Auth display name unchanged or user not found');
      }

      LoggingService.auth.i('AuthService - User profile updated successfully');
    } catch (e) {
      LoggingService.auth.e('AuthService - Error updating user profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Delete user account
  static Future<void> deleteAccount() async {
    try {
      LoggingService.auth.i('Attempting to delete user account');

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      final userId = currentUser.uid;

      // Delete all user data from Firestore
      await _retryFirestoreOperation(() async {
        LoggingService.auth.i('Deleting all user data from Firestore: $userId');

        // Delete user document
        await _firestore.collection('users').doc(userId).delete();
        LoggingService.auth.i('User document deleted successfully');

        // Delete all check-ins for the user
        await _deleteUserCheckins(userId);

        // Delete all workout plans for the user
        await _deleteUserWorkoutPlans(userId);

        // Delete all meal plans for the user
        await _deleteUserMealPlans(userId);

        LoggingService.auth.i('All user data deleted successfully');
      });

      // Delete Firebase Auth account
      LoggingService.auth.i('Deleting Firebase Auth account: $userId');
      await currentUser.delete();
      LoggingService.auth.i('Firebase Auth account deleted successfully');

      // Clear local storage
      await _storageService.clearUser();

      // Clear meal plan data from local storage
      await _clearMealPlanData(userId);

      // Sign out to complete the deletion process
      await signOut();

      LoggingService.auth.i('User account deleted successfully');
    } on FirebaseAuthException catch (e) {
      LoggingService.auth.e(
          'Firebase Auth error during account deletion: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      LoggingService.auth.e('Unexpected error during account deletion: $e');
      throw Exception('Failed to delete account: $e');
    }
  }

  /// Delete all check-ins for a user
  static Future<void> _deleteUserCheckins(String userId) async {
    try {
      LoggingService.auth.i('Deleting all check-ins for user: $userId');

      final querySnapshot = await _firestore
          .collection('checkins')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      LoggingService.auth.i(
          'Deleted ${querySnapshot.docs.length} check-ins for user: $userId');
    } catch (e) {
      LoggingService.auth.e('Error deleting user check-ins: $e');
      // Don't rethrow - we want to continue with account deletion even if check-in deletion fails
    }
  }

  /// Delete all workout plans for a user
  static Future<void> _deleteUserWorkoutPlans(String userId) async {
    try {
      LoggingService.auth.i('Deleting all workout plans for user: $userId');

      final querySnapshot = await _firestore
          .collection('workout_plans')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      LoggingService.auth.i(
          'Deleted ${querySnapshot.docs.length} workout plans for user: $userId');
    } catch (e) {
      LoggingService.auth.e('Error deleting user workout plans: $e');
      // Don't rethrow - we want to continue with account deletion even if workout plan deletion fails
    }
  }

  /// Delete all meal plans for a user
  static Future<void> _deleteUserMealPlans(String userId) async {
    try {
      LoggingService.auth.i('Deleting all meal plans for user: $userId');

      final querySnapshot = await _firestore
          .collection('meal_plans')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      LoggingService.auth.i(
          'Deleted ${querySnapshot.docs.length} meal plans for user: $userId');
    } catch (e) {
      LoggingService.auth.e('Error deleting user meal plans: $e');
      // Don't rethrow - we want to continue with account deletion even if meal plan deletion fails
    }
  }

  /// Clear meal plan data from local storage
  static Future<void> _clearMealPlanData(String userId) async {
    try {
      LoggingService.auth.i('Clearing meal plan data from local storage for user: $userId');
      
      // Clear both local storage services
      await Future.wait([
        MealPlanStorageService.clearMealPlanData(userId),
        MealPlanLocalStorageService.clearMealPlan(),
      ]);
      
      LoggingService.auth.i('Meal plan data cleared from all local storage services successfully');
    } catch (e) {
      LoggingService.auth.e('Error clearing meal plan data from local storage: $e');
      // Don't rethrow - we want to continue with account deletion even if local storage clearing fails
    }
  }

  /// Get current user model
  static Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) return null;

    return await _getUserDocument(user.uid);
  }

  /// Clear all local storage data (useful for debugging or manual cleanup)
  static Future<void> clearAllLocalStorage() async {
    try {
      LoggingService.auth.i('Clearing all local storage data');
      
      await Future.wait([
        _storageService.clearUser(),
        MealPlanStorageService.clearMealPlanData(''), // Clear all meal plan data
        MealPlanLocalStorageService.clearMealPlan(),
        WorkoutPlanLocalStorageService.clearWorkoutPlan(),
      ]);
      
      LoggingService.auth.i('All local storage data cleared successfully');
    } catch (e) {
      LoggingService.auth.e('Error clearing all local storage data: $e');
      throw Exception('Failed to clear local storage: $e');
    }
  }

  // Private methods for Firestore operations

  static Future<void> _createUserDocument(UserModel userModel) async {
    await _retryFirestoreOperation(() async {
      // Ensure user is authenticated before accessing Firestore
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      LoggingService.auth.i('Creating user document for: ${userModel.id}');
      await _firestore
          .collection('users')
          .doc(userModel.id)
          .set(userModel.toJson());
      LoggingService.auth.i('User document created successfully');
    });
  }

  static Future<UserModel?> _getUserDocument(String userId) async {
    return await _retryFirestoreOperation(() async {
      // Ensure user is authenticated before accessing Firestore
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      LoggingService.auth.i('Getting user document for: $userId');
      LoggingService.auth.i('Current Firebase user: ${currentUser.uid}');
      LoggingService.auth.i('User IDs match: ${currentUser.uid == userId}');
      
      final doc = await _firestore.collection('users').doc(userId).get();
      LoggingService.auth.i('Document exists: ${doc.exists}');
      LoggingService.auth.i('Document ID: ${doc.id}');
      
      if (doc.exists) {
        final data = doc.data()!;
        LoggingService.auth.i('User document found with trainingProgramStatus: ${data['trainingProgramStatus']}');
        return UserModel.fromJson(data);
      }
      LoggingService.auth.i('User document not found');
      return null;
    });
  }

  static Future<void> _updateUserDocument(UserModel userModel) async {
    await _retryFirestoreOperation(() async {
      // Ensure user is authenticated before accessing Firestore
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      LoggingService.auth.i('AuthService - Updating user document for: ${userModel.id}');
      LoggingService.auth.d('AuthService - User data to update: ${userModel.toJson()}');

      await _firestore
          .collection('users')
          .doc(userModel.id)
          .update(userModel.toJson());
      LoggingService.auth.i('AuthService - User document updated successfully');
    });
  }

  // Retry logic for Firestore operations
  static Future<T> _retryFirestoreOperation<T>(Future<T> Function() operation,
      {int maxRetries = 3}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        LoggingService.auth.e('Firestore operation failed (attempt $attempts/$maxRetries): $e');
        
        if (e.toString().contains('cloud_firestore/unavailable') ||
            e.toString().contains('cloud_firestore/deadline-exceeded') ||
            e.toString().contains('cloud_firestore/resource-exhausted') ||
            e.toString().contains('network') ||
            e.toString().contains('timeout')) {
          
          if (attempts < maxRetries) {
            LoggingService.auth.w(
                'Firestore error, retrying in ${attempts * 2} seconds... (attempt $attempts/$maxRetries)');
            await Future.delayed(Duration(seconds: attempts * 2));
            continue;
          }
        }
        rethrow;
      }
    }
    throw Exception('Firestore operation failed after $maxRetries attempts');
  }

  /// Change user password
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      LoggingService.auth.i('Attempting to change password');

      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final AuthCredential credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: currentPassword,
      );

      await currentUser.reauthenticateWithCredential(credential);
      LoggingService.auth.i('User re-authenticated successfully');

      // Update password
      await currentUser.updatePassword(newPassword);
      LoggingService.auth.i('Password updated successfully');
    } catch (e) {
      LoggingService.auth.e('Error changing password: $e');
      if (e is FirebaseAuthException) {
        throw _handleFirebaseAuthException(e);
      }
      throw Exception('Failed to change password: $e');
    }
  }

  // Error handling
  static Exception _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception(
            'No user found with this email address. Please check the email or create a new account.');
      case 'wrong-password':
        return Exception('Incorrect password. Please try again.');
      case 'email-already-in-use':
        return Exception('An account with this email already exists.');
      case 'weak-password':
        return Exception(
            'Password is too weak. Please choose a stronger password.');
      case 'invalid-email':
        return Exception('Please enter a valid email address.');
      case 'user-disabled':
        return Exception('This account has been disabled.');
      case 'too-many-requests':
        return Exception('Too many failed attempts. Please try again later.');
      case 'operation-not-allowed':
        return Exception('This sign-in method is not enabled.');
      case 'network-request-failed':
        return Exception('Network error. Please check your connection.');
      case 'invalid-action-code':
        return Exception(
            'The password reset link is invalid or has expired. Please request a new one.');
      case 'expired-action-code':
        return Exception(
            'The password reset link has expired. Please request a new one.');
      case 'user-mismatch':
        return Exception(
            'The email address doesn\'t match the reset link. Please use the correct email.');
      case 'requires-recent-login':
        return Exception(
            'For security reasons, please sign in again before deleting your account.');
      case 'user-token-expired':
        return Exception('Your session has expired. Please sign in again.');
      case 'invalid-credential':
        return Exception(
            'Invalid credentials. Please check your email and password.');
      default:
        return Exception('Authentication failed: ${e.message}');
    }
  }
}
