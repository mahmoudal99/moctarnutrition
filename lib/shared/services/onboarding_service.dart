import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class OnboardingService {
  static final _logger = Logger();
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';
  static const String _hasSeenGetStartedKey = 'has_seen_get_started';

  /// Check if user has seen the get started screen
  static Future<bool> hasSeenGetStarted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenGetStartedKey) ?? false;
  }

  /// Mark get started screen as seen
  static Future<void> markGetStartedAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenGetStartedKey, true);
  }

  /// Check if user has seen the onboarding flow
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenOnboardingKey) ?? false;
  }

  /// Mark onboarding as seen
  static Future<void> markOnboardingAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, true);
  }

  /// Reset onboarding state (useful for testing or when user signs out)
  static Future<void> resetOnboardingState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasSeenOnboardingKey);
    await prefs.remove(_hasSeenGetStartedKey);
    _logger.i('Onboarding state reset successfully');
  }

  /// Get the initial route based on onboarding state
  static Future<String> getInitialRoute() async {
    final hasSeenGetStartedScreen = await hasSeenGetStarted();
    final hasSeenOnboardingScreen = await hasSeenOnboarding();

    if (!hasSeenGetStartedScreen) {
      return '/get-started';
    } else if (!hasSeenOnboardingScreen) {
      return '/onboarding';
    } else {
      return '/auth';
    }
  }
}
 