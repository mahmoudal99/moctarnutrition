import '../../../../shared/enums/subscription_plan.dart';
import '../steps/onboarding_bodybuilding_goal_step.dart';

/// Maps bodybuilding goals selected during onboarding to training programs
/// for targeted upselling in the subscription screen
class BodybuildingGoalMapper {
  /// Maps a bodybuilding goal to its corresponding training program
  static TrainingProgram mapGoalToProgram(BodybuildingGoal goal) {
    switch (goal) {
      case BodybuildingGoal.newToBodybuilding:
        return TrainingProgram.beginner;
      case BodybuildingGoal.photoshootPrep:
        return TrainingProgram.photoshoot;
      case BodybuildingGoal.winterTransformation:
        return TrainingProgram.winter;
      case BodybuildingGoal.sixMonthPlan:
        return TrainingProgram.summer;
      case BodybuildingGoal.couplePlan:
        return TrainingProgram.couple;
    }
  }

  /// Gets the recommended program index for the subscription screen
  /// Returns the index to focus on in the PageView
  static int getRecommendedProgramIndex(BodybuildingGoal? goal) {
    if (goal == null) return 0;
    
    final program = mapGoalToProgram(goal);
    
    // Map programs to their order in the subscription screen
    // This will need to match the order in TrainingProgramTier.getTrainingProgramTiers()
    switch (program) {
      case TrainingProgram.beginner:
        return 0; // First card
      case TrainingProgram.photoshoot:
        return 1; // Second card
      case TrainingProgram.winter:
        return 2; // Third card
      case TrainingProgram.summer:
        return 3; // Fourth card
      case TrainingProgram.couple:
        return 4; // Fifth card
      case TrainingProgram.bodybuilding:
      case TrainingProgram.essential:
        return 0; // Default
    }
  }
}
