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
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLoadingMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Column(
      children: [
        Text(
          'Loading your workout plan...',
          style: AppTextStyles.heading5.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
