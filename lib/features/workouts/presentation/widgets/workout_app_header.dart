import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/profile_photo_provider.dart';
import '../../../../shared/providers/workout_provider.dart';
import '../../../../shared/utils/avatar_utils.dart';

class WorkoutAppHeader extends StatelessWidget {
  final String message;

  const WorkoutAppHeader({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppConstants.surfaceColor,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        child: _buildUserProfileIcon(context),
      ),
      actions: [
        Consumer<WorkoutProvider>(
          builder: (context, workoutProvider, child) {
            if (workoutProvider.isEditMode) {
              return const SizedBox.shrink();
            }
            return IconButton(
              onPressed: () {
                workoutProvider.enterEditMode();
              },
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Schedule',
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppConstants.surfaceColor,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spacingM,
              AppConstants.spacingXL,
              AppConstants.spacingM,
              AppConstants.spacingM,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getUserName(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final name = authProvider.userModel?.name;
    if (name != null && name.isNotEmpty) {
      return name.split(' ').first;
    }
    return 'there';
  }

  Widget _buildUserProfileIcon(BuildContext context) {
    return Consumer<ProfilePhotoProvider>(
      builder: (context, profilePhotoProvider, child) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.userModel;

        if (profilePhotoProvider.hasProfilePhoto) {
          final profileImage = profilePhotoProvider.getProfilePhotoImage();
          if (profileImage != null) {
            return CircleAvatar(
              radius: 24,
              backgroundImage: profileImage,
            );
          }
        }

        if (user != null) {
          return AvatarUtils.buildAvatar(
            photoUrl: user.photoUrl,
            name: user.name,
            email: user.email,
            radius: 24,
            fontSize: 12,
          );
        }

        return _buildDefaultAvatar();
      },
    );
  }

  Widget _buildDefaultAvatar() {
    return const Center(
      child: Icon(
        Icons.person,
        color: AppConstants.primaryColor,
        size: 24,
      ),
    );
  }
}
