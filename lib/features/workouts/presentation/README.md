# Workouts Feature

This feature provides workout management functionality including workout plans, daily workouts, and exercise tracking.

## Features

### Workout Plan Management
- View weekly workout plans
- Daily workout details
- Exercise tracking and progress

### Edit Mode with Drag & Drop
- **Edit Mode**: Toggle edit mode to rearrange workout schedules
- **Drag & Drop**: Drag workout cards between days to swap schedules
- **Visual Feedback**: Clear visual indicators during drag operations
- **Save/Cancel**: Save changes to cloud and local storage or cancel to revert

## Components

### Screens
- `workouts_screen.dart` - Main workouts screen with edit mode
- `workout_details_screen.dart` - Detailed workout view
- `add_workout_screen.dart` - Add new workout
- `add_exercise_screen.dart` - Add exercises to workouts

### Widgets
- `daily_workout_card.dart` - Standard workout card display
- `draggable_workout_card.dart` - Draggable version for edit mode
- `droppable_day_area.dart` - Drop target for workout cards
- `edit_mode_header.dart` - Edit mode controls (save/cancel)
- `workout_app_header.dart` - App header with workout messages
- `view_toggle.dart` - Toggle between day/week views

### Edit Mode Workflow
1. User taps edit button to enter edit mode
2. Workout cards become draggable with visual indicators
3. User can drag cards between days to swap schedules
4. Visual feedback shows valid drop zones
5. User can save changes or cancel to revert

### Data Flow
- Changes are made locally in edit mode
- Only saved to cloud/local storage when user confirms
- Original data is preserved until save/cancel
- Real-time UI updates during drag operations

## Usage

```dart
// Enter edit mode
workoutProvider.enterEditMode();

// Save changes
await workoutProvider.saveEditModeChanges();

// Cancel changes
workoutProvider.cancelEditMode();
```

## State Management

The workout functionality uses Provider pattern with `WorkoutProvider` managing:
- Current workout plan
- Edit mode state
- Original data for cancellation
- Loading and error states 