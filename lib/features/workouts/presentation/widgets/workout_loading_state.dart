import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/profile_photo_provider.dart';
import '../../../../shared/utils/avatar_utils.dart';

class WorkoutLoadingState extends StatelessWidget {
  const WorkoutLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: AppConstants.surfaceColor,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              child: _buildUserProfileIcon(context),
            ),
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
                        'Hi ${_getUserName(context)}!',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppConstants.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingXS),
                      Text(
                        'Loading your workout plan...',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                children: [
                  const SizedBox(height: AppConstants.spacingXL),
                  _buildLoadingSpinner(),
                  const SizedBox(height: AppConstants.spacingXL),
                  _buildLoadingMessage(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSpinner() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: AppConstants.shadowS,
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppConstants.primaryColor,
            strokeWidth: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Column(
      children: [
        Text(
          'Loading Workout Plan',
          style: AppTextStyles.heading4.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingM),
        Text(
          'Please wait while we load your personalized workout plan.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppConstants.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
