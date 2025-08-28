import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/workout_model.dart';
import '../services/exercise_service.dart';
import '../services/exercise_local_storage_service.dart';

class ExerciseProvider extends ChangeNotifier {
  static final _logger = Logger();

  final FreeExerciseService _exerciseService = FreeExerciseService();
  final ExerciseLocalStorageService _localStorage =
      ExerciseLocalStorageService();

  List<Exercise> _availableExercises = [];
  List<Exercise> _filteredExercises = [];
  List<String> _availableMuscleGroups = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _selectedMuscleGroup;

  // Getters
  List<Exercise> get availableExercises => _availableExercises;
  List<Exercise> get filteredExercises => _filteredExercises;
  List<String> get availableMuscleGroups => _availableMuscleGroups;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get selectedMuscleGroup => _selectedMuscleGroup;

  ExerciseProvider() {
    _loadExercises();
  }

  /// Load all exercises from cache first, then API if needed
  Future<void> _loadExercises() async {
    _setLoading(true);
    _error = null;

    try {
      _logger.d('Loading exercises from local cache first');

      // Try to load from cache first
      final cachedExercises = await _localStorage.loadExercises();
      final cachedMuscleGroups = await _localStorage.loadMuscleGroups();

      if (cachedExercises.isNotEmpty && cachedMuscleGroups.isNotEmpty) {
        _availableExercises = cachedExercises;
        _availableMuscleGroups = cachedMuscleGroups;
        _filteredExercises = _availableExercises;
        // Check if cache is stale and update in background
        final isStale = await _localStorage.isCacheStale();
        if (isStale) {
          _logger.d('Cache is stale, updating from API in background');
          _updateFromApiInBackground();
        }
      } else {
        _logger.d('No cached data found, loading from API');
        await _loadFromApi();
      }
    } catch (e) {
      _logger.e('Failed to load exercises from cache: $e');
      // Fallback to API if cache fails
      await _loadFromApi();
    } finally {
      _setLoading(false);
    }
  }

  /// Load exercises from API and cache them
  Future<void> _loadFromApi() async {
    try {
      _logger.d('Loading exercises from Free Exercise API');

      _availableExercises = await _exerciseService.getAllExercises();
      _availableMuscleGroups = await _exerciseService
          .getPrimaryMuscles(); // Use primary muscles for cleaner filtering
      _filteredExercises = _availableExercises;

      // Cache the data
      await _localStorage.saveExercises(_availableExercises);
      await _localStorage.saveMuscleGroups(_availableMuscleGroups);

      _logger.d('Loaded and cached ${_availableExercises.length} exercises');
    } catch (e) {
      _logger.e('Failed to load exercises from API: $e');
      _error = 'Failed to load exercises. Please try again.';
    }
  }

  /// Update from API in background without blocking UI
  Future<void> _updateFromApiInBackground() async {
    try {
      _logger.d('Updating exercises from API in background');

      final newExercises = await _exerciseService.getAllExercises();
      final newMuscleGroups = await _exerciseService
          .getPrimaryMuscles(); // Use primary muscles for cleaner filtering

      // Only update if we got new data
      if (newExercises.isNotEmpty && newMuscleGroups.isNotEmpty) {
        _availableExercises = newExercises;
        _availableMuscleGroups = newMuscleGroups;

        // Re-apply current filters
        _filterExercises();

        // Update cache
        await _localStorage.saveExercises(_availableExercises);
        await _localStorage.saveMuscleGroups(_availableMuscleGroups);

        _logger.d(
            'Updated exercises in background: ${_availableExercises.length} exercises');
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Failed to update exercises in background: $e');
      // Don't show error to user for background updates
    }
  }

  /// Refresh exercises (reload from service and clear cache)
  Future<void> refreshExercises() async {
    _logger.d('Refreshing exercises from API');
    _setLoading(true);
    _error = null;

    try {
      // Clear cache to force fresh load
      await _localStorage.clearExercises();
      await _loadFromApi();
    } catch (e) {
      _logger.e('Failed to refresh exercises: $e');
      _error = 'Failed to refresh exercises. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  /// Clear local cache manually
  Future<void> clearCache() async {
    _logger.d('Clearing exercise cache');
    await _localStorage.clearExercises();
    _availableExercises = [];
    _availableMuscleGroups = [];
    _filteredExercises = [];
    notifyListeners();
  }

  /// Set search query and filter exercises
  void setSearchQuery(String query) {
    _searchQuery = query;
    _filterExercises();
  }

  /// Set selected muscle group and filter exercises
  void setSelectedMuscleGroup(String? muscleGroup) {
    _selectedMuscleGroup = muscleGroup;
    _filterExercises();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedMuscleGroup = null;
    _filterExercises();
  }

  /// Filter exercises based on current search query and muscle group
  void _filterExercises() {
    try {
      _logger.d(
          'Filtering exercises locally with query: "$_searchQuery", muscle group: "$_selectedMuscleGroup"');
      _logger.d('Total available exercises: ${_availableExercises.length}');

      List<Exercise> filtered = _availableExercises;

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final lowercaseQuery = _searchQuery.toLowerCase();
        filtered = filtered.where((exercise) {
          return exercise.name.toLowerCase().contains(lowercaseQuery) ||
              exercise.description.toLowerCase().contains(lowercaseQuery);
        }).toList();
        _logger.d('After search filter: ${filtered.length} exercises');
      }

      // Filter by muscle group - use exact match for cleaner results
      if (_selectedMuscleGroup != null && _selectedMuscleGroup!.isNotEmpty) {
        final lowercaseTarget = _selectedMuscleGroup!.toLowerCase();
        _logger.d('Filtering by muscle group: "$lowercaseTarget"');

        filtered = filtered.where((exercise) {
          // Check if any muscle group exactly matches the selected target
          final hasMatch = exercise.muscleGroups
              .any((muscle) => muscle.toLowerCase() == lowercaseTarget);
          if (hasMatch) {
            _logger.d(
                'Exercise "${exercise.name}" matches muscle group "$lowercaseTarget"');
          }
          return hasMatch;
        }).toList();

        _logger.d('After muscle group filter: ${filtered.length} exercises');
      }

      _filteredExercises = filtered;
      _logger
          .d('Final filtered result: ${_filteredExercises.length} exercises');
      notifyListeners();
    } catch (e) {
      _logger.e('Error filtering exercises: $e');
      _error = 'Failed to filter exercises. Please try again.';
      notifyListeners();
    }
  }

  /// Get exercise by ID
  Future<Exercise?> getExerciseById(String id) async {
    return await _exerciseService.getExerciseById(id);
  }

  /// Get exercises by muscle group
  Future<List<Exercise>> getExercisesByMuscleGroup(String muscleGroup) async {
    return await _exerciseService.getExercisesByTarget(muscleGroup);
  }

  /// Search exercises
  Future<List<Exercise>> searchExercises(String query) async {
    return await _exerciseService.searchExercises(query);
  }

  /// Get cache status information
  Future<Map<String, dynamic>> getCacheStatus() async {
    final lastUpdated = await _localStorage.getLastUpdated();
    final isStale = await _localStorage.isCacheStale();

    return {
      'hasCachedData': _availableExercises.isNotEmpty,
      'exerciseCount': _availableExercises.length,
      'muscleGroupCount': _availableMuscleGroups.length,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'isStale': isStale,
      'cacheAge': lastUpdated != null
          ? DateTime.now().difference(lastUpdated).inHours
          : null,
    };
  }

  /// Check if exercises are loaded
  bool get hasExercises => _availableExercises.isNotEmpty;

  /// Check if there are filtered results
  bool get hasFilteredResults => _filteredExercises.isNotEmpty;

  /// Get exercise count
  int get totalExerciseCount => _availableExercises.length;

  /// Get filtered exercise count
  int get filteredExerciseCount => _filteredExercises.length;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
