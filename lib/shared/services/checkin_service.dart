import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';
import '../models/checkin_model.dart';

class CheckinService {
  static final _logger = Logger();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const _uuid = Uuid();

  // Collection references
  static CollectionReference<Map<String, dynamic>> get _checkinsCollection =>
      _firestore.collection('checkins');

  /// Get current week's check-in for a user
  static Future<CheckinModel?> getCurrentWeekCheckin(String userId) async {
    try {
      final weekStart = CheckinModel.createForCurrentWeek(userId).weekStartDate;

      final querySnapshot = await _checkinsCollection
          .where('userId', isEqualTo: userId)
          .where('weekStartDate', isEqualTo: Timestamp.fromDate(weekStart))
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final rawData = doc.data();
        final data = rawData != null
            ? Map<String, dynamic>.from(rawData as Map<String, dynamic>)
            : <String, dynamic>{};
        data['id'] = doc.id;
        return CheckinModel.fromJson(data);
      }

      return null;
    } catch (e) {
      _logger.e('Error getting current week check-in: $e');
      rethrow;
    }
  }

  /// Get check-in for a specific week
  static Future<CheckinModel?> getCheckinForWeek(
      String userId, DateTime weekStart) async {
    try {
      final querySnapshot = await _checkinsCollection
          .where('userId', isEqualTo: userId)
          .where('weekStartDate', isEqualTo: Timestamp.fromDate(weekStart))
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final rawData = doc.data();
        final data = rawData != null
            ? Map<String, dynamic>.from(rawData as Map<String, dynamic>)
            : <String, dynamic>{};
        data['id'] = doc.id;
        return CheckinModel.fromJson(data);
      }

      return null;
    } catch (e) {
      _logger.e('Error getting check-in for week: $e');
      rethrow;
    }
  }

  /// Get all check-ins for a user (paginated)
  static Future<List<CheckinModel>> getUserCheckins(
    String userId, {
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _checkinsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('weekStartDate', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        final rawData = doc.data();
        final data = rawData != null 
            ? Map<String, dynamic>.from(rawData as Map<String, dynamic>)
            : <String, dynamic>{};
        data['id'] = doc.id;
        return CheckinModel.fromJson(data);
      }).toList();
    } catch (e) {
      _logger.e('Error getting user check-ins: $e');
      rethrow;
    }
  }

  /// Create a new check-in
  static Future<CheckinModel> createCheckin(CheckinModel checkin) async {
    try {
      final docRef = await _checkinsCollection.add(checkin.toJson());
      return checkin.copyWith(id: docRef.id);
    } catch (e) {
      _logger.e('Error creating check-in: $e');
      rethrow;
    }
  }

  /// Update an existing check-in
  static Future<void> updateCheckin(CheckinModel checkin) async {
    try {
      await _checkinsCollection
          .doc(checkin.id)
          .update(checkin.copyWith(updatedAt: DateTime.now()).toJson());
    } catch (e) {
      _logger.e('Error updating check-in: $e');
      rethrow;
    }
  }

  /// Delete a check-in
  static Future<void> deleteCheckin(String checkinId) async {
    try {
      await _checkinsCollection.doc(checkinId).delete();
    } catch (e) {
      _logger.e('Error deleting check-in: $e');
      rethrow;
    }
  }

  /// Submit a check-in with photo and data
  static Future<CheckinModel> submitCheckin({
    required String userId,
    required File photoFile,
    String? notes,
    double? weight,
    double? bodyFatPercentage,
    double? muscleMass,
    Map<String, double>? measurements,
    String? mood,
    int? energyLevel,
    int? motivationLevel,
  }) async {
    try {
      // Get or create current week check-in
      CheckinModel? currentCheckin = await getCurrentWeekCheckin(userId);

      if (currentCheckin == null) {
        currentCheckin = CheckinModel.createForCurrentWeek(userId);
        currentCheckin = await createCheckin(currentCheckin);
      }

      // Upload photo
      final photoUrls =
          await _uploadCheckinPhoto(userId, currentCheckin.id, photoFile);

      // Update check-in with submitted data
      final updatedCheckin = currentCheckin.copyWith(
        photoUrl: photoUrls['full'],
        photoThumbnailUrl: photoUrls['thumbnail'],
        notes: notes,
        weight: weight,
        bodyFatPercentage: bodyFatPercentage,
        muscleMass: muscleMass,
        measurements: measurements,
        mood: mood,
        energyLevel: energyLevel,
        motivationLevel: motivationLevel,
        status: CheckinStatus.completed,
        submittedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await updateCheckin(updatedCheckin);
      return updatedCheckin;
    } catch (e) {
      _logger.e('Error submitting check-in: $e');
      rethrow;
    }
  }

  /// Upload check-in photo and create thumbnail
  static Future<Map<String, String>> _uploadCheckinPhoto(
    String userId,
    String checkinId,
    File photoFile,
  ) async {
    try {
      // Read and process image
      final bytes = await photoFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Create thumbnail (resize to 300x300)
      final thumbnail = img.copyResize(
        image,
        width: 300,
        height: 300,
        interpolation: img.Interpolation.linear,
      );
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: 80);

      // Generate unique filenames
      final photoId = _uuid.v4();
      final fullPhotoPath = 'checkins/$userId/$checkinId/full_$photoId.jpg';
      final thumbnailPath = 'checkins/$userId/$checkinId/thumb_$photoId.jpg';

      // Upload full photo
      final fullPhotoRef = _storage.ref().child(fullPhotoPath);
      await fullPhotoRef.putData(bytes);

      // Upload thumbnail
      final thumbnailRef = _storage.ref().child(thumbnailPath);
      await thumbnailRef.putData(thumbnailBytes);

      // Get download URLs
      final fullPhotoUrl = await fullPhotoRef.getDownloadURL();
      final thumbnailUrl = await thumbnailRef.getDownloadURL();

      return {
        'full': fullPhotoUrl,
        'thumbnail': thumbnailUrl,
      };
    } catch (e) {
      _logger.e('Error uploading check-in photo: $e');
      rethrow;
    }
  }

  /// Get check-in progress summary for a user
  static Future<CheckinProgressSummary> getProgressSummary(
      String userId) async {
    try {
      final checkins = await getUserCheckins(userId, limit: 100);

      if (checkins.isEmpty) {
        return CheckinProgressSummary(
          totalCheckins: 0,
          completedCheckins: 0,
          missedCheckins: 0,
          currentStreak: 0,
          longestStreak: 0,
        );
      }

      // Calculate basic stats
      final completedCheckins =
          checkins.where((c) => c.status == CheckinStatus.completed).length;
      final missedCheckins =
          checkins.where((c) => c.status == CheckinStatus.missed).length;
      final totalCheckins = checkins.length;

      // Calculate streaks
      final sortedCheckins = checkins
          .where((c) => c.status == CheckinStatus.completed)
          .toList()
        ..sort((a, b) => b.weekStartDate.compareTo(a.weekStartDate));

      int currentStreak = 0;
      int longestStreak = 0;
      int tempStreak = 0;
      DateTime? lastWeek = null;

      for (final checkin in sortedCheckins) {
        if (lastWeek == null) {
          tempStreak = 1;
          lastWeek = checkin.weekStartDate;
        } else {
          final weekDiff = lastWeek.difference(checkin.weekStartDate).inDays;
          if (weekDiff == 7) {
            tempStreak++;
            lastWeek = checkin.weekStartDate;
          } else {
            // Streak broken
            if (tempStreak > longestStreak) {
              longestStreak = tempStreak;
            }
            tempStreak = 1;
            lastWeek = checkin.weekStartDate;
          }
        }
      }

      // Update longest streak if current streak is longer
      if (tempStreak > longestStreak) {
        longestStreak = tempStreak;
      }

      // Calculate current streak (consecutive weeks from most recent)
      if (sortedCheckins.isNotEmpty) {
        final currentWeekStart =
            CheckinModel.createForCurrentWeek(userId).weekStartDate;
        final lastCheckinWeek = sortedCheckins.first.weekStartDate;

        if (lastCheckinWeek.isAtSameMomentAs(currentWeekStart) ||
            lastCheckinWeek
                .isAfter(currentWeekStart.subtract(const Duration(days: 7)))) {
          currentStreak = tempStreak;
        }
      }

      // Calculate averages
      final completedCheckinsList =
          checkins.where((c) => c.status == CheckinStatus.completed).toList();

      double? averageWeight;
      double? averageBodyFat;
      double? averageEnergyLevel;
      double? averageMotivationLevel;

      if (completedCheckinsList.isNotEmpty) {
        final weights = completedCheckinsList
            .where((c) => c.weight != null)
            .map((c) => c.weight!)
            .toList();
        final bodyFats = completedCheckinsList
            .where((c) => c.bodyFatPercentage != null)
            .map((c) => c.bodyFatPercentage!)
            .toList();
        final energyLevels = completedCheckinsList
            .where((c) => c.energyLevel != null)
            .map((c) => c.energyLevel!.toDouble())
            .toList();
        final motivationLevels = completedCheckinsList
            .where((c) => c.motivationLevel != null)
            .map((c) => c.motivationLevel!.toDouble())
            .toList();

        averageWeight = weights.isNotEmpty
            ? weights.reduce((a, b) => a + b) / weights.length
            : null;
        averageBodyFat = bodyFats.isNotEmpty
            ? bodyFats.reduce((a, b) => a + b) / bodyFats.length
            : null;
        averageEnergyLevel = energyLevels.isNotEmpty
            ? energyLevels.reduce((a, b) => a + b) / energyLevels.length
            : null;
        averageMotivationLevel = motivationLevels.isNotEmpty
            ? motivationLevels.reduce((a, b) => a + b) / motivationLevels.length
            : null;
      }

      // Calculate next check-in date
      final nextCheckinDate = _calculateNextCheckinDate(checkins);

      return CheckinProgressSummary(
        totalCheckins: totalCheckins,
        completedCheckins: completedCheckins,
        missedCheckins: missedCheckins,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        lastCheckinDate:
            sortedCheckins.isNotEmpty ? sortedCheckins.first.submittedAt : null,
        nextCheckinDate: nextCheckinDate,
        averageWeight: averageWeight,
        averageBodyFat: averageBodyFat,
        averageEnergyLevel: averageEnergyLevel,
        averageMotivationLevel: averageMotivationLevel,
      );
    } catch (e) {
      _logger.e('Error getting progress summary: $e');
      rethrow;
    }
  }

  /// Calculate next check-in date
  static DateTime? _calculateNextCheckinDate(List<CheckinModel> checkins) {
    if (checkins.isEmpty) return null;

    final sortedCheckins = checkins
        .where((c) => c.status == CheckinStatus.completed)
        .toList()
      ..sort((a, b) => b.weekStartDate.compareTo(a.weekStartDate));

    if (sortedCheckins.isEmpty) return null;

    final lastCheckinWeek = sortedCheckins.first.weekStartDate;
    final currentWeekStart =
        CheckinModel.createForCurrentWeek('').weekStartDate;

    // If last check-in was this week, next check-in is next week
    if (lastCheckinWeek.isAtSameMomentAs(currentWeekStart)) {
      return currentWeekStart.add(const Duration(days: 7));
    }

    // If last check-in was last week, next check-in is this week
    if (lastCheckinWeek
        .isAtSameMomentAs(currentWeekStart.subtract(const Duration(days: 7)))) {
      return currentWeekStart;
    }

    // Otherwise, next check-in is the week after the last check-in
    return lastCheckinWeek.add(const Duration(days: 7));
  }

  /// Mark overdue check-ins as missed
  static Future<void> markOverdueCheckins(String userId) async {
    try {
      final currentWeekStart =
          CheckinModel.createForCurrentWeek(userId).weekStartDate;

      // Get all pending check-ins that are overdue
      final querySnapshot = await _checkinsCollection
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .where('weekStartDate',
              isLessThan: Timestamp.fromDate(currentWeekStart))
          .get();

      final batch = _firestore.batch();

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'status': 'missed',
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      if (querySnapshot.docs.isNotEmpty) {
        await batch.commit();
        _logger.i(
            'Marked ${querySnapshot.docs.length} overdue check-ins as missed');
      }
    } catch (e) {
      _logger.e('Error marking overdue check-ins: $e');
      rethrow;
    }
  }

  /// Get check-ins for a date range
  static Future<List<CheckinModel>> getCheckinsForDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _checkinsCollection
          .where('userId', isEqualTo: userId)
          .where('weekStartDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('weekStartDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('weekStartDate', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final rawData = doc.data();
        final data = rawData != null 
            ? Map<String, dynamic>.from(rawData as Map<String, dynamic>)
            : <String, dynamic>{};
        data['id'] = doc.id;
        return CheckinModel.fromJson(data);
      }).toList();
    } catch (e) {
      _logger.e('Error getting check-ins for date range: $e');
      rethrow;
    }
  }
}
