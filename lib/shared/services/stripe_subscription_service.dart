import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/subscription_model.dart';
import '../models/user_model.dart';
import 'config_service.dart';

/// Service for handling Stripe subscription operations
/// This service manages subscription creation, management, and status tracking
class StripeSubscriptionService {
  static final _logger = Logger();

  // Stripe configuration
  static String? _publishableKey;
  static String? _backendUrl;

  // Initialize Stripe with publishable key
  static Future<void> initialize({
    required String publishableKey,
    required String backendUrl,
  }) async {
    _publishableKey = publishableKey;
    _backendUrl = backendUrl;

    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();

    _logger.i('Stripe initialized successfully');
  }

  /// Create a checkout session for subscription
  static Future<StripeCheckoutResult> createCheckoutSession({
    required String priceId,
    required String userId,
    required String successUrl,
    required String cancelUrl,
    String? customerEmail,
  }) async {
    try {
      _logger.i('Creating checkout session for priceId: $priceId');

      final response = await http.post(
        Uri.parse('$_backendUrl/create-checkout-session'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'priceId': priceId,
          'userId': userId,
          'successUrl': successUrl,
          'cancelUrl': cancelUrl,
          'customerEmail': customerEmail,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StripeCheckoutResult.success(
          sessionId: data['sessionId'],
          url: data['url'],
        );
      } else {
        final error = json.decode(response.body);
        return StripeCheckoutResult.error(
          message: error['message'] ?? 'Failed to create checkout session',
        );
      }
    } catch (e) {
      _logger.e('Error creating checkout session: $e');
      return StripeCheckoutResult.error(
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Present Stripe checkout session
  static Future<StripePaymentResult> presentCheckout({
    required String sessionId,
  }) async {
    try {
      _logger.i('Presenting checkout session: $sessionId');

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'Moctar Nutrition',
          paymentIntentClientSecret: sessionId,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      _logger.i('Payment successful');
      return StripePaymentResult.success();
    } on StripeException catch (e) {
      _logger.e('Stripe payment error: ${e.error.message}');
      return StripePaymentResult.error(
        message: e.error.message ?? 'Payment failed',
        code: e.error.code?.name,
      );
    } catch (e) {
      _logger.e('Payment error: $e');
      return StripePaymentResult.error(
        message: 'Payment failed: ${e.toString()}',
      );
    }
  }

  /// Create a customer portal session for subscription management
  static Future<StripePortalResult> createPortalSession({
    required String customerId,
    required String returnUrl,
  }) async {
    try {
      _logger.i('Creating portal session for customer: $customerId');

      final response = await http.post(
        Uri.parse('$_backendUrl/create-portal-session'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'customerId': customerId,
          'returnUrl': returnUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StripePortalResult.success(url: data['url']);
      } else {
        final error = json.decode(response.body);
        return StripePortalResult.error(
          message: error['message'] ?? 'Failed to create portal session',
        );
      }
    } catch (e) {
      _logger.e('Error creating portal session: $e');
      return StripePortalResult.error(
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Get subscription status from backend
  static Future<StripeSubscriptionStatus?> getSubscriptionStatus({
    required String userId,
  }) async {
    try {
      _logger.i('Getting subscription status for user: $userId');

      final response = await http.get(
        Uri.parse('$_backendUrl/subscription-status/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StripeSubscriptionStatus.fromJson(data);
      } else {
        _logger.w('Failed to get subscription status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting subscription status: $e');
      return null;
    }
  }

  /// Cancel subscription
  static Future<StripeCancelResult> cancelSubscription({
    required String subscriptionId,
    bool immediately = false,
  }) async {
    try {
      _logger.i('Cancelling subscription: $subscriptionId');

      final response = await http.post(
        Uri.parse('$_backendUrl/cancel-subscription'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'subscriptionId': subscriptionId,
          'immediately': immediately,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StripeCancelResult.success(
          cancelledAt: data['cancelledAt'] != null
              ? DateTime.parse(data['cancelledAt'])
              : null,
        );
      } else {
        final error = json.decode(response.body);
        return StripeCancelResult.error(
          message: error['message'] ?? 'Failed to cancel subscription',
        );
      }
    } catch (e) {
      _logger.e('Error cancelling subscription: $e');
      return StripeCancelResult.error(
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Update subscription plan
  static Future<StripeUpdateResult> updateSubscription({
    required String subscriptionId,
    required String newPriceId,
    bool prorate = true,
  }) async {
    try {
      _logger.i('Updating subscription: $subscriptionId to price: $newPriceId');

      final response = await http.post(
        Uri.parse('$_backendUrl/update-subscription'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'subscriptionId': subscriptionId,
          'newPriceId': newPriceId,
          'prorate': prorate,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StripeUpdateResult.success(
          updatedAt: DateTime.parse(data['updatedAt']),
        );
      } else {
        final error = json.decode(response.body);
        return StripeUpdateResult.error(
          message: error['message'] ?? 'Failed to update subscription',
        );
      }
    } catch (e) {
      _logger.e('Error updating subscription: $e');
      return StripeUpdateResult.error(
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Get available subscription plans
  static Future<List<StripePrice>> getAvailablePlans() async {
    try {
      _logger.i('Getting available subscription plans');

      final response = await http.get(
        Uri.parse('$_backendUrl/subscription-plans'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> plans = data['plans'];
        return plans.map((plan) => StripePrice.fromJson(plan)).toList();
      } else {
        _logger.w('Failed to get subscription plans: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting subscription plans: $e');
      return [];
    }
  }

  /// Handle webhook events (for backend integration)
  static Future<void> handleWebhookEvent(Map<String, dynamic> event) async {
    try {
      final eventType = event['type'] as String;
      _logger.i('Handling webhook event: $eventType');

      switch (eventType) {
        case 'checkout.session.completed':
          await _handleCheckoutCompleted(event);
          break;
        case 'customer.subscription.created':
          await _handleSubscriptionCreated(event);
          break;
        case 'customer.subscription.updated':
          await _handleSubscriptionUpdated(event);
          break;
        case 'customer.subscription.deleted':
          await _handleSubscriptionDeleted(event);
          break;
        case 'invoice.payment_succeeded':
          await _handlePaymentSucceeded(event);
          break;
        case 'invoice.payment_failed':
          await _handlePaymentFailed(event);
          break;
        default:
          _logger.w('Unhandled webhook event type: $eventType');
      }
    } catch (e) {
      _logger.e('Error handling webhook event: $e');
    }
  }

  // Private webhook handlers
  static Future<void> _handleCheckoutCompleted(
      Map<String, dynamic> event) async {
    final session = event['data']['object'];
    final userId = session['client_reference_id'];
    final customerId = session['customer'];

    _logger.i('Checkout completed for user: $userId, customer: $customerId');
    // Backend should handle updating user subscription status
  }

  static Future<void> _handleSubscriptionCreated(
      Map<String, dynamic> event) async {
    final subscription = event['data']['object'];
    final customerId = subscription['customer'];

    _logger.i('Subscription created for customer: $customerId');
    // Backend should handle activating user subscription
  }

  static Future<void> _handleSubscriptionUpdated(
      Map<String, dynamic> event) async {
    final subscription = event['data']['object'];
    final customerId = subscription['customer'];

    _logger.i('Subscription updated for customer: $customerId');
    // Backend should handle updating user subscription
  }

  static Future<void> _handleSubscriptionDeleted(
      Map<String, dynamic> event) async {
    final subscription = event['data']['object'];
    final customerId = subscription['customer'];

    _logger.i('Subscription deleted for customer: $customerId');
    // Backend should handle deactivating user subscription
  }

  static Future<void> _handlePaymentSucceeded(
      Map<String, dynamic> event) async {
    final invoice = event['data']['object'];
    final customerId = invoice['customer'];

    _logger.i('Payment succeeded for customer: $customerId');
    // Backend should handle extending subscription
  }

  static Future<void> _handlePaymentFailed(Map<String, dynamic> event) async {
    final invoice = event['data']['object'];
    final customerId = invoice['customer'];

    _logger.i('Payment failed for customer: $customerId');
    // Backend should handle payment failure notifications
  }
}

/// Result classes for Stripe operations
class StripeCheckoutResult {
  final bool isSuccess;
  final String? sessionId;
  final String? url;
  final String? errorMessage;

  StripeCheckoutResult._({
    required this.isSuccess,
    this.sessionId,
    this.url,
    this.errorMessage,
  });

  factory StripeCheckoutResult.success({
    required String sessionId,
    required String url,
  }) {
    return StripeCheckoutResult._(
      isSuccess: true,
      sessionId: sessionId,
      url: url,
    );
  }

  factory StripeCheckoutResult.error({required String message}) {
    return StripeCheckoutResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class StripePaymentResult {
  final bool isSuccess;
  final String? errorMessage;
  final String? errorCode;

  StripePaymentResult._({
    required this.isSuccess,
    this.errorMessage,
    this.errorCode,
  });

  factory StripePaymentResult.success() {
    return StripePaymentResult._(isSuccess: true);
  }

  factory StripePaymentResult.error({
    required String message,
    String? code,
  }) {
    return StripePaymentResult._(
      isSuccess: false,
      errorMessage: message,
      errorCode: code,
    );
  }
}

class StripePortalResult {
  final bool isSuccess;
  final String? url;
  final String? errorMessage;

  StripePortalResult._({
    required this.isSuccess,
    this.url,
    this.errorMessage,
  });

  factory StripePortalResult.success({required String url}) {
    return StripePortalResult._(
      isSuccess: true,
      url: url,
    );
  }

  factory StripePortalResult.error({required String message}) {
    return StripePortalResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class StripeCancelResult {
  final bool isSuccess;
  final DateTime? cancelledAt;
  final String? errorMessage;

  StripeCancelResult._({
    required this.isSuccess,
    this.cancelledAt,
    this.errorMessage,
  });

  factory StripeCancelResult.success({DateTime? cancelledAt}) {
    return StripeCancelResult._(
      isSuccess: true,
      cancelledAt: cancelledAt,
    );
  }

  factory StripeCancelResult.error({required String message}) {
    return StripeCancelResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class StripeUpdateResult {
  final bool isSuccess;
  final DateTime? updatedAt;
  final String? errorMessage;

  StripeUpdateResult._({
    required this.isSuccess,
    this.updatedAt,
    this.errorMessage,
  });

  factory StripeUpdateResult.success({required DateTime updatedAt}) {
    return StripeUpdateResult._(
      isSuccess: true,
      updatedAt: updatedAt,
    );
  }

  factory StripeUpdateResult.error({required String message}) {
    return StripeUpdateResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

/// Stripe subscription status model
class StripeSubscriptionStatus {
  final String subscriptionId;
  final String customerId;
  final String status;
  final String? currentPeriodEnd;
  final String? cancelAtPeriodEnd;
  final String? canceledAt;
  final Map<String, dynamic>? metadata;

  StripeSubscriptionStatus({
    required this.subscriptionId,
    required this.customerId,
    required this.status,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd,
    this.canceledAt,
    this.metadata,
  });

  factory StripeSubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return StripeSubscriptionStatus(
      subscriptionId: json['subscriptionId'] as String,
      customerId: json['customerId'] as String,
      status: json['status'] as String,
      currentPeriodEnd: json['currentPeriodEnd'] as String?,
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] as String?,
      canceledAt: json['canceledAt'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  bool get isActive => status == 'active';

  bool get isCanceled => status == 'canceled';

  bool get isPastDue => status == 'past_due';

  bool get willCancelAtPeriodEnd => cancelAtPeriodEnd == 'true';

  DateTime? get currentPeriodEndDate {
    if (currentPeriodEnd == null) return null;
    return DateTime.tryParse(currentPeriodEnd!);
  }
}

/// Stripe price model
class StripePrice {
  final String id;
  final String productId;
  final String nickname;
  final int unitAmount;
  final String currency;
  final String interval;
  final int intervalCount;
  final Map<String, dynamic>? metadata;

  StripePrice({
    required this.id,
    required this.productId,
    required this.nickname,
    required this.unitAmount,
    required this.currency,
    required this.interval,
    required this.intervalCount,
    this.metadata,
  });

  factory StripePrice.fromJson(Map<String, dynamic> json) {
    return StripePrice(
      id: json['id'] as String,
      productId: json['productId'] as String,
      nickname: json['nickname'] as String,
      unitAmount: json['unitAmount'] as int,
      currency: json['currency'] as String,
      interval: json['interval'] as String,
      intervalCount: json['intervalCount'] as int,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  double get price => unitAmount / 100.0; // Convert from cents
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  String get intervalText {
    if (intervalCount == 1) {
      return '/$interval';
    }
    return '/${intervalCount} ${interval}s';
  }
}
