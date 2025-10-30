import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class ProfileQuickAccessGrid extends StatelessWidget {
  final List<QuickAccessItem> items;

  const ProfileQuickAccessGrid({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 5,
      children: items.map((item) => QuickAccessTile(item: item)).toList(),
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(item.icon, color: AppConstants.primaryColor, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.label,
                      style: AppTextStyles.bodySmall
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickAccessItem {
  final String label;
  final IconData icon;
  final String? badge;
  final VoidCallback? onTap;

  const QuickAccessItem({
    required this.label,
    required this.icon,
    this.badge,
    this.onTap,
  });
}
