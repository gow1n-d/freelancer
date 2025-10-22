import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription_model.dart';
import '../utils/constants.dart';
import '../utils/app_config.dart';
import 'mock/mock_firestore_service.dart';

/// Service for managing subscriptions
class SubscriptionService {
  final FirebaseFirestore? _firestore;
  final MockFirestoreService? _mockFirestore;

  SubscriptionService({MockFirestoreService? mockFirestore})
      : _firestore = AppConfig.enableMockMode ? null : FirebaseFirestore.instance,
        _mockFirestore = AppConfig.enableMockMode ? mockFirestore : null;

  /// Get subscription pricing from Firestore (or mock)
  Future<SubscriptionPricing> getPricing() async {
    try {
      if (AppConfig.enableMockMode && _mockFirestore != null) {
        return await _mockFirestore!.getSubscriptionPricing();
      }

      final doc = await _firestore!
          .collection(AppConstants.appConfigCollection)
          .doc(AppConstants.subscriptionPricingDoc)
          .get();

      if (doc.exists) {
        return SubscriptionPricing.fromFirestore(doc);
      }

      // Return defaults if not configured
      return SubscriptionPricing.defaults();
    } catch (e) {
      // Return defaults on error
      return SubscriptionPricing.defaults();
    }
  }

  /// Get trial settings from Firestore (or mock)
  Future<TrialSettings> getTrialSettings() async {
    try {
      if (AppConfig.enableMockMode && _mockFirestore != null) {
        return await _mockFirestore!.getTrialSettings();
      }

      final doc = await _firestore!
          .collection(AppConstants.appConfigCollection)
          .doc(AppConstants.trialSettingsDoc)
          .get();

      if (doc.exists) {
        return TrialSettings.fromFirestore(doc);
      }

      // Return defaults if not configured
      return TrialSettings.defaults();
    } catch (e) {
      // Return defaults on error
      return TrialSettings.defaults();
    }
  }

  /// Get user's subscription
  Future<SubscriptionModel?> getSubscription(String userId) async {
    try {
      if (AppConfig.enableMockMode && _mockFirestore != null) {
        return await _mockFirestore!.getSubscription(userId);
      }

      final doc = await _firestore!
          .collection(AppConstants.subscriptionsCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return SubscriptionModel.fromFirestore(doc);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch subscription: $e');
    }
  }

  /// Stream user's subscription
  Stream<SubscriptionModel?> streamSubscription(String userId) {
    if (AppConfig.enableMockMode) {
      // Mock mode doesn't support streams, return current value
      return Stream.value(null);
    }

    return _firestore!
        .collection(AppConstants.subscriptionsCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return SubscriptionModel.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Start trial period for user
  Future<void> startTrial(String userId) async {
    try {
      if (AppConfig.enableMockMode && _mockFirestore != null) {
        return await _mockFirestore!.startTrial(userId);
      }

      final trialSettings = await getTrialSettings();

      if (!trialSettings.enabled) {
        throw Exception('Trial is not enabled');
      }

      final now = DateTime.now();
      final endDate = now.add(Duration(days: trialSettings.days));

      final subscription = SubscriptionModel(
        userId: userId,
        status: AppConstants.subscriptionTrial,
        plan: null,
        startDate: now,
        endDate: endDate,
        autoRenewal: false,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore!
          .collection(AppConstants.subscriptionsCollection)
          .doc(userId)
          .set(subscription.toFirestore());

      // Update user document
      await _firestore!.collection(AppConstants.usersCollection).doc(userId).update({
        'subscriptionStatus': AppConstants.subscriptionTrial,
        'subscriptionStartDate': Timestamp.fromDate(now),
        'subscriptionEndDate': Timestamp.fromDate(endDate),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to start trial: $e');
    }
  }

  /// Activate subscription after payment
  Future<void> activateSubscription({
    required String userId,
    required String plan,
    required String paymentId,
  }) async {
    try {
      if (AppConfig.enableMockMode && _mockFirestore != null) {
        return await _mockFirestore!.activateSubscription(
          userId: userId,
          plan: plan,
          paymentId: paymentId,
        );
      }

      final now = DateTime.now();
      DateTime endDate;

      // Calculate end date based on plan
      if (plan == AppConstants.planMonthly) {
        endDate = DateTime(now.year, now.month + 1, now.day);
      } else {
        // Yearly
        endDate = DateTime(now.year + 1, now.month, now.day);
      }

      final subscription = SubscriptionModel(
        userId: userId,
        status: AppConstants.subscriptionActive,
        plan: plan,
        startDate: now,
        endDate: endDate,
        autoRenewal: true,
        createdAt: now,
        updatedAt: now,
      );

      // Update subscription document
      await _firestore!
          .collection(AppConstants.subscriptionsCollection)
          .doc(userId)
          .set(subscription.toFirestore());

      // Update user document
      await _firestore!.collection(AppConstants.usersCollection).doc(userId).update({
        'subscriptionStatus': AppConstants.subscriptionActive,
        'subscriptionPlan': plan,
        'subscriptionStartDate': Timestamp.fromDate(now),
        'subscriptionEndDate': Timestamp.fromDate(endDate),
        'autoRenewal': true,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to activate subscription: $e');
    }
  }

  /// Cancel subscription (marks for non-renewal at end of period)
  Future<void> cancelSubscription(String userId) async {
    try {
      if (AppConfig.enableMockMode && _mockFirestore != null) {
        return await _mockFirestore!.cancelSubscription(userId);
      }

      await _firestore!
          .collection(AppConstants.subscriptionsCollection)
          .doc(userId)
          .update({
        'status': AppConstants.subscriptionCancelled,
        'autoRenewal': false,
        'updatedAt': Timestamp.now(),
      });

      await _firestore!.collection(AppConstants.usersCollection).doc(userId).update({
        'autoRenewal': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to cancel subscription: $e');
    }
  }

  /// Get payment history for user
  Future<List<PaymentModel>> getPaymentHistory(String userId) async {
    try {
      if (AppConfig.enableMockMode && _mockFirestore != null) {
        return await _mockFirestore!.getPaymentHistory(userId);
      }

      final snapshot = await _firestore!
          .collection(AppConstants.paymentsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch payment history: $e');
    }
  }

  /// Check if user is eligible for trial
  Future<bool> isEligibleForTrial(String userId) async {
    try {
      if (AppConfig.enableMockMode && _mockFirestore != null) {
        return await _mockFirestore!.isEligibleForTrial(userId);
      }

      // Check if user already has or had a subscription
      final subscription = await getSubscription(userId);

      // Eligible if no subscription or never subscribed
      return subscription == null ||
          subscription.status == AppConstants.subscriptionNone;
    } catch (e) {
      return false;
    }
  }

  /// Format subscription status for display
  String formatStatus(String status) {
    switch (status) {
      case AppConstants.subscriptionNone:
        return 'No Subscription';
      case AppConstants.subscriptionTrial:
        return 'Free Trial';
      case AppConstants.subscriptionActive:
        return 'Active';
      case AppConstants.subscriptionExpired:
        return 'Expired';
      case AppConstants.subscriptionCancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  /// Format plan for display
  String formatPlan(String? plan) {
    if (plan == null) return 'No Plan';
    return plan == AppConstants.planMonthly ? 'Monthly' : 'Yearly';
  }
}
