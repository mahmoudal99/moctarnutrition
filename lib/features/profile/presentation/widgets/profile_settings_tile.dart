import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_constants.dart';

class ProfileSettingsTile extends StatelessWidget {
  final SettingsItem item;

  const ProfileSettingsTile({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: SvgPicture.asset(
          "assets/images/${item.icon}",
          color: Colors.black,
          height: 16,
        ),
        title: Text(item.label, style: AppTextStyles.bodyMedium),
        trailing: item.trailing,
        onTap: item.onTap,
      ),
    );
  }
}

class SettingsItem {
  final String label;
  final String icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsItem({
    required this.label,
    required this.icon,
    this.trailing,
    this.onTap,
  });
}
