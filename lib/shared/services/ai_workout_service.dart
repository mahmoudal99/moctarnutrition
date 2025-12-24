import 'dart:convert';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import '../models/workout_plan_model.dart';
import '../models/workout_model.dart';
import 'parser_service.dart';
import 'config_service.dart';
import 'rate_limit_service.dart';
import 'workout_approval_notification_service.dart';

// Import ValidationException from parser service
import 'parser_service.dart' show ValidationException;

class AIWorkoutService {
  static final _logger = Logger();

  /// Generate a complete workout plan based on user preferences
  static Future<WorkoutPlanModel> generateWorkoutPlan(
    UserModel user,
    String userId,
  ) async {
    _logger.i('Generating AI workout plan for user: ${user.id}');

    try {
      final workoutPlan = await _generateWorkoutPlanWithRetry(user, userId);
      _logger.i('Successfully generated workout plan: ${workoutPlan.title}');
      
      // Only send approval notifications for bodybuilders who need trainer approval
      // Non-bodybuilders get auto-approved, so no need for approval notifications
      if (user.preferences.isBodybuilder) {
        await WorkoutApprovalNotificationService.notifyWorkoutPlanPending(
          userId,
          workoutPlan.title,
        );
        
        await WorkoutApprovalNotificationService.notifyTrainersNewWorkoutPlan(
          userId,
          workoutPlan.title,
        );
        
        await WorkoutApprovalNotificationService.notifyAdminsNewWorkoutPlan(
          userId,
          workoutPlan.title,
        );
      } else {
        _logger.i('Non-bodybuilder user - workout plan auto-approved, skipping approval notifications');
      }
      
      return workoutPlan;
    } catch (e) {
      _logger.e('Failed to generate workout plan: $e');
      rethrow;
    }
  }

  /// Generate workout plan with retry logic
  static Future<WorkoutPlanModel> _generateWorkoutPlanWithRetry(
    UserModel user,
    String userId, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        _logger.d('Generating workout plan - attempt $attempt');
        return await _generateWorkoutPlanInternal(user, userId);
      } catch (e) {
        _logger.w('Attempt $attempt failed: $e');
        if (attempt == maxRetries) {
          rethrow;
        }
        // Wait before retry
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    throw Exception(
        'Failed to generate workout plan after $maxRetries attempts');
  }

  /// Internal workout plan generation
  static Future<WorkoutPlanModel> _generateWorkoutPlanInternal(
    UserModel user,
    String userId,
  ) async {
    final workoutPrompt = _buildWorkoutPlanPrompt(user);

    final requestBody = {
      'model': ConfigService.openAIModel,
      'messages': [
        {
          'role': 'system',
          'content': _getSystemPrompt(),
        },
        {
          'role': 'user',
          'content': workoutPrompt,
        },
      ],
      'temperature': ConfigService.openAITemperature,
      'max_tokens': ConfigService.openAIMaxTokens,
    };

    final response = await RateLimitService.makeApiCall(
      url: Uri.parse(ConfigService.openAIBaseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ConfigService.openAIApiKey}',
      },
      body: jsonEncode(requestBody),
      context: 'workout plan generation',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      _logger.i('Workout plan response received successfully');
      _logger.d('Raw AI response: $content');

      try {
        final workoutPlan =
            await _parseWorkoutPlanFromAI(content, user, userId);
        return workoutPlan;
      } catch (e) {
        if (e is ValidationException) {
          _logger.w(
              'Workout plan validation failed: ${e.message}. Regenerating...');
          throw e; // This will trigger retry
        }
        rethrow;
      }
    } else {
      _logger.e('API Error: ${response.statusCode} - ${response.body}');
      throw Exception(
          'Failed to generate workout plan: ${response.statusCode}');
    }
  }

  /// Build the prompt for workout plan generation
  static String _buildWorkoutPlanPrompt(UserModel user) {
    final prefs = user.preferences;

    // Determine workout schedule based on user preferences
    final int workoutDays = prefs.weeklyWorkoutDays;
    final List<int>? specificDays = prefs.specificWorkoutDays;
    
    // Build workout schedule description
    String workoutScheduleDescription;
    String restDayInstructions;
    
    if (specificDays != null && specificDays.isNotEmpty) {
      // User has selected specific days
      final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final selectedDayNames = specificDays.map((d) => dayNames[d - 1]).toList();
      final restDays = List.generate(7, (i) => i + 1)
          .where((d) => !specificDays.contains(d))
          .map((d) => dayNames[d - 1])
          .toList();
      
      workoutScheduleDescription = '''
- **Workout Days**: ${selectedDayNames.join(', ')} (${specificDays.length} days total)
- **Rest Days**: ${restDays.join(', ')} (${restDays.length} days total)''';
      
      restDayInstructions = '''
WORKOUT SCHEDULE (MUST FOLLOW EXACTLY):
- The user wants to workout on these specific days: ${selectedDayNames.join(', ')}
- The following days MUST be rest/recovery days: ${restDays.join(', ')}
- For rest days, set "restDay" to a string describing the recovery activities (e.g., "Active recovery day for muscle repair and growth")
- For workout days, set "restDay" to null
- Do NOT include workouts in the workouts array on rest days''';
    } else {
      // User has selected number of days per week
      final restDaysCount = 7 - workoutDays;
      workoutScheduleDescription = '''
- **Workout Days Per Week**: $workoutDays days
- **Rest Days Per Week**: $restDaysCount days''';
      
      restDayInstructions = '''
WORKOUT SCHEDULE (MUST FOLLOW EXACTLY):
- Generate a 7-day plan with exactly $workoutDays workout days and $restDaysCount rest/recovery days
- Distribute workout days evenly throughout the week for optimal recovery
- For rest days, set "restDay" to a string describing the recovery activities (e.g., "Active recovery day for muscle repair and growth")
- For workout days, set "restDay" to null
- Do NOT include workouts in the workouts array on rest days''';
    }

    return '''
Generate a personalized 7-day workout plan based on the following user preferences:

User Profile:
- Age: ${prefs.age}
- Gender: ${prefs.gender}
- Weight: ${prefs.weight} kg
- Height: ${prefs.height} cm
- Activity Level: ${_getActivityLevelDescription(prefs.activityLevel)}
- Fitness Goal: ${_getFitnessGoalDescription(prefs.fitnessGoal)}
- Preferred Workout Styles: ${prefs.preferredWorkoutStyles.join(', ')}
$workoutScheduleDescription

$restDayInstructions

CRITICAL PROGRAMMING REQUIREMENTS (MUST FOLLOW EXACTLY):
1. Each major muscle group MUST be trained at least 2× per week - NO EXCEPTIONS
2. Aim for 10–20 sets per muscle group weekly, split across multiple workouts (2–4 sessions, 2–3 exercises per session)
3. Each workout session MUST include: dynamic warm-up, 2–3 exercises per target muscle, cool-down/stretching
4. Use evidence-based rep and set ranges: 3–4 sets of 8–12 reps for muscle gain, 3–5 sets of 3–6 reps for strength
5. Program at least one full rest or active recovery day per week
6. Ensure progressive overload and sufficient rest between sets (60-180 seconds)
7. Every exercise must include sets, reps, tempo, rest time, and detailed form cues

MUSCLE GROUP TRAINING FREQUENCY (CRITICAL):
- Chest: Train 2-3 times per week with 2-3 exercises per session
- Back: Train 2-3 times per week with 2-3 exercises per session  
- Shoulders: Train 2-3 times per week with 2-3 exercises per session
- Biceps: Train 2-3 times per week with 2-3 exercises per session
- Triceps: Train 2-3 times per week with 2-3 exercises per session
- Legs (Quads/Hamstrings): Train 2-3 times per week with 2-3 exercises per session
- Core: Train 2-3 times per week with 2-3 exercises per session

VOLUME REQUIREMENTS (MUST MEET):
- Beginner: 8–10 weekly sets per muscle group
- Intermediate: 12–15 weekly sets per muscle group
- Advanced: 15–20 weekly sets per muscle group
- Each exercise: 3-4 sets minimum
- Each muscle group: 2-3 different exercises per session

WORKOUT SPLIT GUIDELINES:
- Beginner: Use full-body or upper/lower splits with 8–10 weekly sets per muscle group
- Intermediate: Use push/pull/legs or upper/lower splits with 12–15 weekly sets per muscle group  
- Advanced: Use specialized splits with 15–20 weekly sets per muscle group
- Never increase total weekly volume by more than 10–20% per month

EXERCISE SELECTION:
- Focus on compound movements for efficiency
- Include both strength and cardio elements as appropriate
- Vary exercises throughout the week to prevent plateaus
- Consider equipment availability and user preferences
- Ensure exercises are safe and appropriate for the user's age and fitness level

Please generate the workout plan in the following JSON format. IMPORTANT: All numeric values must be integers (not strings):
{
  "title": "Personalized Workout Plan",
  "description": "A comprehensive workout plan tailored to your preferences",
  "type": "ai_generated",
  "dailyWorkouts": [
    {
      "id": "day_1",
      "dayName": "Monday",
      "title": "Workout Title",
      "description": "Workout description with target muscle groups and training focus",
      "estimatedDuration": 45,
      "restDay": null,
      "workouts": [
        {
          "id": "workout_1",
          "title": "Workout Name",
          "description": "Detailed workout description with training focus",
          "difficulty": "beginner",
          "category": "strength",
          "estimatedDuration": 30,
          "exercises": [
            {
              "id": "exercise_1",
              "name": "Exercise Name",
              "description": "Detailed exercise description with form cues, tempo, and breathing instructions",
              "sets": 3,
              "reps": 12,
              "tempo": "2-0-2-0",
              "muscleGroups": ["Chest", "Triceps"],
              "order": 1,
              "equipment": "Dumbbells",
              "restTime": 60,
              "formCues": "Keep chest up, engage core, control the movement"
            }
          ]
        }
      ]
    },
    {
      "id": "day_2",
      "dayName": "Tuesday",
      "title": "Rest & Recovery",
      "description": "Active recovery day - light stretching, walking, or mobility work",
      "estimatedDuration": 20,
      "restDay": "Active recovery day for muscle repair and growth. Recommended activities: light stretching, walking, or mobility work.",
      "workouts": []
    }
  ]
}

VALIDATION CHECKLIST (MUST VERIFY BEFORE RESPONDING):
✓ CRITICAL: The plan has exactly $workoutDays workout days and ${7 - workoutDays} rest days as specified by the user
✓ Each major muscle group appears in at least 2 different workout days
✓ Each muscle group has 2-3 different exercises per session
✓ Each exercise has 3-4 sets minimum
✓ Total weekly sets per muscle group: 8-20 sets
✓ Each workout includes warm-up and cool-down
✓ Rest days have "restDay" set to a descriptive string and empty workouts array
✓ Every exercise includes tempo, rest time, and form cues
✓ CRITICAL: All numeric fields (sets, reps, estimatedDuration, restTime, order) are integers, NOT strings
✓ CRITICAL: JSON is valid and properly formatted

IMPORTANT REQUIREMENTS:
- Use realistic exercise names and descriptions
- Include proper form cues, tempo, and safety instructions for every exercise
- Vary exercises throughout the week to target all major muscle groups
- Include rest days or active recovery days where appropriate
- Make sure all exercises are suitable for the user's fitness level
- Include equipment requirements and alternatives if applicable
- Ensure progressive overload principles are built into the program
- Provide clear warm-up and cool-down recommendations for each session

FINAL REMINDER: If you generate a plan with only 1 workout per muscle group or less than 3 sets per exercise, you have FAILED to follow the requirements. Regenerate the plan.
''';
  }

  /// Get system prompt for workout generation
  static String _getSystemPrompt() {
    return '''You are a professional fitness trainer and workout planner with expertise in evidence-based exercise programming. Generate detailed, personalized workout plans in JSON format following scientific best practices.

Key responsibilities:
1. Create safe and effective workout routines based on exercise science
2. Consider user's fitness level, goals, and preferences
3. Provide clear exercise descriptions with form cues and safety instructions
4. Include appropriate rest periods and recovery protocols
5. Ensure exercises are suitable for the user's age and fitness level
6. Always respond with valid JSON format
7. CRITICAL: All numeric values (sets, reps, estimatedDuration, restTime, order) must be integers, NOT strings

Evidence-based programming guidelines (MANDATORY):
- Each major muscle group MUST be trained at least 2× per week - NEVER create plans with only 1 workout per muscle group
- Aim for 10–20 sets per muscle group weekly, split across multiple workouts (2-4 sessions)
- Use evidence-based rep and set ranges: 3–4 sets of 8–12 reps for muscle gain, 3–5 sets of 3–6 reps for strength
- Program at least one full rest or active recovery day per week
- Ensure progressive overload and sufficient rest between sets (60-180 seconds)
- Include proper form/safety guidance for every exercise
- Each muscle group must have 2-3 different exercises per session
- Each exercise must have minimum 3 sets (never less than 3 sets)

Workout structure guidelines:
- Each session: dynamic warm-up, 2–3 exercises per target muscle, cool-down/stretching
- Use Push/Pull/Legs, Upper/Lower, or Full-Body splits based on user level
- Beginner routines: 8–10 weekly sets, 1–2 exercises per muscle per session
- Intermediate/Advanced: Increase volume and variety as experience improves
- Never increase total weekly volume by more than 10–20% per month

Exercise guidelines:
- Use proper exercise names and terminology
- Include detailed form instructions with tempo and breathing cues
- Specify appropriate sets, reps, rest times, and equipment
- Focus on compound movements for efficiency
- Include both strength and cardio elements as appropriate
- Every exercise must list sets, reps, tempo, rest, and form cues

Safety first:
- Never recommend exercises that could be dangerous
- Consider user's physical limitations and injury history
- Include proper warm-up recommendations
- Suggest modifications for different fitness levels
- Advise against overtraining and excessive volume increases''';
  }

  /// Parse workout plan from AI response
  static Future<WorkoutPlanModel> _parseWorkoutPlanFromAI(
    String content,
    UserModel user,
    String userId,
  ) async {
    try {
      // Extract JSON from the response
      final jsonStart = content.indexOf('{');
      final jsonEnd = content.lastIndexOf('}') + 1;

      if (jsonStart == -1 || jsonEnd == 0) {
        throw ValidationException('No valid JSON found in AI response');
      }

      final jsonString = content.substring(jsonStart, jsonEnd);
      final jsonData = jsonDecode(jsonString);

      // Validate the JSON structure
      await _validateWorkoutPlanJson(jsonData);

      // Convert to WorkoutPlanModel
      return _convertJsonToWorkoutPlan(jsonData, user, userId);
    } catch (e) {
      _logger.e('Failed to parse workout plan: $e');
      throw ValidationException('Failed to parse workout plan: $e');
    }
  }

  /// Validate workout plan JSON structure
  static Future<void> _validateWorkoutPlanJson(
      Map<String, dynamic> json) async {
    final requiredFields = ['title', 'description', 'dailyWorkouts'];

    for (final field in requiredFields) {
      if (!json.containsKey(field)) {
        throw ValidationException('Missing required field: $field');
      }
    }

    if (json['dailyWorkouts'] is! List) {
      throw ValidationException('dailyWorkouts must be an array');
    }

    final dailyWorkouts = json['dailyWorkouts'] as List;
    if (dailyWorkouts.isEmpty) {
      throw ValidationException('dailyWorkouts cannot be empty');
    }

    // Validate each daily workout
    for (int i = 0; i < dailyWorkouts.length; i++) {
      final dailyWorkout = dailyWorkouts[i];
      if (dailyWorkout is! Map<String, dynamic>) {
        throw ValidationException('dailyWorkout[$i] must be an object');
      }

      final requiredDailyFields = [
        'id',
        'dayName',
        'title',
        'description',
        'workouts'
      ];
      for (final field in requiredDailyFields) {
        if (!dailyWorkout.containsKey(field)) {
          throw ValidationException(
              'Missing required field in dailyWorkout[$i]: $field');
        }
      }
    }
  }

  /// Convert JSON to WorkoutPlanModel
  static WorkoutPlanModel _convertJsonToWorkoutPlan(
    Map<String, dynamic> json,
    UserModel user,
    String userId,
  ) {
    final dailyWorkouts = (json['dailyWorkouts'] as List).map((dailyJson) {
      return DailyWorkout(
        id: dailyJson['id'] as String,
        dayName: dailyJson['dayName'] as String,
        title: dailyJson['title'] as String,
        description: dailyJson['description'] as String,
        workouts: (dailyJson['workouts'] as List).map((workoutJson) {
          return _convertJsonToWorkoutModel(workoutJson);
        }).toList(),
        estimatedDuration: _parseIntRequired(dailyJson['estimatedDuration'], 'estimatedDuration'),
        restDay: _parseRestDay(dailyJson['restDay']),
      );
    }).toList();

    // Determine approval status based on user type
    // Non-bodybuilders get auto-approved, bodybuilders need trainer approval
    final approvalStatus = user.preferences.isBodybuilder
        ? WorkoutPlanApprovalStatus.pending
        : WorkoutPlanApprovalStatus.approved;

    return WorkoutPlanModel(
      id: const Uuid().v4(),
      userId: userId,
      title: json['title'] as String,
      description: json['description'] as String,
      type: WorkoutPlanType.ai_generated,
      dailyWorkouts: dailyWorkouts,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      approvalStatus: approvalStatus,
      approvedAt: user.preferences.isBodybuilder ? null : DateTime.now(),
    );
  }

  /// Convert JSON to WorkoutModel
  static WorkoutModel _convertJsonToWorkoutModel(Map<String, dynamic> json) {
    return WorkoutModel(
      id: json['id'] as String? ?? const Uuid().v4(),
      title: json['title'] as String,
      description: json['description'] as String,
      trainerId: 'ai_trainer',
      trainerName: 'AI Fitness Coach',
      difficulty: _parseDifficulty(json['difficulty'] as String?),
      category: _parseCategory(json['category'] as String?),
      estimatedDuration: _parseIntRequired(json['estimatedDuration'], 'estimatedDuration'),
      exercises: (json['exercises'] as List).map((exerciseJson) {
        return _convertJsonToExercise(exerciseJson);
      }).toList(),
      tags: ['ai_generated', 'personalized'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Convert JSON to Exercise
  static Exercise _convertJsonToExercise(Map<String, dynamic> json) {
    try {
      return Exercise(
        id: json['id'] as String? ?? const Uuid().v4(),
        name: json['name'] as String,
        description: json['description'] as String,
        sets: _parseIntRequired(json['sets'], 'sets'),
        reps: _parseIntRequired(json['reps'], 'reps'),
        tempo: json['tempo'] as String?,
        duration: _safeParseInt(json['duration']),
        restTime: _safeParseInt(json['restTime']),
        equipment: json['equipment'] as String?,
        muscleGroups: List<String>.from(json['muscleGroups'] ?? []),
        order: _parseIntRequired(json['order'], 'order'),
        formCues: json['formCues'] as String?,
      );
    } catch (e) {
      _logger.e('Error converting exercise JSON: $e');
      _logger.e('Exercise JSON data: $json');
      rethrow;
    }
  }

  /// Safely parse an integer from dynamic value (handles both int and string)
  static int? _safeParseInt(dynamic value, {int? defaultValue}) {
    if (value == null) return defaultValue;
    
    if (value is int) return value;
    
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    
    if (value is double) return value.toInt();
    
    return defaultValue;
  }

  /// Parse an integer from dynamic value - throws error if not valid integer
  static int _parseIntRequired(dynamic value, String fieldName) {
    if (value == null) {
      throw ValidationException('Field "$fieldName" is null - AI must provide this value');
    }
    
    if (value is int) return value;
    
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        _logger.w('AI returned string "$value" for field "$fieldName" - should be integer');
        return parsed;
      } else {
        throw ValidationException('Field "$fieldName" contains invalid string "$value" - must be a valid integer');
      }
    }
    
    if (value is double) {
      _logger.w('AI returned double $value for field "$fieldName" - should be integer');
      return value.toInt();
    }
    
    throw ValidationException('Field "$fieldName" has unexpected type ${value.runtimeType} with value "$value" - must be integer');
  }

  /// Parse restDay field - handles both string and boolean values
  /// Returns a string description for rest days, or null for workout days
  static String? _parseRestDay(dynamic value) {
    if (value == null) return null;
    
    if (value is String) return value;
    
    // Handle case where AI returns a boolean instead of a string
    if (value is bool) {
      if (value) {
        return 'Rest and recovery day';
      }
      return null;
    }
    
    return null;
  }

  /// Parse difficulty string to enum
  static WorkoutDifficulty _parseDifficulty(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'beginner':
        return WorkoutDifficulty.beginner;
      case 'intermediate':
        return WorkoutDifficulty.intermediate;
      case 'advanced':
        return WorkoutDifficulty.advanced;
      default:
        return WorkoutDifficulty.beginner;
    }
  }

  /// Parse category string to enum
  static WorkoutCategory _parseCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'strength':
        return WorkoutCategory.strength;
      case 'cardio':
        return WorkoutCategory.cardio;
      case 'flexibility':
        return WorkoutCategory.flexibility;
      case 'hiit':
        return WorkoutCategory.hiit;
      case 'yoga':
        return WorkoutCategory.yoga;
      case 'pilates':
        return WorkoutCategory.pilates;
      default:
        return WorkoutCategory.strength;
    }
  }

  /// Get activity level description
  static String _getActivityLevelDescription(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sedentary (little to no exercise)';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active (light exercise 1-3 days/week)';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active (moderate exercise 3-5 days/week)';
      case ActivityLevel.veryActive:
        return 'Very Active (hard exercise 6-7 days/week)';
      case ActivityLevel.extremelyActive:
        return 'Extremely Active (very hard exercise, physical job)';
    }
  }

  /// Get fitness goal description
  static String _getFitnessGoalDescription(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return 'Weight Loss';
      case FitnessGoal.weightGain:
        return 'Weight Gain';
      case FitnessGoal.muscleGain:
        return 'Muscle Gain';
      case FitnessGoal.maintenance:
        return 'Maintenance';
      case FitnessGoal.endurance:
        return 'Endurance';
      case FitnessGoal.strength:
        return 'Strength';
    }
  }
}
