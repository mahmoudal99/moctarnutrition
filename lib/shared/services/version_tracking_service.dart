import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class VersionTrackingService {
  static final _logger = Logger();
  static const String _viewedVersionsKey = 'viewed_versions';

  /// Check if user has viewed the "What's New" modal for the current version
  static Future<bool> hasViewedCurrentVersion(String currentVersion) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final viewedVersions = prefs.getStringList(_viewedVersionsKey) ?? [];
      final hasViewed = viewedVersions.contains(currentVersion);

      _logger.d(
          'VersionTrackingService - Checking if version $currentVersion has been viewed: $hasViewed');
      _logger.d(
          'VersionTrackingService - Previously viewed versions: $viewedVersions');

      return hasViewed;
    } catch (e) {
      _logger.e('VersionTrackingService - Error checking viewed version: $e');
      return false;
    }
  }

  /// Mark the current version as viewed
  static Future<void> markCurrentVersionAsViewed(String currentVersion) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final viewedVersions = prefs.getStringList(_viewedVersionsKey) ?? [];

      if (!viewedVersions.contains(currentVersion)) {
        viewedVersions.add(currentVersion);
        await prefs.setStringList(_viewedVersionsKey, viewedVersions);
        _logger.i(
            'VersionTrackingService - Marked version $currentVersion as viewed');
        _logger
            .d('VersionTrackingService - All viewed versions: $viewedVersions');
      }
    } catch (e) {
      _logger.e('VersionTrackingService - Error marking version as viewed: $e');
    }
  }

  /// Get all previously viewed versions
  static Future<List<String>> getViewedVersions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final viewedVersions = prefs.getStringList(_viewedVersionsKey) ?? [];
      _logger.d(
          'VersionTrackingService - Retrieved viewed versions: $viewedVersions');
      return viewedVersions;
    } catch (e) {
      _logger.e('VersionTrackingService - Error getting viewed versions: $e');
      return [];
    }
  }

  /// Clear all viewed version history (useful for testing)
  static Future<void> clearViewedVersions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_viewedVersionsKey);
      _logger.i('VersionTrackingService - Cleared all viewed versions');
    } catch (e) {
      _logger.e('VersionTrackingService - Error clearing viewed versions: $e');
    }
  }
}
