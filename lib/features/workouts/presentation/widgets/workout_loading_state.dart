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
                        'Preparing your workout plan...',
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
                  _buildLoadingSpinner(),
                  const SizedBox(height: AppConstants.spacingXL),
                  _buildLoadingTitle(),
                  const SizedBox(height: AppConstants.spacingM),
                  _buildLoadingDescription(),
                  const SizedBox(height: AppConstants.spacingXL),
                  _buildLoadingSteps(),
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
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: AppConstants.shadowM,
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppConstants.primaryColor,
            strokeWidth: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingTitle() {
    return Text(
      'Creating Your Perfect Workout',
      style: AppTextStyles.heading4.copyWith(
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLoadingDescription() {
    return Text(
      'We\'re analyzing your preferences and fitness goals to create a personalized workout plan just for you.',
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppConstants.textSecondary,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLoadingSteps() {
    return Column(
      children: [
        _buildLoadingStep(
          'Analyzing your fitness goals',
          Icons.track_changes,
          true,
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildLoadingStep(
          'Designing workout routines',
          Icons.fitness_center,
          true,
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildLoadingStep(
          'Optimizing for your schedule',
          Icons.schedule,
          false,
        ),
      ],
    );
  }

  Widget _buildLoadingStep(String text, IconData icon, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: isCompleted
              ? AppConstants.primaryColor.withOpacity(0.3)
              : AppConstants.textTertiary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppConstants.primaryColor
                  : AppConstants.textTertiary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
            ),
            child: Icon(
              icon,
              color: isCompleted
                  ? AppConstants.surfaceColor
                  : AppConstants.textTertiary,
              size: 16,
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isCompleted
                    ? AppConstants.textPrimary
                    : AppConstants.textSecondary,
                fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (isCompleted)
            const Icon(
              Icons.check_circle,
              color: AppConstants.primaryColor,
              size: 20,
            ),
        ],
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