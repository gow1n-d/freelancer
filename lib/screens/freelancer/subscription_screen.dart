import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/subscription_model.dart';
import '../../services/auth_provider.dart';
import '../../services/subscription_service.dart';
import '../../services/payment_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Screen for selecting and purchasing subscription plans
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _subscriptionService = SubscriptionService();
  final _paymentService = PaymentService();

  SubscriptionPricing? _pricing;
  TrialSettings? _trialSettings;
  SubscriptionModel? _currentSubscription;
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _isTrialEligible = false;

  String? _selectedPlan;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initializePayment();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.firebaseUser?.uid;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Load pricing, trial settings, and current subscription in parallel
      final results = await Future.wait([
        _subscriptionService.getPricing(),
        _subscriptionService.getTrialSettings(),
        _subscriptionService.getSubscription(userId),
        _subscriptionService.isEligibleForTrial(userId),
      ]);

      setState(() {
        _pricing = results[0] as SubscriptionPricing;
        _trialSettings = results[1] as TrialSettings;
        _currentSubscription = results[2] as SubscriptionModel?;
        _isTrialEligible = results[3] as bool;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load subscription data: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _initializePayment() {
    _paymentService.initializeRazorpay(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onExternalWallet: _handleExternalWallet,
    );
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.firebaseUser?.uid;

      if (userId == null || _selectedPlan == null) {
        throw Exception('Missing user or plan information');
      }

      // Verify payment with backend
      final isVerified = await _paymentService.verifyPayment(
        orderId: response.orderId ?? '',
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
        userId: userId,
        planType: _selectedPlan!,
      );

      if (!isVerified) {
        throw Exception('Payment verification failed');
      }

      // Activate subscription
      await _subscriptionService.activateSubscription(
        userId: userId,
        plan: _selectedPlan!,
        paymentId: response.paymentId ?? '',
      );

      // Save payment record
      final amount = _selectedPlan == AppConstants.planMonthly
          ? _pricing!.monthlyPrice
          : _pricing!.yearlyPrice;

      await _paymentService.savePayment(
        paymentId: response.paymentId ?? '',
        orderId: response.orderId ?? '',
        userId: userId,
        amount: amount,
        plan: _selectedPlan!,
        status: 'success',
        razorpaySignature: response.signature,
      );

      // Refresh user data
      await authProvider.refreshUserData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription activated successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to activate subscription: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
        _selectedPlan = null;
      });
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    // Log payment error
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.firebaseUser?.uid;

    if (userId != null) {
      _paymentService.logPaymentError(
        userId: userId,
        orderId: response.message ?? '',
        errorCode: response.code.toString(),
        errorMessage: response.message ?? 'Unknown error',
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message}'),
        backgroundColor: AppTheme.errorColor,
      ),
    );

    _selectedPlan = null;
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet: ${response.walletName}'),
        backgroundColor: AppTheme.infoColor,
      ),
    );

    _selectedPlan = null;
  }

  Future<void> _handleStartTrial() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.firebaseUser?.uid;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _subscriptionService.startTrial(userId);
      await authProvider.refreshUserData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_trialSettings!.days}-day trial started!'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start trial: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleSubscribe(String planType) async {
    setState(() {
      _isProcessing = true;
      _selectedPlan = planType;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.firebaseUser?.uid;
      final user = authProvider.currentUser;

      if (userId == null || user == null) {
        throw Exception('User not authenticated');
      }

      final amount = planType == AppConstants.planMonthly
          ? _pricing!.monthlyPrice
          : _pricing!.yearlyPrice;

      // Create order via Cloud Function
      final orderData = await _paymentService.createOrder(
        userId: userId,
        planType: planType,
        amount: amount * 100, // Convert to paise
      );

      // Open Razorpay checkout
      _paymentService.openCheckout(
        orderId: orderData['orderId'],
        amount: orderData['amount'],
        userPhone: user.phoneNumber,
        userName: user.name.isNotEmpty ? user.name : null,
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _selectedPlan = null;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initiate payment: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header section
                  Text(
                    'Get Premium Access',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock all features and grow your business',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Trial banner (if eligible)
                  if (_trialSettings?.enabled == true && _isTrialEligible)
                    _buildTrialBanner(),

                  // Plan cards
                  if (_pricing != null) ...[
                    _buildPlanCard(
                      planType: AppConstants.planMonthly,
                      title: 'Monthly Plan',
                      price: _pricing!.monthlyPrice,
                      duration: 'month',
                      isPopular: false,
                    ),
                    const SizedBox(height: 16),
                    _buildPlanCard(
                      planType: AppConstants.planYearly,
                      title: 'Yearly Plan',
                      price: _pricing!.yearlyPrice,
                      duration: 'year',
                      isPopular: true,
                      discountPercent: _pricing!.yearlyDiscountPercent,
                      savings: _pricing!.monthlySavings,
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Features list
                  _buildFeaturesList(),

                  const SizedBox(height: 24),

                  // Processing indicator
                  if (_isProcessing)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildTrialBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.secondaryColor,
            AppTheme.secondaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.card_giftcard_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Try ${_trialSettings!.days}-Day Free Trial',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No credit card required',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isProcessing ? null : _handleStartTrial,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.secondaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Start Free Trial'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String planType,
    required String title,
    required int price,
    required String duration,
    required bool isPopular,
    int? discountPercent,
    int? savings,
  }) {
    final isCurrentPlan =
        _currentSubscription?.plan == planType && _currentSubscription!.isActive;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isPopular ? AppTheme.secondaryColor : AppTheme.borderColor,
          width: isPopular ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Popular badge
          if (isPopular)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
                child: Text(
                  'BEST VALUE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),

                // Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                    ),
                    Text(
                      price.toString(),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                    ),
                    Text(
                      '/$duration',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),

                // Discount badge
                if (discountPercent != null && discountPercent > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Save $discountPercent% (₹$savings/year)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Subscribe button
                ElevatedButton(
                  onPressed: isCurrentPlan || _isProcessing
                      ? null
                      : () => _handleSubscribe(planType),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPopular
                        ? AppTheme.secondaryColor
                        : AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    isCurrentPlan ? 'Current Plan' : 'Subscribe',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Premium Features',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem('Appear in customer search results'),
            _buildFeatureItem('Unlimited booking requests'),
            _buildFeatureItem('Direct customer contact'),
            _buildFeatureItem('Rating and review system'),
            _buildFeatureItem('Profile customization'),
            _buildFeatureItem('Payment collection tools'),
            _buildFeatureItem('Analytics and insights'),
            _buildFeatureItem('Priority customer support'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppTheme.successColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
