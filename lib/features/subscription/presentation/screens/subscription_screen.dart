import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/subscription_model.dart';

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
    final pricingTiers = PricingTier.getPricingTiers();

    return Scaffold(
      body: SafeArea(
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
                child: Stack(
                  children: [
                    // Image container
                    Container(
                      width: 200,
                      height: 270,
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
                          image: AssetImage(_getCurrentPageImage(pricingTiers)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
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
              Text(
                'Choose Your Plan',
                style: AppTextStyles.heading4,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCards(List<PricingTier> pricingTiers) {
    return SizedBox(
      height: 320, // Reduced height for more compact cards
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        itemCount: pricingTiers.length,
        itemBuilder: (context, index) {
          final tier = pricingTiers[index];
          final price = tier.monthlyPrice;

          return Container(
            margin:
                const EdgeInsets.symmetric(horizontal: AppConstants.spacingXS),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusXL),
            ),
            child: _buildPricingCard(
              tier: tier,
              price: price,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPricingCard({
    required PricingTier tier,
    required double price,
  }) {
    return Card(
      elevation: 20,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tier.name, style: AppTextStyles.heading4),
                      const SizedBox(height: AppConstants.spacingXS),
                      Text(
                        tier.description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppConstants.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          price.toStringAsFixed(0),
                          style: AppTextStyles.heading2.copyWith(
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
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _handleSubscription(tier.plan);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.spacingM,
                    horizontal: AppConstants.spacingL,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
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
    );
  }

  String _getCurrentPageImage(List<PricingTier> pricingTiers) {
    if (_currentPageIndex < pricingTiers.length) {
      return _getTierImage(pricingTiers[_currentPageIndex]);
    }
    return 'assets/images/moc_one.jpg';
  }

  String _getTierImage(PricingTier tier) {
    switch (tier.plan) {
      case SubscriptionPlan.free:
        return 'assets/images/moc_one.jpg';
      case SubscriptionPlan.basic:
        return 'assets/images/moc_two.jpg';
      case SubscriptionPlan.premium:
        return 'assets/images/moc_three.jpg';
      default:
        return 'assets/images/moc_one.jpg';
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

  void _handleSubscription(SubscriptionPlan plan) {
    // TODO: Implement subscription logic
    // After selecting a plan, go to auth screen for sign up
    context.go('/auth-signup');
  }
}
