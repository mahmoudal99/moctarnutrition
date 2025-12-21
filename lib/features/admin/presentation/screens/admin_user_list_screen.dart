import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:champions_gym_app/shared/models/user_model.dart';
import 'package:champions_gym_app/shared/utils/avatar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';



class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  late Future<List<UserModel>> _usersFuture;
  String _search = '';
  TrainingProgramStatus? _selectedProgram;
  bool _showNewUsersOnly = false;
  bool _sortByNameAZ = true;

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
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 96),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 12),
            _buildFilters(),
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
                      .where((u) => _matchesFilters(u))
                      .toList();
                  
                  if (_sortByNameAZ) {
                    users.sort((a, b) => _compareUsers(a, b));
                  }
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
                          HapticFeedback.lightImpact();
                          context.push('/admin/user-detail', extra: user);
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

  bool _matchesFilters(UserModel user) {
    // Search filter
    if (_search.isNotEmpty) {
      final matchesSearch = (user.name?.toLowerCase().contains(_search.toLowerCase()) ?? false) ||
          user.email.toLowerCase().contains(_search.toLowerCase());
      if (!matchesSearch) return false;
    }

    // Program type filter
    if (_selectedProgram != null && user.trainingProgramStatus != _selectedProgram) {
      return false;
    }


    // New users only filter
    if (_showNewUsersOnly) {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      if (user.createdAt.isBefore(sevenDaysAgo)) {
        return false;
      }
    }

    return true;
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
      onChanged: (value) {
        if (value.length == 1) {
          HapticFeedback.selectionClick();
        }
        setState(() => _search = value);
      },
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Filters', style: AppTextStyles.heading5),
            const Spacer(),
            if (_hasActiveFilters())
              TextButton(
                onPressed: _clearFilters,
                child: Text('Clear All', style: AppTextStyles.bodySmall.copyWith(
                  color: AppConstants.primaryColor,
                )),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildProgramFilterChip(),
                const SizedBox(width: 8),
                _buildNewUsersChip(),
                const SizedBox(width: 8),
                _buildNameSortChip(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _hasActiveFilters() {
    return _selectedProgram != null || 
           _showNewUsersOnly;
  }

  void _clearFilters() {
    setState(() {
      _selectedProgram = null;
      _showNewUsersOnly = false;
      _sortByNameAZ = true;
    });
  }

  int _compareUsers(UserModel a, UserModel b) {
    final nameA = a.name?.toLowerCase() ?? '';
    final nameB = b.name?.toLowerCase() ?? '';

    if (nameA.isEmpty && nameB.isEmpty) {
      // If both names are empty, sort by email
      return a.email.toLowerCase().compareTo(b.email.toLowerCase());
    } else if (nameA.isEmpty) {
      // Empty names go to the end
      return 1;
    } else if (nameB.isEmpty) {
      // Empty names go to the end
      return -1;
    } else {
      // Sort by name A-Z
      return nameA.compareTo(nameB);
    }
  }

  Widget _buildProgramFilterChip() {
    return Container(
      decoration: BoxDecoration(
        color: _selectedProgram != null 
            ? AppConstants.primaryColor.withOpacity(0.12)
            : AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: _selectedProgram != null 
              ? AppConstants.primaryColor
              : AppConstants.borderColor,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TrainingProgramStatus?>(
          value: _selectedProgram,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              'All Programs',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
          ),
          items: [
            DropdownMenuItem<TrainingProgramStatus?>(
              value: null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Text(
                  'All Programs',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ),
            ...TrainingProgramStatus.values.map((program) => DropdownMenuItem<TrainingProgramStatus?>(
              value: program,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Text(
                  _getProgramLabel(program),
                  style: AppTextStyles.bodySmall,
                ),
              ),
            )),
          ],
          onChanged: (value) {
            setState(() => _selectedProgram = value);
          },
          icon: Icon(
            Icons.arrow_drop_down,
            color: _selectedProgram != null 
                ? AppConstants.primaryColor 
                : AppConstants.textSecondary,
          ),
          style: AppTextStyles.bodySmall.copyWith(
            color: _selectedProgram != null 
                ? AppConstants.primaryColor 
                : AppConstants.textSecondary,
            fontWeight: _selectedProgram != null ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildNewUsersChip() {
    return FilterChip(
      label: const Text('New Users (7 days)'),
      selected: _showNewUsersOnly,
      onSelected: (selected) {
        setState(() => _showNewUsersOnly = selected);
      },
      selectedColor: AppConstants.successColor.withOpacity(0.12),
      checkmarkColor: AppConstants.successColor,
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: _showNewUsersOnly 
            ? AppConstants.successColor 
            : AppConstants.textSecondary,
        fontWeight: _showNewUsersOnly ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }


  String _getProgramLabel(TrainingProgramStatus status) {
    switch (status) {
      case TrainingProgramStatus.winter:
        return 'Winter Plan';
      case TrainingProgramStatus.summer:
        return 'Summer Plan';
      case TrainingProgramStatus.bodybuilding:
        return 'Body Building';
      case TrainingProgramStatus.none:
        return 'No Program';
    }
  }



  Widget _buildNameSortChip() {
    return FilterChip(
      label: const Text('Name A-Z'),
      selected: _sortByNameAZ,
      onSelected: (selected) {
        setState(() => _sortByNameAZ = selected);
      },
      selectedColor: AppConstants.copperwoodColor.withOpacity(0.12),
      checkmarkColor: AppConstants.copperwoodColor,
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: _sortByNameAZ 
            ? AppConstants.copperwoodColor
            : AppConstants.textSecondary,
        fontWeight: _sortByNameAZ ? FontWeight.w600 : FontWeight.normal,
      ),
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
                  child: Icon(
                    Icons.person,
                    color: AppConstants.textTertiary.withOpacity(0.3),
                    size: 24,
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

  Color _trainingProgramColor(TrainingProgramStatus status) {
    switch (status) {
      case TrainingProgramStatus.bodybuilding:
        return AppConstants.successColor;
      case TrainingProgramStatus.summer:
        return AppConstants.secondaryColor;
      case TrainingProgramStatus.winter:
        return AppConstants.primaryColor;
      case TrainingProgramStatus.none:
      default:
        return AppConstants.textTertiary;
    }
  }

  String _trainingProgramLabel(TrainingProgramStatus status) {
    switch (status) {
      case TrainingProgramStatus.bodybuilding:
        return 'Body Building';
      case TrainingProgramStatus.summer:
        return 'Summer Plan';
      case TrainingProgramStatus.winter:
        return 'Winter Plan';
      case TrainingProgramStatus.none:
      default:
        return 'No Program';
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
              AvatarUtils.buildAvatar(
                photoUrl: user.photoUrl,
                name: user.name,
                email: user.email,
                radius: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name ?? user.email,
                      style: AppTextStyles.heading5
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: AppTextStyles.caption
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
                            color: _trainingProgramColor(user.trainingProgramStatus)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _trainingProgramLabel(user.trainingProgramStatus),
                            style: AppTextStyles.caption.copyWith(
                              color:
                                  _trainingProgramColor(user.trainingProgramStatus),
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
