import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/checkin_provider.dart';
import '../../../../shared/models/checkin_model.dart';
import '../widgets/checkin_history_list.dart';

class CheckinHistoryScreen extends StatefulWidget {
  const CheckinHistoryScreen({super.key});

  @override
  State<CheckinHistoryScreen> createState() => _CheckinHistoryScreenState();
}

class _CheckinHistoryScreenState extends State<CheckinHistoryScreen> {
  String _searchQuery = '';
  CheckinStatus? _statusFilter;
  bool _isLoadingMore = false;

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
    await checkinProvider.loadUserCheckins(refresh: true);
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final checkinProvider =
        Provider.of<CheckinProvider>(context, listen: false);
    await checkinProvider.loadUserCheckins();

    setState(() {
      _isLoadingMore = false;
    });
  }

  List<CheckinModel> _getFilteredCheckins(List<CheckinModel> checkins) {
    var filtered = checkins;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((checkin) {
        final notes = checkin.notes?.toLowerCase() ?? '';
        final mood = checkin.mood?.toLowerCase() ?? '';
        final searchLower = _searchQuery.toLowerCase();

        return notes.contains(searchLower) ||
            mood.contains(searchLower) ||
            checkin.weekStartDate.toString().contains(searchLower);
      }).toList();
    }

    // Apply status filter
    if (_statusFilter != null) {
      filtered =
          filtered.where((checkin) => checkin.status == _statusFilter).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Check-in History',
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
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          _buildSearchAndFilterSection(),

          // Check-ins list
          Expanded(
            child: Consumer<CheckinProvider>(
              builder: (context, checkinProvider, child) {
                if (checkinProvider.isLoading &&
                    checkinProvider.userCheckins.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (checkinProvider.error != null) {
                  return _buildErrorState(checkinProvider.error!);
                }

                final filteredCheckins =
                    _getFilteredCheckins(checkinProvider.userCheckins);

                if (filteredCheckins.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: _loadData,
                  child: CheckinHistoryList(
                    checkins: filteredCheckins,
                    onCheckinTap: (checkin) =>
                        _viewCheckinDetails(context, checkin),
                    showLoadMore:
                        checkinProvider.hasMoreCheckins && !_isLoadingMore,
                    onLoadMore: _loadMore,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: AppConstants.textTertiary.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search check-ins...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppConstants.textTertiary.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppConstants.textTertiary.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppConstants.primaryColor,
                ),
              ),
              filled: true,
              fillColor: AppConstants.backgroundColor,
            ),
          ),

          const SizedBox(height: 12),

          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', null),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', CheckinStatus.completed),
                const SizedBox(width: 8),
                _buildFilterChip('Missed', CheckinStatus.missed),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', CheckinStatus.pending),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, CheckinStatus? status) {
    final isSelected = _statusFilter == status;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _statusFilter = selected ? status : null;
        });
      },
      backgroundColor: AppConstants.backgroundColor,
      selectedColor: AppConstants.primaryColor.withOpacity(0.2),
      checkmarkColor: AppConstants.primaryColor,
      labelStyle: AppTextStyles.bodyMedium.copyWith(
        color:
            isSelected ? AppConstants.primaryColor : AppConstants.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? AppConstants.primaryColor
              : AppConstants.textTertiary.withOpacity(0.3),
        ),
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
            Icon(
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: AppConstants.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No check-ins found',
              style: AppTextStyles.heading4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _statusFilter != null
                  ? 'Try adjusting your search or filters'
                  : 'Start your fitness journey by taking your first progress photo',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty && _statusFilter == null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push('/checkin/form'),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take First Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _viewCheckinDetails(BuildContext context, CheckinModel checkin) {
    context.push('/checkin/details', extra: checkin);
  }
}
