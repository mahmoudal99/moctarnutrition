import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import 'user_local_storage_service.dart';

class AuthService {
  static final _logger = Logger();
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final UserLocalStorageService _storageService = UserLocalStorageService();

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
      _logger.i('Attempting to sign up with email: $email');
      
      // Create user with Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to create user account');
      }

      // Update display name
      await user.updateDisplayName(name);

      // Create user document in Firestore
      final UserModel userModel = UserModel(
        id: user.uid,
        email: email,
        name: name,
        photoUrl: user.photoURL,
        role: UserRole.user,
        subscriptionStatus: SubscriptionStatus.free,
        preferences: UserPreferences.defaultPreferences(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _createUserDocument(userModel);

      _logger.i('User signed up successfully: ${user.uid}');
      return userModel;
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth error during sign up: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      _logger.e('Unexpected error during sign up: $e');
      throw Exception('Failed to create account: $e');
    }
  }

  /// Sign in with email and password
  static Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('Attempting to sign in with email: $email');
      
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to sign in');
      }

      // Get user data from Firestore
      final UserModel? userModel = await _getUserDocument(user.uid);
      if (userModel == null) {
        throw Exception('User profile not found');
      }

      _logger.i('User signed in successfully: ${user.uid}');
      return userModel;
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth error during sign in: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      _logger.e('Unexpected error during sign in: $e');
      throw Exception('Failed to sign in: $e');
    }
  }

  /// Sign in with Google
  static Future<UserModel> signInWithGoogle() async {
    try {
      _logger.i('Attempting Google sign in');
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      
      if (user == null) {
        throw Exception('Failed to sign in with Google');
      }

      // Wait a moment for Firebase Auth to fully establish the user
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if user document exists
      UserModel? userModel = await _getUserDocument(user.uid);
      
      if (userModel == null) {
        // Create new user document for first-time Google sign in
        userModel = UserModel(
          id: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? 'User',
          photoUrl: user.photoURL,
          role: UserRole.user,
          subscriptionStatus: SubscriptionStatus.free,
          preferences: UserPreferences.defaultPreferences(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await _createUserDocument(userModel);
        _logger.i('Created new user document for Google sign in: ${user.uid}');
      } else {
        // Update existing user with latest Google info
        userModel = userModel.copyWith(
          name: user.displayName ?? userModel.name,
          photoUrl: user.photoURL ?? userModel.photoUrl,
          updatedAt: DateTime.now(),
        );
        await _updateUserDocument(userModel);
        _logger.i('Updated existing user document for Google sign in: ${user.uid}');
      }

      _logger.i('Google sign in successful: ${user.uid}');
      return userModel;
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth error during Google sign in: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      _logger.e('Unexpected error during Google sign in: $e');
      
      // Provide more specific error messages for common issues
      if (e.toString().contains('cloud_firestore/unavailable')) {
        throw Exception('Firebase service is temporarily unavailable. Please try again in a few moments.');
      } else if (e.toString().contains('cloud_firestore/permission-denied')) {
        throw Exception('Permission denied. Please ensure you are properly authenticated.');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error. Please check your internet connection and try again.');
      } else {
        throw Exception('Failed to sign in with Google: $e');
      }
    }
  }

  /// Sign in with Apple
  static Future<UserModel> signInWithApple() async {
    try {
      _logger.i('Attempting Apple sign in');
      
      // Check if Apple Sign-In is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('Apple Sign-In is not available on this device');
      }
      
      // Request credential for the currently signed in Apple account
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create an `OAuthCredential` from the credential returned by Apple
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in the user with Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(oauthCredential);
      final User? user = userCredential.user;
      
      if (user == null) {
        throw Exception('Failed to sign in with Apple');
      }

      // Wait a moment for Firebase Auth to fully establish the user
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if user document exists
      UserModel? userModel = await _getUserDocument(user.uid);
      
      if (userModel == null) {
        // Create new user document for first-time Apple sign in
        final String displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
        
        userModel = UserModel(
          id: user.uid,
          email: user.email ?? appleCredential.email ?? '',
          name: displayName.isNotEmpty ? displayName : 'User',
          photoUrl: user.photoURL,
          role: UserRole.user,
          subscriptionStatus: SubscriptionStatus.free,
          preferences: UserPreferences.defaultPreferences(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await _createUserDocument(userModel);
        _logger.i('Created new user document for Apple sign in: ${user.uid} with name: $displayName');
      } else {
        // For existing users, only update name if Apple provides it (first-time sign-in)
        final String displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
        if (displayName.isNotEmpty && (userModel.name == null || userModel.name!.isEmpty)) {
          // Only update if user doesn't have a name yet (first-time Apple sign-in)
          userModel = userModel.copyWith(
            name: displayName,
            updatedAt: DateTime.now(),
          );
          await _updateUserDocument(userModel);
          _logger.i('Updated existing user name for Apple sign in: ${user.uid} with name: $displayName');
        } else {
          _logger.i('Existing user signed in with Apple: ${user.uid} (name already set)');
        }
      }

      _logger.i('Apple sign in successful: ${user.uid}');
      return userModel;
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth error during Apple sign in: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      _logger.e('Unexpected error during Apple sign in: $e');
      
      // Provide more specific error messages for common Apple Sign-In issues
      if (e.toString().contains('AuthorizationErrorCode.unknown')) {
        throw Exception('Apple Sign-In configuration error. Please ensure Apple Sign-In is enabled in Apple Developer Console and Firebase Console.');
      } else if (e.toString().contains('not available')) {
        throw Exception('Apple Sign-In is not available on this device. Please use email/password or Google Sign-In.');
      } else if (e.toString().contains('cloud_firestore/unavailable')) {
        throw Exception('Firebase service is temporarily unavailable. Please try again in a few moments.');
      } else if (e.toString().contains('cloud_firestore/permission-denied')) {
        throw Exception('Permission denied. Please ensure you are properly authenticated.');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error. Please check your internet connection and try again.');
      } else {
        throw Exception('Failed to sign in with Apple: $e');
      }
    }
  }

  /// Sign in anonymously (guest mode)
  static Future<UserModel> signInAnonymously() async {
    try {
      _logger.i('Attempting anonymous sign in');
      
      final UserCredential userCredential = await _auth.signInAnonymously();
      final User? user = userCredential.user;
      
      if (user == null) {
        throw Exception('Failed to sign in anonymously');
      }

      // Wait a moment for Firebase Auth to fully establish the user
      await Future.delayed(const Duration(milliseconds: 500));

      // Create user document for anonymous user
      final UserModel userModel = UserModel(
        id: user.uid,
        email: 'guest@championsgym.com',
        name: 'Guest User',
        photoUrl: null,
        role: UserRole.user,
        subscriptionStatus: SubscriptionStatus.free,
        preferences: UserPreferences.defaultPreferences(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _createUserDocument(userModel);

      _logger.i('Anonymous sign in successful: ${user.uid}');
      return userModel;
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth error during anonymous sign in: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      _logger.e('Unexpected error during anonymous sign in: $e');
      
      // Provide more specific error messages for common issues
      if (e.toString().contains('cloud_firestore/unavailable')) {
        throw Exception('Firebase service is temporarily unavailable. Please try again in a few moments.');
      } else if (e.toString().contains('cloud_firestore/permission-denied')) {
        throw Exception('Permission denied. Please ensure you are properly authenticated.');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error. Please check your internet connection and try again.');
      } else {
        throw Exception('Failed to sign in anonymously: $e');
      }
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      _logger.i('Signing out user');
      
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
        _storageService.clearUser(),
      ]);

      _logger.i('User signed out successfully');
    } catch (e) {
      _logger.e('Error during sign out: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Reset password
  static Future<void> resetPassword(String email) async {
    try {
      _logger.i('Attempting to reset password for: $email');
      
      await _auth.sendPasswordResetEmail(email: email);
      
      _logger.i('Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth error during password reset: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      _logger.e('Unexpected error during password reset: $e');
      throw Exception('Failed to send password reset email: $e');
    }
  }

  /// Update user profile
  static Future<void> updateUserProfile(UserModel userModel) async {
    try {
      _logger.i('Updating user profile: ${userModel.id}');
      
      await _updateUserDocument(userModel);
      
      // Update Firebase Auth display name if it changed
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.displayName != userModel.name) {
        await currentUser.updateDisplayName(userModel.name);
      }
      
      _logger.i('User profile updated successfully');
    } catch (e) {
      _logger.e('Error updating user profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Get current user model
  static Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) return null;
    
    return await _getUserDocument(user.uid);
  }

  // Private methods for Firestore operations

  static Future<void> _createUserDocument(UserModel userModel) async {
    await _retryFirestoreOperation(() async {
      // Ensure user is authenticated before accessing Firestore
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      _logger.i('Creating user document for: ${userModel.id}');
      await _firestore.collection('users').doc(userModel.id).set(userModel.toJson());
      _logger.i('User document created successfully');
    });
  }

  static Future<UserModel?> _getUserDocument(String userId) async {
    return await _retryFirestoreOperation(() async {
      // Ensure user is authenticated before accessing Firestore
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      _logger.i('Getting user document for: $userId');
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        _logger.i('User document found');
        return UserModel.fromJson(doc.data()!);
      }
      _logger.i('User document not found');
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
      
      _logger.i('Updating user document for: ${userModel.id}');
      await _firestore.collection('users').doc(userModel.id).update(userModel.toJson());
      _logger.i('User document updated successfully');
    });
  }

  // Retry logic for Firestore operations
  static Future<T> _retryFirestoreOperation<T>(Future<T> Function() operation, {int maxRetries = 3}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (e.toString().contains('cloud_firestore/unavailable') && attempts < maxRetries) {
          _logger.w('Firestore unavailable, retrying in ${attempts * 2} seconds... (attempt $attempts/$maxRetries)');
          await Future.delayed(Duration(seconds: attempts * 2));
          continue;
        }
        rethrow;
      }
    }
    throw Exception('Firestore operation failed after $maxRetries attempts');
  }

  // Error handling
  static Exception _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found with this email address.');
      case 'wrong-password':
        return Exception('Incorrect password. Please try again.');
      case 'email-already-in-use':
        return Exception('An account with this email already exists.');
      case 'weak-password':
        return Exception('Password is too weak. Please choose a stronger password.');
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
      default:
        return Exception('Authentication failed: ${e.message}');
    }
  }
} 