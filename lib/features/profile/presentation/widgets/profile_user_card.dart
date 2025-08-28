import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:logger/logger.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/auth_provider.dart' as app_auth;
import '../../../../shared/providers/profile_photo_provider.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/utils/avatar_utils.dart';

class ProfileUserCard extends StatelessWidget {
  final UserModel user;
  final firebase_auth.User authUser;
  final app_auth.AuthProvider authProvider;

  const ProfileUserCard({
    super.key,
    required this.user,
    required this.authUser,
    required this.authProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfilePhotoProvider>(
      builder: (context, profilePhotoProvider, child) {
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Stack(
                  children: [
                    profilePhotoProvider.hasProfilePhoto
                        ? CircleAvatar(
                            radius: 38,
                            backgroundImage:
                                profilePhotoProvider.getProfilePhotoImage(),
                          )
                        : AvatarUtils.buildAvatar(
                            photoUrl: user.photoUrl,
                            name: user.name,
                            email: user.email,
                            radius: 38,
                            fontSize: 18,
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
                          child: const Icon(Icons.check,
                              size: 16, color: Colors.white),
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
                          if (user.subscriptionStatus ==
                              SubscriptionStatus.premium)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppConstants.primaryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Premium',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppConstants.primaryColor,
                                      fontWeight: FontWeight.bold)),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: AppConstants.textTertiary),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _showEditProfileDialog(
                                  context, user, authProvider);
                            },
                            tooltip: 'Edit profile',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: AppTextStyles.caption
                            .copyWith(color: AppConstants.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Role: ${user.role.name}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppConstants.textTertiary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Member since ${_formatDate(user.createdAt)}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppConstants.textTertiary),
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
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _showEditProfileDialog(BuildContext context, UserModel user,
      app_auth.AuthProvider authProvider) {
    final nameController = TextEditingController(text: user.name ?? '');
    final logger = Logger();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
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
                onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final newName = nameController.text.trim();
                        logger.d(
                            'Edit profile - New name: "$newName", Current name: "${user.name}"');

                        if (newName.isNotEmpty && newName != user.name) {
                          setState(() {
                            isLoading = true;
                          });

                          // Update user profile
                          final updatedUser = user.copyWith(
                            name: newName,
                            updatedAt: DateTime.now(),
                          );

                          logger.d(
                              'Edit profile - Updating user profile with new name: "$newName"');

                          try {
                            // Update the AuthProvider which will handle both Firebase and local storage
                            final success = await authProvider
                                .updateUserProfile(updatedUser);

                            logger.d('Edit profile - Update result: $success');

                            if (context.mounted) {
                              Navigator.of(context).pop();
                              // Profile update handled silently - the UI will reflect the changes automatically
                            }
                          } catch (e) {
                            logger
                                .e('Edit profile - Error updating profile: $e');
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              // Error handled silently - user can try again if needed
                            }
                          }
                        } else {
                          logger.d(
                              'Edit profile - No changes or empty name, closing dialog');
                          Navigator.of(context).pop();
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
