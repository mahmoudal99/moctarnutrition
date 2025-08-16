import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/profile_photo_service.dart';

class ProfilePhotoProvider extends ChangeNotifier {
  String? _storedProfilePhoto;
  String? _currentUserId;

  String? get storedProfilePhoto => _storedProfilePhoto;
  bool get hasProfilePhoto => _storedProfilePhoto != null;

  /// Initialize the provider with a user ID
  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    await _loadProfilePhoto();
  }

  /// Load the stored profile photo for the current user
  Future<void> _loadProfilePhoto() async {
    if (_currentUserId == null) return;
    
    try {
      final base64Image = await ProfilePhotoService.getProfilePhoto(_currentUserId!);
      if (base64Image != null) {
        _storedProfilePhoto = base64Image;
        notifyListeners();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Update the profile photo
  Future<bool> updateProfilePhoto(String imagePath) async {
    if (_currentUserId == null) return false;
    
    try {
      final success = await ProfilePhotoService.storeProfilePhoto(_currentUserId!, imagePath);
      if (success) {
        await _loadProfilePhoto(); // Reload the photo
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Remove the profile photo
  Future<bool> removeProfilePhoto() async {
    if (_currentUserId == null) return false;
    
    try {
      final success = await ProfilePhotoService.removeProfilePhoto(_currentUserId!);
      if (success) {
        _storedProfilePhoto = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get the profile photo as a memory image
  MemoryImage? getProfilePhotoImage() {
    if (_storedProfilePhoto != null) {
      try {
        return MemoryImage(base64Decode(_storedProfilePhoto!));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Clear the provider state
  void clear() {
    _storedProfilePhoto = null;
    _currentUserId = null;
    notifyListeners();
  }
} 