# Meal Prep Feature - Refactored Structure

This document outlines the refactored structure of the meal prep feature, which has been separated into distinct components for better maintainability and debugging.

## Overview

The meal prep feature has been refactored to separate:
1. **Meal Plan Viewing** - For users to view their generated meal plans
2. **Admin Setup Flow** - For admins to generate meal plans
3. **Shared Components** - Reusable widgets and utilities

## Directory Structure

```
lib/features/meal_prep/
├── presentation/
│   ├── screens/
│   │   ├── meal_prep_screen.dart (refactored main screen)
│   │   ├── meal_prep_demo.dart (demo screen)
│   │   └── meal_detail_screen.dart
│   └── widgets/
│       ├── meal_plan_view.dart (main meal plan display)
│       ├── nutrition_summary_card.dart
│       ├── meal_day_card.dart
│       ├── meal_card.dart
│       ├── admin_meal_setup_flow.dart (admin setup flow)
│       ├── waiting_for_meal_plan.dart
│       ├── shared/
│       │   └── meal_prep_widgets.dart (reusable components)
│       └── setup_steps/
│           ├── goal_selection_step.dart
│           ├── meal_frequency_step.dart
│           ├── calories_step.dart
│           ├── cheat_day_step.dart
│           ├── plan_duration_step.dart
│           └── final_review_step.dart
```

## Components

### 1. Meal Plan Viewing Components

#### `MealPlanView`
- **Purpose**: Main container for displaying a complete meal plan
- **Usage**: Used when a meal plan exists and needs to be displayed
- **Features**: 
  - Shows nutrition summary
  - Lists all meal days
  - Handles meal tap events

#### `NutritionSummaryCard`
- **Purpose**: Displays overall nutrition information
- **Features**:
  - Total calories, protein, carbs
  - Color-coded nutrition cards
  - Clean, card-based design

#### `MealDayCard`
- **Purpose**: Displays a single day's meals
- **Features**:
  - Expandable card design
  - Shows day number and total calories
  - Contains individual meal cards

#### `MealCard`
- **Purpose**: Displays individual meal information
- **Features**:
  - Meal type icons and colors
  - Nutrition information (protein, carbs, fat)
  - "View Recipe" button
  - Navigation to meal detail screen

### 2. Admin Setup Flow Components

#### `AdminMealSetupFlow`
- **Purpose**: Handles the complete meal plan generation process
- **Features**:
  - Multi-step setup process
  - Progress tracking
  - Loading states
  - AI meal plan generation

#### Setup Steps
Each step is a separate widget for better maintainability:

- **`GoalSelectionStep`**: Choose nutrition goal (lose fat, build muscle, etc.)
- **`MealFrequencyStep`**: Select number of meals per day
- **`CaloriesStep`**: Set daily calorie target
- **`CheatDayStep`**: Choose cheat day (optional)
- **`PlanDurationStep`**: Set plan rotation and reminders
- **`FinalReviewStep`**: Review all selections before generation

### 3. Shared Components

#### `MealPrepWidgets`
Contains reusable widgets:

- **`MealInfoCard`**: Standardized card for meal information
- **`NutritionChip`**: Small nutrition display chips
- **`MealPrepProgressIndicator`**: Progress bar with message
- **`SectionHeader`**: Section headers with optional actions
- **`EmptyStateWidget`**: Empty state displays

#### `WaitingForMealPlan`
- **Purpose**: Shows when users are waiting for admin to generate meal plan
- **Features**: Clear messaging and visual indicators

## Usage

### For Users (Viewing Meal Plans)
```dart
// Show existing meal plan
if (mealPlan != null) {
  return MealPlanView(
    mealPlan: mealPlan,
    onMealTap: () => handleMealTap(),
  );
}

// Show waiting state
return const WaitingForMealPlan();
```

### For Admins (Generating Meal Plans)
```dart
// Show admin setup flow
return AdminMealSetupFlow(
  onMealPlanGenerated: () => handleMealPlanGenerated(),
);
```

### Main Screen Logic
```dart
@override
Widget build(BuildContext context) {
  if (_showAdminSetup) {
    return AdminMealSetupFlow(
      onMealPlanGenerated: _onMealPlanGenerated,
    );
  }

  if (_currentMealPlan != null) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meal Plan')),
      body: MealPlanView(
        mealPlan: _currentMealPlan!,
        onMealTap: _onMealTap,
      ),
    );
  }

  return const WaitingForMealPlan();
}
```

## Benefits of Refactoring

1. **Separation of Concerns**: Meal viewing and admin setup are now separate
2. **Reusability**: Components can be reused across different screens
3. **Maintainability**: Each component has a single responsibility
4. **Testability**: Individual components can be tested in isolation
5. **Debugging**: Easier to identify and fix issues in specific components
6. **Future Changes**: Adding new features or modifying existing ones is simpler

## Migration Guide

The refactoring is complete! The main `MealPrepScreen` has been updated with the new modular structure.

1. The original screen has been replaced with the refactored version
2. All imports have been updated to use the new component structure
3. Test each component individually using the demo screen
4. Use the new shared widgets for any customizations

## Future Enhancements

- Add more shared widgets as needed
- Create additional setup steps for advanced features
- Implement component-level testing
- Add animation transitions between states
- Create theme-aware components 