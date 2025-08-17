import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/exercise_provider.dart';

class ExerciseSearchFilter extends StatelessWidget {
  const ExerciseSearchFilter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExerciseProvider>(
      builder: (context, exerciseProvider, child) {
        return Column(
          children: [
            // Search bar
            Container(
              margin: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: AppConstants.surfaceColor,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                boxShadow: AppConstants.shadowS,
              ),
              child: TextField(
                onChanged: (value) {
                  exerciseProvider.setSearchQuery(value);
                },
                decoration: InputDecoration(
                  hintText: 'Search exercises...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: exerciseProvider.searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            exerciseProvider.setSearchQuery('');
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppConstants.surfaceColor,
                ),
              ),
            ),
            
            // Muscle group filter
            if (exerciseProvider.availableMuscleGroups.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter by Muscle Group',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // All exercises filter
                          FilterChip(
                            label: const Text('All'),
                            selected: exerciseProvider.selectedMuscleGroup == null,
                            onSelected: (selected) {
                              if (selected) {
                                exerciseProvider.setSelectedMuscleGroup(null);
                              }
                            },
                            selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                            checkmarkColor: AppConstants.primaryColor,
                          ),
                          const SizedBox(width: AppConstants.spacingS),
                          // Individual muscle group filters
                          ...exerciseProvider.availableMuscleGroups.map((muscleGroup) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                right: AppConstants.spacingS,
                              ),
                              child: FilterChip(
                                label: Text(muscleGroup),
                                selected: exerciseProvider.selectedMuscleGroup == muscleGroup,
                                onSelected: (selected) {
                                  if (selected) {
                                    exerciseProvider.setSelectedMuscleGroup(muscleGroup);
                                  } else {
                                    exerciseProvider.setSelectedMuscleGroup(null);
                                  }
                                },
                                selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                                checkmarkColor: AppConstants.primaryColor,
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
            ],
            
            // Results count
            if (exerciseProvider.searchQuery.isNotEmpty || 
                exerciseProvider.selectedMuscleGroup != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                ),
                child: Row(
                  children: [
                    Text(
                      '${exerciseProvider.filteredExerciseCount} exercises found',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        exerciseProvider.clearFilters();
                      },
                      child: const Text('Clear filters'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingS),
            ],
          ],
        );
      },
    );
  }
} 