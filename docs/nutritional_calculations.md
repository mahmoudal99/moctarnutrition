# Nutritional Target Calculations

This document outlines the nutritional target calculations used in the Moctar Nutrition app, based on the Mifflin-St Jeor equation and evidence-based recommendations.

## Calorie Target Calculation

### BMR Calculation (Mifflin-St Jeor Equation)

The app uses the Mifflin-St Jeor equation to calculate Basal Metabolic Rate (BMR):

**For Men:**
```
BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age(y) + 5
```

**For Women:**
```
BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age(y) - 161
```

### Activity Level Multipliers

BMR is multiplied by activity level factors to calculate Total Daily Energy Expenditure (TDEE):

- **Sedentary**: 1.2 (little or no exercise)
- **Lightly Active**: 1.35 (light exercise 1-3 days/week)
- **Moderately Active**: 1.55 (moderate exercise 3-5 days/week)
- **Very Active**: 1.725 (hard exercise 6-7 days/week)
- **Extremely Active**: 1.9 (very hard exercise, physical job)

### Goal Adjustments

The app applies goal-specific adjustments to TDEE:

- **Weight Loss**: Subtract 500 kcal/day (for ~0.5 kg/week loss)
- **Muscle Gain**: Add 300 kcal/day (moderate surplus)
- **Maintenance**: No adjustment
- **Endurance**: Add 200 kcal/day (performance surplus)
- **Strength**: Add 400 kcal/day (muscle building surplus)

### Safety Rails

- Minimum calories: 85% of BMR or gender-specific minimums (1200 kcal for females, 1500 kcal for males)
- Maximum surplus: 50% above TDEE

## Macronutrient Calculations

### Protein Requirements

Protein targets are calculated based on body weight and fitness goal:

- **Weight Loss**: 2.2 g/kg (2.4 g/kg for vegans)
- **Muscle Gain**: 1.6 g/kg (2.0 g/kg for vegans)
- **Maintenance**: 1.4 g/kg (1.8 g/kg for vegans)
- **Endurance**: 1.3 g/kg (1.6 g/kg for vegans)
- **Strength**: 1.7 g/kg (2.0 g/kg for vegans)

### Fat Requirements

- **Minimum**: 0.6 g/kg body weight or 20% of calories (whichever is higher)
- **Target**: 25% of calories (middle of 20-35% range)
- **Maximum**: 35% of calories

### Carbohydrate Requirements

- **Calculation**: Remaining calories after protein and fat allocation
- **Minimum**: 130g (for brain function)
- **Conversion**: 4 kcal per gram

### Caloric Values

- **Protein**: 4 kcal per gram
- **Carbohydrates**: 4 kcal per gram
- **Fat**: 9 kcal per gram

## Example Calculation

**Male, 30 years old, 80kg, 180cm, Moderately Active, Weight Loss Goal**

1. **BMR**: 10 × 80 + 6.25 × 180 - 5 × 30 + 5 = 1780 kcal
2. **TDEE**: 1780 × 1.55 = 2759 kcal
3. **Daily Target**: 2759 - 500 = 2259 kcal
4. **Protein**: 80 × 2.2 = 176g (704 kcal)
5. **Fat**: 2259 × 0.25 = 565 kcal (63g)
6. **Carbs**: 2259 - 704 - 565 = 990 kcal (248g)

## Implementation Notes

- All calculations are performed in the `CalorieCalculationService`
- Results are rounded to whole numbers for user display
- The app ensures minimum safe calorie levels are maintained
- Macro percentages are calculated and displayed to users
- Vegan users receive higher protein recommendations due to lower bioavailability

## Testing

The calculations are validated through comprehensive unit tests that verify:
- BMR calculations match Mifflin-St Jeor equation
- Activity multipliers are correctly applied
- Goal adjustments produce expected results
- Macro calculations follow 4-4-9 kcal/g rule
- Total macro calories equal daily target
- Safety rails are enforced
