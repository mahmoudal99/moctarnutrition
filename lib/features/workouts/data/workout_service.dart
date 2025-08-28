import '../../../shared/models/workout_model.dart';
import '../../../shared/models/workout_plan_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/ai_workout_service.dart';

class WorkoutService {
  static final WorkoutService _instance = WorkoutService._internal();
  factory WorkoutService() => _instance;
  WorkoutService._internal();

  // Dummy workout data for Strength Training
  WorkoutPlanModel getStrengthTrainingPlan(String userId) {
    return WorkoutPlanModel(
      id: 'strength_plan_1',
      userId: userId,
      title: 'Beginner Strength Training',
      description: 'A comprehensive strength training program for beginners',
      type: WorkoutPlanType.strength,
      dailyWorkouts: [
        DailyWorkout(
          id: 'day_1',
          dayName: 'Monday',
          title: 'Upper Body Push',
          description: 'Focus on chest, shoulders, and triceps',
          workouts: [
            _createWorkout(
              'Push-ups',
              'Classic bodyweight exercise for chest and triceps',
              WorkoutCategory.strength,
              [
                Exercise(
                  id: 'pushup_1',
                  name: 'Push-ups',
                  description: 'Standard push-ups with proper form',
                  sets: 3,
                  reps: 10,
                  muscleGroups: ['Chest', 'Triceps', 'Shoulders'],
                  order: 1,
                ),
                Exercise(
                  id: 'dips_1',
                  name: 'Dips',
                  description: 'Tricep dips using parallel bars or chair',
                  sets: 3,
                  reps: 8,
                  muscleGroups: ['Triceps', 'Chest'],
                  order: 2,
                ),
                Exercise(
                  id: 'pike_pushup_1',
                  name: 'Pike Push-ups',
                  description: 'Modified push-ups targeting shoulders',
                  sets: 3,
                  reps: 8,
                  muscleGroups: ['Shoulders', 'Triceps'],
                  order: 3,
                ),
              ],
            ),
          ],
          estimatedDuration: 45,
        ),
        DailyWorkout(
          id: 'day_2',
          dayName: 'Tuesday',
          title: 'Lower Body',
          description: 'Focus on legs and glutes',
          workouts: [
            _createWorkout(
              'Squats & Lunges',
              'Lower body strength building',
              WorkoutCategory.strength,
              [
                Exercise(
                  id: 'squat_1',
                  name: 'Bodyweight Squats',
                  description: 'Standard squats with proper form',
                  sets: 3,
                  reps: 15,
                  muscleGroups: ['Quadriceps', 'Glutes'],
                  order: 1,
                ),
                Exercise(
                  id: 'lunge_1',
                  name: 'Walking Lunges',
                  description: 'Forward lunges with walking motion',
                  sets: 3,
                  reps: 12,
                  muscleGroups: ['Quadriceps', 'Glutes', 'Hamstrings'],
                  order: 2,
                ),
                Exercise(
                  id: 'calf_1',
                  name: 'Calf Raises',
                  description: 'Standing calf raises',
                  sets: 3,
                  reps: 20,
                  muscleGroups: ['Calves'],
                  order: 3,
                ),
              ],
            ),
          ],
          estimatedDuration: 40,
        ),
        DailyWorkout(
          id: 'day_3',
          dayName: 'Wednesday',
          title: 'Rest Day',
          description: 'Active recovery and stretching',
          workouts: [],
          estimatedDuration: 20,
          restDay: 'Active recovery - light stretching and mobility work',
        ),
        DailyWorkout(
          id: 'day_4',
          dayName: 'Thursday',
          title: 'Upper Body Pull',
          description: 'Focus on back and biceps',
          workouts: [
            _createWorkout(
              'Pull-ups & Rows',
              'Back and bicep strengthening',
              WorkoutCategory.strength,
              [
                Exercise(
                  id: 'pullup_1',
                  name: 'Assisted Pull-ups',
                  description: 'Pull-ups with assistance band or partner',
                  sets: 3,
                  reps: 5,
                  muscleGroups: ['Back', 'Biceps'],
                  order: 1,
                ),
                Exercise(
                  id: 'row_1',
                  name: 'Inverted Rows',
                  description: 'Bodyweight rows using a bar or table',
                  sets: 3,
                  reps: 10,
                  muscleGroups: ['Back', 'Biceps'],
                  order: 2,
                ),
                Exercise(
                  id: 'curl_1',
                  name: 'Bicep Curls',
                  description: 'Dumbbell or resistance band curls',
                  sets: 3,
                  reps: 12,
                  muscleGroups: ['Biceps'],
                  order: 3,
                ),
              ],
            ),
          ],
          estimatedDuration: 45,
        ),
        DailyWorkout(
          id: 'day_5',
          dayName: 'Friday',
          title: 'Core & Cardio',
          description: 'Core strength and cardiovascular fitness',
          workouts: [
            _createWorkout(
              'Core Circuit',
              'Comprehensive core workout',
              WorkoutCategory.strength,
              [
                Exercise(
                  id: 'plank_1',
                  name: 'Plank',
                  description: 'Hold plank position',
                  sets: 3,
                  reps: 1,
                  duration: 30,
                  muscleGroups: ['Core'],
                  order: 1,
                ),
                Exercise(
                  id: 'crunch_1',
                  name: 'Crunches',
                  description: 'Standard abdominal crunches',
                  sets: 3,
                  reps: 15,
                  muscleGroups: ['Core'],
                  order: 2,
                ),
                Exercise(
                  id: 'mountain_climber_1',
                  name: 'Mountain Climbers',
                  description: 'Dynamic core exercise',
                  sets: 3,
                  reps: 1,
                  duration: 30,
                  muscleGroups: ['Core', 'Shoulders'],
                  order: 3,
                ),
              ],
            ),
          ],
          estimatedDuration: 35,
        ),
        DailyWorkout(
          id: 'day_6',
          dayName: 'Saturday',
          title: 'Full Body',
          description: 'Complete body workout',
          workouts: [
            _createWorkout(
              'Full Body Circuit',
              'Complete body strength training',
              WorkoutCategory.strength,
              [
                Exercise(
                  id: 'burpee_1',
                  name: 'Burpees',
                  description: 'Full body conditioning exercise',
                  sets: 3,
                  reps: 8,
                  muscleGroups: ['Full Body'],
                  order: 1,
                ),
                Exercise(
                  id: 'jump_squat_1',
                  name: 'Jump Squats',
                  description: 'Explosive squat variations',
                  sets: 3,
                  reps: 10,
                  muscleGroups: ['Quadriceps', 'Glutes'],
                  order: 2,
                ),
                Exercise(
                  id: 'pushup_2',
                  name: 'Push-ups',
                  description: 'Standard push-ups',
                  sets: 3,
                  reps: 10,
                  muscleGroups: ['Chest', 'Triceps'],
                  order: 3,
                ),
              ],
            ),
          ],
          estimatedDuration: 50,
        ),
        DailyWorkout(
          id: 'day_7',
          dayName: 'Sunday',
          title: 'Rest Day',
          description: 'Complete rest and recovery',
          workouts: [],
          estimatedDuration: 0,
          restDay: 'Complete rest - focus on recovery and nutrition',
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Dummy workout data for Body Building
  WorkoutPlanModel getBodyBuildingPlan(String userId) {
    return WorkoutPlanModel(
      id: 'bodybuilding_plan_1',
      userId: userId,
      title: 'Body Building Split',
      description: 'Classic bodybuilding split for muscle hypertrophy',
      type: WorkoutPlanType.bodybuilding,
      dailyWorkouts: [
        DailyWorkout(
          id: 'bb_day_1',
          dayName: 'Monday',
          title: 'Chest & Triceps',
          description: 'Focus on chest development and tricep isolation',
          workouts: [
            _createWorkout(
              'Chest Press',
              'Compound chest movements',
              WorkoutCategory.strength,
              [
                Exercise(
                  id: 'bench_press_1',
                  name: 'Bench Press',
                  description: 'Barbell bench press for chest development',
                  sets: 4,
                  reps: 8,
                  muscleGroups: ['Chest', 'Triceps', 'Shoulders'],
                  order: 1,
                ),
                Exercise(
                  id: 'incline_press_1',
                  name: 'Incline Press',
                  description: 'Incline barbell press for upper chest',
                  sets: 3,
                  reps: 10,
                  muscleGroups: ['Chest', 'Triceps'],
                  order: 2,
                ),
                Exercise(
                  id: 'dumbbell_fly_1',
                  name: 'Dumbbell Flyes',
                  description: 'Isolation exercise for chest',
                  sets: 3,
                  reps: 12,
                  muscleGroups: ['Chest'],
                  order: 3,
                ),
                Exercise(
                  id: 'tricep_dip_1',
                  name: 'Tricep Dips',
                  description: 'Weighted tricep dips',
                  sets: 3,
                  reps: 10,
                  muscleGroups: ['Triceps'],
                  order: 4,
                ),
              ],
            ),
          ],
          estimatedDuration: 60,
        ),
        DailyWorkout(
          id: 'bb_day_2',
          dayName: 'Tuesday',
          title: 'Back & Biceps',
          description: 'Back thickness and bicep development',
          workouts: [
            _createWorkout(
              'Back & Biceps',
              'Back and bicep focused workout',
              WorkoutCategory.strength,
              [
                Exercise(
                  id: 'deadlift_1',
                  name: 'Deadlift',
                  description: 'Compound back exercise',
                  sets: 4,
                  reps: 6,
                  muscleGroups: ['Back', 'Hamstrings'],
                  order: 1,
                ),
                Exercise(
                  id: 'pullup_2',
                  name: 'Pull-ups',
                  description: 'Weighted pull-ups',
                  sets: 3,
                  reps: 8,
                  muscleGroups: ['Back', 'Biceps'],
                  order: 2,
                ),
                Exercise(
                  id: 'barbell_row_1',
                  name: 'Barbell Rows',
                  description: 'Bent-over barbell rows',
                  sets: 3,
                  reps: 10,
                  muscleGroups: ['Back'],
                  order: 3,
                ),
                Exercise(
                  id: 'bicep_curl_1',
                  name: 'Barbell Curls',
                  description: 'Standing barbell curls',
                  sets: 3,
                  reps: 12,
                  muscleGroups: ['Biceps'],
                  order: 4,
                ),
              ],
            ),
          ],
          estimatedDuration: 65,
        ),
        DailyWorkout(
          id: 'bb_day_3',
          dayName: 'Wednesday',
          title: 'Rest Day',
          description: 'Recovery day',
          workouts: [],
          estimatedDuration: 0,
          restDay: 'Rest and recovery - focus on nutrition',
        ),
        DailyWorkout(
          id: 'bb_day_4',
          dayName: 'Thursday',
          title: 'Shoulders & Traps',
          description: 'Shoulder development and trap work',
          workouts: [
            _createWorkout(
              'Shoulders & Traps',
              'Shoulder and trap focused workout',
              WorkoutCategory.strength,
              [
                Exercise(
                  id: 'overhead_press_1',
                  name: 'Overhead Press',
                  description: 'Military press for shoulder development',
                  sets: 4,
                  reps: 8,
                  muscleGroups: ['Shoulders', 'Triceps'],
                  order: 1,
                ),
                Exercise(
                  id: 'lateral_raise_1',
                  name: 'Lateral Raises',
                  description: 'Dumbbell lateral raises',
                  sets: 3,
                  reps: 12,
                  muscleGroups: ['Shoulders'],
                  order: 2,
                ),
                Exercise(
                  id: 'shrug_1',
                  name: 'Barbell Shrugs',
                  description: 'Trap development exercise',
                  sets: 3,
                  reps: 15,
                  muscleGroups: ['Traps'],
                  order: 3,
                ),
              ],
            ),
          ],
          estimatedDuration: 55,
        ),
        DailyWorkout(
          id: 'bb_day_5',
          dayName: 'Friday',
          title: 'Legs',
          description: 'Complete leg development',
          workouts: [
            _createWorkout(
              'Leg Day',
              'Comprehensive leg workout',
              WorkoutCategory.strength,
              [
                Exercise(
                  id: 'squat_2',
                  name: 'Barbell Squats',
                  description: 'Compound leg exercise',
                  sets: 4,
                  reps: 8,
                  muscleGroups: ['Quadriceps', 'Glutes'],
                  order: 1,
                ),
                Exercise(
                  id: 'leg_press_1',
                  name: 'Leg Press',
                  description: 'Machine leg press',
                  sets: 3,
                  reps: 10,
                  muscleGroups: ['Quadriceps'],
                  order: 2,
                ),
                Exercise(
                  id: 'leg_curl_1',
                  name: 'Leg Curls',
                  description: 'Hamstring isolation',
                  sets: 3,
                  reps: 12,
                  muscleGroups: ['Hamstrings'],
                  order: 3,
                ),
                Exercise(
                  id: 'calf_raise_1',
                  name: 'Standing Calf Raises',
                  description: 'Calf development',
                  sets: 4,
                  reps: 15,
                  muscleGroups: ['Calves'],
                  order: 4,
                ),
              ],
            ),
          ],
          estimatedDuration: 70,
        ),
        DailyWorkout(
          id: 'bb_day_6',
          dayName: 'Saturday',
          title: 'Arms',
          description: 'Arm specialization day',
          workouts: [
            _createWorkout(
              'Arm Day',
              'Bicep and tricep focused workout',
              WorkoutCategory.strength,
              [
                Exercise(
                  id: 'close_grip_bench_1',
                  name: 'Close-Grip Bench Press',
                  description: 'Tricep-focused bench press',
                  sets: 3,
                  reps: 8,
                  muscleGroups: ['Triceps', 'Chest'],
                  order: 1,
                ),
                Exercise(
                  id: 'skull_crusher_1',
                  name: 'Skull Crushers',
                  description: 'Tricep isolation exercise',
                  sets: 3,
                  reps: 12,
                  muscleGroups: ['Triceps'],
                  order: 2,
                ),
                Exercise(
                  id: 'preacher_curl_1',
                  name: 'Preacher Curls',
                  description: 'Bicep isolation exercise',
                  sets: 3,
                  reps: 12,
                  muscleGroups: ['Biceps'],
                  order: 3,
                ),
                Exercise(
                  id: 'hammer_curl_1',
                  name: 'Hammer Curls',
                  description: 'Dumbbell hammer curls',
                  sets: 3,
                  reps: 12,
                  muscleGroups: ['Biceps', 'Forearms'],
                  order: 4,
                ),
              ],
            ),
          ],
          estimatedDuration: 50,
        ),
        DailyWorkout(
          id: 'bb_day_7',
          dayName: 'Sunday',
          title: 'Rest Day',
          description: 'Complete rest and recovery',
          workouts: [],
          estimatedDuration: 0,
          restDay: 'Complete rest - focus on recovery and nutrition',
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  WorkoutModel _createWorkout(
    String title,
    String description,
    WorkoutCategory category,
    List<Exercise> exercises,
  ) {
    return WorkoutModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      trainerId: 'dummy_trainer',
      trainerName: 'Moctar Fitness',
      difficulty: WorkoutDifficulty.intermediate,
      category: category,
      estimatedDuration: exercises.length * 15, // Rough estimate
      exercises: exercises,
      tags: ['dummy', 'predefined'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Get workout plan based on user's selected workout styles
  WorkoutPlanModel? getWorkoutPlanForUser(
      String userId, List<String> workoutStyles) {
    if (workoutStyles.contains('Strength Training')) {
      return getStrengthTrainingPlan(userId);
    } else if (workoutStyles.contains('Body Building')) {
      return getBodyBuildingPlan(userId);
    }
    return null; // For other workout styles, return null (AI will handle)
  }

  // Generate AI workout plan for user
  Future<WorkoutPlanModel> generateAIWorkoutPlan(
      UserModel user, String userId) async {
    return await AIWorkoutService.generateWorkoutPlan(user, userId);
  }
}
