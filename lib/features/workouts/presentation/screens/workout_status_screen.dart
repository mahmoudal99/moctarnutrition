import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../../../shared/models/workout_plan_model.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/services/workout_approval_service.dart';

class WorkoutStatusScreen extends StatefulWidget {
  const WorkoutStatusScreen({super.key});

  @override
  State<WorkoutStatusScreen> createState() => _WorkoutStatusScreenState();
}

class _WorkoutStatusScreenState extends State<WorkoutStatusScreen> {
  static final _logger = Logger();
  List<WorkoutPlanModel> _workoutPlans = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWorkoutPlans();
  }

  Future<void> _loadWorkoutPlans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userModel?.id;
      
      if (userId == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final plans = await WorkoutApprovalService.getWorkoutPlanHistory(userId);
      setState(() {
        _workoutPlans = plans;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error loading workout plans: $e');
      setState(() {
        _error = 'Failed to load workout plans';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Workout Plans'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWorkoutPlans,
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
                        onPressed: _loadWorkoutPlans,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _workoutPlans.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No workout plans yet',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Generate your first workout plan to get started!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadWorkoutPlans,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _workoutPlans.length,
                        itemBuilder: (context, index) {
                          final plan = _workoutPlans[index];
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
                _buildStatusChip(plan.approvalStatus),
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
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Created: ${_formatDate(plan.createdAt)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (plan.approvedAt != null) ...[
                  const Spacer(),
                  Icon(Icons.check_circle, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Approved: ${_formatDate(plan.approvedAt!)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ],
            ),
            if (plan.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rejection reason: ${plan.rejectionReason}',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (plan.approvedByTrainerName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Approved by: ${plan.approvedByTrainerName}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(WorkoutPlanApprovalStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case WorkoutPlanApprovalStatus.pending:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        text = 'PENDING';
        break;
      case WorkoutPlanApprovalStatus.approved:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        text = 'APPROVED';
        break;
      case WorkoutPlanApprovalStatus.rejected:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        text = 'REJECTED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
