import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/workout_model.dart';
import '../services/exercise_service.dart';

class ExerciseProvider extends ChangeNotifier {
  static final _logger = Logger();
  
  final ExerciseService _exerciseService = ExerciseService();
  
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

  /// Load all exercises from the service
  Future<void> _loadExercises() async {
    _setLoading(true);
    _error = null;

    try {
      _logger.d('Loading exercises from exercise service');
      
      _availableExercises = _exerciseService.getAllExercises();
      _availableMuscleGroups = _exerciseService.getAvailableMuscleGroups();
      _filteredExercises = _availableExercises;
      
      _logger.d('Loaded ${_availableExercises.length} exercises');
    } catch (e) {
      _logger.e('Failed to load exercises: $e');
      _error = 'Failed to load exercises. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh exercises (reload from service)
  Future<void> refreshExercises() async {
    _logger.d('Refreshing exercises');
    await _loadExercises();
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
    _filteredExercises = _exerciseService.filterExercises(
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      muscleGroup: _selectedMuscleGroup,
    );
    notifyListeners();
  }

  /// Get exercise by ID
  Exercise? getExerciseById(String id) {
    return _exerciseService.getExerciseById(id);
  }

  /// Get exercises by muscle group
  List<Exercise> getExercisesByMuscleGroup(String muscleGroup) {
    return _exerciseService.getExercisesByMuscleGroup(muscleGroup);
  }

  /// Search exercises
  List<Exercise> searchExercises(String query) {
    return _exerciseService.searchExercises(query);
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