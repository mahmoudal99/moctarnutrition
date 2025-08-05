import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/checkin_provider.dart';
import '../../../../shared/providers/auth_provider.dart' as app_auth;
import '../../../../shared/models/checkin_model.dart';
import '../widgets/checkin_status_card.dart';
import '../widgets/checkin_progress_summary.dart';
import '../widgets/checkin_history_list.dart';
import 'checkin_form_screen.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final checkinProvider =
        Provider.of<CheckinProvider>(context, listen: false);
    await checkinProvider.refresh();
  }

  Future<void> _cleanupData() async {
    final checkinProvider =
        Provider.of<CheckinProvider>(context, listen: false);
    await checkinProvider.markOverdueCheckins();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Weekly Check-in',
          style:
              AppTextStyles.heading4.copyWith(color: AppConstants.textPrimary),
        ),
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppConstants.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppConstants.textPrimary),
            onPressed: _loadData,
          ),
          // IconButton(
          //   icon: const Icon(Icons.cleaning_services, color: AppConstants.textPrimary),
          //   onPressed: _cleanupData,
          //   tooltip: 'Cleanup duplicates',
          // ),
        ],
      ),
      body: Consumer2<CheckinProvider, app_auth.AuthProvider>(
        builder: (context, checkinProvider, authProvider, child) {
          print('CheckinScreen - isLoading: ${checkinProvider.isLoading}');
          print('CheckinScreen - userCheckins.length: ${checkinProvider.userCheckins.length}');
          print('CheckinScreen - error: ${checkinProvider.error}');
          
          if (checkinProvider.isLoading &&
              checkinProvider.userCheckins.isEmpty) {
            print('CheckinScreen - Showing loading indicator');
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (checkinProvider.error != null) {
            print('CheckinScreen - Showing error state');
            return _buildErrorState(checkinProvider.error!);
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Current week check-in status
                CheckinStatusCard(
                  currentCheckin: checkinProvider.currentWeekCheckin,
                  onCheckinNow: () => _navigateToCheckinForm(context),
                  onViewCheckin: () => _viewCurrentCheckin(context),
                ),

                const SizedBox(height: 24),

                // Progress summary
                if (checkinProvider.progressSummary != null)
                  CheckinProgressSummaryWidget(
                    summary: checkinProvider.progressSummary!,
                  ),

                const SizedBox(height: 24),

                // Check-in history
                _buildHistorySection(checkinProvider),
                const SizedBox(height: 128),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppConstants.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: AppTextStyles.heading4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(CheckinProvider checkinProvider) {
    print('_buildHistorySection - userCheckins.length: ${checkinProvider.userCheckins.length}');
    print('_buildHistorySection - isEmpty: ${checkinProvider.userCheckins.isEmpty}');
    
    if (checkinProvider.userCheckins.isEmpty) {
      print('_buildHistorySection - Building empty history');
    } else {
      print('_buildHistorySection - Building history list with ${checkinProvider.userCheckins.take(5).length} items');
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Check-in History',
              style: AppTextStyles.heading4,
            ),
            if (checkinProvider.userCheckins.isNotEmpty)
              TextButton(
                onPressed: () => _viewAllHistory(context),
                child: Text(
                  'View All',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (checkinProvider.userCheckins.isEmpty)
          _buildEmptyHistory()
        else
          CheckinHistoryList(
            checkins: checkinProvider.userCheckins.take(5).toList(),
            onCheckinTap: (checkin) => _viewCheckinDetails(context, checkin),
            showLoadMore: checkinProvider.hasMoreCheckins,
            onLoadMore: () => checkinProvider.loadUserCheckins(),
          ),
      ],
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 48,
            color: AppConstants.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No check-ins yet',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Start your fitness journey by taking your first progress photo',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppConstants.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _navigateToCheckinForm(context),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take First Photo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCheckinForm(BuildContext context) {
    context.push('/checkin/form');
  }

  void _viewCurrentCheckin(BuildContext context) {
    final checkinProvider =
        Provider.of<CheckinProvider>(context, listen: false);
    final currentCheckin = checkinProvider.currentWeekCheckin;

    if (currentCheckin != null) {
      context.push('/checkin/details', extra: currentCheckin);
    }
  }

  void _viewCheckinDetails(BuildContext context, CheckinModel checkin) {
    context.push('/checkin/details', extra: checkin);
  }

  void _viewAllHistory(BuildContext context) {
    context.push('/checkin/history');
  }
}
