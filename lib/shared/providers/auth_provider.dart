import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_local_storage_service.dart';
import '../services/onboarding_service.dart';
import '../services/workout_plan_local_storage_service.dart';
import '../services/notification_service.dart';
import 'profile_photo_provider.dart';

class AuthProvider extends ChangeNotifier {
  static final _logger = Logger();
  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;
  final UserLocalStorageService _storageService = UserLocalStorageService();
  ProfilePhotoProvider? _profilePhotoProvider;

  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _firebaseUser != null && _userModel != null;
  bool get isGuest => _firebaseUser?.isAnonymous ?? false;

  /// Set the profile photo provider reference
  void setProfilePhotoProvider(ProfilePhotoProvider provider) {
    _profilePhotoProvider = provider;
  }

  AuthProvider() {
    _initializeAuthState();
    _loadCachedUserData();
  }

  /// Initialize authentication state listener
  void _initializeAuthState() {
    AuthService.authStateChanges.listen((User? user) async {
      _logger.i('AuthProvider - Auth state changed: ${user?.email ?? 'null'}');
      _firebaseUser = user;
      
      if (user != null) {
        // User is signed in
        _logger.i('AuthProvider - Loading user model for: ${user.uid}');
        await _loadUserModel(user.uid);
      } else {
        // User is signed out
        _logger.i('AuthProvider - User signed out, clearing data');
        _userModel = null;
        await _storageService.clearUser();
        await WorkoutPlanLocalStorageService.clearWorkoutPlan();
        
        // Cancel workout notifications when user is signed out
        await NotificationService.cancelWorkoutNotifications();
        
        // Clear profile photo provider
        if (_profilePhotoProvider != null) {
          _logger.i('AuthProvider - Clearing profile photo provider');
          _profilePhotoProvider!.clear();
        }
      }
      
      _error = null;
      _logger.d('AuthProvider - Notifying listeners');
      notifyListeners();
    });
  }

  /// Load cached user data on app startup
  Future<void> _loadCachedUserData() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Load cached user data
      final cachedUser = await _storageService.loadUser();
      if (cachedUser != null) {
        _userModel = cachedUser;
        _logger.i('Loaded cached user: ${cachedUser.name}');
      }

      // Check if Firebase user is still authenticated
      final currentFirebaseUser = AuthService.currentUser;
      if (currentFirebaseUser != null) {
        _firebaseUser = currentFirebaseUser;
        _logger.i('Firebase user still authenticated: ${currentFirebaseUser.email}');
      } else {
        // Firebase user is not authenticated, clear cached data
        _userModel = null;
        await _storageService.clearUser();
        _logger.i('Firebase user not authenticated, cleared cached data');
      }
    } catch (e) {
      _logger.e('Error loading cached user data: $e');
      _error = 'Failed to load cached user data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load user model from Firestore
  Future<void> _loadUserModel(String userId) async {
    try {
      _logger.i('AuthProvider - Starting to load user model');
      _isLoading = true;
      notifyListeners();

      final userModel = await AuthService.getCurrentUserModel();
      if (userModel != null) {
        _logger.i('AuthProvider - User model loaded: ${userModel.name} with role: ${userModel.role}');
        
        // Check if this is a different user than the previously cached one
        final cachedUser = await _storageService.loadUser();
        final isDifferentUser = cachedUser?.id != userModel.id;
        
        if (isDifferentUser) {
          _logger.i('AuthProvider - Different user detected, clearing workout plan cache');
          await WorkoutPlanLocalStorageService.clearWorkoutPlan();
        }
        
        _userModel = userModel;
        await _storageService.saveUser(userModel);
        
        // Initialize profile photo provider if available
        if (_profilePhotoProvider != null) {
          _logger.i('AuthProvider - Initializing profile photo provider for user: ${userModel.id}');
          await _profilePhotoProvider!.initialize(userModel.id);
        }
      } else {
        _logger.w('AuthProvider - No user model found');
      }
    } catch (e) {
      _logger.e('AuthProvider - Error loading user model: $e');
      _error = 'Failed to load user profile: $e';
    } finally {
      _logger.d('AuthProvider - Finished loading user model, setting isLoading to false');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign up with email and password
  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userModel = await AuthService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );

      _userModel = userModel;
      await _storageService.saveUser(userModel);
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userModel = await AuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _userModel = userModel;
      await _storageService.saveUser(userModel);
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userModel = await AuthService.signInWithGoogle();
      
      _userModel = userModel;
      await _storageService.saveUser(userModel);
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with Apple
  Future<bool> signInWithApple() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userModel = await AuthService.signInWithApple();
      
      _userModel = userModel;
      await _storageService.saveUser(userModel);
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in anonymously (guest mode)
  Future<bool> signInAnonymously() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userModel = await AuthService.signInAnonymously();
      
      _userModel = userModel;
      await _storageService.saveUser(userModel);
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Cancel workout notifications before signing out
      await NotificationService.cancelWorkoutNotifications();
      
      await AuthService.signOut();
      
      _firebaseUser = null;
      _userModel = null;
      
      // Reset onboarding state when user signs out
      await OnboardingService.resetOnboardingState();
      
      // Clear workout plan cache when user signs out
      await WorkoutPlanLocalStorageService.clearWorkoutPlan();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await AuthService.resetPassword(email);
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await AuthService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile(UserModel userModel) async {
    try {
      _logger.i('AuthProvider - Starting profile update for user: ${userModel.id}');
      _logger.d('AuthProvider - New name: "${userModel.name}"');
      
      _isLoading = true;
      _error = null;
      notifyListeners();

      await AuthService.updateUserProfile(userModel);
      _logger.i('AuthProvider - AuthService update completed');
      
      _userModel = userModel;
      await _storageService.saveUser(userModel);
      _logger.i('AuthProvider - Local storage update completed');
      
      _logger.i('AuthProvider - Profile update successful');
      return true;
    } catch (e) {
      _logger.e('AuthProvider - Error updating profile: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete user account
  Future<bool> deleteAccount() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Cancel workout notifications before deleting account
      await NotificationService.cancelWorkoutNotifications();
      
      await AuthService.deleteAccount();
      
      // Clear local state
      _firebaseUser = null;
      _userModel = null;
      
      // Reset onboarding state when user deletes account
      await OnboardingService.resetOnboardingState();
      
      // Clear workout plan cache when user deletes account
      await WorkoutPlanLocalStorageService.clearWorkoutPlan();
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    if (_firebaseUser != null) {
      await _loadUserModel(_firebaseUser!.uid);
    }
  }

  /// Initialize user data (call this when app starts)
  Future<void> initializeUserData() async {
    await _loadCachedUserData();
  }
} 