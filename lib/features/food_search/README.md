# Food Search Feature

This feature allows users to search for foods using the Open Food Facts API and add them to their daily nutritional intake.

## Features

- **Food Search**: Search for foods by name using the Open Food Facts database
- **Barcode Scanning**: Get product information by scanning barcodes
- **Nutrition Information**: Display comprehensive nutrition facts including calories, protein, carbs, fat, fiber, sugar, and sodium
- **Meal Integration**: Add foods to specific meal types (breakfast, lunch, dinner, snack)
- **Serving Size Adjustment**: Adjust serving sizes with a slider (0.5x to 3.0x)
- **Allergen Information**: Display allergen tags and dietary restrictions

## Implementation

### Files Structure

```
lib/features/food_search/
├── presentation/
│   ├── screens/
│   │   └── food_search_screen.dart
│   └── widgets/
│       ├── food_search_bar.dart
│       ├── food_product_card.dart
│       └── add_food_dialog.dart
└── README.md
```

### Key Components

1. **FoodSearchService**: Handles API calls to Open Food Facts
2. **FoodSearchScreen**: Main search interface
3. **FoodSearchBar**: Search input with debounced search
4. **FoodProductCard**: Displays food product information
5. **AddFoodDialog**: Allows users to select meal type and serving size

### API Integration

The feature uses the Open Food Facts API v3.24.0 with the following configuration:

- **User Agent**: "Moctar Nutrition"
- **Language**: English
- **Country**: United States
- **Search Fields**: Barcode, name, brands, images, nutrition, allergens, etc.

### Nutrition Data

Nutrition information is extracted from the Open Food Facts database and includes:

- Calories (kcal)
- Protein (g)
- Carbohydrates (g)
- Fat (g)
- Fiber (g)
- Sugar (g)
- Sodium (g)

### Usage

1. Navigate to the Food Search screen from the home screen
2. Enter a food name in the search bar
3. Browse search results with nutrition information
4. Tap on a food item to open the add dialog
5. Select meal type and adjust serving size
6. Add the food to your daily intake

## Dependencies

- `openfoodfacts: ^3.24.0` - Open Food Facts API client
- `provider: ^6.1.1` - State management
- `logger: ^2.0.2+1` - Logging

## Future Enhancements

- Barcode scanner integration
- Food favorites and history
- Nutrition goal tracking
- Meal planning integration
- Offline caching
- Multi-language support

## Notes

This is a minimal implementation for testing purposes. The feature currently shows a success message when adding foods but doesn't persist the data to the user's daily intake. Future versions will integrate with the existing meal planning and nutrition tracking systems.
