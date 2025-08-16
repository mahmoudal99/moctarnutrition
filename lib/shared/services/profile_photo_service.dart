import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class ProfilePhotoService {
  static final _logger = Logger();
  static const String _keyPrefix = 'profile_photo_';

  /// Get the stored profile photo for a user
  static Future<String?> getProfilePhoto(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = '$_keyPrefix$userId';
      return prefs.getString(key);
    } catch (e) {
      _logger.e('Error getting profile photo: $e');
      return null;
    }
  }

  /// Store a profile photo for a user
  static Future<bool> storeProfilePhoto(String userId, String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        _logger.e('Image file does not exist: $imagePath');
        return false;
      }

      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);
      
      final prefs = await SharedPreferences.getInstance();
      final String key = '$_keyPrefix$userId';
      await prefs.setString(key, base64Image);
      
      _logger.d('Profile photo stored successfully for user: $userId');
      return true;
    } catch (e) {
      _logger.e('Error storing profile photo: $e');
      return false;
    }
  }

  /// Remove the stored profile photo for a user
  static Future<bool> removeProfilePhoto(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = '$_keyPrefix$userId';
      await prefs.remove(key);
      
      _logger.d('Profile photo removed successfully for user: $userId');
      return true;
    } catch (e) {
      _logger.e('Error removing profile photo: $e');
      return false;
    }
  }

  /// Check if a user has a stored profile photo
  static Future<bool> hasProfilePhoto(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = '$_keyPrefix$userId';
      return prefs.containsKey(key);
    } catch (e) {
      _logger.e('Error checking profile photo: $e');
      return false;
    }
  }

  /// Get the profile photo key for a user
  static String getProfilePhotoKey(String userId) {
    return '$_keyPrefix$userId';
  }
} 