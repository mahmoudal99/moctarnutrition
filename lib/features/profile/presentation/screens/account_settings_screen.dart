import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/auth_provider.dart' as app_auth;
import '../../../../shared/providers/profile_photo_provider.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/utils/avatar_utils.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  @override
  void initState() {
    super.initState();
    _initializeProfilePhoto();
  }

  Future<void> _initializeProfilePhoto() async {
    final user = context.read<app_auth.AuthProvider>().userModel;
    if (user != null) {
      final profilePhotoProvider = context.read<ProfilePhotoProvider>();
      await profilePhotoProvider.initialize(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppConstants.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<app_auth.AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.userModel;
          final authUser = authProvider.firebaseUser;

          if (user == null || authUser == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _PersonalInfoSection(
                user: user,
                authUser: authUser,
              ),
              const SizedBox(height: 24),
              _SubscriptionSection(user: user),
              const SizedBox(height: 24),
              _AccountDetailsSection(user: user, authUser: authUser),
              const SizedBox(height: 24),
              _SecuritySection(authUser: authUser),
              const SizedBox(height: 24),
              _DangerZoneSection(),
              const SizedBox(height: 128),
            ],
          );
        },
      ),
    );
  }
}

class _PersonalInfoSection extends StatelessWidget {
  final UserModel user;
  final firebase_auth.User authUser;

  const _PersonalInfoSection({
    required this.user,
    required this.authUser,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfilePhotoProvider>(
      builder: (context, profilePhotoProvider, child) {
        return _SettingsSection(
          title: 'Personal Information',
          icon: Icons.person,
          children: [
            _InfoCard(
              title: 'Profile Photo',
              subtitle: 'Tap to change your profile picture',
              leading: profilePhotoProvider.hasProfilePhoto
                  ? CircleAvatar(
                      radius: 24,
                      backgroundImage:
                          profilePhotoProvider.getProfilePhotoImage(),
                    )
                  : AvatarUtils.buildAvatar(
                      photoUrl: user.photoUrl,
                      name: user.name,
                      email: user.email,
                      radius: 24,
                      fontSize: 14,
                    ),
              onTap: () =>
                  _showChangePhotoDialog(context, profilePhotoProvider),
            ),
            _InfoCard(
              title: 'Full Name',
              subtitle: user.name ?? 'Not set',
              trailing:
                  const Icon(Icons.edit, color: AppConstants.textTertiary),
              onTap: () => _showEditNameDialog(context, user),
            ),
            _InfoCard(
              title: 'Email',
              subtitle: user.email,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppConstants.successColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Verified',
                  style: AppTextStyles.caption.copyWith(
                    color: AppConstants.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _InfoCard(
              title: 'Age',
              subtitle: '${user.preferences.age} years old',
              onTap: () => _showEditAgeDialog(context, user),
            ),
            _InfoCard(
              title: 'Gender',
              subtitle: user.preferences.gender,
              onTap: () => _showEditGenderDialog(context, user),
            ),
          ],
        );
      },
    );
  }

  void _showChangePhotoDialog(
      BuildContext context, ProfilePhotoProvider profilePhotoProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Profile Photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(context, ImageSource.camera, profilePhotoProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(context, ImageSource.gallery, profilePhotoProvider);
              },
            ),
            if (profilePhotoProvider.hasProfilePhoto || user.photoUrl != null)
              ListTile(
                leading:
                    const Icon(Icons.delete, color: AppConstants.errorColor),
                title: const Text('Remove Photo',
                    style: TextStyle(color: AppConstants.errorColor)),
                onTap: () {
                  Navigator.of(context).pop();
                  profilePhotoProvider.removeProfilePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source,
      ProfilePhotoProvider profilePhotoProvider) async {
    try {
      Logger().d('Starting image picker for source: $source');

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      Logger().d('Image picker result: ${image?.path}');

      if (image != null) {
        Logger().d('Image selected, processing...');
        await profilePhotoProvider.updateProfilePhoto(image.path);
      } else {
        Logger().d('No image selected');
      }
    } catch (e) {
      Logger().e('Error in _pickImage: $e');
    }
  }

  void _showEditNameDialog(BuildContext context, UserModel user) {
    final nameController = TextEditingController(text: user.name ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your full name',
          ),
          textCapitalization: TextCapitalization.words,
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
                // TODO: Implement name update
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }


  void _showEditAgeDialog(BuildContext context, UserModel user) {
    final ageController =
        TextEditingController(text: user.preferences.age.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Age'),
        content: TextField(
          controller: ageController,
          decoration: const InputDecoration(
            labelText: 'Age',
            hintText: 'Enter your age',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newAge = int.tryParse(ageController.text);
              if (newAge != null &&
                  newAge > 0 &&
                  newAge != user.preferences.age) {
                // TODO: Implement age update
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditGenderDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Gender'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Male'),
              onTap: () {
                // TODO: Implement gender update
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('Female'),
              onTap: () {
                // TODO: Implement gender update
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('Other'),
              onTap: () {
                // TODO: Implement gender update
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionSection extends StatelessWidget {
  final UserModel user;

  const _SubscriptionSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final trainingProgramStatus = user.trainingProgramStatus;
    final isBodybuilding = trainingProgramStatus == TrainingProgramStatus.bodybuilding;
    final isSummer = trainingProgramStatus == TrainingProgramStatus.summer;
    final isWinter = trainingProgramStatus == TrainingProgramStatus.winter;
    final hasNoProgram = trainingProgramStatus == TrainingProgramStatus.none;

    return _SettingsSection(
      title: 'Subscription',
      icon: Icons.card_membership,
      children: [
        _InfoCard(
          title: 'Current Plan',
          subtitle: _getTrainingProgramName(trainingProgramStatus),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  _getTrainingProgramColor(trainingProgramStatus).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getTrainingProgramIcon(trainingProgramStatus),
              color: _getTrainingProgramColor(trainingProgramStatus),
              size: 20,
            ),
          ),
          trailing: hasNoProgram
              ? ElevatedButton(
                  onPressed: () => _upgradeSubscription(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 32),
                  ),
                  child: const Text('Upgrade'),
                )
              : null,
        ),
        if (!hasNoProgram) ...[
          const _InfoCard(
            title: 'Billing Cycle',
            subtitle: 'Monthly', // TODO: Get from subscription data
          ),
          _InfoCard(
            title: 'Next Billing Date',
            subtitle: user.programPurchaseDate != null
                ? _formatDate(user.programPurchaseDate!)
                : 'Not available',
          ),
          _InfoCard(
            title: 'Payment Method',
            subtitle: '•••• •••• •••• 4242', // TODO: Get from Stripe
            trailing: const Icon(Icons.edit, color: AppConstants.textTertiary),
            onTap: () => _managePaymentMethod(context),
          ),
        ],
        _InfoCard(
          title: 'Subscription Management',
          subtitle: hasNoProgram
              ? 'Upgrade to access premium features'
              : 'Manage your subscription',
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _manageSubscription(context),
        ),
      ],
    );
  }

  String _getTrainingProgramName(TrainingProgramStatus status) {
    switch (status) {
      case TrainingProgramStatus.winter:
        return 'Winter Plan';
      case TrainingProgramStatus.summer:
        return 'Summer Plan';
      case TrainingProgramStatus.bodybuilding:
        return 'Body Building';
      case TrainingProgramStatus.none:
      default:
        return 'No Program';
    }
  }

  Color _getTrainingProgramColor(TrainingProgramStatus status) {
    switch (status) {
      case TrainingProgramStatus.winter:
        return AppConstants.primaryColor;
      case TrainingProgramStatus.summer:
        return AppConstants.secondaryColor;
      case TrainingProgramStatus.bodybuilding:
        return AppConstants.accentColor;
      case TrainingProgramStatus.none:
      default:
        return AppConstants.textTertiary;
    }
  }

  IconData _getTrainingProgramIcon(TrainingProgramStatus status) {
    switch (status) {
      case TrainingProgramStatus.winter:
        return Icons.ac_unit;
      case TrainingProgramStatus.summer:
        return Icons.star;
      case TrainingProgramStatus.bodybuilding:
        return Icons.diamond;
      case TrainingProgramStatus.none:
      default:
        return Icons.cancel;
    }
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _upgradeSubscription(BuildContext context) {
    // TODO: Navigate to subscription screen
    context.push('/subscription');
  }

  void _managePaymentMethod(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Methods'),
        content: const Text(
            'Payment method management will be available when Stripe integration is complete.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _manageSubscription(BuildContext context) {
    // TODO: Navigate to subscription management
    context.push('/subscription');
  }
}

class _AccountDetailsSection extends StatelessWidget {
  final UserModel user;
  final firebase_auth.User authUser;

  const _AccountDetailsSection({
    required this.user,
    required this.authUser,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'Account Details',
      icon: Icons.account_circle,
      children: [
        _InfoCard(
          title: 'User ID',
          subtitle: user.id,
          trailing: IconButton(
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: user.id));
            },
          ),
        ),
        _InfoCard(
          title: 'Account Type',
          subtitle: _getRoleDisplayName(user.role),
        ),
        _InfoCard(
          title: 'Member Since',
          subtitle: _formatDate(user.createdAt),
        ),
        _InfoCard(
          title: 'Last Updated',
          subtitle: _formatDate(user.updatedAt),
        ),
        if (user.selectedTrainerId != null)
          _InfoCard(
            title: 'Assigned Trainer',
            subtitle: 'Trainer ID: ${user.selectedTrainerId}',
            onTap: () => _viewTrainerDetails(context),
          ),
      ],
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.user:
        return 'Regular User';
      case UserRole.trainer:
        return 'Trainer';
      case UserRole.admin:
        return 'Administrator';
    }
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _viewTrainerDetails(BuildContext context) {
    // TODO: Navigate to trainer details
  }
}

class _SecuritySection extends StatelessWidget {
  final firebase_auth.User authUser;

  const _SecuritySection({required this.authUser});

  @override
  Widget build(BuildContext context) {
    // Check if user signed in with email/password
    final isEmailProvider = authUser.providerData.any(
      (userInfo) => userInfo.providerId == 'password',
    );

    return _SettingsSection(
      title: 'Security',
      icon: Icons.security,
      children: [
        if (isEmailProvider)
          _InfoCard(
            title: 'Change Password',
            subtitle: 'Update your account password',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _changePassword(context),
          ),
        _InfoCard(
          title: 'Login Sessions',
          subtitle: 'Manage active sessions',
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _manageSessions(context),
        ),
      ],
    );
  }

  void _changePassword(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ChangePasswordDialog(),
    );
  }

  void _manageSessions(BuildContext context) {
    // TODO: Implement session management
  }
}

class _DangerZoneSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'Account Deletion',
      icon: Icons.warning,
      children: [
        _InfoCard(
          title: 'Delete Account',
          subtitle: 'Permanently delete your account and all data',
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.errorColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.delete_forever,
              color: AppConstants.errorColor,
              size: 20,
            ),
          ),
          onTap: () => _showDeleteAccountDialog(context),
        ),
      ],
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete your account?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'This action cannot be undone. All your data including:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '• Profile information\n• Workout plans\n• Progress data\n• Meal preferences\n• Check-in history',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 12),
            Text(
              'will be permanently deleted.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _handleDeleteAccount(context);
            },
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount(BuildContext context) async {
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);

    try {
      final success = await authProvider.deleteAccount();

      if (success && context.mounted) {
        context.go('/get-started');
      }
    } catch (e) {
      // Handle error silently or log it
      Logger().e('Error deleting account: $e');
    }
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppConstants.textSecondary, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _InfoCard({
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(title, style: AppTextStyles.bodyMedium),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrentPassword,
              decoration: InputDecoration(
                labelText: 'Current Password',
                hintText: 'Enter your current password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrentPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureCurrentPassword = !_obscureCurrentPassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your current password';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                labelText: 'New Password',
                hintText: 'Enter your new password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a new password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                hintText: 'Confirm your new password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your new password';
                }
                if (value != _newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleChangePassword,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Change Password'),
        ),
      ],
    );
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      final success = await authProvider.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pop();
        _showSuccessDialog();
      } else if (mounted) {
        _showErrorDialog(authProvider.error ?? 'Failed to change password');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Your password has been changed successfully.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
