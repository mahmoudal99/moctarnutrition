import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/models/user_model.dart';
import '../widgets/profile_quick_access_grid.dart';
import '../widgets/profile_settings_tile.dart';
import '../widgets/profile_delete_account_dialog.dart';
import '../screens/nutrition_preferences_screen.dart';
import '../screens/workout_preferences_screen.dart';
import '../screens/help_center_screen.dart';
import '../screens/account_settings_screen.dart';
import '../screens/bug_report_screen.dart';
import '../screens/feedback_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/workout_notification_settings_screen.dart';

class ProfileDataProvider {
  static List<QuickAccessItem> getQuickAccessItems(BuildContext context) {
    return [
      QuickAccessItem(
        label: 'Weekly Check-in',
        icon: Icons.camera_alt,
        onTap: () => context.push('/checkin'),
      ),
      QuickAccessItem(
        label: 'Progress',
        icon: Icons.show_chart,
        onTap: () => context.go('/progress'),
      ),
    ];
  }

  static List<SettingsItem> getSettingsItems(BuildContext context) {
    return [
      SettingsItem(
        label: 'Account Settings',
        icon: Icons.settings,
        onTap: () => context.push('/account-settings'),
      ),
      const SettingsItem(
        label: 'Reminders',
        icon: Icons.alarm,
        trailing: Switch(value: false, onChanged: null),
      ),
      SettingsItem(
        label: 'Workout Preferences',
        icon: Icons.fitness_center,
        onTap: () => context.push('/workout-preferences'),
      ),
      SettingsItem(
        label: 'Workout Notifications',
        icon: Icons.notifications_active,
        onTap: () => context.push('/workout-notifications'),
      ),
      SettingsItem(
        label: 'Nutrition Preferences',
        icon: Icons.restaurant,
        onTap: () => context.push('/nutrition-preferences'),
      ),
    ];
  }

  static List<SettingsItem> getPrivacyItems(BuildContext context) {
    return [
      SettingsItem(
        label: 'Privacy Policy',
        icon: Icons.privacy_tip,
        onTap: () => context.push('/privacy-policy'),
      ),
      SettingsItem(
        label: 'Delete Account',
        icon: Icons.delete_forever,
        onTap: () {
          ProfileDeleteAccountDialog.show(context);
        },
      ),
    ];
  }

  static List<SettingsItem> getSupportItems(BuildContext context) {
    return [
      SettingsItem(
        label: 'Help Center',
        icon: Icons.help_outline,
        onTap: () => context.push('/help-center'),
      ),
      SettingsItem(
        label: 'Report a Bug',
        icon: Icons.bug_report,
        onTap: () => context.push('/bug-report'),
      ),
      SettingsItem(
        label: 'Feedback',
        icon: Icons.feedback,
        onTap: () => context.push('/feedback'),
      ),
    ];
  }

  static List<MockStat> getUserStats(UserModel user) {
    // TODO: Replace with real stats from user data
    return [
      const MockStat(value: '0', label: 'Workouts'),
      const MockStat(value: '0', label: 'Weeks Streak'),
      const MockStat(value: '0', label: 'Calories'),
      const MockStat(value: '0', label: 'Meals'),
    ];
  }
}

class MockStat {
  final String value;
  final String label;

  const MockStat({required this.value, required this.label});
}
