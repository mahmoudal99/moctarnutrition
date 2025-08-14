import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/services/protein_calculation_service.dart';
import '../../../../shared/services/calorie_calculation_service.dart';
import '../../../../shared/services/user_local_storage_service.dart';

class ProteinCalculationScreen extends StatefulWidget {
  const ProteinCalculationScreen({super.key});

  @override
  State<ProteinCalculationScreen> createState() =>
      _ProteinCalculationScreenState();
}

class _ProteinCalculationScreenState extends State<ProteinCalculationScreen>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  bool _isCalculating = true;
  bool _showResults = false;
  ProteinTargets? _proteinTargets;
  CalorieTargets? _calorieTargets;
  String _currentStep = 'Analyzing your profile...';
  double _progress = 0.0;

  final List<String> _calculationSteps = [
    'Analyzing your profile...',
    'Calculating body composition...',
    'Determining protein needs...',
    'Optimizing for your goals...',
    'Creating meal distribution...',
    'Finalizing recommendations...',
  ];

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _startCalculation();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _startCalculation() async {
    _loadingController.repeat();
    _progressController.forward();

    // Simulate calculation steps
    for (int i = 0; i < _calculationSteps.length; i++) {
      await Future.delayed(Duration(milliseconds: 600 + (i * 200)));
      if (mounted) {
        setState(() {
          _currentStep = _calculationSteps[i];
          _progress = (i + 1) / _calculationSteps.length;
        });
      }
    }

    // Add a timeout to prevent getting stuck
    final calculationTimeout = Future.delayed(const Duration(seconds: 10));
    final calculationFuture = _performCalculations();

    try {
      await Future.any([calculationFuture, calculationTimeout]);
    } catch (e) {
      print('Calculation timeout or error: $e');
      if (mounted) {
        setState(() {
          _isCalculating = false;
          _showResults = true;
        });
      }
    }
  }

  Future<void> _performCalculations() async {
    try {
      print('Starting protein calculation with onboarding data...');

      // Get onboarding data from the onboarding service
      final onboardingData = await _getOnboardingData();

      if (onboardingData != null) {
        final proteinTargets =
            ProteinCalculationService.calculateProteinTargets(onboardingData);
        print('Protein calculation completed: ${proteinTargets.dailyTarget}g');

        print('Starting calorie calculation...');
        final calorieTargets =
            CalorieCalculationService.calculateCalorieTargets(onboardingData);
        print(
            'Calorie calculation completed: ${calorieTargets.dailyTarget} calories');

        // Store the calculated targets for later use when user signs up
        await _storeCalculatedTargets(proteinTargets, calorieTargets);

        if (mounted) {
          setState(() {
            _proteinTargets = proteinTargets;
            _calorieTargets = calorieTargets;
            _isCalculating = false;
          });
          print('State updated: _isCalculating = false');

          // Show results after a brief pause
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            setState(() {
              _showResults = true;
            });
            print('Results shown: _showResults = true');
          }
        }
      } else {
        print('No onboarding data available');
        if (mounted) {
          setState(() {
            _isCalculating = false;
            _showResults = true;
          });
        }
      }
    } catch (e, stackTrace) {
      print('Error during calculation: $e');
      print('Stack trace: $stackTrace');

      // Even if there's an error, we should still show something
      if (mounted) {
        setState(() {
          _isCalculating = false;
          _showResults = true;
        });
      }
    }
  }

  Future<UserModel?> _getOnboardingData() async {
    try {
      // Get the onboarding data that was just collected using UserLocalStorageService
      final userLocalStorageService = UserLocalStorageService();
      final user = await userLocalStorageService.loadUser();

      if (user != null) {
        print('Found onboarding user data:');
        print('  Fitness Goal: ${user.preferences.fitnessGoal}');
        print('  Weight: ${user.preferences.weight}kg');
        print('  Height: ${user.preferences.height}cm');
        print('  Age: ${user.preferences.age}');
        print('  Gender: ${user.preferences.gender}');
        print(
            '  Dietary Restrictions: ${user.preferences.dietaryRestrictions}');
        print('  Workout Styles: ${user.preferences.preferredWorkoutStyles}');
        return user;
      } else {
        print('No onboarding user data found');
        return null;
      }
    } catch (e) {
      print('Error getting onboarding data: $e');
      return null;
    }
  }

  Future<void> _storeCalculatedTargets(
      ProteinTargets proteinTargets, CalorieTargets calorieTargets) async {
    // Store the calculated targets in SharedPreferences for later use
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'temp_protein_targets', jsonEncode(proteinTargets.toJson()));
    await prefs.setString(
        'temp_calorie_targets', jsonEncode(calorieTargets.toJson()));
    print('Calculated targets stored for later use');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            children: [
              if (_isCalculating) _buildLoadingSection(),
              if (!_isCalculating && _showResults) _buildResultsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Loading animation
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(60),
              boxShadow: AppConstants.shadowM,
            ),
            child: Lottie.asset(
              'assets/animations/loading.json',
              controller: _loadingController,
              width: 80,
              height: 80,
            ),
          ),

          const SizedBox(height: AppConstants.spacingXL),

          // Title
          Text(
            'Calculating Your Nutrition Targets',
            style: AppTextStyles.heading3.copyWith(
              color: AppConstants.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppConstants.spacingM),

          // Current step
          Text(
            _currentStep,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppConstants.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppConstants.spacingXL),

          // Progress bar
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: AppConstants.textTertiary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppConstants.primaryGradient,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppConstants.spacingM),

          // Progress percentage
          Text(
            '${(_progress * 100).round()}%',
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_proteinTargets == null) return const SizedBox.shrink();

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppConstants.primaryGradient,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: AppConstants.shadowM,
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      size: 40,
                      color: AppConstants.surfaceColor,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingL),
                  Text(
                    'Your Nutrition Targets',
                    style: AppTextStyles.heading3,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  Text(
                    'Personalized for ${_proteinTargets!.fitnessGoal}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.spacingXL),

            // Daily target cards
            _buildProteinTargetCard(),

            const SizedBox(height: AppConstants.spacingL),

            _buildCalorieTargetCard(),

            const SizedBox(height: AppConstants.spacingL),

            // Meal distribution
            _buildMealDistributionSection(),

            const SizedBox(height: AppConstants.spacingL),

            // Macro breakdown
            _buildMacroBreakdownSection(),

            const SizedBox(height: AppConstants.spacingL),

            // Recommendations
            _buildRecommendationsSection(),

            const SizedBox(height: AppConstants.spacingXL),

            // Continue button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Continue to Subscription',
                onPressed: () {
                  context.go('/subscription');
                },
                type: ButtonType.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProteinTargetCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        gradient: AppConstants.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: AppConstants.shadowM,
      ),
      child: Column(
        children: [
          Text(
            '${_proteinTargets!.dailyTarget}g',
            style: AppTextStyles.heading1.copyWith(
              color: AppConstants.surfaceColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Daily Protein Target',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppConstants.surfaceColor.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTargetDetail(
                '${_proteinTargets!.proteinPerKg.toStringAsFixed(1)}g/kg',
                'Per kg',
              ),
              _buildTargetDetail(
                '${_proteinTargets!.proteinPerLb.toStringAsFixed(1)}g/lb',
                'Per lb',
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Based on ${_proteinTargets!.weightBase} (${_proteinTargets!.baseWeight.toStringAsFixed(1)}kg)',
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.surfaceColor.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieTargetCard() {
    if (_calorieTargets == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        gradient: AppConstants.secondaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: AppConstants.shadowM,
      ),
      child: Column(
        children: [
          Text(
            '${_calorieTargets!.dailyTarget}',
            style: AppTextStyles.heading1.copyWith(
              color: AppConstants.surfaceColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Daily Calorie Target',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppConstants.surfaceColor.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTargetDetail(
                '${_calorieTargets!.rmr}',
                'RMR',
              ),
              _buildTargetDetail(
                '${_calorieTargets!.tdee}',
                'TDEE',
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            '${_calorieTargets!.activityLevel} • ${_calorieTargets!.bodyFatPercentage.toStringAsFixed(1)}% body fat',
            style: AppTextStyles.caption.copyWith(
              color: AppConstants.surfaceColor.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTargetDetail(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppConstants.surfaceColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppConstants.surfaceColor.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildMealDistributionSection() {
    if (_proteinTargets!.mealDistribution == null)
      return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meal Distribution',
          style: AppTextStyles.heading4,
        ),
        const SizedBox(height: AppConstants.spacingM),
        ..._proteinTargets!.mealDistribution!
            .map((meal) => _buildMealCard(meal)),
      ],
    );
  }

  Widget _buildMealCard(MealProteinDistribution meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '${meal.mealNumber}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.mealName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${meal.proteinTarget}g protein',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingS,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
            ),
            child: Text(
              '${meal.proteinTarget}g',
              style: AppTextStyles.caption.copyWith(
                color: AppConstants.surfaceColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBreakdownSection() {
    if (_calorieTargets == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Macronutrient Breakdown',
          style: AppTextStyles.heading4,
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildMacroCard('Protein', _calorieTargets!.macros.protein,
            AppConstants.primaryColor),
        const SizedBox(height: AppConstants.spacingS),
        _buildMacroCard(
            'Fat', _calorieTargets!.macros.fat, AppConstants.warningColor),
        const SizedBox(height: AppConstants.spacingS),
        _buildMacroCard('Carbohydrates', _calorieTargets!.macros.carbs,
            AppConstants.successColor),
      ],
    );
  }

  Widget _buildMacroCard(String name, MacroNutrient macro, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${macro.grams}g • ${macro.calories} cal',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingS,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
            ),
            child: Text(
              '${macro.percentage}%',
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    final allRecommendations = <String>[];

    // Add protein recommendations
    allRecommendations.addAll(_proteinTargets!.recommendations);

    // Add calorie recommendations
    if (_calorieTargets != null) {
      allRecommendations.addAll(_calorieTargets!.recommendations);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommendations',
          style: AppTextStyles.heading4,
        ),
        const SizedBox(height: AppConstants.spacingM),
        ...allRecommendations
            .map((recommendation) => _buildRecommendationItem(recommendation)),
      ],
    );
  }

  Widget _buildRecommendationItem(String recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Text(
              recommendation,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppConstants.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
