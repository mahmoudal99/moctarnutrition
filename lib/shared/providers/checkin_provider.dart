import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/checkin_model.dart';
import '../services/checkin_service.dart';

class CheckinProvider extends ChangeNotifier {
  static final _logger = Logger();
  CheckinModel? _currentWeekCheckin;
  List<CheckinModel> _userCheckins = [];
  CheckinProgressSummary? _progressSummary;
  bool _isLoading = false;
  String? _error;
  bool _hasMoreCheckins = true;
  DocumentSnapshot? _lastDocument;

  // Getters
  CheckinModel? get currentWeekCheckin => _currentWeekCheckin;

  List<CheckinModel> get userCheckins => _userCheckins;

  CheckinProgressSummary? get progressSummary => _progressSummary;

  bool get isLoading => _isLoading;

  String? get error => _error;

  bool get hasMoreCheckins => _hasMoreCheckins;

  /// Load current week's check-in
  Future<void> loadCurrentWeekCheckin() async {
    try {
      _setLoading(true);
      _clearError();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      _currentWeekCheckin =
          await CheckinService.getCurrentWeekCheckin(user.uid);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load current week check-in: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load user's check-ins (paginated)
  Future<void> loadUserCheckins({bool refresh = false}) async {
    try {
      if (refresh) {
        _userCheckins.clear();
        _lastDocument = null;
        _hasMoreCheckins = true;
      }

      if (!_hasMoreCheckins || _isLoading) return;

      _setLoading(true);
      _clearError();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      _logger.i('Loading check-ins for user: ${user.uid}');
      final checkins = await CheckinService.getUserCheckins(
        user.uid,
        limit: 20,
        lastDocument: _lastDocument,
      );

      _logger.i('Loaded ${checkins.length} check-ins');
      for (final checkin in checkins) {
        _logger.d(
            'Check-in: ${checkin.id} - Week: ${checkin.weekStartDate} - Status: ${checkin.status}');
      }

      if (refresh) {
        _logger.d(
            'Refreshing - setting _userCheckins to ${checkins.length} items');
        _userCheckins = checkins;
      } else {
        _logger.d('Adding ${checkins.length} items to existing list');
        _userCheckins.addAll(checkins);
      }

      _hasMoreCheckins = checkins.length == 20;
      if (checkins.isNotEmpty) {
        _lastDocument = await _getLastDocument(user.uid);
      }

      _logger.d(
          'Total check-ins in provider after assignment: ${_userCheckins.length}');
      _logger.d(
          'Provider _userCheckins content: ${_userCheckins.map((c) => '${c.id}:${c.status}').toList()}');
      notifyListeners();
    } catch (e) {
      _logger.e('Error loading check-ins: $e');
      _setError('Failed to load check-ins: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load progress summary
  Future<void> loadProgressSummary() async {
    try {
      _setLoading(true);
      _clearError();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      _progressSummary = await CheckinService.getProgressSummary(user.uid);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load progress summary: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Submit a check-in
  Future<bool> submitCheckin({
    required String photoPath,
    String? notes,
    double? weight,
    Map<String, double>? measurements,
    String? mood,
    int? energyLevel,
    int? motivationLevel,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate that it's Sunday
      final now = DateTime.now();
      if (now.weekday != 7) {
        _setError('Check-ins can only be submitted on Sundays');
        return false;
      }

      // Check if there's already a completed check-in for this week
      final existingCheckin =
          await CheckinService.getCurrentWeekCheckin(user.uid);
      if (existingCheckin != null &&
          existingCheckin.status == CheckinStatus.completed) {
        _setError('You have already submitted a check-in for this week');
        return false;
      }

      final photoFile = await _getPhotoFile(photoPath);
      if (photoFile == null) {
        throw Exception('Failed to load photo file');
      }

      final submittedCheckin = await CheckinService.submitCheckin(
        userId: user.uid,
        photoFile: photoFile,
        notes: notes,
        weight: weight,
        measurements: measurements,
        mood: mood,
        energyLevel: energyLevel,
        motivationLevel: motivationLevel,
      );

      // Update current week check-in
      _currentWeekCheckin = submittedCheckin;

      // Add to user check-ins list if not already there
      final existingIndex =
          _userCheckins.indexWhere((c) => c.id == submittedCheckin.id);
      if (existingIndex >= 0) {
        _userCheckins[existingIndex] = submittedCheckin;
      } else {
        _userCheckins.insert(0, submittedCheckin);
      }

      // Reload progress summary
      await loadProgressSummary();

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to submit check-in: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing check-in
  Future<bool> updateCheckin(CheckinModel checkin) async {
    try {
      _setLoading(true);
      _clearError();

      await CheckinService.updateCheckin(checkin);

      // Update in local lists
      if (_currentWeekCheckin?.id == checkin.id) {
        _currentWeekCheckin = checkin;
      }

      final index = _userCheckins.indexWhere((c) => c.id == checkin.id);
      if (index >= 0) {
        _userCheckins[index] = checkin;
      }

      // Reload progress summary
      await loadProgressSummary();

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update check-in: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a check-in
  Future<bool> deleteCheckin(String checkinId) async {
    try {
      _setLoading(true);
      _clearError();

      await CheckinService.deleteCheckin(checkinId);

      // Remove from local lists
      if (_currentWeekCheckin?.id == checkinId) {
        _currentWeekCheckin = null;
      }

      _userCheckins.removeWhere((c) => c.id == checkinId);

      // Reload progress summary
      await loadProgressSummary();

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete check-in: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Mark overdue check-ins as missed and cleanup duplicates
  Future<void> markOverdueCheckins() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Clean up duplicate pending check-ins first
      await CheckinService.cleanupDuplicatePendingCheckins(user.uid);

      // Then mark overdue check-ins and create missing weekly ones
      await CheckinService.markOverdueCheckins(user.uid);

      // Reload data to reflect changes
      await loadCurrentWeekCheckin();
      await loadUserCheckins(refresh: true);
      await loadProgressSummary();
    } catch (e) {
      _setError('Failed to mark overdue check-ins: $e');
    }
  }

  /// Refresh all check-in data
  Future<void> refresh() async {
    _logger.i('Refresh started');
    try {
      _logger.d('Loading current week check-in...');
      await loadCurrentWeekCheckin();
      _logger.d('Current week check-in loaded');

      _logger.d('Loading user check-ins...');
      await loadUserCheckins(refresh: true);
      _logger.d('User check-ins loaded');

      _logger.d('Loading progress summary...');
      await loadProgressSummary();
      _logger.d('Progress summary loaded');

      _logger.i('Refresh completed successfully');
    } catch (e) {
      _logger.e('Error during refresh: $e');
      rethrow;
    }
  }

  /// Clear all data
  void clear() {
    _currentWeekCheckin = null;
    _userCheckins.clear();
    _progressSummary = null;
    _lastDocument = null;
    _hasMoreCheckins = true;
    _clearError();
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  Future<DocumentSnapshot?> _getLastDocument(String userId) async {
    try {
      // Get the most recent check-in to use as the last document
      final recentCheckins = await CheckinService.getUserCheckins(
        userId,
        limit: 1,
      );

      if (recentCheckins.isNotEmpty) {
        // We need to get the actual document snapshot
        // Since CheckinService doesn't expose the collection directly,
        // we'll use a different approach by getting the check-in ID
        // and then fetching the document snapshot
        final checkin = recentCheckins.first;
        final docRef =
            FirebaseFirestore.instance.collection('checkins').doc(checkin.id);
        return await docRef.get();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<File?> _getPhotoFile(String photoPath) async {
    try {
      return File(photoPath);
    } catch (e) {
      return null;
    }
  }

  /// Get check-in for a specific week
  CheckinModel? getCheckinForWeek(DateTime weekStart) {
    try {
      return _userCheckins.firstWhere(
        (checkin) => checkin.weekStartDate.isAtSameMomentAs(weekStart),
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if user has a check-in for the current week
  bool get hasCurrentWeekCheckin => _currentWeekCheckin != null;

  /// Check if current week check-in is completed
  bool get isCurrentWeekCompleted =>
      _currentWeekCheckin?.status == CheckinStatus.completed;

  /// Check if current week check-in is overdue
  bool get isCurrentWeekOverdue => _currentWeekCheckin?.isOverdue ?? false;

  /// Get days until next check-in
  int get daysUntilNextCheckin {
    if (_currentWeekCheckin?.isCurrentWeek == true) {
      return _currentWeekCheckin!.daysUntilDue;
    }
    return 0;
  }

  /// Get the most recent completed check-in
  CheckinModel? get mostRecentCheckin {
    final completedCheckins = _userCheckins
        .where((c) => c.status == CheckinStatus.completed)
        .toList();

    if (completedCheckins.isEmpty) return null;

    completedCheckins.sort((a, b) => b.submittedAt!.compareTo(a.submittedAt!));
    return completedCheckins.first;
  }

  /// Get check-ins for a specific month
  List<CheckinModel> getCheckinsForMonth(int year, int month) {
    return _userCheckins.where((checkin) {
      return checkin.weekStartDate.year == year &&
          checkin.weekStartDate.month == month;
    }).toList();
  }

  /// Get check-ins for a date range
  List<CheckinModel> getCheckinsForDateRange(
      DateTime startDate, DateTime endDate) {
    return _userCheckins.where((checkin) {
      return checkin.weekStartDate
              .isAfter(startDate.subtract(const Duration(days: 1))) &&
          checkin.weekStartDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }
}
