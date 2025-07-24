import 'package:flutter/material.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';

class AdminHomeScreen extends StatelessWidget {
  final String adminName;
  const AdminHomeScreen({Key? key, this.adminName = 'Moctar'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome back, $adminName!', style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            Text('This is your admin dashboard.', style: AppTextStyles.bodyMedium.copyWith(color: AppConstants.textSecondary)),
            const SizedBox(height: 32),
            // TODO: Add admin dashboard widgets here
          ],
        ),
      ),
    );
  }
} 