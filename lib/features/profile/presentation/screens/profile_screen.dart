import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
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

class ProfileScreen extends StatelessWidget {
  static final _logger = Logger();

  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<app_auth.AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.userModel;
        final authUser = authProvider.firebaseUser;

        // Debug logging
        _logger.d('Profile Screen - AuthProvider state:');
        _logger.d('  isAuthenticated: ${authProvider.isAuthenticated}');
        _logger.d('  isLoading: ${authProvider.isLoading}');
        _logger.d('  userModel: ${user?.name ?? 'null'}');
        _logger.d('  firebaseUser: ${authUser?.email ?? 'null'}');

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
        final settings = ProfileDataProvider.getSettingsItems(context);
        final privacy = ProfileDataProvider.getPrivacyItems(context);
        final support = ProfileDataProvider.getSupportItems(context);

        return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                ProfileUserCard(
                  user: user,
                  authUser: authUser,
                  authProvider: authProvider,
                ),
                if (user.role != UserRole.admin) ...[
                  const SizedBox(height: 20),
                  ProfileQuickAccessGrid(items: quickAccess),
                ],
                const SizedBox(height: 24),
                const ProfileSectionHeader(title: 'Settings'),
                const NotificationsToggle(),
                const RemindersToggle(),
                ...settings
                    .where((item) =>
                        item.label != 'Notifications' &&
                        item.label != 'Reminders')
                    .map((item) => ProfileSettingsTile(item: item)),
                const SizedBox(height: 24),
                const ProfileSectionHeader(title: 'Privacy'),
                ...privacy.map((item) => ProfileSettingsTile(item: item)),
                const SizedBox(height: 24),
                const ProfileSectionHeader(title: 'Support'),
                ...support.map((item) => ProfileSettingsTile(item: item)),
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
