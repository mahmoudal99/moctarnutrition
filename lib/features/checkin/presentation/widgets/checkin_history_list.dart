import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/checkin_model.dart';
import 'checkin_history_item.dart';

class CheckinHistoryList extends StatelessWidget {
  final List<CheckinModel> checkins;
  final Function(CheckinModel) onCheckinTap;
  final bool showLoadMore;
  final VoidCallback? onLoadMore;

  const CheckinHistoryList({
    super.key,
    required this.checkins,
    required this.onCheckinTap,
    this.showLoadMore = false,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (checkins.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        ...checkins.map((checkin) => CheckinHistoryItem(
              checkin: checkin,
              onTap: () => onCheckinTap(checkin),
            )),
        if (showLoadMore && onLoadMore != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onLoadMore,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppConstants.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Load More',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
