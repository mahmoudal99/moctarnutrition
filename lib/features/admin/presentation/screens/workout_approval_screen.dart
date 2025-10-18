import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../../../shared/models/workout_plan_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/services/workout_approval_service.dart';

class WorkoutApprovalScreen extends StatefulWidget {
  const WorkoutApprovalScreen({super.key});

  @override
  State<WorkoutApprovalScreen> createState() => _WorkoutApprovalScreenState();
}

class _WorkoutApprovalScreenState extends State<WorkoutApprovalScreen> {
  static final _logger = Logger();
  List<WorkoutPlanModel> _pendingPlans = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPendingPlans();
  }

  Future<void> _loadPendingPlans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final plans = await WorkoutApprovalService.getPendingWorkoutPlans();
      setState(() {
        _pendingPlans = plans;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error loading pending plans: $e');
      setState(() {
        _error = 'Failed to load pending workout plans';
        _isLoading = false;
      });
    }
  }

  Future<void> _approvePlan(WorkoutPlanModel plan) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.userModel;
    
    if (currentUser == null) {
      _showErrorSnackBar('User not authenticated');
      return;
    }

    try {
      await WorkoutApprovalService.approveWorkoutPlan(
        plan.id,
        currentUser.id,
        currentUser.name ?? 'Trainer',
      );
      
      _showSuccessSnackBar('Workout plan approved successfully');
      _loadPendingPlans(); // Refresh the list
    } catch (e) {
      _logger.e('Error approving plan: $e');
      _showErrorSnackBar('Failed to approve workout plan');
    }
  }

  Future<void> _rejectPlan(WorkoutPlanModel plan) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.userModel;
    
    if (currentUser == null) {
      _showErrorSnackBar('User not authenticated');
      return;
    }

    // Show dialog to get rejection reason
    final reason = await _showRejectionDialog();
    if (reason == null || reason.isEmpty) return;

    try {
      await WorkoutApprovalService.rejectWorkoutPlan(
        plan.id,
        currentUser.id,
        currentUser.name ?? 'Trainer',
        reason,
      );
      
      _showSuccessSnackBar('Workout plan rejected');
      _loadPendingPlans(); // Refresh the list
    } catch (e) {
      _logger.e('Error rejecting plan: $e');
      _showErrorSnackBar('Failed to reject workout plan');
    }
  }

  Future<String?> _showRejectionDialog() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Workout Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Plan Approvals'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingPlans,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPendingPlans,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _pendingPlans.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Colors.green,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No pending workout plans',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'All workout plans are up to date!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPendingPlans,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pendingPlans.length,
                        itemBuilder: (context, index) {
                          final plan = _pendingPlans[index];
                          return _buildWorkoutPlanCard(plan);
                        },
                      ),
                    ),
    );
  }

  Widget _buildWorkoutPlanCard(WorkoutPlanModel plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PENDING',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'User ID: ${plan.userId}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Created: ${_formatDate(plan.createdAt)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.fitness_center, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${plan.dailyWorkouts.length} days',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Type: ${plan.type.toString().split('.').last}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectPlan(plan),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Reject', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approvePlan(plan),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('Approve', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
