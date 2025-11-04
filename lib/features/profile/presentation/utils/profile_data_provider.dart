import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/models/user_model.dart';
import '../widgets/profile_quick_access_grid.dart';
import '../widgets/profile_settings_tile.dart';
import '../widgets/profile_delete_account_dialog.dart';

class ProfileDataProvider {
  static List<QuickAccessItem> getQuickAccessItems(BuildContext context) {
    return [
      QuickAccessItem(
        label: 'Weekly Check-in',
        icon: "camera-add-03-stroke-rounded.svg",
        onTap: () => context.push('/checkin'),
      ),
      QuickAccessItem(
        label: 'Progress',
        icon: "chart-line-data-01-stroke-rounded.svg",
        onTap: () => context.go('/progress'),
      ),
    ];
  }

  static List<SettingsItem> getSettingsItems(BuildContext context, {UserModel? user}) {
    final List<SettingsItem> items = [
      SettingsItem(
        label: 'Account Settings',
        icon: "setting-07-stroke-rounded.svg",
        onTap: () => context.push('/account-settings'),
      ),
    ];

    // Only add user-specific settings for non-admin users
    if (user == null || user.role != UserRole.admin) {
      items.addAll([
        const SettingsItem(
          label: 'Reminders',
          icon: "notification-01-stroke-rounded.svg",
          trailing: Switch(value: false, onChanged: null),
        ),
        SettingsItem(
          label: 'Workout Preferences',
          icon: "dumbbell-01-stroke-rounded.svg",
          onTap: () => context.push('/workout-preferences'),
        ),
        SettingsItem(
          label: 'Workout Notifications',
          icon: "notification-square-stroke-rounded.svg",
          onTap: () => context.push('/workout-notifications'),
        ),
        SettingsItem(
          label: 'Nutrition Preferences',
          icon: "tablet-pen-stroke-rounded.svg",
          onTap: () => context.push('/nutrition-preferences'),
        ),
      ]);
    }

    return items;
  }

  static List<SettingsItem> getPrivacyItems(BuildContext context) {
    return [
      SettingsItem(
        label: 'Privacy Policy',
        icon: "police-badge-stroke-rounded.svg",
        onTap: () => context.push('/privacy-policy'),
      ),
      SettingsItem(
        label: 'Delete Account',
        icon: "delete-03-stroke-rounded.svg",
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
        icon: "help-square-stroke-rounded.svg",
        onTap: () => context.push('/help-center'),
      ),
      SettingsItem(
        label: 'Report a Bug',
        icon: "bug-02-stroke-rounded.svg",
        onTap: () => context.push('/bug-report'),
      ),
      SettingsItem(
        label: 'Feedback',
        icon: "comment-01-stroke-rounded.svg",
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
