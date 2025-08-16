import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class ProfileSettingsTile extends StatelessWidget {
  final SettingsItem item;

  const ProfileSettingsTile({
    super.key,
    required this.item,
  });

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

class SettingsItem {
  final String label;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsItem({
    required this.label,
    required this.icon,
    this.trailing,
    this.onTap,
  });
} 