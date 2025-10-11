enum SubscriptionPlan { free, basic, premium }

enum BillingCycle { monthly, yearly }

class SubscriptionModel {
  final String id;
  final String userId;
  final SubscriptionPlan plan;
  final BillingCycle billingCycle;
  final double price;
  final String currency;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String? paymentMethodId;
  final String? receiptUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.plan,
    required this.billingCycle,
    required this.price,
    this.currency = 'USD',
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.paymentMethodId,
    this.receiptUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      plan: SubscriptionPlan.values.firstWhere(
        (e) => e.toString() == 'SubscriptionPlan.${json['plan']}',
        orElse: () => SubscriptionPlan.free,
      ),
      billingCycle: BillingCycle.values.firstWhere(
        (e) => e.toString() == 'BillingCycle.${json['billingCycle']}',
        orElse: () => BillingCycle.monthly,
      ),
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
      paymentMethodId: json['paymentMethodId'] as String?,
      receiptUrl: json['receiptUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'plan': plan.toString().split('.').last,
      'billingCycle': billingCycle.toString().split('.').last,
      'price': price,
      'currency': currency,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'paymentMethodId': paymentMethodId,
      'receiptUrl': receiptUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isExpiringSoon {
    final daysUntilExpiry = endDate.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 7 && daysUntilExpiry > 0;
  }
}

class SubscriptionPlanDetails {
  final SubscriptionPlan plan;
  final String name;
  final String description;
  final double monthlyPrice;
  final double yearlyPrice;
  final List<String> features;
  final bool isPopular;
  final bool isRecommended;

  SubscriptionPlanDetails({
    required this.plan,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
    this.isPopular = false,
    this.isRecommended = false,
  });
}

class SubscriptionFeatures {
  static const Map<SubscriptionPlan, List<String>> features = {
    SubscriptionPlan.free: [
      'Access to basic workouts',
      'Limited meal plans',
      'Basic progress tracking',
      'Community access',
    ],
    SubscriptionPlan.basic: [
      'All free features',
      'Unlimited workouts',
      'AI-generated meal plans',
      'Progress analytics',
      'Trainer selection',
      'Ad-free experience',
    ],
    SubscriptionPlan.premium: [
      'All basic features',
      'Personalized AI coaching',
      '1-on-1 trainer sessions',
      'Advanced analytics',
      'Custom meal plans',
      'Priority support',
      'Exclusive content',
      'Early access to features',
    ],
  };

  static List<String> getFeaturesForPlan(SubscriptionPlan plan) {
    return features[plan] ?? [];
  }

  static bool hasFeature(
      SubscriptionPlan userPlan, SubscriptionPlan requiredPlan) {
    final planOrder = {
      SubscriptionPlan.free: 0,
      SubscriptionPlan.basic: 1,
      SubscriptionPlan.premium: 2,
    };

    return planOrder[userPlan]! >= planOrder[requiredPlan]!;
  }
}

class PricingTier {
  final SubscriptionPlan plan;
  final String name;
  final String description;
  final double monthlyPrice;
  final double yearlyPrice;
  final double yearlySavings;
  final List<String> features;
  final bool isPopular;
  final bool isRecommended;

  PricingTier({
    required this.plan,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.yearlySavings,
    required this.features,
    this.isPopular = false,
    this.isRecommended = false,
  });

  static List<PricingTier> getPricingTiers() {
    return [
      PricingTier(
        plan: SubscriptionPlan.free,
        name: 'Winter',
        description: 'Perfect for getting started',
        monthlyPrice: 0,
        yearlyPrice: 0,
        yearlySavings: 0,
        features:
            SubscriptionFeatures.getFeaturesForPlan(SubscriptionPlan.free),
        isRecommended: true,
      ),
      PricingTier(
        plan: SubscriptionPlan.basic,
        name: 'Summer Transformation',
        description: 'Great for regular fitness enthusiasts',
        monthlyPrice: 9.99,
        yearlyPrice: 99.99,
        yearlySavings: 19.89,
        features:
            SubscriptionFeatures.getFeaturesForPlan(SubscriptionPlan.basic),
        isPopular: true,
      ),
      PricingTier(
        plan: SubscriptionPlan.premium,
        name: 'Year-Round Champion',
        description: 'Ultimate fitness experience',
        monthlyPrice: 19.99,
        yearlyPrice: 199.99,
        yearlySavings: 39.89,
        features:
            SubscriptionFeatures.getFeaturesForPlan(SubscriptionPlan.premium),
      ),
    ];
  }
}
