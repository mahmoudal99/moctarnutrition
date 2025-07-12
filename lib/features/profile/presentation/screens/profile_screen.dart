import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data
    final user = _mockUser;
    final stats = _mockStats;
    final quickAccess = _mockQuickAccess;
    final ctaList = _mockCTA;
    final settings = _mockSettings;
    final support = _mockSupport;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            _UserCard(user: user),
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
  }
}

// --- User Card ---
class _UserCard extends StatelessWidget {
  final _MockUser user;

  const _UserCard({required this.user});

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
                  backgroundImage: NetworkImage(user.photoUrl),
                ),
                if (user.isVerified)
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
                          user.name,
                          style: AppTextStyles.heading4,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (user.membership == 'Premium')
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
                        onPressed: () {},
                        tooltip: 'Edit profile',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: AppTextStyles.caption.copyWith(color: AppConstants.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.branch,
                    style: AppTextStyles.caption.copyWith(color: AppConstants.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Member since ${user.joinDate}',
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
                        style: AppTextStyles.bodyMedium
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
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        onPressed: () {},
      ),
    );
  }
}

// --- MOCK DATA MODELS ---
class _MockUser {
  final String name;
  final String username;
  final String photoUrl;
  final String membership;
  final String branch;
  final String joinDate;
  final bool isVerified;

  const _MockUser({
    required this.name,
    required this.username,
    required this.photoUrl,
    required this.membership,
    required this.branch,
    required this.joinDate,
    required this.isVerified,
  });
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

// --- MOCK DATA ---
const _mockUser = _MockUser(
  name: 'Mahmoud Almahroum',
  username: 'champion150',
  photoUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
  membership: 'Premium',
  branch: 'Downtown Gym',
  joinDate: 'Jan 2023',
  isVerified: true,
);

const _mockStats = [
  _MockStat(value: '124', label: 'Workouts'),
  _MockStat(value: '6', label: 'Weeks Streak'),
  _MockStat(value: '18,500', label: 'Calories'),
  _MockStat(value: 'PR: 120kg', label: 'Best Squat'),
];

const _mockQuickAccess = [
  _MockQuickAccess(
      label: 'My Workouts', icon: Icons.fitness_center, badge: null),
  _MockQuickAccess(
      label: 'Class Schedule', icon: Icons.calendar_month, badge: 'NEW'),
  _MockQuickAccess(label: 'Progress', icon: Icons.show_chart, badge: null),
  _MockQuickAccess(label: 'Favorites', icon: Icons.star, badge: null),
];

const _mockCTA = [
  _MockCTA(label: 'Refer a Friend', icon: Icons.group_add, isProminent: true),
  _MockCTA(label: 'Upgrade Membership', icon: Icons.workspace_premium),
  _MockCTA(label: 'Book a 1-on-1 Trainer', icon: Icons.person_search),
];

final _mockSettings = [
  _MockSettingsItem(
      label: 'Notifications',
      icon: Icons.notifications,
      trailing: Switch(value: true, onChanged: null)),
  _MockSettingsItem(
      label: 'Reminders',
      icon: Icons.alarm,
      trailing: Switch(value: false, onChanged: null)),
  _MockSettingsItem(
      label: 'Dark Mode',
      icon: Icons.dark_mode,
      trailing: Switch(value: false, onChanged: null)),
  _MockSettingsItem(label: 'Workout Preferences', icon: Icons.fitness_center),
  _MockSettingsItem(label: 'Nutrition Preferences', icon: Icons.restaurant),
  _MockSettingsItem(label: 'Payment Info', icon: Icons.credit_card),
  _MockSettingsItem(label: 'Account Settings', icon: Icons.settings),
];

final _mockSupport = [
  _MockSettingsItem(label: 'Help Center', icon: Icons.help_outline),
  _MockSettingsItem(label: 'Report a Bug', icon: Icons.bug_report),
  _MockSettingsItem(label: 'Feedback', icon: Icons.feedback),
];
