import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/services/progress_service.dart';
import '../widgets/progress_summary_card.dart';
import '../widgets/weight_tab.dart';
import '../widgets/mood_tab.dart';
import '../widgets/measurements_tab.dart';

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
                return ProgressSummaryCard(summary: snapshot.data!);
              }
              return const SizedBox.shrink();
            },
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                WeightTab(dataFuture: _weightDataFuture),
                MoodTab(dataFuture: _moodDataFuture),
                MeasurementsTab(
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
