# Home Feature

## Overview
The Home feature provides users with a comprehensive dashboard showing their daily nutrition and fitness data. It follows the design from the provided screenshot and includes real data integration.

## Components

### HomeScreen (`screens/home_screen.dart`)
The main home screen that displays:
- App header with logo and burned calories indicator
- Day selector for viewing different dates
- Calorie summary card with activity ring
- Nutrition goals cards (protein, carbs, fat)
- Floating action button for adding meals

### DaySelector (`widgets/day_selector.dart`)
A horizontal scrollable list showing days of the week with dates. Users can select different days to view data for those specific dates.

### CalorieSummaryCard (`widgets/calorie_summary_card.dart`)
Displays the main calorie information:
- Calories left for the day
- Activity bonus calories
- Activity ring showing calories burned

### ActivityRing (`widgets/activity_ring.dart`)
A circular progress indicator showing calories burned vs target, with a flame icon in the center.

### NutritionGoalsCard (`widgets/nutrition_goals_card.dart`)
Shows macronutrient targets in a paginated card layout:
- Protein left (grams)
- Carbs left (grams) 
- Fat left (grams)
- Each card has an icon and pagination dots

## Data Integration

The home screen integrates with:
- `AuthProvider` for user data
- `CalorieCalculationService` for nutrition targets
- User preferences for personalized goals

## Navigation

The home screen is accessible via:
- `/home` route
- Bottom navigation "Home" tab
- Default landing page for authenticated users

## Future Enhancements

- [ ] Integrate with actual meal logging data
- [ ] Add activity tracking integration
- [ ] Implement meal logging flow from FAB
- [ ] Add data persistence for daily tracking
- [ ] Implement notifications for meal reminders
