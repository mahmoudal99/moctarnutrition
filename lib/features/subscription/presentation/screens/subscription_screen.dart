import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/models/subscription_model.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  BillingCycle _selectedBillingCycle = BillingCycle.monthly;
  SubscriptionPlan? _selectedPlan;

  @override
  Widget build(BuildContext context) {
    final pricingTiers = PricingTier.getPricingTiers();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                child: Column(
                  children: [
                    _buildBillingCycleSelector(),
                    const SizedBox(height: AppConstants.spacingXL),
                    _buildPricingCards(pricingTiers),
                    const SizedBox(height: AppConstants.spacingXL),
                    _buildFeaturesComparison(pricingTiers),
                    const SizedBox(height: AppConstants.spacingXL),
                    _buildSubscriptionButton(),
                    const SizedBox(height: AppConstants.spacingL),
                    _buildTermsAndPrivacy(),
                  ],
                ),
              ),
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
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Text(
                  'Choose Your Plan',
                  style: AppTextStyles.heading3,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Balance the back button
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Unlock your full potential with our premium features',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppConstants.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBillingCycleSelector() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingS),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: AppConstants.textTertiary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildBillingOption(
              title: 'Monthly',
              subtitle: 'Flexible billing',
              isSelected: _selectedBillingCycle == BillingCycle.monthly,
              onTap: () {
                setState(() {
                  _selectedBillingCycle = BillingCycle.monthly;
                });
              },
            ),
          ),
          Expanded(
            child: _buildBillingOption(
              title: 'Yearly',
              subtitle: 'Save up to 40%',
              isSelected: _selectedBillingCycle == BillingCycle.yearly,
              onTap: () {
                setState(() {
                  _selectedBillingCycle = BillingCycle.yearly;
                });
              },
              isPopular: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    bool isPopular = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.spacingM,
          horizontal: AppConstants.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        child: Column(
          children: [
            if (isPopular)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.accentColor,
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: Text(
                  'SAVE',
                  style: AppTextStyles.caption.copyWith(
                    color: AppConstants.surfaceColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            if (isPopular) const SizedBox(height: AppConstants.spacingXS),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppConstants.surfaceColor
                    : AppConstants.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: isSelected
                    ? AppConstants.surfaceColor.withOpacity(0.8)
                    : AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCards(List<PricingTier> pricingTiers) {
    return Column(
      children: pricingTiers.map((tier) {
        final isSelected = _selectedPlan == tier.plan;
        final price = _selectedBillingCycle == BillingCycle.monthly
            ? tier.monthlyPrice
            : tier.yearlyPrice;

        return Container(
          margin: const EdgeInsets.only(bottom: AppConstants.spacingL),
          child: _buildPricingCard(
            tier: tier,
            price: price,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _selectedPlan = tier.plan;
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPricingCard({
    required PricingTier tier,
    required double price,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor
              : AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(
            color: isSelected
                ? AppConstants.primaryColor
                : AppConstants.textTertiary.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppConstants.shadowL : AppConstants.shadowS,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tier.isPopular)
                Container(
                  margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingM,
                    vertical: AppConstants.spacingS,
                  ),
                  decoration: const BoxDecoration(
                    color: AppConstants.accentColor,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(AppConstants.radiusL),
                      bottomLeft: Radius.circular(AppConstants.radiusM),
                    ),
                  ),
                  child: Text(
                    'MOST POPULAR',
                    style: AppTextStyles.caption.copyWith(
                      color: AppConstants.surfaceColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tier.name,
                          style: AppTextStyles.heading4.copyWith(
                            color: isSelected
                                ? AppConstants.surfaceColor
                                : AppConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingXS),
                        Text(
                          tier.description,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isSelected
                                ? AppConstants.surfaceColor.withOpacity(0.8)
                                : AppConstants.textSecondary,
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
                              color: isSelected
                                  ? AppConstants.surfaceColor
                                  : AppConstants.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            price.toStringAsFixed(0),
                            style: AppTextStyles.heading2.copyWith(
                              color: isSelected
                                  ? AppConstants.surfaceColor
                                  : AppConstants.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _selectedBillingCycle == BillingCycle.monthly
                            ? '/month'
                            : '/year',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isSelected
                              ? AppConstants.surfaceColor.withOpacity(0.8)
                              : AppConstants.textSecondary,
                        ),
                      ),
                      if (_selectedBillingCycle == BillingCycle.yearly &&
                          tier.yearlySavings > 0)
                        Container(
                          margin: const EdgeInsets.only(
                              top: AppConstants.spacingXS),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingS,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.accentColor,
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusS),
                          ),
                          child: Text(
                            'Save \$${tier.yearlySavings.toStringAsFixed(0)}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppConstants.surfaceColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingL),
              ...tier.features.take(3).map((feature) => _buildFeatureItem(
                    feature: feature,
                    isSelected: isSelected,
                  )),
              if (tier.features.length > 3)
                Text(
                  '+${tier.features.length - 3} more features',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected
                        ? AppConstants.surfaceColor.withOpacity(0.8)
                        : AppConstants.accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required String feature,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: isSelected
                ? AppConstants.surfaceColor
                : AppConstants.accentColor,
            size: 20,
          ),
          const SizedBox(width: AppConstants.spacingS),
          Expanded(
            child: Text(
              feature,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected
                    ? AppConstants.surfaceColor.withOpacity(0.9)
                    : AppConstants.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesComparison(List<PricingTier> pricingTiers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feature Comparison',
          style: AppTextStyles.heading4,
        ),
        const SizedBox(height: AppConstants.spacingM),
        Container(
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            border: Border.all(
              color: AppConstants.textTertiary.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              _buildComparisonHeader(pricingTiers),
              ...SubscriptionFeatures.features[SubscriptionPlan.free]!.map(
                (feature) => _buildComparisonRow(feature, pricingTiers),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonHeader(List<PricingTier> pricingTiers) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppConstants.radiusL),
          topRight: Radius.circular(AppConstants.radiusL),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Features',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...pricingTiers.map((tier) => Expanded(
                child: Text(
                  tier.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: tier.isPopular ? AppConstants.accentColor : null,
                  ),
                  textAlign: TextAlign.center,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String feature, List<PricingTier> pricingTiers) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppConstants.textTertiary.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: AppTextStyles.bodySmall,
            ),
          ),
          ...pricingTiers.map((tier) => Expanded(
                child: Icon(
                  SubscriptionFeatures.hasFeature(
                          tier.plan, SubscriptionPlan.free)
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: SubscriptionFeatures.hasFeature(
                          tier.plan, SubscriptionPlan.free)
                      ? AppConstants.accentColor
                      : AppConstants.textTertiary,
                  size: 20,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSubscriptionButton() {
    if (_selectedPlan == null) {
      return const SizedBox.shrink();
    }

    final selectedTier = PricingTier.getPricingTiers().firstWhere(
      (tier) => tier.plan == _selectedPlan,
    );

    return Column(
      children: [
        CustomButton(
          text: 'Start ${selectedTier.name} Plan',
          onPressed: () {
            _handleSubscription();
          },
        ),
        const SizedBox(height: AppConstants.spacingM),
        Text(
          'Cancel anytime. No commitment required.',
          style: AppTextStyles.caption.copyWith(
            color: AppConstants.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTermsAndPrivacy() {
    return Column(
      children: [
        Text(
          'By subscribing, you agree to our',
          style: AppTextStyles.caption.copyWith(
            color: AppConstants.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                // TODO: Navigate to terms
              },
              child: Text(
                'Terms of Service',
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.primaryColor,
                ),
              ),
            ),
            Text(
              ' and ',
              style: AppTextStyles.caption.copyWith(
                color: AppConstants.textTertiary,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to privacy
              },
              child: Text(
                'Privacy Policy',
                style: AppTextStyles.caption.copyWith(
                  color: AppConstants.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleSubscription() {
    if (_selectedPlan == null) return;

    // TODO: Implement subscription logic
    // After selecting a plan, go to auth screen for sign up
    context.go('/auth-signup');
  }
}
