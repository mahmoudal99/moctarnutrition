import 'package:flutter/material.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:champions_gym_app/shared/services/stripe_analytics_service.dart';
import 'package:logger/logger.dart';

class AdminHomeScreen extends StatefulWidget {
  final String adminName;

  const AdminHomeScreen({Key? key, this.adminName = 'Moctar'})
      : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  String selectedPeriod = 'This Month';
  bool _isLoading = true;
  StripeDashboardMetrics? _metrics;
  String? _errorMessage;
  final _logger = Logger();
  
  // Cache for different periods to avoid unnecessary API calls
  final Map<String, StripeDashboardMetrics> _metricsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Cache duration - refresh data if older than 5 minutes
  static const Duration _cacheDuration = Duration(minutes: 5);

  final List<String> timePeriods = [
    'Today',
    'This Week',
    'This Month',
    'Last Month',
    'This Year',
    'Last Year',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAndFetchData();
  }

  Future<void> _initializeAndFetchData() async {
    try {
      await StripeAnalyticsService.initialize();
      
      // Check if we have cached data for the initial period
      if (_isDataCached(selectedPeriod)) {
        _logger.i('Using cached data for initial period: $selectedPeriod');
        if (mounted) {
          setState(() {
            _metrics = _metricsCache[selectedPeriod];
            _isLoading = false;
          });
        }
        return; // Exit early if we have cached data
      }
      
      // Only show loading if we need to fetch data
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
      
      await _fetchDataForPeriod(selectedPeriod);
    } catch (e) {
      _logger.e('Error initializing analytics service: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load metrics data';
          _isLoading = false;
        });
      }
    }
  }
  
  /// Force refresh data by clearing cache and fetching fresh data
  Future<void> _forceRefreshData() async {
    _logger.i('Force refreshing data - clearing cache');
    
    // Clear all cached data
    _metricsCache.clear();
    _cacheTimestamps.clear();
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    await _fetchDataForPeriod(selectedPeriod);
  }

  void _onPeriodChanged(String? newPeriod) {
    if (newPeriod != null && newPeriod != selectedPeriod) {
      setState(() {
        selectedPeriod = newPeriod;
        _errorMessage = null;
      });
      
      // Check if we have cached data for this period
      if (_isDataCached(newPeriod)) {
        _logger.i('Using cached data for period: $newPeriod');
        setState(() {
          _metrics = _metricsCache[newPeriod];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = true;
        });
        _fetchDataForPeriod(newPeriod);
      }
    }
  }

  Future<void> _fetchDataForPeriod(String period) async {
    try {
      _logger.i('Fetching data for period: $period');
      final metrics = await StripeAnalyticsService.getMetricsForPeriod(period);
      
      _logger.i('Received metrics: $metrics');
      
      if (mounted) {
        // Cache the data
        if (metrics != null) {
          _metricsCache[period] = metrics;
          _cacheTimestamps[period] = DateTime.now();
        }
        
        setState(() {
          _metrics = metrics;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      _logger.e('Error fetching metrics for period $period: $e');
      _logger.e('Stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load metrics for $period: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }
  
  /// Check if data is cached and still valid for the given period
  bool _isDataCached(String period) {
    if (!_metricsCache.containsKey(period) || !_cacheTimestamps.containsKey(period)) {
      return false;
    }
    
    final cacheTime = _cacheTimestamps[period]!;
    final now = DateTime.now();
    final isExpired = now.difference(cacheTime) > _cacheDuration;
    
    if (isExpired) {
      _logger.i('Cache expired for period: $period');
      _metricsCache.remove(period);
      _cacheTimestamps.remove(period);
      return false;
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null && _metrics == null) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppConstants.errorColor,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppConstants.errorColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeAndFetchData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final metrics = _buildMetricsData();
    final lastUpdated = _metrics?.lastUpdated != null 
        ? 'Last Updated ${_formatLastUpdated(_metrics!.lastUpdated)}'
        : 'Last Updated ${TimeOfDay.now().format(context)}';

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Welcome back, ${widget.adminName}!',
                      style: AppTextStyles.heading3),
                  IconButton(
                    onPressed: _forceRefreshData,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh metrics',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 15),
              // Sales Card
              _SalesCard(
                lastUpdated: lastUpdated,
                totalRevenue: _metrics?.revenue.totalRevenue ?? 0.0,
                historicalData: _metrics?.historicalData ?? [],
              ),
              const SizedBox(height: 18),
              _StatisticsCard(
                stats: _buildStatisticsData(),
                selectedPeriod: selectedPeriod,
                timePeriods: timePeriods,
                onPeriodChanged: _onPeriodChanged,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 28),
              // Metrics grid
              Stack(
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: metrics.map((m) => _MetricCard(m)).toList(),
                  ),
                  if (_isLoading && _metrics != null)
                    Positioned.fill(
                      child: Container(
                        color: Colors.white.withOpacity(0.7),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
    );
  }

  List<_MetricCardData> _buildMetricsData() {
    if (_metrics == null) {
      return [
        _MetricCardData('Active Customers', '0', Icons.group, AppConstants.primaryColor),
        _MetricCardData('New Customers', '0', Icons.person_add, AppConstants.accentColor),
        _MetricCardData('Total Sales', '0', Icons.shopping_cart, AppConstants.secondaryColor),
        _MetricCardData('Success Rate', '0%', Icons.check_circle, AppConstants.successColor),
      ];
    }

    return [
      _MetricCardData(
        'Active Customers', 
        '${_metrics!.activeCustomers}', 
        Icons.group, 
        AppConstants.primaryColor
      ),
      _MetricCardData(
        'New Customers', 
        '${_metrics!.newCustomers}', 
        Icons.person_add, 
        AppConstants.accentColor
      ),
      _MetricCardData(
        'Total Sales', 
        '${_metrics!.sales.totalSales}', 
        Icons.shopping_cart, 
        AppConstants.secondaryColor
      ),
      _MetricCardData(
        'Success Rate', 
        _metrics!.transactions.formattedSuccessRate, 
        Icons.check_circle, 
        AppConstants.successColor
      ),
    ];
  }

  List<_SalesStat> _buildStatisticsData() {
    if (_metrics == null) {
    return [
      _SalesStat('Earnings', '€0.00', '0%', true),
      _SalesStat('Sales', '€0.00', '0%', true),
      _SalesStat('Transactions', '0', '0%', true),
    ];
    }

    return [
      _SalesStat(
        'Earnings', 
        _metrics!.revenue.formattedTotalRevenue, 
        _metrics!.revenue.formattedRevenueGrowth ?? '0%', 
        (_metrics!.revenue.revenueGrowth ?? 0) >= 0
      ),
      _SalesStat(
        'Sales', 
        _metrics!.sales.formattedTotalSalesValue, 
        _metrics!.sales.formattedSalesGrowth ?? '0%', 
        (_metrics!.sales.salesGrowth ?? 0) >= 0
      ),
      _SalesStat(
        'Transactions', 
        '${_metrics!.transactions.totalTransactions}', 
        _metrics!.transactions.formattedTransactionGrowth ?? '0%', 
        (_metrics!.transactions.transactionGrowth ?? 0) >= 0
      ),
    ];
  }

  String _formatLastUpdated(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: data.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(data.icon, color: data.color, size: 20),
                ),
                Icon(
                  Icons.trending_up,
                  color: data.color.withOpacity(0.6),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data.value,
              style: AppTextStyles.heading4.copyWith(
                color: data.color,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 4),
            Text(
              data.label,
              style: AppTextStyles.caption.copyWith(
                color: AppConstants.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesCard extends StatelessWidget {
  final String lastUpdated;
  final double totalRevenue;
  final List<HistoricalDataPoint> historicalData;

  const _SalesCard({
    required this.lastUpdated,
    required this.totalRevenue,
    required this.historicalData,
  });

  @override
  Widget build(BuildContext context) {
    final totalBalance = '€${totalRevenue.toStringAsFixed(2)}';
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
            // Revenue trend chart
            Container(
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: _buildRevenueChart(),
            ),
            const SizedBox(height: 18),
            // Stats row moved to separate widget below
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    if (historicalData.isEmpty) {
      // Show a flat line if no data
      return LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: 10,
          lineBarsData: [
            LineChartBarData(
              spots: [
                const FlSpot(0, 5),
                const FlSpot(6, 5),
              ],
              isCurved: false,
              color: const Color(0xFF4F8DFD).withOpacity(0.3),
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      );
    }

    // Convert historical data to chart spots
    final spots = <FlSpot>[];
    final maxRevenue = historicalData.map((e) => e.revenue).reduce((a, b) => a > b ? a : b);
    final minRevenue = historicalData.map((e) => e.revenue).reduce((a, b) => a < b ? a : b);
    final revenueRange = maxRevenue - minRevenue;
    
    for (int i = 0; i < historicalData.length; i++) {
      final dataPoint = historicalData[i];
      double yValue;
      
      if (revenueRange == 0) {
        yValue = 5.0; // Center if all values are the same
      } else {
        // Normalize to 0-10 range
        yValue = ((dataPoint.revenue - minRevenue) / revenueRange) * 8 + 1;
      }
      
      spots.add(FlSpot(i.toDouble(), yValue));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (historicalData.length - 1).toDouble(),
        minY: 0,
        maxY: 10,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF4F8DFD),
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF4F8DFD).withOpacity(0.1),
            ),
          ),
        ],
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
  final String selectedPeriod;
  final List<String> timePeriods;
  final Function(String?) onPeriodChanged;
  final bool isLoading;

  const _StatisticsCard({
    required this.stats,
    required this.selectedPeriod,
    required this.timePeriods,
    required this.onPeriodChanged,
    this.isLoading = false,
  });

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
                // Functional filter dropdown
                PopupMenuButton<String>(
                  onSelected: onPeriodChanged,
                  itemBuilder: (BuildContext context) {
                    return timePeriods.map((String period) {
                      return PopupMenuItem<String>(
                        value: period,
                        child: Text(
                          period,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: period == selectedPeriod
                                ? AppConstants.primaryColor
                                : AppConstants.textPrimary,
                            fontWeight: period == selectedPeriod
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(selectedPeriod,
                            style: AppTextStyles.caption
                                .copyWith(color: AppConstants.textSecondary)),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 16, color: AppConstants.textSecondary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 80,
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Row(
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
