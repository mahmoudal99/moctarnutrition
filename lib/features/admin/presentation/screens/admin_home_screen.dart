import 'package:flutter/material.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminHomeScreen extends StatelessWidget {
  final String adminName;

  const AdminHomeScreen({Key? key, this.adminName = 'Moctar'})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricCardData('Clients', '42', Icons.group, AppConstants.primaryColor),
      _MetricCardData('Active Subs', '30', Icons.workspace_premium,
          AppConstants.accentColor),
      _MetricCardData('Pending Check-ins', '5', Icons.pending_actions,
          AppConstants.secondaryColor),
    ];
    final now = TimeOfDay.now();
    final lastUpdated = 'Last Updated ${now.format(context)}';
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
              // Text('This is your admin dashboard.',
              //     style: AppTextStyles.bodyMedium
              //         .copyWith(color: AppConstants.textSecondary)),
              const SizedBox(height: 15),
              // Sales Card
              _SalesCard(lastUpdated: lastUpdated),
              const SizedBox(height: 18),
              _StatisticsCard(stats: [
                _SalesStat('Earnings', '€12,235.99', '+20.46%', true),
                _SalesStat('Sales', '€31,890.00', '-3.46%', false),
                _SalesStat('Product Views', ' 129,781', '+8.30%', true),
              ]),
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
              const SizedBox(height: 96),
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
                  Text(data.value,
                      style: AppTextStyles.heading4.copyWith(
                          color: data.color, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(data.label,
                      style: AppTextStyles.caption
                          .copyWith(color: AppConstants.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesCard extends StatelessWidget {
  final String lastUpdated;

  const _SalesCard({required this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    // Dummy data
    final totalBalance = '€25,640.00';
    final stats = [
      _SalesStat('Total Earnings', '€12,235.99', '+20.46%', true),
      _SalesStat('Number of Sales', '€31,890.00', '-3.46%', false),
      _SalesStat('Product Views', ' 129,781', '+8.30%', true),
    ];
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: const Color(0xFF23272F),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total balance',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Colors.white70)),
                Text(totalBalance,
                    style: AppTextStyles.heading2.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            Text(lastUpdated,
                style: AppTextStyles.caption.copyWith(color: Colors.white54)),
            const SizedBox(height: 16),
            // Placeholder for line chart
            Container(
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 10,
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        FlSpot(0, 1),
                        FlSpot(1, 7.5),
                        FlSpot(2, 2),
                        FlSpot(3, 8),
                        FlSpot(4, 6.5),
                        FlSpot(5, 9),
                        FlSpot(6, 1),
                      ],
                      isCurved: true,
                      color: const Color(0xFF4F8DFD),
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Stats row moved to separate widget below
          ],
        ),
      ),
    );
  }
}

class _SalesStat {
  final String label;
  final String value;
  final String percent;
  final bool isUp;

  _SalesStat(this.label, this.value, this.percent, this.isUp);
}

class _SalesStatWidget extends StatelessWidget {
  final _SalesStat stat;

  const _SalesStatWidget(this.stat);

  @override
  Widget build(BuildContext context) {
    final color =
        stat.isUp ? AppConstants.successColor : AppConstants.errorColor;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          stat.label,
          style:
              AppTextStyles.caption.copyWith(color: AppConstants.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 5),
        Text(
          stat.value,
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(stat.isUp ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14, color: color),
            const SizedBox(width: 2),
            Text(
              stat.percent,
              style: AppTextStyles.caption
                  .copyWith(color: color, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatisticsCard extends StatelessWidget {
  final List<_SalesStat> stats;

  const _StatisticsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      margin: const EdgeInsets.only(top: 18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Statistics',
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.bold)),
                // Placeholder for filter dropdown
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text('This Month',
                          style: AppTextStyles.caption
                              .copyWith(color: AppConstants.textSecondary)),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: AppConstants.textSecondary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 80,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _SalesStatWidget(stats[0])),
                  _verticalDivider(),
                  Expanded(child: _SalesStatWidget(stats[1])),
                  _verticalDivider(),
                  Expanded(child: _SalesStatWidget(stats[2])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _verticalDivider() {
  return Align(
    alignment: Alignment.center,
    child: Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppConstants.textTertiary.withOpacity(0.15),
    ),
  );
}
