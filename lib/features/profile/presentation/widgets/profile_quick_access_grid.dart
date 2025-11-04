import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_constants.dart';

class ProfileQuickAccessGrid extends StatelessWidget {
  final List<QuickAccessItem> items;

  const ProfileQuickAccessGrid({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: items
          .map((item) => QuickAccessTile(item: item))
          .toList(growable: false),
    );
  }
}

class QuickAccessTile extends StatelessWidget {
  final QuickAccessItem item;

  const QuickAccessTile({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final Widget? trailing = item.trailing ??
        (item.badge != null
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.badge!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: SvgPicture.asset("assets/images/${item.icon}",
            color: Colors.black, height: 16),
        title: Text(
          item.label,
          style: AppTextStyles.bodyMedium,
        ),
        trailing: trailing,
        onTap: item.onTap,
      ),
    );
  }
}

class QuickAccessItem {
  final String label;
  final String icon;
  final String? badge;
  final VoidCallback? onTap;
  final Widget? trailing;

  const QuickAccessItem({
    required this.label,
    required this.icon,
    this.badge,
    this.onTap,
    this.trailing,
  });
}
