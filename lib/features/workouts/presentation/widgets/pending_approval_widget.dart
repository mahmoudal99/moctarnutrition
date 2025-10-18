import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/workout_provider.dart';

class PendingApprovalWidget extends StatelessWidget {
  const PendingApprovalWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, WorkoutProvider>(
      builder: (context, authProvider, workoutProvider, child) {
        final user = authProvider.userModel;
        if (user == null) return const SizedBox.shrink();

        return FutureBuilder<bool>(
          future: workoutProvider.hasPendingWorkoutPlans(user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }

            if (snapshot.hasData && snapshot.data == true) {
              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: Colors.orange[600],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Workout Plan Pending Approval',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your personalized workout plan is being reviewed by our trainers.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/workout-status',
                              );
                            },
                            icon: const Icon(Icons.visibility),
                            label: const Text('View Status'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange[700],
                              side: BorderSide(color: Colors.orange[300]!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Navigate to generate new plan
                              Navigator.pushNamed(
                                context,
                                '/workouts',
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Generate New'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}
