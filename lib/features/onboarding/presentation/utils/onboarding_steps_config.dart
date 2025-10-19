import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/onboarding_step.dart';

class OnboardingStepsConfig {
  static List<OnboardingStep> getSteps() {
    return [
      OnboardingStep(
        title: 'WELCOME TO MOCTAR NUTRITION',
        subtitle: 'Transform your body, transform your life.',
        icon: "arrow.json",
        showIconColor: false,
        color: AppConstants.primaryColor,
        highlightedWords: ['MOCTAR', 'NUTRITION'],
      ),
      OnboardingStep(
        title: 'Start with You',
        subtitle: 'Choose your gender to personalize your fitness journey.',
        icon: "gender.json",
        color: AppConstants.accentColor,
        showIconColor: false,
        highlightedWords: ['You'],
      ),
      OnboardingStep(
        title: 'Height & Weight',
        subtitle: 'Your height and weight help us tailor your progress plan.',
        icon: "weight.json",
        color: AppConstants.errorColor,
        showIconColor: false,
        highlightedWords: ['Height', 'Weight'],
      ),
      OnboardingStep(
        title: 'Your Age',
        subtitle: 'Tell us your age to build workouts that matches your energy.',
        icon: "weight.json",
        color: AppConstants.warningColor,
        showIconColor: false,
        highlightedWords: ['Age'],
      ),
      OnboardingStep(
        title: 'Desired Weight',
        subtitle: 'What is your target weight?',
        icon: "target.json",
        color: AppConstants.proteinColor,
        showIconColor: false,
        highlightedWords: ['Desired'],
      ),
      OnboardingStep(
        title: 'What is your primary objective?',
        subtitle: 'Choose your fitness goal',
        icon: "target.json",
        color: AppConstants.carbsColor,
        showIconColor: false,
        highlightedWords: ['objective'],
      ),
      OnboardingStep(
        title: 'How active are you?',
        subtitle: 'Select your activity level',
        icon: "run.json",
        color: AppConstants.fatColor,
        highlightedWords: ['active'],
      ),
      OnboardingStep(
        title: 'Any dietary restrictions?',
        subtitle: 'Select all that apply',
        icon: "diet.json",
        color: AppConstants.successColor,
        highlightedWords: ['dietary'],
      ),
      OnboardingStep(
        title: 'Preferred workout styles',
        subtitle: 'Choose your favorites',
        icon: "run.json",
        color: AppConstants.primaryColor,
        highlightedWords: ['workout', 'styles'],
      ),
      OnboardingStep(
        title: 'Weekly Workout Goal',
        subtitle: 'How often do you want to train?',
        icon: "calendar.json",
        color: AppConstants.secondaryColor,
        highlightedWords: ['Goal'],
      ),
      OnboardingStep(
        title: 'Food preferences',
        subtitle: 'Tell us what you like and don\'t like',
        icon: "prefs.json",
        color: AppConstants.successColor,
        highlightedWords: ['preferences'],
      ),
      OnboardingStep(
        title: 'Allergies & Intolerances',
        subtitle: 'Keep you safe and healthy',
        icon: "failed.json",
        color: AppConstants.errorColor,
        highlightedWords: ['Allergies'],
      ),
      OnboardingStep(
        title: 'Meal Count & Timing',
        subtitle: 'Your eating schedule',
        icon: "recipes.json",
        color: AppConstants.accentColor,
        showIconColor: false,
        highlightedWords: ['Timing'],
      ),
      OnboardingStep(
        title: 'Batch Cooking Preferences',
        subtitle: 'Your meal preparation habits',
        icon: "diet.json",
        color: AppConstants.warningColor,
        highlightedWords: ['Cooking'],
      ),
      OnboardingStep(
        title: 'Workout Previews',
        subtitle: 'Get workout previews on training days',
        icon: "run.json",
        color: AppConstants.primaryColor,
        highlightedWords: ['Previews'],
      ),
      OnboardingStep(
        title: 'Help Us Grow!',
        subtitle: 'Help us improve with your feedback',
        icon: "rating.json",
        color: AppConstants.successColor,
        showIconColor: false,
        highlightedWords: ['rating'],
      ),
    ];
  }

  static OnboardingStep getBMIStep() {
    return OnboardingStep(
      title: 'Your BMI',
      subtitle:
          'Calculated from your height and weight to tailor your experience.',
      icon: "heartbeat.json",
      color: AppConstants.warningColor,
      highlightedWords: ['BMI'],
    );
  }
}
