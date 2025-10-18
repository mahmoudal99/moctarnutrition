import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'config_service.dart';

/// Service for fetching Stripe analytics and metrics data
/// This service provides revenue, sales, and transaction metrics for the admin dashboard
class StripeAnalyticsService {
  static final _logger = Logger();
  static String? _backendUrl;

  /// Initialize the service with backend URL
  static Future<void> initialize() async {
    _backendUrl = ConfigService.stripeBackendUrl;
    _logger.i('StripeAnalyticsService initialized');
  }

  /// Get revenue metrics for a specific time period
  static Future<StripeRevenueMetrics?> getRevenueMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _logger.i('Fetching revenue metrics');
      
      final response = await http.get(
        Uri.parse('$_backendUrl/getRevenueMetrics').replace(
          queryParameters: {
            if (startDate != null) 'startDate': startDate.toIso8601String(),
            if (endDate != null) 'endDate': endDate.toIso8601String(),
          },
        ),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StripeRevenueMetrics.fromJson(data);
      } else {
        _logger.w('Failed to get revenue metrics: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting revenue metrics: $e');
      return null;
    }
  }

  /// Get product sales metrics
  static Future<StripeSalesMetrics?> getSalesMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _logger.i('Fetching sales metrics');
      
      final response = await http.get(
        Uri.parse('$_backendUrl/getSalesMetrics').replace(
          queryParameters: {
            if (startDate != null) 'startDate': startDate.toIso8601String(),
            if (endDate != null) 'endDate': endDate.toIso8601String(),
          },
        ),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StripeSalesMetrics.fromJson(data);
      } else {
        _logger.w('Failed to get sales metrics: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting sales metrics: $e');
      return null;
    }
  }

  /// Get transaction metrics
  static Future<StripeTransactionMetrics?> getTransactionMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _logger.i('Fetching transaction metrics');
      
      final response = await http.get(
        Uri.parse('$_backendUrl/getTransactionMetrics').replace(
          queryParameters: {
            if (startDate != null) 'startDate': startDate.toIso8601String(),
            if (endDate != null) 'endDate': endDate.toIso8601String(),
          },
        ),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StripeTransactionMetrics.fromJson(data);
      } else {
        _logger.w('Failed to get transaction metrics: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting transaction metrics: $e');
      return null;
    }
  }

  /// Get comprehensive dashboard metrics
  static Future<StripeDashboardMetrics?> getDashboardMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _logger.i('Fetching comprehensive dashboard metrics');
      
      final response = await http.get(
        Uri.parse('$_backendUrl/getDashboardMetrics').replace(
          queryParameters: {
            if (startDate != null) 'startDate': startDate.toIso8601String(),
            if (endDate != null) 'endDate': endDate.toIso8601String(),
          },
        ),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StripeDashboardMetrics.fromJson(data);
      } else {
        _logger.w('Failed to get dashboard metrics: ${response.statusCode}');
        _logger.w('Error response: ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting dashboard metrics: $e');
      return null;
    }
  }

  /// Get recent transactions
  static Future<List<RecentTransaction>?> getRecentTransactions({
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _logger.i('Fetching recent transactions with limit: $limit');
      
      final response = await http.get(
        Uri.parse('$_backendUrl/getRecentTransactions').replace(
          queryParameters: {
            'limit': limit.toString(),
            if (startDate != null) 'startDate': startDate.toIso8601String(),
            if (endDate != null) 'endDate': endDate.toIso8601String(),
          },
        ),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final transactionsList = (data['transactions'] as List<dynamic>?)
            ?.map((item) => RecentTransaction.fromJson(item as Map<String, dynamic>))
            .toList() ?? [];
        return transactionsList;
      } else {
        _logger.w('Failed to get recent transactions: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting recent transactions: $e');
      return null;
    }
  }

  /// Get metrics for a specific time period (helper method)
  static Future<StripeDashboardMetrics?> getMetricsForPeriod(String period) async {
    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate = now;

    switch (period.toLowerCase()) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'this week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'this month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'last month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        startDate = lastMonth;
        endDate = DateTime(now.year, now.month, 1).subtract(const Duration(days: 1));
        break;
      case 'this year':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'last year':
        startDate = DateTime(now.year - 1, 1, 1);
        endDate = DateTime(now.year, 1, 1).subtract(const Duration(days: 1));
        break;
    }

    return getDashboardMetrics(startDate: startDate, endDate: endDate);
  }
}

/// Model for Stripe revenue metrics
class StripeRevenueMetrics {
  final double totalRevenue;
  final double netRevenue;
  final double refundedAmount;
  final int totalTransactions;
  final double averageTransactionValue;
  final String currency;
  final double? previousPeriodRevenue;
  final double? revenueGrowth;

  StripeRevenueMetrics({
    required this.totalRevenue,
    required this.netRevenue,
    required this.refundedAmount,
    required this.totalTransactions,
    required this.averageTransactionValue,
    required this.currency,
    this.previousPeriodRevenue,
    this.revenueGrowth,
  });

  factory StripeRevenueMetrics.fromJson(Map<String, dynamic> json) {
    return StripeRevenueMetrics(
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      netRevenue: (json['netRevenue'] as num).toDouble(),
      refundedAmount: (json['refundedAmount'] as num).toDouble(),
      totalTransactions: json['totalTransactions'] as int,
      averageTransactionValue: (json['averageTransactionValue'] as num).toDouble(),
      currency: json['currency'] as String,
      previousPeriodRevenue: json['previousPeriodRevenue'] != null 
          ? (json['previousPeriodRevenue'] as num).toDouble() 
          : null,
      revenueGrowth: json['revenueGrowth'] != null 
          ? (json['revenueGrowth'] as num).toDouble() 
          : null,
    );
  }

  String get formattedTotalRevenue => '${_getCurrencySymbol()}${totalRevenue.toStringAsFixed(2)}';
  String get formattedNetRevenue => '${_getCurrencySymbol()}${netRevenue.toStringAsFixed(2)}';
  String get formattedAverageTransaction => '${_getCurrencySymbol()}${averageTransactionValue.toStringAsFixed(2)}';
  
  String _getCurrencySymbol() {
    switch (currency.toLowerCase()) {
      case 'eur':
        return '€';
      case 'usd':
        return '\$';
      default:
        return '€'; // Default to euro
    }
  }
  
  String? get formattedRevenueGrowth {
    if (revenueGrowth == null) return null;
    final sign = revenueGrowth! >= 0 ? '+' : '';
    return '$sign${revenueGrowth!.toStringAsFixed(2)}%';
  }
}

/// Model for Stripe sales metrics
class StripeSalesMetrics {
  final Map<String, int> productSales;
  final int totalSales;
  final double totalSalesValue;
  final String currency;
  final double? previousPeriodSales;
  final double? salesGrowth;

  StripeSalesMetrics({
    required this.productSales,
    required this.totalSales,
    required this.totalSalesValue,
    required this.currency,
    this.previousPeriodSales,
    this.salesGrowth,
  });

  factory StripeSalesMetrics.fromJson(Map<String, dynamic> json) {
    return StripeSalesMetrics(
      productSales: Map<String, int>.from(json['productSales'] as Map),
      totalSales: json['totalSales'] as int,
      totalSalesValue: (json['totalSalesValue'] as num).toDouble(),
      currency: json['currency'] as String,
      previousPeriodSales: json['previousPeriodSales'] != null 
          ? (json['previousPeriodSales'] as num).toDouble() 
          : null,
      salesGrowth: json['salesGrowth'] != null 
          ? (json['salesGrowth'] as num).toDouble() 
          : null,
    );
  }

  String get formattedTotalSalesValue => '${_getCurrencySymbol()}${totalSalesValue.toStringAsFixed(2)}';
  
  String _getCurrencySymbol() {
    switch (currency.toLowerCase()) {
      case 'eur':
        return '€';
      case 'usd':
        return '\$';
      default:
        return '€'; // Default to euro
    }
  }
  
  String? get formattedSalesGrowth {
    if (salesGrowth == null) return null;
    final sign = salesGrowth! >= 0 ? '+' : '';
    return '$sign${salesGrowth!.toStringAsFixed(2)}%';
  }
}

/// Model for Stripe transaction metrics
class StripeTransactionMetrics {
  final int totalTransactions;
  final int successfulTransactions;
  final int failedTransactions;
  final double successRate;
  final double averageTransactionValue;
  final String currency;
  final int? previousPeriodTransactions;
  final double? transactionGrowth;

  StripeTransactionMetrics({
    required this.totalTransactions,
    required this.successfulTransactions,
    required this.failedTransactions,
    required this.successRate,
    required this.averageTransactionValue,
    required this.currency,
    this.previousPeriodTransactions,
    this.transactionGrowth,
  });

  factory StripeTransactionMetrics.fromJson(Map<String, dynamic> json) {
    return StripeTransactionMetrics(
      totalTransactions: json['totalTransactions'] as int,
      successfulTransactions: json['successfulTransactions'] as int,
      failedTransactions: json['failedTransactions'] as int,
      successRate: (json['successRate'] as num).toDouble(),
      averageTransactionValue: (json['averageTransactionValue'] as num).toDouble(),
      currency: json['currency'] as String,
      previousPeriodTransactions: json['previousPeriodTransactions'] as int?,
      transactionGrowth: json['transactionGrowth'] != null 
          ? (json['transactionGrowth'] as num).toDouble() 
          : null,
    );
  }

  String get formattedAverageTransaction => '\$${averageTransactionValue.toStringAsFixed(2)}';
  String get formattedSuccessRate => '${successRate.toStringAsFixed(1)}%';
  
  String? get formattedTransactionGrowth {
    if (transactionGrowth == null) return null;
    final sign = transactionGrowth! >= 0 ? '+' : '';
    return '$sign${transactionGrowth!.toStringAsFixed(2)}%';
  }
}

/// Model for historical revenue data points
class HistoricalDataPoint {
  final String date;
  final double revenue;

  HistoricalDataPoint({
    required this.date,
    required this.revenue,
  });

  factory HistoricalDataPoint.fromJson(Map<String, dynamic> json) {
    return HistoricalDataPoint(
      date: json['date'] as String,
      revenue: (json['revenue'] as num).toDouble(),
    );
  }
}

/// Model for recent transaction data
class RecentTransaction {
  final String id;
  final double amount;
  final String currency;
  final String status;
  final String productName;
  final String? customerEmail;
  final String? userId;
  final DateTime created;
  final String description;

  RecentTransaction({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.productName,
    this.customerEmail,
    this.userId,
    required this.created,
    required this.description,
  });

  factory RecentTransaction.fromJson(Map<String, dynamic> json) {
    return RecentTransaction(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      status: json['status'] as String,
      productName: json['productName'] as String,
      customerEmail: json['customerEmail'] as String?,
      userId: json['userId'] as String?,
      created: DateTime.parse(json['created'] as String),
      description: json['description'] as String,
    );
  }

  String get formattedAmount {
    final symbol = _getCurrencySymbol();
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  String _getCurrencySymbol() {
    switch (currency.toLowerCase()) {
      case 'eur':
        return '€';
      case 'usd':
        return '\$';
      default:
        return '€'; // Default to euro
    }
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(created);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${created.day}/${created.month}/${created.year}';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'succeeded':
        return const Color(0xFF10B981); // Green
      case 'requires_payment_method':
      case 'requires_confirmation':
        return const Color(0xFFF59E0B); // Yellow
      case 'canceled':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }
}

/// Comprehensive dashboard metrics model
class StripeDashboardMetrics {
  final StripeRevenueMetrics revenue;
  final StripeSalesMetrics sales;
  final StripeTransactionMetrics transactions;
  final int activeCustomers;
  final int newCustomers;
  final List<HistoricalDataPoint> historicalData;
  final List<RecentTransaction> recentTransactions;
  final DateTime lastUpdated;

  StripeDashboardMetrics({
    required this.revenue,
    required this.sales,
    required this.transactions,
    required this.activeCustomers,
    required this.newCustomers,
    required this.historicalData,
    required this.recentTransactions,
    required this.lastUpdated,
  });

  factory StripeDashboardMetrics.fromJson(Map<String, dynamic> json) {
    final historicalDataList = (json['historicalData'] as List<dynamic>?)
        ?.map((item) => HistoricalDataPoint.fromJson(item as Map<String, dynamic>))
        .toList() ?? [];
    
    final recentTransactionsList = (json['recentTransactions'] as List<dynamic>?)
        ?.map((item) => RecentTransaction.fromJson(item as Map<String, dynamic>))
        .toList() ?? [];
    
    return StripeDashboardMetrics(
      revenue: StripeRevenueMetrics.fromJson(json['revenue'] as Map<String, dynamic>),
      sales: StripeSalesMetrics.fromJson(json['sales'] as Map<String, dynamic>),
      transactions: StripeTransactionMetrics.fromJson(json['transactions'] as Map<String, dynamic>),
      activeCustomers: json['activeCustomers'] as int,
      newCustomers: json['newCustomers'] as int,
      historicalData: historicalDataList,
      recentTransactions: recentTransactionsList,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
}
