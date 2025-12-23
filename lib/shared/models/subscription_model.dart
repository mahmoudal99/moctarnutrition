import 'package:champions_gym_app/shared/enums/subscription_plan.dart';

class TrainingProgramModel {
  final String id;
  final String userId;
  final TrainingProgram program;
  final double price;
  final String currency;
  final DateTime purchaseDate;
  final bool isActive;
  final String? paymentMethodId;
  final String? receiptUrl;
  final String? stripePaymentIntentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  TrainingProgramModel({
    required this.id,
    required this.userId,
    required this.program,
    required this.price,
    this.currency = 'EUR',
    required this.purchaseDate,
    this.isActive = true,
    this.paymentMethodId,
    this.receiptUrl,
    this.stripePaymentIntentId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrainingProgramModel.fromJson(Map<String, dynamic> json) {
    return TrainingProgramModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      program: TrainingProgram.values.firstWhere(
        (e) => e.toString() == 'TrainingProgram.${json['program']}',
        orElse: () => TrainingProgram.summer,
      ),
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'EUR',
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
      paymentMethodId: json['paymentMethodId'] as String?,
      receiptUrl: json['receiptUrl'] as String?,
      stripePaymentIntentId: json['stripePaymentIntentId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'program': program.toString().split('.').last,
      'price': price,
      'currency': currency,
      'purchaseDate': purchaseDate.toIso8601String(),
      'isActive': isActive,
      'paymentMethodId': paymentMethodId,
      'receiptUrl': receiptUrl,
      'stripePaymentIntentId': stripePaymentIntentId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isActiveProgram => isActive;
}

class TrainingProgramDetails {
  final TrainingProgram program;
  final String name;
  final String description;
  final double price;
  final List<String> features;
  final bool isPopular;
  final bool isRecommended;

  TrainingProgramDetails({
    required this.program,
    required this.name,
    required this.description,
    required this.price,
    required this.features,
    this.isPopular = false,
    this.isRecommended = false,
  });
}

class TrainingProgramFeatures {
  static const Map<TrainingProgram, List<String>> features = {
    TrainingProgram.winter: [
      'Winter-specific workouts',
      'Indoor training focus',
      'AI-generated meal plans',
      'Progress analytics',
      'Trainer selection',
      'Ad-free experience',
      'Winter transformation guide',
    ],
    TrainingProgram.summer: [
      'All winter features',
      'Summer-specific workouts',
      'Outdoor training options',
      'Summer transformation guide',
    ],
    TrainingProgram.bodybuilding: [
      'All summer features',
      'Advanced bodybuilding workouts',
      '1-on-1 trainer sessions',
      'Advanced analytics',
      'Custom meal plans',
      'Priority support',
      'Exclusive content',
      'Bodybuilding nutrition guide',
    ],
    TrainingProgram.essential: [
      'Personalized nutrition plans',
      'Customized daily rhythm',
      'Sustainable meal guidance',
      'Progress tracking',
      'Monthly subscription',
    ],
  };

  static List<String> getFeaturesForProgram(TrainingProgram program) {
    return features[program] ?? [];
  }

  static bool hasFeature(
      TrainingProgram userProgram, TrainingProgram requiredProgram) {
    final programOrder = {
      TrainingProgram.essential: 0,
      TrainingProgram.winter: 1,
      TrainingProgram.summer: 2,
      TrainingProgram.bodybuilding: 3,
    };

    return programOrder[userProgram]! >= programOrder[requiredProgram]!;
  }
}

class TrainingProgramTier {
  final TrainingProgram program;
  final String name;
  final String description;
  final double price;
  final List<String> features;
  final bool isPopular;
  final bool isRecommended;

  TrainingProgramTier({
    required this.program,
    required this.name,
    required this.description,
    required this.price,
    required this.features,
    this.isPopular = false,
    this.isRecommended = false,
  });

  static List<TrainingProgramTier> getTrainingProgramTiers() {
    return [
      TrainingProgramTier(
        program: TrainingProgram.winter,
        name: 'Winter Plan',
        description: 'Perfect for winter training',
        price: 340.00,
        features:
            TrainingProgramFeatures.getFeaturesForProgram(TrainingProgram.winter),
        isRecommended: true,
      ),
      TrainingProgramTier(
        program: TrainingProgram.summer,
        name: 'Summer Plan',
        description: 'Get ready for summer!',
        price: 510.00,
        features:
            TrainingProgramFeatures.getFeaturesForProgram(TrainingProgram.summer),
        isPopular: true,
      ),
      TrainingProgramTier(
        program: TrainingProgram.bodybuilding,
        name: 'Body Building',
        description: 'Ultimate fitness experience',
        price: 850.00,
        features:
            TrainingProgramFeatures.getFeaturesForProgram(TrainingProgram.bodybuilding),
      ),
    ];
  }

  /// Get the Essential tier for non-bodybuilding users
  static TrainingProgramTier getEssentialTier() {
    return TrainingProgramTier(
      program: TrainingProgram.essential,
      name: 'Essential',
      description: 'Essential is designed for those who value clarity over clutter. We\'ve stripped away the noise to give you exactly what you need to thrive: personalized plans, nutrition, and a sustainable daily rhythm. It\'s not a diet or a boot camp — it\'s the blueprint for your new everyday.',
      price: 30.00,
      features: TrainingProgramFeatures.getFeaturesForProgram(TrainingProgram.essential),
      isRecommended: true,
    );
  }
}
