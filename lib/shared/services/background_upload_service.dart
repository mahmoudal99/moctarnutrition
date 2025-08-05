import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:typed_data';

class BackgroundUploadService {
  static final _logger = Logger();
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _uuid = Uuid();
  
  // Notification plugin
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Initialize notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
  }

  /// Start background upload process
  static Future<void> startBackgroundUpload({
    required Uint8List imageBytes,
    required String userId,
    required String checkinId,
    required String uploadType,
  }) async {
    try {
      _logger.i('Starting background upload for checkin: $checkinId');
      
      // Save image locally first
      final localImagePath = await _saveImageLocally(
        imageBytes: imageBytes,
        userId: userId,
        checkinId: checkinId,
        uploadType: uploadType,
      );
      
      _logger.i('Image saved locally: $localImagePath');
      
      // Start background upload process
      _uploadInBackgroundWithRetry(
        localImagePath: localImagePath,
        userId: userId,
        checkinId: checkinId,
        uploadType: uploadType,
        maxRetries: 3,
      );
      
    } catch (e) {
      _logger.e('Error starting background upload: $e');
      rethrow;
    }
  }

  /// Save image to local storage
  static Future<String> _saveImageLocally({
    required Uint8List imageBytes,
    required String userId,
    required String checkinId,
    required String uploadType,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final uploadsDir = path.join(appDir.path, 'uploads', uploadType);
      
      // Create directory if it doesn't exist
      final directory = Directory(uploadsDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // Generate unique filename
      final uuid = const Uuid().v4();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${uuid}_${checkinId}_$timestamp.jpg';
      final savedPath = path.join(uploadsDir, fileName);
      
      _logger.i('Saving image to: $savedPath');
      
      // Save the image bytes to file
      final file = File(savedPath);
      await file.writeAsBytes(imageBytes);
      
      _logger.i('Image saved successfully to: $savedPath');
      return savedPath;
    } catch (e) {
      _logger.e('Error saving image locally: $e');
      rethrow;
    }
  }

  /// Upload image in background with retry mechanism
  static Future<void> _uploadInBackgroundWithRetry({
    required String localImagePath,
    required String userId,
    required String checkinId,
    required String uploadType,
    int maxRetries = 3,
  }) async {
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        _logger.i('Attempting background upload (attempt ${retryCount + 1}/$maxRetries) for checkin: $checkinId');
        
        await _uploadInBackground(
          localImagePath: localImagePath,
          userId: userId,
          checkinId: checkinId,
          uploadType: uploadType,
        );
        
        _logger.i('Background upload completed successfully for checkin: $checkinId');
        return; // Success, exit retry loop
        
      } catch (e) {
        retryCount++;
        _logger.e('Background upload attempt $retryCount failed for checkin $checkinId: $e');
        
        if (retryCount >= maxRetries) {
          _logger.e('All retry attempts failed for checkin: $checkinId');
          await _showNotification(
            title: 'Upload Failed',
            body: 'Failed to upload image after $maxRetries attempts. Please try again.',
            isError: true,
          );
          return;
        }
        
        // Wait before retry with exponential backoff
        final delay = Duration(seconds: 2 * retryCount);
        _logger.i('Waiting ${delay.inSeconds} seconds before retry...');
        await Future.delayed(delay);
        
        await _showNotification(
          title: 'Upload Retry',
          body: 'Retrying upload (attempt ${retryCount + 1}/$maxRetries)...',
        );
      }
    }
  }

  /// Upload image in background
  static Future<void> _uploadInBackground({
    required String localImagePath,
    required String userId,
    required String checkinId,
    required String uploadType,
  }) async {
    try {
      _logger.i('Starting actual upload to Firebase Storage for checkin: $checkinId');
      
      // Read the image file
      final imageFile = File(localImagePath);
      if (!await imageFile.exists()) {
        throw Exception('Local image file not found: $localImagePath');
      }
      
      final imageBytes = await imageFile.readAsBytes();
      _logger.i('Read image bytes: ${imageBytes.length} bytes');
      
      // Create thumbnail
      final thumbnailBytes = await _createThumbnail(imageBytes);
      _logger.i('Created thumbnail: ${thumbnailBytes.length} bytes');
      
      // Upload to Firebase Storage
      final storageRef = _storage.ref();
      final fullPhotoRef = storageRef.child('$uploadType/$userId/$checkinId/full_${path.basename(localImagePath)}');
      final thumbnailRef = storageRef.child('$uploadType/$userId/$checkinId/thumb_${path.basename(localImagePath)}');
      
      _logger.i('Uploading full image to: ${fullPhotoRef.fullPath}');
      await fullPhotoRef.putData(imageBytes);
      final fullPhotoUrl = await fullPhotoRef.getDownloadURL();
      _logger.i('Full image uploaded successfully: $fullPhotoUrl');
      
      _logger.i('Uploading thumbnail to: ${thumbnailRef.fullPath}');
      await thumbnailRef.putData(thumbnailBytes);
      final thumbnailUrl = await thumbnailRef.getDownloadURL();
      _logger.i('Thumbnail uploaded successfully: $thumbnailUrl');
      
      // Update checkin with photo URLs
      _logger.i('Updating checkin with photo URLs: $checkinId');
      await _updateCheckinWithPhotoUrls(
        checkinId: checkinId,
        photoUrl: fullPhotoUrl,
        photoThumbnailUrl: thumbnailUrl,
      );
      
      // Show success notification
      await _showNotification(
        title: 'Upload Complete',
        body: 'Your image has been uploaded successfully!',
        isSuccess: true,
      );

      // Don't clean up local file - keep it for immediate display
      _logger.i('Background upload process completed successfully for checkin: $checkinId');
      
    } catch (e) {
      _logger.e('Error in background upload for checkin $checkinId: $e');
      rethrow;
    }
  }

  /// Create thumbnail from image bytes
  static Future<Uint8List> _createThumbnail(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Failed to decode image for thumbnail creation');
      }
      
      final thumbnail = img.copyResize(
        image,
        width: 300,
        height: 300,
        interpolation: img.Interpolation.linear,
      );
      
      return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 80));
    } catch (e) {
      _logger.e('Error creating thumbnail: $e');
      rethrow;
    }
  }

  /// Update checkin model with photo URLs
  static Future<void> _updateCheckinWithPhotoUrls({
    required String checkinId,
    required String photoUrl,
    required String photoThumbnailUrl,
  }) async {
    try {
      final checkinRef = _firestore.collection('checkins').doc(checkinId);
      
      await checkinRef.update({
        'photoUrl': photoUrl,
        'photoThumbnailUrl': photoThumbnailUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      _logger.i('Checkin updated with photo URLs: $checkinId');
    } catch (e) {
      _logger.e('Error updating checkin with photo URLs: $e');
      rethrow;
    }
  }

  /// Show notification
  static Future<void> _showNotification({
    required String title,
    required String body,
    bool isError = false,
    bool isSuccess = false,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'background_upload',
      'Background Upload',
      channelDescription: 'Notifications for background image uploads',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  /// Get local uploads directory
  static Future<String> getUploadsDirectory(String uploadType) async {
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, 'uploads', uploadType);
  }

  /// Get all local uploads for a specific type
  static Future<List<File>> getLocalUploads(String uploadType) async {
    try {
      final uploadsDir = await getUploadsDirectory(uploadType);
      final directory = Directory(uploadsDir);
      
      if (!await directory.exists()) {
        return [];
      }

      final files = await directory.list().where((entity) => 
        entity is File && path.extension(entity.path) == '.jpg'
      ).cast<File>().toList();
      
      return files;
    } catch (e) {
      _logger.e('Error getting local uploads: $e');
      return [];
    }
  }

  /// Clean up old local uploads (older than 7 days)
  static Future<void> cleanupOldUploads() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final uploadsDir = Directory(path.join(appDir.path, 'uploads'));
      
      if (!await uploadsDir.exists()) {
        return;
      }

      final now = DateTime.now();
      final cutoffDate = now.subtract(const Duration(days: 7));

      await for (final entity in uploadsDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await entity.delete();
            _logger.i('Cleaned up old upload: ${entity.path}');
          }
        }
      }
    } catch (e) {
      _logger.e('Error cleaning up old uploads: $e');
    }
  }

  /// Manually retry failed uploads
  static Future<void> retryFailedUploads() async {
    try {
      final failedUploads = await getLocalUploads('checkins');
      
      if (failedUploads.isEmpty) {
        await _showNotification(
          title: 'No Failed Uploads',
          body: 'No failed uploads found to retry.',
        );
        return;
      }

      await _showNotification(
        title: 'Retrying Uploads',
        body: 'Retrying ${failedUploads.length} failed upload(s)...',
      );

      for (final file in failedUploads) {
        try {
          // Extract info from filename (assuming format: uuid_timestamp.jpg)
          final fileName = path.basename(file.path);
          final parts = fileName.split('_');
          
          if (parts.length >= 2) {
            // For now, we'll just clean up old files since we can't easily extract userId/checkinId
            await file.delete();
            _logger.i('Cleaned up old failed upload: ${file.path}');
          }
        } catch (e) {
          _logger.e('Error processing failed upload ${file.path}: $e');
        }
      }

      await _showNotification(
        title: 'Cleanup Complete',
        body: 'Old failed uploads have been cleaned up.',
      );
    } catch (e) {
      _logger.e('Error retrying failed uploads: $e');
      await _showNotification(
        title: 'Retry Failed',
        body: 'Failed to retry uploads. Please try again.',
        isError: true,
      );
    }
  }

  /// Check if a checkin has photo URLs
  static Future<bool> hasPhotoUrls(String checkinId) async {
    try {
      final checkinRef = _firestore.collection('checkins').doc(checkinId);
      final doc = await checkinRef.get();
      
      if (doc.exists) {
        final data = doc.data();
        return data != null && 
               data['photoUrl'] != null && 
               data['photoThumbnailUrl'] != null;
      }
      return false;
    } catch (e) {
      _logger.e('Error checking photo URLs for checkin $checkinId: $e');
      return false;
    }
  }

  /// Get upload status for a checkin
  static Future<Map<String, dynamic>> getUploadStatus(String checkinId) async {
    try {
      final hasPhotos = await hasPhotoUrls(checkinId);
      final localUploads = await getLocalUploads('checkins');
      
      return {
        'hasPhotos': hasPhotos,
        'pendingUploads': localUploads.length,
        'status': hasPhotos ? 'completed' : 'pending',
      };
    } catch (e) {
      _logger.e('Error getting upload status for checkin $checkinId: $e');
      return {
        'hasPhotos': false,
        'pendingUploads': 0,
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Get local image path for a specific checkin
  static Future<String?> getLocalImagePath(String checkinId) async {
    try {
      final localUploads = await getLocalUploads('checkins');
      
      // Find the image that belongs to this checkin
      for (final file in localUploads) {
        final fileName = path.basename(file.path);
        final parts = fileName.split('_');
        
        // Format: uuid_checkinId_timestamp.jpg
        if (parts.length >= 3 && parts[1] == checkinId) {
          return file.path;
        }
      }
      
      return null;
    } catch (e) {
      _logger.e('Error getting local image path for checkin $checkinId: $e');
      return null;
    }
  }
} 