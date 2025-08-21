import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/onboarding_step.dart';

class OnboardingStepsConfig {
  static List<OnboardingStep> getSteps() {
    return [
      OnboardingStep(
        title: 'KICKSTART YOUR FITNESS JOURNEY',
        subtitle: 'Your journey to a healthier lifestyle starts here',
        icon: "arrow.json",
        showIconColor: false,
        color: AppConstants.primaryColor,
      ),
      OnboardingStep(
        title: 'Choose your Gender',
        subtitle: 'This will be used to calibrate your custom plan',
        icon: "weight.json",
        color: AppConstants.accentColor,
        showIconColor: false,
      ),
      OnboardingStep(
        title: 'Height & weight',
        subtitle: 'This will be used to calibrate your custom plan',
        icon: "weight.json",
        color: AppConstants.accentColor,
        showIconColor: false,
      ),
      OnboardingStep(
        title: 'Your Age',
        subtitle: 'This will be used to calculate your age',
        icon: "weight.json",
        color: AppConstants.accentColor,
        showIconColor: false,
      ),
      OnboardingStep(
        title: 'Desired Weight',
        subtitle: 'What is your target weight?',
        icon: "target.json",
        color: AppConstants.primaryColor,
        showIconColor: false,
      ),
      OnboardingStep(
        title: 'What is your primary objective?',
        subtitle: 'Choose your fitness goal',
        icon: "target.json",
        color: AppConstants.secondaryColor,
        showIconColor: false,
      ),
      OnboardingStep(
        title: 'How active are you?',
        subtitle: 'Select your activity level',
        icon: "run.json",
        color: AppConstants.warningColor,
      ),
      OnboardingStep(
        title: 'Any dietary restrictions?',
        subtitle: 'Select all that apply',
        icon: "diet.json",
        color: AppConstants.successColor,
      ),
      OnboardingStep(
        title: 'Preferred workout styles',
        subtitle: 'Choose your favorites',
        icon: "run.json",
        color: AppConstants.primaryColor,
      ),
      OnboardingStep(
        title: 'Weekly Workout Goal',
        subtitle: 'How often do you want to train?',
        icon: "calendar.json",
        color: AppConstants.secondaryColor,
      ),
      OnboardingStep(
        title: 'Food preferences',
        subtitle: 'Tell us what you like and don\'t like',
        icon: "prefs.json",
        color: AppConstants.successColor,
      ),
      OnboardingStep(
        title: 'Allergies & Intolerances',
        subtitle: 'Keep you safe and healthy',
        icon: "failed.json",
        color: AppConstants.errorColor,
      ),
      OnboardingStep(
        title: 'Meal Count & Timing',
        subtitle: 'Your eating schedule',
        icon: "recipes.json",
        color: AppConstants.accentColor,
        showIconColor: false,
      ),
      OnboardingStep(
        title: 'Batch Cooking Preferences',
        subtitle: 'Your meal preparation habits',
        icon: "diet.json",
        color: AppConstants.warningColor,
      ),
      OnboardingStep(
        title: 'Workout Previews',
        subtitle: 'Get workout previews on training days',
        icon: "run.json",
        color: AppConstants.primaryColor,
      ),
      OnboardingStep(
        title: 'Give us a rating',
        subtitle: 'Help us improve with your feedback',
        icon: "target.json",
        color: AppConstants.successColor,
        showIconColor: false,
      ),
    ];
  }

  static OnboardingStep getBMIStep() {
    return OnboardingStep(
      title: 'Your BMI',
      subtitle: 'Calculated from your height and weight to tailor your experience.',
      icon: "heartbeat.json",
      color: AppConstants.warningColor,
    );
  }
}
