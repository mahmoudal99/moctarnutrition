import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/user_model.dart';
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
  late ConfettiController _confettiController;

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

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    _startCalculation();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _progressController.dispose();
    _confettiController.dispose();
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

      // Get onboarding data from the onboarding service
      final onboardingData = await _getOnboardingData();

      if (onboardingData != null) {
        final proteinTargets =
            ProteinCalculationService.calculateProteinTargets(onboardingData);

        final calorieTargets =
            CalorieCalculationService.calculateCalorieTargets(onboardingData);

        // Store the calculated targets for later use when user signs up
        await _storeCalculatedTargets(proteinTargets, calorieTargets);

        if (mounted) {
          setState(() {
            _proteinTargets = proteinTargets;
            _calorieTargets = calorieTargets;
            _isCalculating = false;
          });

          // Show results after a brief pause
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            setState(() {
              _showResults = true;
            });
            // Trigger confetti animation
            _confettiController.play();
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isCalculating = false;
            _showResults = true;
          });
        }
      }
    } catch (e, stackTrace) {

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
        return user;
      } else {
        return null;
      }
    } catch (e) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Stack(
        children: [
          SafeArea(
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
          // Confetti widget positioned to cover the entire screen
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Color(0xFFE91E63), // Pink
                Color(0xFF9C27B0), // Purple
                Color(0xFF3F51B5), // Indigo
                Color(0xFF2196F3), // Blue
                Color(0xFF00BCD4), // Cyan
                Color(0xFF4CAF50), // Green
                Color(0xFF8BC34A), // Light Green
                Color(0xFFFF9800), // Orange
                Color(0xFFFF5722), // Deep Orange
              ],
              numberOfParticles: 20,
              gravity: 0.3,
              emissionFrequency: 0.05,
              minimumSize: const Size(10, 10),
              maximumSize: const Size(20, 20),
            ),
          ),
        ],
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
    if (_proteinTargets == null || _calorieTargets == null) {
      return const SizedBox.shrink();
    }

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Congratulations Section
            Center(
              child: Column(
                children: [
                  Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      color: AppConstants.textPrimary,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: AppConstants.shadowM,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 35,
                      color: AppConstants.surfaceColor,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingL),
                  Text(
                    'Congratulations',
                    style: AppTextStyles.heading3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  Text(
                    'your custom plan is ready!',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.spacingL),

            // Nutrition Targets Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: AppConstants.spacingM,
              mainAxisSpacing: AppConstants.spacingM,
              childAspectRatio: 1.1,
              children: [
                _buildNutritionCard(
                  'Calories',
                  '${_calorieTargets!.dailyTarget}',
                  Icons.local_fire_department,
                  AppConstants.textPrimary,
                  0.75, // Progress percentage
                ),
                _buildNutritionCard(
                  'Carbs',
                  '${_calculateCarbs()}g',
                  Icons.grain,
                  const Color(0xFFD4A574), // Light brown
                  0.65, // Progress percentage
                ),
                _buildNutritionCard(
                  'Protein',
                  '${_proteinTargets!.dailyTarget}g',
                  Icons.restaurant,
                  const Color(0xFFE57373), // Red
                  0.85, // Progress percentage
                ),
                _buildNutritionCard(
                  'Fats',
                  '${_calculateFats()}g',
                  Icons.water_drop,
                  const Color(0xFF81C784), // Light blue
                  0.45, // Progress percentage
                ),
              ],
            ),

            const SizedBox(height: AppConstants.spacingXL),

            // How to reach your goals section
            Text(
              'How to reach your goals:',
              style: AppTextStyles.heading4.copyWith(
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),

            const SizedBox(height: AppConstants.spacingL),

            // Goal cards
            Column(
              children: [
                _buildGoalCard(
                  Icons.flash_on,
                  const Color(0xFFE91E63), // Pink
                  'Use health scores to improve your routine',
                ),
                const SizedBox(height: AppConstants.spacingM),
                _buildGoalCard(
                  Icons.eco, // Avocado-like icon
                  const Color(0xFF8BC34A), // Green
                  'Track your food',
                ),
                const SizedBox(height: AppConstants.spacingM),
                _buildGoalCard(
                  Icons.local_fire_department,
                  const Color(0xFFFF9800), // Orange
                  'Follow your daily calorie recommendation',
                ),
                const SizedBox(height: AppConstants.spacingM),
                _buildMacroBalanceCard(),
              ],
            ),

            const SizedBox(height: AppConstants.spacingXL),

            // Plan sources text
            Text(
              'Plan based on the following sources,',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppConstants.spacingXL),

            // Continue button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  context.go('/auth-signup');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: AppConstants.surfaceColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Let\'s get started!',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCard(
      String title, String value, IconData icon, Color color, double progress) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: AppConstants.shadowS,
      ),
      child: Column(
        children: [
          // Header with icon and title
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: AppConstants.spacingXS),
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingM),

          // Circular progress indicator
          SizedBox(
            width: 75,
            height: 75,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                SizedBox(
                  width: 75,
                  height: 75,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 8,
                    backgroundColor: AppConstants.textTertiary.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                // Progress circle
                SizedBox(
                  width: 75,
                  height: 75,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                // Value text
                Text(
                  value,
                  style: AppTextStyles.heading5.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  int _calculateCarbs() {
    // Use the calculated macros from CalorieCalculationService
    return _calorieTargets!.macros.carbs.grams;
  }

  int _calculateFats() {
    // Use the calculated macros from CalorieCalculationService
    return _calorieTargets!.macros.fat.grams;
  }

  double _calculateWeightLoss() {
    // Calculate weight loss based on calorie deficit
    // Assuming a 500 calorie daily deficit leads to ~0.5kg per week
    // For 3 months (12 weeks), that's about 6kg
    return 5.0; // Default to 5kg for now
  }

  String _getTargetDate() {
    // Calculate target date (3 months from now)
    final now = DateTime.now();
    final targetDate = DateTime(now.year, now.month + 3, now.day);
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[targetDate.month - 1]} ${targetDate.day}';
  }

  Widget _buildGoalCard(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: AppConstants.shadowS,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: AppConstants.surfaceColor,
              size: 18,
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppConstants.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: AppConstants.shadowS,
      ),
      child: Row(
        children: [
          // Three overlapping circular icons
          SizedBox(
            width: 40,
            height: 32,
            child: Stack(
              children: [
                // Brown circle with wheat symbol
                Positioned(
                  left: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4A574), // Brown
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstants.surfaceColor,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.grain,
                      color: AppConstants.surfaceColor,
                      size: 12,
                    ),
                  ),
                ),
                // Red circle with lightning bolt
                Positioned(
                  left: 8,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE57373), // Red
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstants.surfaceColor,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.flash_on,
                      color: AppConstants.surfaceColor,
                      size: 12,
                    ),
                  ),
                ),
                // Blue circle with water drop
                Positioned(
                  left: 16,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF81C784), // Blue
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstants.surfaceColor,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.water_drop,
                      color: AppConstants.surfaceColor,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Text(
              'Balance your carbs, proteins, and fat',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppConstants.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
