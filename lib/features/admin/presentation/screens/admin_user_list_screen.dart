import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:champions_gym_app/shared/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:champions_gym_app/features/admin/presentation/screens/admin_user_detail_screen.dart';

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({Key? key}) : super(key: key);

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  late Future<List<UserModel>> _usersFuture;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
  }

  Future<List<UserModel>> _fetchUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    return snapshot.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('All Users'),
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<UserModel>>(
                future: _usersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingShimmer();
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: \\${snapshot.error}'));
                  }
                  final users = (snapshot.data ?? [])
                      .where((u) =>
                          _search.isEmpty ||
                          (u.name
                                  ?.toLowerCase()
                                  .contains(_search.toLowerCase()) ??
                              false) ||
                          u.email.toLowerCase().contains(_search.toLowerCase()))
                      .toList();
                  if (users.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _UserCard(
                        user: user,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminUserDetailScreen(user: user),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search users by name or email',
        prefixIcon: const Icon(Icons.search, color: AppConstants.textTertiary),
        filled: true,
        fillColor: AppConstants.surfaceColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (value) => setState(() => _search = value),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.separated(
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppConstants.textTertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 14,
                        color: AppConstants.textTertiary.withOpacity(0.1),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 12,
                        color: AppConstants.textTertiary.withOpacity(0.08),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 48,
                  height: 20,
                  color: AppConstants.textTertiary.withOpacity(0.08),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline,
              size: 64, color: AppConstants.textTertiary.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('No users found', style: AppTextStyles.heading4),
          const SizedBox(height: 8),
          Text('Try a different search or check back later.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppConstants.textSecondary)),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _UserCard({required this.user, required this.onTap});

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppConstants.primaryColor;
      case UserRole.trainer:
        return AppConstants.accentColor;
      case UserRole.user:
      default:
        return AppConstants.textTertiary;
    }
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.trainer:
        return 'Trainer';
      case UserRole.user:
      default:
        return 'User';
    }
  }

  Color _subscriptionColor(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.premium:
        return AppConstants.successColor;
      case SubscriptionStatus.basic:
        return AppConstants.secondaryColor;
      case SubscriptionStatus.cancelled:
        return AppConstants.errorColor;
      case SubscriptionStatus.free:
      default:
        return AppConstants.textTertiary;
    }
  }

  String _subscriptionLabel(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.premium:
        return 'Premium';
      case SubscriptionStatus.basic:
        return 'Basic';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
      case SubscriptionStatus.free:
      default:
        return 'Free';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              user.photoUrl != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(user.photoUrl!),
                      radius: 24,
                    )
                  : CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          AppConstants.primaryColor.withOpacity(0.08),
                      child:
                          Icon(Icons.person, color: AppConstants.primaryColor),
                    ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name ?? user.email,
                      style: AppTextStyles.bodyLarge
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppConstants.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _roleColor(user.role).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _roleLabel(user.role),
                            style: AppTextStyles.caption.copyWith(
                              color: _roleColor(user.role),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _subscriptionColor(user.subscriptionStatus)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _subscriptionLabel(user.subscriptionStatus),
                            style: AppTextStyles.caption.copyWith(
                              color:
                                  _subscriptionColor(user.subscriptionStatus),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios,
                  color: AppConstants.textTertiary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
