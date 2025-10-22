import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

/// Subscription model for freelancer subscriptions
class SubscriptionModel {
  final String userId;
  final String status; // 'none', 'trial', 'active', 'expired', 'cancelled'
  final String? plan; // 'monthly' or 'yearly'
  final DateTime? startDate;
  final DateTime? endDate;
  final bool autoRenewal;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionModel({
    required this.userId,
    required this.status,
    this.plan,
    this.startDate,
    this.endDate,
    required this.autoRenewal,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if subscription is active (including trial)
  bool get isActive =>
      status == AppConstants.subscriptionActive ||
      status == AppConstants.subscriptionTrial;

  /// Check if subscription is expired
  bool get isExpired => status == AppConstants.subscriptionExpired;

  /// Check if in trial period
  bool get isTrial => status == AppConstants.subscriptionTrial;

  /// Check if subscription exists
  bool get hasSubscription => status != AppConstants.subscriptionNone;

  /// Get days remaining
  int? get daysRemaining {
    if (endDate == null) return null;
    final now = DateTime.now();
    if (endDate!.isBefore(now)) return 0;
    return endDate!.difference(now).inDays;
  }

  /// Check if subscription is expiring soon (less than 7 days)
  bool get isExpiringSoon {
    final days = daysRemaining;
    return days != null && days > 0 && days <= 7;
  }

  /// Factory constructor from Firestore document
  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SubscriptionModel(
      userId: data['userId'] ?? doc.id,
      status: data['status'] ?? AppConstants.subscriptionNone,
      plan: data['plan'],
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      autoRenewal: data['autoRenewal'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'status': status,
      'plan': plan,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'autoRenewal': autoRenewal,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  SubscriptionModel copyWith({
    String? userId,
    String? status,
    String? plan,
    DateTime? startDate,
    DateTime? endDate,
    bool? autoRenewal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionModel(
      userId: userId ?? this.userId,
      status: status ?? this.status,
      plan: plan ?? this.plan,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      autoRenewal: autoRenewal ?? this.autoRenewal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Payment record model
class PaymentModel {
  final String paymentId;
  final String orderId;
  final String userId;
  final int amount;
  final String currency;
  final String plan;
  final String status; // 'success', 'failed', 'pending'
  final String? razorpaySignature;
  final DateTime createdAt;

  PaymentModel({
    required this.paymentId,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.plan,
    required this.status,
    this.razorpaySignature,
    required this.createdAt,
  });

  /// Factory constructor from Firestore document
  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PaymentModel(
      paymentId: data['paymentId'] ?? '',
      orderId: data['orderId'] ?? '',
      userId: data['userId'] ?? '',
      amount: data['amount'] ?? 0,
      currency: data['currency'] ?? 'INR',
      plan: data['plan'] ?? '',
      status: data['status'] ?? 'pending',
      razorpaySignature: data['razorpaySignature'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'paymentId': paymentId,
      'orderId': orderId,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'plan': plan,
      'status': status,
      'razorpaySignature': razorpaySignature,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Subscription pricing configuration
class SubscriptionPricing {
  final int monthlyPrice;
  final int yearlyPrice;
  final String currency;

  SubscriptionPricing({
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.currency,
  });

  /// Calculate yearly discount percentage
  int get yearlyDiscountPercent {
    final monthlyYearlyCost = monthlyPrice * 12;
    final savings = monthlyYearlyCost - yearlyPrice;
    return ((savings / monthlyYearlyCost) * 100).round();
  }

  /// Get monthly savings for yearly plan
  int get monthlySavings {
    final monthlyYearlyCost = monthlyPrice * 12;
    return monthlyYearlyCost - yearlyPrice;
  }

  /// Factory constructor from Firestore document
  factory SubscriptionPricing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SubscriptionPricing(
      monthlyPrice: data['monthlyPrice'] ?? 299,
      yearlyPrice: data['yearlyPrice'] ?? 2990,
      currency: data['currency'] ?? 'INR',
    );
  }

  /// Default pricing (fallback)
  factory SubscriptionPricing.defaults() {
    return SubscriptionPricing(
      monthlyPrice: 299,
      yearlyPrice: 2990,
      currency: 'INR',
    );
  }
}

/// Trial settings configuration
class TrialSettings {
  final bool enabled;
  final int days;

  TrialSettings({
    required this.enabled,
    required this.days,
  });

  /// Factory constructor from Firestore document
  factory TrialSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TrialSettings(
      enabled: data['enabled'] ?? true,
      days: data['days'] ?? 7,
    );
  }

  /// Default trial settings (fallback)
  factory TrialSettings.defaults() {
    return TrialSettings(
      enabled: true,
      days: 7,
    );
  }
}
