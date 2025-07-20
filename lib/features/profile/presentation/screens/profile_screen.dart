import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/auth_provider.dart' as app_auth;
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/services/onboarding_service.dart';
import '../../../onboarding/presentation/screens/get_started_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<app_auth.AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.userModel;
        final authUser = authProvider.firebaseUser;
        
        // Debug logging
        print('Profile Screen - AuthProvider state:');
        print('  isAuthenticated: ${authProvider.isAuthenticated}');
        print('  isLoading: ${authProvider.isLoading}');
        print('  userModel: ${user?.name ?? 'null'}');
        print('  firebaseUser: ${authUser?.email ?? 'null'}');
        
        if (authProvider.isLoading) {
          return const Scaffold(
            backgroundColor: AppConstants.backgroundColor,
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }





        if (user == null || authUser == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/get-started');
            }
          });
          return const GetStartedScreen();
        }

        final stats = _getUserStats(user);
        final quickAccess = _getQuickAccessItems(context);
        final ctaList = _getCTAItems(context, user);
        final settings = _getSettingsItems(context);
        final support = _getSupportItems(context);

        return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                _UserCard(user: user, authUser: authUser, authProvider: authProvider),
                const SizedBox(height: 20),
                // _StatsGrid(stats: stats),
                const SizedBox(height: 20),
                _QuickAccessGrid(items: quickAccess),
                const SizedBox(height: 20),
                _CTASection(items: ctaList),
                const SizedBox(height: 28),
                _SectionHeader(title: 'Settings'),
                ...settings.map((item) => _SettingsTile(item: item)),
                const SizedBox(height: 24),
                _SectionHeader(title: 'Support'),
                ...support.map((item) => _SettingsTile(item: item)),
                const SizedBox(height: 32),
                _LogoutButton(),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- User Card ---
class _UserCard extends StatelessWidget {
  final UserModel user;
  final firebase_auth.User authUser;
  final app_auth.AuthProvider authProvider;

  const _UserCard({required this.user, required this.authUser, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundImage: user.photoUrl != null 
                      ? NetworkImage(user.photoUrl!) 
                      : null,
                  backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                  child: user.photoUrl == null
                      ? Text(
                          (user.name?.isNotEmpty == true) ? user.name![0].toUpperCase() : 'U',
                          style: AppTextStyles.heading4.copyWith(
                            color: AppConstants.primaryColor,
                          ),
                        )
                      : null,
                ),
                if (authUser.emailVerified)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppConstants.successColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.check, size: 16, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name ?? 'User',
                          style: AppTextStyles.heading4,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (user.subscriptionStatus == SubscriptionStatus.premium)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Premium',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppConstants.primaryColor,
                                  fontWeight: FontWeight.bold)),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppConstants.textTertiary),
                        onPressed: () => _showEditProfileDialog(context, user, authProvider),
                        tooltip: 'Edit profile',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: AppTextStyles.caption.copyWith(color: AppConstants.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Role: ${user.role.name}',
                    style: AppTextStyles.caption.copyWith(color: AppConstants.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Member since ${_formatDate(user.createdAt)}',
                    style: AppTextStyles.caption.copyWith(color: AppConstants.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Stats Grid ---
class _StatsGrid extends StatelessWidget {
  final List<_MockStat> stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1,
      children: stats.map((stat) => _StatCard(stat: stat)).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final _MockStat stat;

  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                stat.value,
                style: AppTextStyles.heading4.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                stat.label,
                style: AppTextStyles.caption.copyWith(color: AppConstants.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Quick Access Grid ---
class _QuickAccessGrid extends StatelessWidget {
  final List<_MockQuickAccess> items;

  const _QuickAccessGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.7,
      children: items.map((item) => _QuickAccessTile(item: item)).toList(),
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  final _MockQuickAccess item;

  const _QuickAccessTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(item.icon, color: AppConstants.primaryColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.label,
                        style: AppTextStyles.bodySmall
                            .copyWith(fontWeight: FontWeight.w600)),
                    // if (item.badge != null)
                    //   Container(
                    //     margin: const EdgeInsets.only(top: 4),
                    //     padding: const EdgeInsets.symmetric(
                    //         horizontal: 6, vertical: 2),
                    //     decoration: BoxDecoration(
                    //       color: AppConstants.accentColor.withOpacity(0.12),
                    //       borderRadius: BorderRadius.circular(6),
                    //     ),
                    //     child: Text(item.badge!,
                    //         style: AppTextStyles.caption
                    //             .copyWith(color: AppConstants.accentColor)),
                    //   ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- CTA Section ---
class _CTASection extends StatelessWidget {
  final List<_MockCTA> items;

  const _CTASection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) => _CTATile(item: item)).toList(),
    );
  }
}

class _CTATile extends StatelessWidget {
  final _MockCTA item;

  const _CTATile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      color:
          item.isProminent ? AppConstants.primaryColor.withOpacity(0.08) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(item.icon, color: AppConstants.primaryColor),
        title: Text(item.label,
            style:
                AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        trailing: item.trailing,
        onTap: item.onTap,
      ),
    );
  }
}

// --- Section Header ---
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(title,
          style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold, color: AppConstants.textSecondary)),
    );
  }
}

// --- Settings Tile ---
class _SettingsTile extends StatelessWidget {
  final _MockSettingsItem item;

  const _SettingsTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(item.icon, color: AppConstants.textSecondary),
      title: Text(item.label, style: AppTextStyles.bodyMedium),
      trailing: item.trailing,
      onTap: item.onTap,
    );
  }
}

// --- Logout Button ---
class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<app_auth.AuthProvider>(
      builder: (context, authProvider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor.withOpacity(0.12),
              foregroundColor: AppConstants.errorColor,
              minimumSize: const Size.fromHeight(48),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            icon: authProvider.isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppConstants.errorColor),
                    ),
                  )
                : const Icon(Icons.logout),
            label: Text(authProvider.isLoading ? 'Signing out...' : 'Logout'),
            onPressed: authProvider.isLoading ? null : () => _handleLogout(context, authProvider),
          ),
        );
      },
    );
  }

  void _handleLogout(BuildContext context, app_auth.AuthProvider authProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await authProvider.signOut();
      if (context.mounted) {
        // AuthProvider already resets onboarding state, just navigate to get started screen
        context.go('/get-started');
      }
    }
  }
}



class _MockStat {
  final String value;
  final String label;

  const _MockStat({required this.value, required this.label});
}

class _MockQuickAccess {
  final String label;
  final IconData icon;
  final String? badge;
  final VoidCallback? onTap;

  const _MockQuickAccess(
      {required this.label, required this.icon, this.badge, this.onTap});
}

class _MockCTA {
  final String label;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isProminent;

  const _MockCTA(
      {required this.label,
      required this.icon,
      this.trailing,
      this.onTap,
      this.isProminent = false});
}

class _MockSettingsItem {
  final String label;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MockSettingsItem(
      {required this.label, required this.icon, this.trailing, this.onTap});
}

// --- HELPER FUNCTIONS ---
String _formatDate(DateTime date) {
  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[date.month - 1]} ${date.year}';
}

void _showEditProfileDialog(BuildContext context, UserModel user, app_auth.AuthProvider authProvider) {
  final nameController = TextEditingController(text: user.name ?? '');
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter your full name',
            ),
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final newName = nameController.text.trim();
            if (newName.isNotEmpty && newName != user.name) {
              // Update user profile
              final updatedUser = user.copyWith(
                name: newName,
                updatedAt: DateTime.now(),
              );
              
              try {
                await AuthService.updateUserProfile(updatedUser);
                
                // Update the AuthProvider to reflect changes immediately
                await authProvider.updateUserProfile(updatedUser);
                
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully'),
                      backgroundColor: AppConstants.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update profile: $e'),
                      backgroundColor: AppConstants.errorColor,
                    ),
                  );
                }
              }
            } else {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

// --- DATA GENERATION FUNCTIONS ---
List<_MockStat> _getUserStats(UserModel user) {
  // TODO: Replace with real stats from user data
  return [
    const _MockStat(value: '0', label: 'Workouts'),
    const _MockStat(value: '0', label: 'Weeks Streak'),
    const _MockStat(value: '0', label: 'Calories'),
    const _MockStat(value: '0', label: 'Meals'),
  ];
}

List<_MockQuickAccess> _getQuickAccessItems(BuildContext context) {
  return [
    _MockQuickAccess(
      label: 'My Workouts', 
      icon: Icons.fitness_center, 
      onTap: () => context.go('/workouts'),
    ),
    _MockQuickAccess(
      label: 'Meal Plans', 
      icon: Icons.restaurant, 
      onTap: () => context.go('/meal-prep'),
    ),
    _MockQuickAccess(
      label: 'Progress', 
      icon: Icons.show_chart, 
      onTap: () => context.go('/progress'),
    ),
    _MockQuickAccess(
      label: 'Favorites', 
      icon: Icons.star, 
      onTap: () => context.go('/favorites'),
    ),
  ];
}

List<_MockCTA> _getCTAItems(BuildContext context, UserModel user) {
  return [
    _MockCTA(
      label: 'Refer a Friend', 
      icon: Icons.group_add, 
      isProminent: true,
      onTap: () {
        // TODO: Implement refer a friend
      },
    ),
    if (user.subscriptionStatus == SubscriptionStatus.free)
      _MockCTA(
        label: 'Upgrade Membership', 
        icon: Icons.workspace_premium,
        onTap: () => context.go('/subscription'),
      ),
    _MockCTA(
      label: 'Book a 1-on-1 Trainer', 
      icon: Icons.person_search,
      onTap: () {
        // TODO: Implement trainer booking
      },
    ),
  ];
}

List<_MockSettingsItem> _getSettingsItems(BuildContext context) {
  return [
    _MockSettingsItem(
      label: 'Notifications',
      icon: Icons.notifications,
      trailing: Switch(value: true, onChanged: null),
    ),
    _MockSettingsItem(
      label: 'Reminders',
      icon: Icons.alarm,
      trailing: Switch(value: false, onChanged: null),
    ),
    _MockSettingsItem(
      label: 'Dark Mode',
      icon: Icons.dark_mode,
      trailing: Switch(value: false, onChanged: null),
    ),
    _MockSettingsItem(
      label: 'Workout Preferences', 
      icon: Icons.fitness_center,
      onTap: () {
        // TODO: Navigate to workout preferences
      },
    ),
    _MockSettingsItem(
      label: 'Nutrition Preferences', 
      icon: Icons.restaurant,
      onTap: () {
        // TODO: Navigate to nutrition preferences
      },
    ),
    _MockSettingsItem(
      label: 'Payment Info', 
      icon: Icons.credit_card,
      onTap: () {
        // TODO: Navigate to payment settings
      },
    ),
    _MockSettingsItem(
      label: 'Account Settings', 
      icon: Icons.settings,
      onTap: () {
        // TODO: Navigate to account settings
      },
    ),
  ];
}

List<_MockSettingsItem> _getSupportItems(BuildContext context) {
  return [
    _MockSettingsItem(
      label: 'Help Center', 
      icon: Icons.help_outline,
      onTap: () {
        // TODO: Open help center
      },
    ),
    _MockSettingsItem(
      label: 'Report a Bug', 
      icon: Icons.bug_report,
      onTap: () {
        // TODO: Open bug report
      },
    ),
    _MockSettingsItem(
      label: 'Feedback', 
      icon: Icons.feedback,
      onTap: () {
        // TODO: Open feedback form
      },
    ),
  ];
}


