import 'package:flutter/material.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';

class AdminHomeScreen extends StatelessWidget {
  final String adminName;
  const AdminHomeScreen({Key? key, this.adminName = 'Moctar'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy data for now
    final metrics = [
      _MetricCardData('Clients', '42', Icons.group, AppConstants.primaryColor),
      _MetricCardData('Active Subs', '30', Icons.workspace_premium, AppConstants.accentColor),
      _MetricCardData('Total Sales', ' 2,500', Icons.attach_money, AppConstants.successColor),
      _MetricCardData('Monthly Sales', ' 800', Icons.trending_up, AppConstants.warningColor),
      _MetricCardData('Pending Check-ins', '5', Icons.pending_actions, AppConstants.secondaryColor),
    ];
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back, $adminName!', style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              Text('This is your admin dashboard.', style: AppTextStyles.bodyMedium.copyWith(color: AppConstants.textSecondary)),
              const SizedBox(height: 28),
              // Metrics grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: metrics.map((m) => _MetricCard(m)).toList(),
              ),
              const SizedBox(height: 32),
              // TODO: Add more admin dashboard widgets here
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _MetricCardData(this.label, this.value, this.icon, this.color);
}

class _MetricCard extends StatelessWidget {
  final _MetricCardData data;
  const _MetricCard(this.data);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(data.icon, color: data.color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(data.value, style: AppTextStyles.heading4.copyWith(color: data.color, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(data.label, style: AppTextStyles.caption.copyWith(color: AppConstants.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 