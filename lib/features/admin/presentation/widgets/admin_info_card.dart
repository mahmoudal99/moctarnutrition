import 'package:flutter/material.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';

class AdminInfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const AdminInfoCard({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.heading5,
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class AdminInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;

  const AdminInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: valueColor ?? Colors.grey[800],
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.end,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.share,
                    size: 16,
                    color: valueColor ?? Colors.grey[600],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
