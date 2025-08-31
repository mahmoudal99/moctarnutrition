# Food Search Feature

This feature provides comprehensive food search and barcode scanning capabilities using the Open Food Facts API.

## Features

### 1. Text Search
- Search for foods by name using the Open Food Facts database
- Real-time search results with product information
- Filter and browse through search results

### 2. Barcode Scanner
- **NEW**: Scan barcodes on food products using your device's camera
- Automatically fetch product information from Open Food Facts
- View detailed nutrition information and product details
- Add scanned foods directly to your meal plan

## How to Use

### Text Search
1. Navigate to the Food Search screen
2. Type the name of the food you're looking for
3. Browse through search results
4. Tap on a food item to view details and add to your meal plan

### Barcode Scanner
1. **From Home Screen**: Tap the barcode scanner icon (📱) in the header
2. **From Food Search Screen**: 
   - Tap the barcode scanner icon (📱) in the app bar, or
   - Use the floating action button "Scan Barcode"
3. Point your camera at a food product's barcode
4. The app will automatically detect the barcode and fetch product information
5. Review the product details and nutrition information
6. Tap "Add to Meal Plan" to add it to your daily intake

## Screens

### FoodSearchScreen
- Main search interface with text search
- Search results display
- Access to barcode scanner

### BarcodeScannerScreen
- Camera interface for scanning barcodes
- Visual scanning overlay with frame
- Camera controls (pause/resume, switch camera)

### FoodDetailsScreen
- Comprehensive product information display
- Nutrition facts and serving sizes
- Allergen and ingredient information
- Nutri-Score and Eco-Score (when available)
- Integration with meal planning system

## Technical Details

### Dependencies
- `mobile_scanner`: For barcode scanning functionality
- `openfoodfacts`: For accessing the Open Food Facts API
- `provider`: For state management

### Permissions Required
- **Android**: `android.permission.CAMERA`
- **iOS**: Camera access (already configured in Info.plist)

### API Integration
- Uses Open Food Facts API v3
- Supports multiple languages and countries
- Fetches comprehensive product data including:
  - Basic product information
  - Nutrition facts
  - Allergens
  - Ingredients
  - Nutri-Score and Eco-Score
  - Product images

## Data Flow

1. **Barcode Detection**: Camera captures barcode image
2. **API Call**: Barcode sent to Open Food Facts API
3. **Product Fetch**: Product information retrieved and converted to app models
4. **Display**: Product details shown in FoodDetailsScreen
5. **Integration**: User can add food to meal plan using existing AddFoodDialog

## Error Handling

- Product not found: Shows dialog with option to retry
- Network errors: Displays error message with retry option
- Camera issues: Graceful fallback with user guidance

## Future Enhancements

- Offline barcode database caching
- Batch barcode scanning
- Product history and favorites
- Nutritional comparison tools
- Dietary restriction filtering
