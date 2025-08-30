import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/food_search_service.dart';
import '../widgets/food_search_bar.dart';
import '../widgets/food_product_card.dart';
import '../widgets/add_food_dialog.dart';

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<FoodProduct> _searchResults = [];
  bool _isLoading = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    // Initialize Open Food Facts API
    FoodSearchService.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchFoods(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _lastQuery = '';
      });
      return;
    }

    if (query == _lastQuery) return;

    setState(() {
      _isLoading = true;
      _lastQuery = query;
    });

    try {
      final results = await FoodSearchService.searchFoods(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching foods: $e')),
        );
      }
    }
  }

  void _onFoodSelected(FoodProduct food) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AddFoodDialog(food: food),
    );
    
    // If food was added successfully, return true to the home screen
    if (result == true) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Search'),
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: FoodSearchBar(
              controller: _searchController,
              onSearch: _searchFoods,
            ),
          ),
          
          // Search Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty && _lastQuery.isNotEmpty
                    ? const Center(
                        child: Text(
                          'No foods found. Try a different search term.',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : _searchResults.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 64,
                                  color: AppConstants.textTertiary,
                                ),
                                SizedBox(height: AppConstants.spacingM),
                                Text(
                                  'Search for foods to add to your daily intake',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppConstants.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.spacingM,
                            ),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final food = _searchResults[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
                                child: FoodProductCard(
                                  food: food,
                                  onTap: () => _onFoodSelected(food),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
