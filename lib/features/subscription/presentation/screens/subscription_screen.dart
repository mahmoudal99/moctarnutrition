import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:champions_gym_app/shared/enums/subscription_plan.dart';
import 'package:champions_gym_app/shared/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../shared/models/subscription_model.dart';
import '../../../../shared/services/stripe_subscription_service.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/services/config_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPageIndex = 0;
  double _imageOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _startImageFadeIn();
  }

  void _startImageFadeIn() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _imageOpacity = 1.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pricingTiers = TrainingProgramTier.getTrainingProgramTiers();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_getCurrentBackgroundImage(pricingTiers)),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: AppConstants.spacingL),
              // Dynamic personal training image based on current page
              AnimatedOpacity(
                opacity: _imageOpacity,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                child: Center(
                  child: SizedBox(
                    width: 280,
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Left image (rotated slightly) - bottom layer
                        Positioned(
                          left: 0,
                          child: Transform.rotate(
                            angle: -0.15,
                            child: Container(
                              width: 160,
                              height: 210,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(AppConstants.radiusL),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.2),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                    offset: const Offset(0, 6),
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.1),
                                    blurRadius: 30,
                                    spreadRadius: 8,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                                image: DecorationImage(
                                  image: AssetImage(
                                      _getSideImage(pricingTiers, -1)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Right image (rotated slightly) - middle layer
                        Positioned(
                          right: 0,
                          child: Transform.rotate(
                            angle: 0.15,
                            child: Container(
                              width: 160,
                              height: 210,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(AppConstants.radiusL),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.2),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                    offset: const Offset(0, 6),
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.1),
                                    blurRadius: 30,
                                    spreadRadius: 8,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                                image: DecorationImage(
                                  image: AssetImage(
                                      _getSideImage(pricingTiers, 1)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Center image (main current page image) - top layer
                        Container(
                          width: 180,
                          height: 225,
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusL),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.1),
                                blurRadius: 40,
                                spreadRadius: 10,
                                offset: const Offset(0, 16),
                              ),
                            ],
                            image: DecorationImage(
                              image: AssetImage(
                                  _getCurrentPageImage(pricingTiers)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              Expanded(
                child: _buildPricingCards(pricingTiers),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Choose Your ',
                      style:
                          AppTextStyles.heading4.copyWith(color: Colors.white),
                    ),
                    TextSpan(
                      text: 'Plan',
                      style: GoogleFonts.ptSerif(
                        fontSize: AppTextStyles.heading4.fontSize,
                        fontWeight: AppTextStyles.heading4.fontWeight,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCards(List<TrainingProgramTier> pricingTiers) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentPageIndex = index;
        });
      },
      itemCount: pricingTiers.length,
      itemBuilder: (context, index) {
        final tier = pricingTiers[index];
        final price = tier.price;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingS),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          ),
          child: _buildPricingCard(
            tier: tier,
            price: price,
          ),
        );
      },
    );
  }

  Widget _buildPricingCard({
    required TrainingProgramTier tier,
    required double price,
  }) {
    return Card(
      elevation: 28,
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
      ),
      child: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tier.name, style: AppTextStyles.heading4),
                const SizedBox(height: AppConstants.spacingXS),
                Text(
                  tier.description,
                  style: AppTextStyles.caption.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                // Features list with bullet points
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: tier.features.map((feature) {
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppConstants.spacingXS),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '•',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppConstants.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppConstants.spacingS),
                          Expanded(
                            child: Text(
                              feature,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppConstants.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _handleTrainingProgram(tier.program);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppConstants.spacingM,
                        horizontal: AppConstants.spacingL,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusL),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Claim ${tier.name}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Price positioned at top right
          Positioned(
            top: AppConstants.spacingM,
            right: AppConstants.spacingM,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '€',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppConstants.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      price.toStringAsFixed(0),
                      style: AppTextStyles.heading3.copyWith(
                        color: AppConstants.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '/month',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentPageImage(List<TrainingProgramTier> pricingTiers) {
    if (_currentPageIndex < pricingTiers.length) {
      return _getTierImage(pricingTiers[_currentPageIndex]);
    }
    return 'assets/images/moc_one.jpg';
  }

  String _getTierImage(TrainingProgramTier tier) {
    switch (tier.program) {
      case TrainingProgram.winter:
        return 'assets/images/moc_one.jpg';
      case TrainingProgram.summer:
        return 'assets/images/moc_two.jpg';
      case TrainingProgram.bodybuilding:
        return 'assets/images/moc_three.jpg';
      case TrainingProgram.essential:
        return 'assets/images/moc_one.jpg';
    }
  }

  String _getSideImage(List<TrainingProgramTier> pricingTiers, int offset) {
    int sideIndex = (_currentPageIndex + offset) % pricingTiers.length;
    if (sideIndex < 0) sideIndex += pricingTiers.length;
    return _getTierImage(pricingTiers[sideIndex]);
  }

  String _getCurrentBackgroundImage(List<TrainingProgramTier> pricingTiers) {
    if (_currentPageIndex < pricingTiers.length) {
      return _getTierBackgroundImage(pricingTiers[_currentPageIndex]);
    }
    return 'assets/images/summer_plan.png';
  }

  String _getTierBackgroundImage(TrainingProgramTier tier) {
    switch (tier.program) {
      case TrainingProgram.winter:
        return 'assets/images/winter.png';
      case TrainingProgram.summer:
        return 'assets/images/summer_plan.png';
      case TrainingProgram.bodybuilding:
        return 'assets/images/transform.png';
      case TrainingProgram.essential:
        return 'assets/images/winter.png';
    }
  }

  Widget _buildPageIndicator(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPageIndex == index
                ? AppConstants.primaryColor
                : AppConstants.textTertiary.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  void _handleTrainingProgram(TrainingProgram program) async {
    // All programs require payment

    // Check if Stripe is configured
    if (!ConfigService.isStripeEnabled) {
      _showErrorDialog(
          'Payment system not configured. Please contact support.');
      return;
    }

    // Get current user
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Debug: Show current auth state

    // Check if user data is still loading
    if (authProvider.isLoading) {
      _showErrorDialog(
          'Loading user data... Please wait a moment and try again.');
      return;
    }

    if (authProvider.userModel == null) {
      // Try to refresh user data automatically
      await authProvider.refreshUser();

      // Check again after refresh
      if (authProvider.userModel == null) {
        _showErrorDialog(
            'User data not found. Please sign out and sign in again.');
        return;
      }
    }

    final user = authProvider.userModel!;

    // Show loading dialog
    _showLoadingDialog();

    try {
      // Map training program to Stripe price ID
      final priceId = _getPriceIdForProgram(program);
      if (priceId == null) {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorDialog(
            'Training program not available. Please contact support.');
        return;
      }

      // Create checkout session
      final checkoutResult =
          await StripeSubscriptionService.createCheckoutSession(
        priceId: priceId,
        userId: user.id,
        successUrl: 'moctarnutrition://subscription-success',
        cancelUrl: 'moctarnutrition://subscription-cancel',
        customerEmail: user.email,
      );

      Navigator.of(context).pop(); // Close loading dialog

      if (checkoutResult.isSuccess && checkoutResult.sessionId != null) {
        // Present Stripe checkout
        final paymentResult = await StripeSubscriptionService.presentCheckout(
          sessionId: checkoutResult.sessionId!,
          checkoutUrl: checkoutResult.url,
        );

        if (paymentResult.isSuccess) {
          // Wait longer for webhook to process the payment
          await Future.delayed(const Duration(seconds: 3));

          // Try to refresh user data multiple times with retry logic
          bool statusUpdated = false;
          int retryCount = 0;
          const maxRetries = 5;

          while (!statusUpdated && retryCount < maxRetries) {
            // Force refresh user data to get updated training program status
            await authProvider.refreshUser();

            // Wait a moment for the refresh to complete
            await Future.delayed(const Duration(milliseconds: 1000));

            // Check if training program status was updated
            final updatedUser = authProvider.userModel;

            if (updatedUser != null &&
                updatedUser.trainingProgramStatus !=
                    TrainingProgramStatus.none) {
              statusUpdated = true;
              _showSuccessDialog('Training program activated successfully!');
              break;
            }

            retryCount++;
            if (retryCount < maxRetries) {
              await Future.delayed(const Duration(seconds: 2));
            }
          }

          if (!statusUpdated) {
            _showErrorDialog(
                'Payment successful but training program status not updated. Please refresh the app or contact support.');
          }
        } else {
          _showErrorDialog(paymentResult.errorMessage ??
              'Payment failed. Please try again.');
        }
      } else {
        _showErrorDialog(checkoutResult.errorMessage ??
            'Failed to create checkout session. Please try again.');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog('An error occurred: ${e.toString()}');
    }
  }

  String? _getPriceIdForProgram(TrainingProgram program) {
    // These should match your Stripe Dashboard price IDs for one-time payments
    switch (program) {
      case TrainingProgram.winter:
        return 'price_1SGzgzBa6NGVc5lJvVOssWsG'; // Winter Plan - $400 one-time (replace with actual price ID)
      case TrainingProgram.summer:
        return 'price_1SGzfcBa6NGVc5lJwmTNs2xk'; // Summer Plan - $600 one-time
      case TrainingProgram.bodybuilding:
        return 'price_1SHG5NBa6NGVc5lJdOEVEhZv'; // Body Building - $1000 one-time (replace with actual price ID)
      case TrainingProgram.essential:
        return 'price_1ShW3jBa6NGVc5lJ3Tgxi0tD'; // Essential - €30/month subscription
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Processing subscription...'),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/home');
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
