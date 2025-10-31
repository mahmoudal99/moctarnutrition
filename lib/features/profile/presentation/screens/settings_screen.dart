import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/auth_provider.dart' as app_auth;
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/version_text.dart';
import '../../../onboarding/presentation/screens/get_started_screen.dart';
import '../widgets/notifications_toggle.dart';
import '../widgets/reminders_toggle.dart';
import '../widgets/profile_user_card.dart';
import '../widgets/profile_quick_access_grid.dart';
import '../widgets/profile_section_header.dart';
import '../widgets/profile_settings_tile.dart';
import '../widgets/profile_logout_button.dart';
import '../utils/profile_data_provider.dart';
import 'debug_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  static final _logger = Logger();

  const ProfileScreen({super.key});

  void showNotificationsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final viewInsets = MediaQuery.of(sheetContext).viewInsets;
        final padding = MediaQuery.of(sheetContext).padding;

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: viewInsets.bottom + padding.bottom + 300,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppConstants.textTertiary.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'SETTINGS',
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.secondaryColor
                ),
              ),
              Text(
                'Notifications',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const NotificationsToggle(),
              const SizedBox(height: 12),
              const RemindersToggle(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<app_auth.AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.userModel;
        final authUser = authProvider.firebaseUser;

        if (user == null || authUser == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/get-started');
            }
          });
          return const GetStartedScreen();
        }

        // Get data from provider
        final quickAccess = ProfileDataProvider.getQuickAccessItems(context);
        final settings = ProfileDataProvider.getSettingsItems(context, user: user);
        final privacy = ProfileDataProvider.getPrivacyItems(context);
        final support = ProfileDataProvider.getSupportItems(context);

        return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                const ProfileSectionHeader(title: 'Settings'),
                ProfileUserCard(
                  user: user,
                  authUser: authUser,
                  authProvider: authProvider,
                ),
                if (user.role != UserRole.admin) ...[
                  const SizedBox(height: 20),
                  ProfileQuickAccessGrid(items: quickAccess),
                ],
                if (user.role != UserRole.admin) ...[
                  ProfileSettingsTile(
                    item: SettingsItem(
                      label: 'Notifications',
                      icon: Icons.notifications_outlined,
                      onTap: () => showNotificationsSheet(context),
                    ),
                  ),
                ],
                ...settings
                    .where((item) =>
                        item.label != 'Notifications' &&
                        item.label != 'Reminders')
                    .map((item) => ProfileSettingsTile(item: item)),
                ...privacy.map((item) => ProfileSettingsTile(item: item)),
                ...support.map((item) => ProfileSettingsTile(item: item)),

                // Debug Settings (only visible in debug mode)
                if (kDebugMode) ...[
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppConstants.errorColor.withOpacity(0.1),
                      child: const Icon(
                        Icons.bug_report,
                        color: AppConstants.errorColor,
                      ),
                    ),
                    title: const Text('Debug Settings'),
                    subtitle:
                        const Text('View pending notifications and debug info'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DebugSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 32),
                const ProfileLogoutButton(),
                const SizedBox(height: 32),
                const VersionText(),
                const SizedBox(height: 96),
              ],
            ),
          ),
        );
      },
    );
  }
}
