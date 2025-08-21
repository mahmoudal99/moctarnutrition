# Workouts Feature - Refactored Structure

This directory contains the refactored workouts feature with improved separation of concerns and better maintainability.

## Structure

### Controllers
- **`controllers/workout_controller.dart`** - Handles business logic for workout plan loading and management
- **`controllers/workout_scroll_controller.dart`** - Manages scroll behavior and floating toggle animations

### Services
- **`services/workout_notification_service.dart`** - Handles workout notification scheduling

### Widgets
- **`widgets/workout_view_builder.dart`** - Builds different workout view states (loading, error, empty)
- **`widgets/floating_toggle_widget.dart`** - Floating toggle component for view switching
- **`widgets/day_view_widget.dart`** - Day view component showing today's workout or no workout state
- **`widgets/week_view_widget.dart`** - Week view component showing the weekly workout plan

### Screens
- **`screens/workouts_screen.dart`** - Main screen that orchestrates all components

## Benefits of Refactoring

1. **Separation of Concerns**: Business logic, UI components, and services are now properly separated
2. **Reusability**: Individual widgets can be reused in other parts of the app
3. **Testability**: Each component can be tested independently
4. **Maintainability**: Easier to modify and extend individual components
5. **Readability**: Smaller, focused files are easier to understand

## Component Responsibilities

### WorkoutController
- Load workout plans for users
- Handle user authentication checks
- Manage workout plan refresh logic
- Determine when to reload workout plans

### WorkoutScrollController
- Manage scroll behavior
- Handle floating toggle animations
- Control scroll threshold detection

### WorkoutNotificationService
- Schedule workout notifications
- Handle notification permission checks
- Manage notification state

### WorkoutViewBuilder
- Build loading states
- Build error states
- Build empty states

### FloatingToggleWidget
- Display floating toggle for view switching
- Handle toggle animations
- Manage toggle positioning

### DayViewWidget
- Display today's workout
- Show no workout state
- Handle day view interactions

### WeekViewWidget
- Display weekly workout plan
- Handle edit mode vs normal mode
- Manage workout card rendering

## Usage

The main `WorkoutsScreen` now acts as a coordinator that:
1. Uses `WorkoutController` for business logic
2. Uses `WorkoutScrollController` for scroll management
3. Uses `WorkoutViewBuilder` for state management
4. Uses individual widgets for UI rendering

This creates a clean, maintainable architecture that follows Flutter best practices. 