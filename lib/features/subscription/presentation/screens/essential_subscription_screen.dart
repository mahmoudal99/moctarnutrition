import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:champions_gym_app/shared/enums/subscription_plan.dart';
import 'package:champions_gym_app/shared/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../shared/models/subscription_model.dart';
import '../../../../shared/services/stripe_subscription_service.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/services/config_service.dart';

class EssentialSubscriptionScreen extends StatefulWidget {
  const EssentialSubscriptionScreen({super.key});

  @override
  State<EssentialSubscriptionScreen> createState() =>
      _EssentialSubscriptionScreenState();
}

class _EssentialSubscriptionScreenState
    extends State<EssentialSubscriptionScreen> {
  @override
  Widget build(BuildContext context) {
    final essentialTier = TrainingProgramTier.getEssentialTier();

    return Scaffold(
      backgroundColor: AppConstants.containerColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingL,
            vertical: AppConstants.spacingM,
          ),
          child: Column(
            children: [
              // Close button at top left
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      // Can't pop, go back to get started screen
                      context.go('/get-started');
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstants.borderColor,
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: AppConstants.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ),

              // Main content area
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingM,
                        vertical: AppConstants.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.copperwoodColor.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusXL),
                      ),
                      child: Text(
                        '✨ ESSENTIAL PLAN',
                        style: AppTextStyles.caption.copyWith(
                          color: AppConstants.copperwoodColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacingM),

                    // Headline
                    Text(
                      'Your Blueprint for',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w300,
                        color: AppConstants.textPrimary,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Everyday Wellness',
                      style: GoogleFonts.ptSerif(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: AppConstants.primaryColor,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppConstants.spacingS),

                    Text(
                      'Personalized nutrition • Sustainable rhythm\nNo clutter, no gimmicks',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppConstants.textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppConstants.spacingL),

                    // Social proof with avatars
                    _buildSocialProof(),

                    const SizedBox(height: AppConstants.spacingL),

                    // Benefits row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildBenefitItem(Icons.restaurant_menu, 'Meal Plans'),
                        _buildBenefitItem(Icons.schedule, 'Daily Rhythm'),
                        _buildBenefitItem(Icons.trending_up, 'Progress'),
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom CTA section
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 16,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Price with rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '€${essentialTier.price.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textPrimary,
                                height: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '/month',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppConstants.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Rating
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingS,
                            vertical: AppConstants.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.successColor.withOpacity(0.15),
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusS),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: AppConstants.copperwoodColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '4.9',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppConstants.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppConstants.spacingM),

                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _handleSubscription(essentialTier.program);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: AppConstants.accentColor,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppConstants.spacingM,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusL),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Start Your Journey',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppConstants.accentColor,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacingS),

                    // Trust indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 13,
                          color: AppConstants.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Secure payment',
                          style: AppTextStyles.caption.copyWith(
                            color: AppConstants.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '•',
                          style: AppTextStyles.caption.copyWith(
                            color: AppConstants.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Cancel anytime',
                          style: AppTextStyles.caption.copyWith(
                            color: AppConstants.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialProof() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
        vertical: AppConstants.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: AppConstants.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stacked avatars
          SizedBox(
            width: 64,
            height: 28,
            child: Stack(
              children: List.generate(3, (index) {
                return Positioned(
                  left: index * 18.0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: [
                        AppConstants.copperwoodColor,
                        AppConstants.secondaryColor,
                        AppConstants.primaryColor,
                      ][index],
                      border: Border.all(
                        color: AppConstants.surfaceColor,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        ['M', 'S', 'A'][index],
                        style: GoogleFonts.nunitoSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.accentColor,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: AppConstants.spacingS),
          Text(
            'Join ',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
          Text(
            '500+ members',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            border: Border.all(
              color: AppConstants.borderColor,
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: AppConstants.copperwoodColor,
            size: 24,
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppConstants.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _handleSubscription(TrainingProgram program) async {
    if (!ConfigService.isStripeEnabled) {
      _showErrorDialog(
          'Payment system not configured. Please contact support.');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isLoading) {
      _showErrorDialog(
          'Loading user data... Please wait a moment and try again.');
      return;
    }

    if (authProvider.userModel == null) {
      await authProvider.refreshUser();
      if (authProvider.userModel == null) {
        _showErrorDialog(
            'User data not found. Please sign out and sign in again.');
        return;
      }
    }

    final user = authProvider.userModel!;
    _showLoadingDialog();

    try {
      const priceId = 'price_1ShW3jBa6NGVc5lJ3Tgxi0tD';

      final checkoutResult =
          await StripeSubscriptionService.createCheckoutSession(
        priceId: priceId,
        userId: user.id,
        successUrl: 'moctarnutrition://subscription-success',
        cancelUrl: 'moctarnutrition://subscription-cancel',
        customerEmail: user.email,
      );

      Navigator.of(context).pop();

      if (checkoutResult.isSuccess && checkoutResult.sessionId != null) {
        final paymentResult = await StripeSubscriptionService.presentCheckout(
          sessionId: checkoutResult.sessionId!,
          checkoutUrl: checkoutResult.url,
        );

        if (paymentResult.isSuccess) {
          await Future.delayed(const Duration(seconds: 3));

          bool statusUpdated = false;
          int retryCount = 0;
          const maxRetries = 5;

          while (!statusUpdated && retryCount < maxRetries) {
            await authProvider.refreshUser();
            await Future.delayed(const Duration(milliseconds: 1000));

            final updatedUser = authProvider.userModel;
            if (updatedUser != null &&
                updatedUser.trainingProgramStatus !=
                    TrainingProgramStatus.none) {
              statusUpdated = true;
              _showSuccessDialog('Welcome to Essential! Let\'s begin.');
              break;
            }

            retryCount++;
            if (retryCount < maxRetries) {
              await Future.delayed(const Duration(seconds: 2));
            }
          }

          if (!statusUpdated) {
            _showErrorDialog(
                'Payment successful but status not updated. Please refresh the app.');
          }
        } else {
          _showErrorDialog(paymentResult.errorMessage ??
              'Payment failed. Please try again.');
        }
      } else {
        _showErrorDialog(checkoutResult.errorMessage ??
            'Failed to create checkout. Please try again.');
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorDialog('An error occurred: ${e.toString()}');
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        content: Row(
          children: [
            CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
            ),
            const SizedBox(width: 16),
            Text('Processing...', style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text('Success', style: AppTextStyles.heading5),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/home');
            },
            child: Text(
              'Continue',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text('Error', style: AppTextStyles.heading5),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
