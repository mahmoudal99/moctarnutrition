# Onboarding Feature - Refactored Structure

This directory contains the refactored onboarding feature, organized into separate classes and files for better maintainability and code organization.

## Directory Structure

```
presentation/
├── models/
│   └── onboarding_step.dart          # OnboardingStep model class
├── screens/
│   ├── onboarding_screen.dart        # Original onboarding screen (to be replaced)
│   └── onboarding_screen_refactored.dart  # New refactored onboarding screen
├── utils/
│   ├── onboarding_step_builder.dart  # Step content building logic
│   └── onboarding_steps_config.dart  # Step configuration and definitions
├── widgets/
│   ├── onboarding_navigation_buttons.dart  # Back/Next navigation buttons
│   ├── onboarding_progress_indicator.dart  # Progress bar and step counter
│   ├── onboarding_step_header.dart   # Step header with icon, title, subtitle
│   └── onboarding_step_page.dart     # Individual step page wrapper
└── steps/                            # Individual step components
    ├── onboarding_welcome_step.dart
    ├── onboarding_gender_step.dart
    ├── onboarding_height_weight_step.dart
    ├── onboarding_age_step.dart
    ├── onboarding_bmi_step.dart
    ├── onboarding_fitness_goal_step.dart
    ├── onboarding_activity_level_step.dart
    ├── onboarding_dietary_restrictions_step.dart
    ├── onboarding_workout_styles_step.dart
    ├── onboarding_weekly_workout_goal_step.dart
    ├── onboarding_food_preferences_step.dart
    ├── onboarding_allergies_step.dart
    ├── onboarding_meal_timing_step.dart
    ├── onboarding_batch_cooking_step.dart
    └── onboarding_workout_notifications_step.dart
```

## Key Components

### Models
- **OnboardingStep**: Data model for individual onboarding steps with title, subtitle, icon, and color

### Utils
- **OnboardingStepBuilder**: Static utility class that handles building step content based on step index
- **OnboardingStepsConfig**: Configuration class that defines all onboarding steps and their properties
- **OnboardingData**: Data container class that holds all user input during onboarding

### Widgets
- **OnboardingProgressIndicator**: Displays progress bar and step counter
- **OnboardingStepHeader**: Renders step icon, title, and subtitle with animations
- **OnboardingStepPage**: Wrapper for individual step pages with animations
- **OnboardingNavigationButtons**: Handles Back/Next navigation with validation

### Main Screen
- **OnboardingScreenRefactored**: Main onboarding screen that orchestrates all components

## Benefits of Refactoring

1. **Separation of Concerns**: Each component has a single responsibility
2. **Reusability**: Components can be reused in other parts of the app
3. **Testability**: Individual components can be tested in isolation
4. **Maintainability**: Easier to modify and extend individual components
5. **Readability**: Code is more organized and easier to understand
6. **Scalability**: Easy to add new steps or modify existing ones

## Migration Guide

To use the refactored version:

1. Replace the import in your router or main app file:
   ```dart
   // Old
   import 'features/onboarding/presentation/screens/onboarding_screen.dart';
   
   // New
   import 'features/onboarding/presentation/screens/onboarding_screen.dart';
   ```

2. Update the class name:
   ```dart
   // Old
   OnboardingScreen()
   
   // New
   OnboardingScreenRefactored()
   ```

## Adding New Steps

1. Create a new step widget in the `steps/` directory
2. Add the step configuration to `OnboardingStepsConfig.getSteps()`
3. Add the step content building logic to `OnboardingStepBuilder.buildStepContent()`
4. Update the step indices in the main screen if needed

## Data Flow

1. **OnboardingScreenRefactored** manages the overall state and navigation
2. **OnboardingData** holds all user input data
3. **OnboardingStepBuilder** creates step content based on current step index
4. Individual step widgets handle their own UI and user interactions
5. State changes are propagated back to the main screen via callbacks
