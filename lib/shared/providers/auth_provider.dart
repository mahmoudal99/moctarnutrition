import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_local_storage_service.dart';
import '../services/onboarding_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;
  final UserLocalStorageService _storageService = UserLocalStorageService();

  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _firebaseUser != null && _userModel != null;
  bool get isGuest => _firebaseUser?.isAnonymous ?? false;

  AuthProvider() {
    _initializeAuthState();
    _loadCachedUserData();
  }

  /// Initialize authentication state listener
  void _initializeAuthState() {
    AuthService.authStateChanges.listen((User? user) async {
      _firebaseUser = user;
      
      if (user != null) {
        // User is signed in
        await _loadUserModel(user.uid);
      } else {
        // User is signed out
        _userModel = null;
        await _storageService.clearUser();
      }
      
      _error = null;
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
        print('Loaded cached user: ${cachedUser.name}');
      }

      // Check if Firebase user is still authenticated
      final currentFirebaseUser = AuthService.currentUser;
      if (currentFirebaseUser != null) {
        _firebaseUser = currentFirebaseUser;
        print('Firebase user still authenticated: ${currentFirebaseUser.email}');
      } else {
        // Firebase user is not authenticated, clear cached data
        _userModel = null;
        await _storageService.clearUser();
        print('Firebase user not authenticated, cleared cached data');
      }
    } catch (e) {
      print('Error loading cached user data: $e');
      _error = 'Failed to load cached user data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load user model from Firestore
  Future<void> _loadUserModel(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userModel = await AuthService.getCurrentUserModel();
      if (userModel != null) {
        _userModel = userModel;
        await _storageService.saveUser(userModel);
      }
    } catch (e) {
      _error = 'Failed to load user profile: $e';
    } finally {
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

      await AuthService.signOut();
      
      _firebaseUser = null;
      _userModel = null;
      
      // Reset onboarding state when user signs out
      await OnboardingService.resetOnboardingState();
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

  /// Update user profile
  Future<bool> updateUserProfile(UserModel userModel) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await AuthService.updateUserProfile(userModel);
      
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