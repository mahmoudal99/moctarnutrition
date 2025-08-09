import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/services/progress_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Future<ProgressSummary>? _progressSummaryFuture;
  Future<List<WeightDataPoint>>? _weightDataFuture;
  Future<List<MoodDataPoint>>? _moodDataFuture;
  Future<List<String>>? _measurementTypesFuture;
  Map<String, Future<List<MeasurementDataPoint>>> _measurementDataFutures = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userModel?.id;

    if (userId != null) {
      setState(() {
        _progressSummaryFuture = ProgressService.getProgressSummary(userId);
        _weightDataFuture = ProgressService.getWeightProgress(userId);
        _moodDataFuture = ProgressService.getMoodProgress(userId);
        _measurementTypesFuture =
            ProgressService.getUserMeasurementTypes(userId);
      });

      // Load measurement data for each type
      _measurementTypesFuture?.then((types) {
        final futures = <String, Future<List<MeasurementDataPoint>>>{};
        for (final type in types) {
          futures[type] = ProgressService.getMeasurementProgress(userId, type);
        }
        setState(() {
          _measurementDataFutures = futures;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Progress Tracking'),
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_outlined),
          onPressed: () => context.go('/profile'),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppConstants.primaryColor,
          unselectedLabelColor: AppConstants.textSecondary,
          indicatorColor: AppConstants.primaryColor,
          tabs: const [
            Tab(text: 'Weight'),
            Tab(text: 'Mood'),
            Tab(text: 'Measurements'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Progress Summary Card
          FutureBuilder<ProgressSummary>(
            future: _progressSummaryFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return _ProgressSummaryCard(summary: snapshot.data!);
              }
              return const SizedBox.shrink();
            },
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _WeightTab(dataFuture: _weightDataFuture),
                _MoodTab(dataFuture: _moodDataFuture),
                _MeasurementsTab(
                  typesFuture: _measurementTypesFuture,
                  dataFutures: _measurementDataFutures,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSummaryCard extends StatelessWidget {
  final ProgressSummary summary;

  const _ProgressSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary.totalCheckins == 0) {
      return Container(
        margin: const EdgeInsets.all(16),
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
          children: [
            const Icon(
              Icons.trending_up,
              size: 48,
              color: AppConstants.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'No Progress Data Yet',
              style: AppTextStyles.heading4.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your first check-in to start tracking your progress!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppConstants.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Check-ins',
                  value: '${summary.totalCheckins}',
                  icon: Icons.assignment_turned_in,
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Weeks Tracked',
                  value: '${summary.trackingWeeks}',
                  icon: Icons.calendar_month,
                ),
              ),
              if (summary.weightStats?.hasProgress == true)
                Expanded(
                  child: _SummaryItem(
                    label: 'Weight Change',
                    value: summary.weightStats!.changeText,
                    icon: Icons.monitor_weight,
                    valueColor: summary.weightStats!.change >= 0
                        ? AppConstants.successColor
                        : AppConstants.errorColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppConstants.primaryColor,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppConstants.textPrimary,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _WeightTab extends StatelessWidget {
  final Future<List<WeightDataPoint>>? dataFuture;

  const _WeightTab({this.dataFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WeightDataPoint>>(
      future: dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 24,
                  color: AppConstants.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading weight data',
                  style: AppTextStyles.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data ?? [];

        if (data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.monitor_weight,
                  size: 24,
                  color: AppConstants.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Weight Data',
                  style: AppTextStyles.heading4.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start logging your weight in check-ins to see progress!',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppConstants.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _WeightChart(data: data),
              const SizedBox(height: 20),
              _WeightDataList(data: data),
              const SizedBox(height: 128),
            ],
          ),
        );
      },
    );
  }
}

class _MoodTab extends StatelessWidget {
  final Future<List<MoodDataPoint>>? dataFuture;

  const _MoodTab({this.dataFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MoodDataPoint>>(
      future: dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 24,
                  color: AppConstants.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading mood data',
                  style: AppTextStyles.bodyLarge,
                ),
              ],
            ),
          );
        }

        final data = snapshot.data ?? [];

        if (data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mood,
                  size: 48,
                  color: AppConstants.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Mood Data',
                  style: AppTextStyles.heading4.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start logging your mood and energy levels to track wellness!',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppConstants.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _MoodChart(data: data),
              const SizedBox(height: 20),
              _MoodDataList(data: data),
              const SizedBox(height: 128),
            ],
          ),
        );
      },
    );
  }
}

class _MeasurementsTab extends StatelessWidget {
  final Future<List<String>>? typesFuture;
  final Map<String, Future<List<MeasurementDataPoint>>> dataFutures;

  const _MeasurementsTab({
    this.typesFuture,
    required this.dataFutures,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: typesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppConstants.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading measurements',
                  style: AppTextStyles.bodyLarge,
                ),
              ],
            ),
          );
        }

        final types = snapshot.data ?? [];

        if (types.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.straighten,
                  size: 24,
                  color: AppConstants.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Measurements',
                  style: AppTextStyles.heading4.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start logging body measurements in check-ins to track changes!',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppConstants.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: types.length,
          itemBuilder: (context, index) {
            final type = types[index];
            final dataFuture = dataFutures[type];

            return _MeasurementCard(
              measurementType: type,
              dataFuture: dataFuture,
            );
          },
        );
      },
    );
  }
}

class _WeightChart extends StatelessWidget {
  final List<WeightDataPoint> data;

  const _WeightChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) {
      return Container(
        height: 200,
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
        child: Center(
          child: Text(
            'Need at least 2 data points to show chart',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
        ),
      );
    }

    final spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();

    final minWeight = data.map((d) => d.weight).reduce((a, b) => a < b ? a : b);
    final maxWeight = data.map((d) => d.weight).reduce((a, b) => a > b ? a : b);
    final weightRange = maxWeight - minWeight;
    final padding = weightRange * 0.1;

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
            'Weight Progress',
            style: AppTextStyles.heading5,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: weightRange > 0 ? weightRange / 4 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppConstants.textTertiary.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}kg',
                          style: AppTextStyles.caption.copyWith(
                            color: AppConstants.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              data[index].weekRange,
                              style: AppTextStyles.caption.copyWith(
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: AppConstants.textTertiary.withOpacity(0.2),
                    ),
                    left: BorderSide(
                      color: AppConstants.textTertiary.withOpacity(0.2),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppConstants.primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppConstants.primaryColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppConstants.primaryColor.withOpacity(0.1),
                    ),
                  ),
                ],
                minY: weightRange > 0 ? minWeight - padding : minWeight - 1,
                maxY: weightRange > 0 ? maxWeight + padding : maxWeight + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodChart extends StatelessWidget {
  final List<MoodDataPoint> data;

  const _MoodChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final energyData = data.where((d) => d.energyLevel != null).toList();
    final motivationData =
        data.where((d) => d.motivationLevel != null).toList();

    if (energyData.isEmpty && motivationData.isEmpty) {
      return Container(
        height: 200,
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
        child: Center(
          child: Text(
            'No energy or motivation data available',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
        ),
      );
    }

    final energySpots = energyData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.energyLevel!.toDouble());
    }).toList();

    final motivationSpots = motivationData.asMap().entries.map((entry) {
      return FlSpot(
          entry.key.toDouble(), entry.value.motivationLevel!.toDouble());
    }).toList();

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mood & Energy Levels',
                style: AppTextStyles.heading4,
              ),
              if (energySpots.isNotEmpty || motivationSpots.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (energySpots.isNotEmpty) ...[
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Energy',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (motivationSpots.isNotEmpty) ...[
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppConstants.accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Motivation',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppConstants.textTertiary.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: AppTextStyles.caption.copyWith(
                            color: AppConstants.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              data[index].weekRange,
                              style: AppTextStyles.caption.copyWith(
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: AppConstants.textTertiary.withOpacity(0.2),
                    ),
                    left: BorderSide(
                      color: AppConstants.textTertiary.withOpacity(0.2),
                    ),
                  ),
                ),
                lineBarsData: [
                  if (energySpots.isNotEmpty)
                    LineChartBarData(
                      spots: energySpots,
                      isCurved: true,
                      color: AppConstants.primaryColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: AppConstants.primaryColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                    ),
                  if (motivationSpots.isNotEmpty)
                    LineChartBarData(
                      spots: motivationSpots,
                      isCurved: true,
                      color: AppConstants.accentColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: AppConstants.accentColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                    ),
                ],
                minY: 0,
                maxY: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightDataList extends StatelessWidget {
  final List<WeightDataPoint> data;

  const _WeightDataList({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Weight History',
              style: AppTextStyles.heading5,
            ),
          ),
          ...data.reversed.take(5).map((point) {
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.monitor_weight,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
              ),
              title: Text(
                '${point.weight.toStringAsFixed(1)} kg',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                point.weekRange,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
              trailing: Text(
                DateFormat('MMM d').format(point.date),
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.textTertiary,
                ),
              ),
            );
          }),
          if (data.length > 5)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Showing latest 5 entries',
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _MoodDataList extends StatelessWidget {
  final List<MoodDataPoint> data;

  const _MoodDataList({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Mood History',
              style: AppTextStyles.heading4,
            ),
          ),
          ...data.reversed.take(5).map((point) {
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppConstants.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.mood,
                  color: AppConstants.accentColor,
                  size: 20,
                ),
              ),
              title: Text(
                point.mood,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    point.weekRange,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  if (point.energyLevel != null ||
                      point.motivationLevel != null)
                    Row(
                      children: [
                        if (point.energyLevel != null) ...[
                          Text(
                            'Energy: ${point.energyLevel}/10',
                            style: AppTextStyles.caption.copyWith(
                              color: AppConstants.textTertiary,
                            ),
                          ),
                          if (point.motivationLevel != null)
                            const SizedBox(width: 12),
                        ],
                        if (point.motivationLevel != null)
                          Text(
                            'Motivation: ${point.motivationLevel}/10',
                            style: AppTextStyles.caption.copyWith(
                              color: AppConstants.textTertiary,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              trailing: Text(
                DateFormat('MMM d').format(point.date),
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.textTertiary,
                ),
              ),
            );
          }),
          if (data.length > 5)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Showing latest 5 entries',
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  final String measurementType;
  final Future<List<MeasurementDataPoint>>? dataFuture;

  const _MeasurementCard({
    required this.measurementType,
    this.dataFuture,
  });

  String get formattedType {
    return measurementType
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ExpansionTile(
        title: Text(
          formattedType,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.straighten,
            color: AppConstants.primaryColor,
            size: 20,
          ),
        ),
        children: [
          if (dataFuture != null)
            FutureBuilder<List<MeasurementDataPoint>>(
              future: dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error loading data',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppConstants.errorColor,
                      ),
                    ),
                  );
                }

                final data = snapshot.data ?? [];

                if (data.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No data available',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    if (data.length >= 2)
                      Container(
                        height: 200,
                        padding: const EdgeInsets.all(16),
                        child: _MeasurementChart(data: data),
                      ),
                    ...data.reversed.take(3).map((point) {
                      return ListTile(
                        title: Text(
                          '${point.value.toStringAsFixed(1)} cm',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          point.weekRange,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppConstants.textSecondary,
                          ),
                        ),
                        trailing: Text(
                          DateFormat('MMM d').format(point.date),
                          style: AppTextStyles.caption.copyWith(
                            color: AppConstants.textTertiary,
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No data available',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MeasurementChart extends StatelessWidget {
  final List<MeasurementDataPoint> data;

  const _MeasurementChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) {
      return Center(
        child: Text(
          'Need at least 2 data points to show chart',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
      );
    }

    final spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    final minValue = data.map((d) => d.value).reduce((a, b) => a < b ? a : b);
    final maxValue = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final valueRange = maxValue - minValue;
    final padding = valueRange > 0 ? valueRange * 0.1 : 1;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: valueRange > 0 ? valueRange / 3 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppConstants.textTertiary.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      data[index].weekRange,
                      style: AppTextStyles.caption.copyWith(
                        color: AppConstants.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(
              color: AppConstants.textTertiary.withOpacity(0.2),
            ),
            left: BorderSide(
              color: AppConstants.textTertiary.withOpacity(0.2),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppConstants.primaryColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: AppConstants.primaryColor,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppConstants.primaryColor.withOpacity(0.1),
            ),
          ),
        ],
        minY: minValue - padding,
        maxY: maxValue + padding,
      ),
    );
  }
}
