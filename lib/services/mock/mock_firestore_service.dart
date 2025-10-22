import '../../models/user_model.dart';
import '../../models/subscription_model.dart';
import '../../utils/app_config.dart';
import '../../utils/constants.dart';

/// Mock Firestore service for demo mode (no Firebase required)
class MockFirestoreService {
  // In-memory storage
  final Map<String, UserModel> _users = {};
  final Map<String, SubscriptionModel> _subscriptions = {};
  final Map<String, PaymentModel> _payments = {};
  final Map<String, dynamic> _appConfig = {};

  MockFirestoreService() {
    _initializeMockData();
  }

  /// Initialize mock data
  void _initializeMockData() {
    // Mock subscription pricing
    _appConfig['subscription_pricing'] = {
      'monthlyPrice': 299,
      'yearlyPrice': 2990,
      'currency': 'INR',
    };

    // Mock trial settings
    _appConfig['trial_settings'] = {
      'enabled': true,
      'days': 7,
    };

    AppConfig.log('Mock: Firestore data initialized');
  }

  /// Get subscription pricing
  Future<SubscriptionPricing> getSubscriptionPricing() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final data = _appConfig['subscription_pricing'] as Map<String, dynamic>;

    return SubscriptionPricing(
      monthlyPrice: data['monthlyPrice'] as int,
      yearlyPrice: data['yearlyPrice'] as int,
      currency: data['currency'] as String,
    );
  }

  /// Get trial settings
  Future<TrialSettings> getTrialSettings() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final data = _appConfig['trial_settings'] as Map<String, dynamic>;

    return TrialSettings(
      enabled: data['enabled'] as bool,
      days: data['days'] as int,
    );
  }

  /// Get user subscription
  Future<SubscriptionModel?> getSubscription(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Return existing subscription or create mock one
    if (_subscriptions.containsKey(userId)) {
      return _subscriptions[userId];
    }

    // Create mock subscription based on config
    if (AppConfig.mockIsInTrial) {
      final subscription = SubscriptionModel(
        userId: userId,
        status: AppConstants.subscriptionTrial,
        plan: null,
        startDate: DateTime.now().subtract(Duration(days: 7 - AppConfig.mockTrialDaysRemaining)),
        endDate: DateTime.now().add(Duration(days: AppConfig.mockTrialDaysRemaining)),
        autoRenewal: false,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now(),
      );

      _subscriptions[userId] = subscription;
      return subscription;
    } else if (AppConfig.mockHasActiveSubscription) {
      final subscription = SubscriptionModel(
        userId: userId,
        status: AppConstants.subscriptionActive,
        plan: AppConfig.mockSubscriptionPlan,
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        endDate: DateTime.now().add(const Duration(days: 20)),
        autoRenewal: true,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      );

      _subscriptions[userId] = subscription;
      return subscription;
    }

    // No subscription
    return SubscriptionModel(
      userId: userId,
      status: AppConstants.subscriptionNone,
      plan: null,
      startDate: null,
      endDate: null,
      autoRenewal: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Start trial
  Future<void> startTrial(String userId) async {
    AppConfig.log('Mock: Starting trial for $userId');
    await Future.delayed(const Duration(milliseconds: 500));

    final subscription = SubscriptionModel(
      userId: userId,
      status: AppConstants.subscriptionTrial,
      plan: null,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
      autoRenewal: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _subscriptions[userId] = subscription;

    // Update user
    if (_users.containsKey(userId)) {
      final user = _users[userId]!;
      _users[userId] = user.copyWith(
        subscriptionStatus: AppConstants.subscriptionTrial,
      );
    }
  }

  /// Activate subscription
  Future<void> activateSubscription({
    required String userId,
    required String plan,
    required String paymentId,
  }) async {
    AppConfig.log('Mock: Activating $plan subscription for $userId');
    await Future.delayed(const Duration(milliseconds: 500));

    final endDate = plan == AppConstants.planMonthly
        ? DateTime.now().add(const Duration(days: 30))
        : DateTime.now().add(const Duration(days: 365));

    final subscription = SubscriptionModel(
      userId: userId,
      status: AppConstants.subscriptionActive,
      plan: plan,
      startDate: DateTime.now(),
      endDate: endDate,
      autoRenewal: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _subscriptions[userId] = subscription;

    // Update user
    if (_users.containsKey(userId)) {
      final user = _users[userId]!;
      _users[userId] = user.copyWith(
        subscriptionStatus: AppConstants.subscriptionActive,
        subscriptionPlan: plan,
        autoRenewal: true,
      );
    }
  }

  /// Cancel subscription
  Future<void> cancelSubscription(String userId) async {
    AppConfig.log('Mock: Cancelling subscription for $userId');
    await Future.delayed(const Duration(milliseconds: 500));

    if (_subscriptions.containsKey(userId)) {
      final current = _subscriptions[userId]!;
      _subscriptions[userId] = SubscriptionModel(
        userId: current.userId,
        status: AppConstants.subscriptionCancelled,
        plan: current.plan,
        startDate: current.startDate,
        endDate: current.endDate,
        autoRenewal: false,
        createdAt: current.createdAt,
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Get payment history
  Future<List<PaymentModel>> getPaymentHistory(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final userPayments = _payments.values
        .where((payment) => payment.userId == userId)
        .toList();

    // Sort by date descending
    userPayments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return userPayments;
  }

  /// Save payment
  Future<void> savePayment(PaymentModel payment) async {
    AppConfig.log('Mock: Saving payment ${payment.paymentId}');
    await Future.delayed(const Duration(milliseconds: 300));
    _payments[payment.paymentId] = payment;
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    AppConfig.log('Mock: Updating profile for $userId');
    await Future.delayed(const Duration(milliseconds: 500));

    if (_users.containsKey(userId)) {
      final currentUser = _users[userId]!;

      _users[userId] = UserModel(
        userId: currentUser.userId,
        phoneNumber: currentUser.phoneNumber,
        role: currentUser.role,
        name: data['name'] ?? currentUser.name,
        email: data['email'] ?? currentUser.email,
        profilePictureUrl: data['profilePictureUrl'] ?? currentUser.profilePictureUrl,
        serviceCategories: data['serviceCategories'] ?? currentUser.serviceCategories,
        rate: data['rate'] ?? currentUser.rate,
        rateType: data['rateType'] ?? currentUser.rateType,
        city: data['city'] ?? currentUser.city,
        state: data['state'] ?? currentUser.state,
        serviceRadius: data['serviceRadius'] ?? currentUser.serviceRadius,
        description: data['description'] ?? currentUser.description,
        subscriptionStatus: currentUser.subscriptionStatus,
        subscriptionPlan: currentUser.subscriptionPlan,
        autoRenewal: currentUser.autoRenewal,
        rating: currentUser.rating,
        totalBookings: currentUser.totalBookings,
        completedBookings: currentUser.completedBookings,
        isAvailable: data['isAvailable'] ?? currentUser.isAvailable,
        createdAt: currentUser.createdAt,
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Get user
  Future<UserModel?> getUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _users[userId];
  }

  /// Set user
  void setUser(String userId, UserModel user) {
    _users[userId] = user;
  }

  /// Check trial eligibility
  Future<bool> isEligibleForTrial(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Check if user has ever had a subscription
    if (_subscriptions.containsKey(userId)) {
      final sub = _subscriptions[userId]!;
      return sub.status == AppConstants.subscriptionNone;
    }

    return true; // Eligible if no subscription record
  }
}
