import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              final user = userProvider.user;
              if (user == null) {
                return const Text('No user profile found. Please complete onboarding.');
              }
              return SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _ProfileCard(user: user),
                    const SizedBox(height: AppConstants.spacingL),
                    _StatSection(user: user),
                    const SizedBox(height: AppConstants.spacingL),
                    _FitnessSection(user: user),
                    const SizedBox(height: AppConstants.spacingL),
                    _DietarySection(user: user),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final UserModel user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return Container(
      width: 360,
      padding: const EdgeInsets.symmetric(
        vertical: AppConstants.spacingXL,
        horizontal: AppConstants.spacingL,
      ),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.06),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                  if (picked != null) {
                    final updated = user.copyWith(photoUrl: picked.path);
                    await userProvider.setUser(updated);
                  }
                },
                child: CircleAvatar(
                  radius: 54,
                  backgroundColor: AppConstants.backgroundColor,
                  backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                      ? (user.photoUrl!.startsWith('http')
                          ? NetworkImage(user.photoUrl!)
                          : FileImage(File(user.photoUrl!)) as ImageProvider)
                      : null,
                  child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 54, color: AppConstants.primaryColor)
                      : null,
                ),
              ),
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppConstants.accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.accentColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),
          Text(
            user.name ?? 'No Name',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingXS),
          _SubscriptionChip(status: user.subscriptionStatus),
        ],
      ),
    );
  }
}

class _SubscriptionChip extends StatelessWidget {
  final SubscriptionStatus status;
  const _SubscriptionChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case SubscriptionStatus.free:
        color = AppConstants.textTertiary;
        label = 'Free';
        break;
      case SubscriptionStatus.basic:
        color = AppConstants.secondaryColor;
        label = 'Basic';
        break;
      case SubscriptionStatus.premium:
        color = AppConstants.accentColor;
        label = 'Premium';
        break;
      case SubscriptionStatus.cancelled:
        color = AppConstants.errorColor;
        label = 'Cancelled';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatSection extends StatelessWidget {
  final UserModel user;
  const _StatSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final prefs = user.preferences;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatCard(
          icon: Icons.monitor_weight,
          label: 'Weight',
          value: '${prefs.weight.toStringAsFixed(1)} kg',
        ),
        const SizedBox(height: AppConstants.spacingM),
        _StatCard(
          icon: Icons.height,
          label: 'Height',
          value: '${prefs.height.toStringAsFixed(0)} cm',
        ),
        const SizedBox(height: AppConstants.spacingM),
        _StatCard(
          icon: Icons.cake,
          label: 'Age',
          value: '${prefs.age} yrs',
        ),
        const SizedBox(height: AppConstants.spacingM),
        _StatCard(
          icon: Icons.person,
          label: 'Gender',
          value: prefs.gender,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: AppConstants.spacingL),
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: AppConstants.shadowS,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppConstants.primaryColor, size: 24),
          const SizedBox(width: AppConstants.spacingM),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(color: AppConstants.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FitnessSection extends StatelessWidget {
  final UserModel user;
  const _FitnessSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final prefs = user.preferences;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoCard(
          icon: Icons.track_changes,
          label: 'Goal',
          value: _goalLabel(prefs.fitnessGoal),
        ),
        const SizedBox(height: AppConstants.spacingM),
        _InfoCard(
          icon: Icons.local_fire_department,
          label: 'Calories',
          value: '${prefs.targetCalories} kcal/day',
        ),
        const SizedBox(height: AppConstants.spacingM),
        _InfoCard(
          icon: Icons.directions_run,
          label: 'Activity',
          value: _activityLabel(prefs.activityLevel),
        ),
      ],
    );
  }

  String _goalLabel(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return 'Weight Loss';
      case FitnessGoal.muscleGain:
        return 'Muscle Gain';
      case FitnessGoal.maintenance:
        return 'Maintenance';
      case FitnessGoal.endurance:
        return 'Endurance';
      case FitnessGoal.strength:
        return 'Strength';
    }
  }

  String _activityLabel(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
      case ActivityLevel.extremelyActive:
        return 'Extremely Active';
    }
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: AppConstants.spacingL),
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: AppConstants.shadowS,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppConstants.primaryColor, size: 24),
          const SizedBox(width: AppConstants.spacingM),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(color: AppConstants.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DietarySection extends StatelessWidget {
  final UserModel user;
  const _DietarySection({required this.user});

  @override
  Widget build(BuildContext context) {
    final restrictions = user.preferences.dietaryRestrictions;
    if (restrictions.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: AppConstants.shadowS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dietary Restrictions',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Wrap(
            spacing: AppConstants.spacingS,
            runSpacing: AppConstants.spacingXS,
            children: restrictions.map((r) => _DietChip(label: r)).toList(),
          ),
        ],
      ),
    );
  }
}

class _DietChip extends StatelessWidget {
  final String label;
  const _DietChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppConstants.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
} 