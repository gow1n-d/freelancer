import '../../utils/app_config.dart';

/// Mock payment service for demo mode (no Razorpay required)
class MockPaymentService {
  Function(Map<String, dynamic>)? _onSuccess;
  Function(Map<String, dynamic>)? _onFailure;

  /// Initialize mock Razorpay (does nothing in mock mode)
  void initialize({
    required Function(Map<String, dynamic>) onSuccess,
    required Function(Map<String, dynamic>) onFailure,
    Function(Map<String, dynamic>)? onExternalWallet,
  }) {
    AppConfig.log('Mock: Payment service initialized');
    _onSuccess = onSuccess;
    _onFailure = onFailure;
  }

  /// Create order (mock)
  Future<Map<String, dynamic>> createOrder({
    required String userId,
    required String planType,
    required int amount,
  }) async {
    AppConfig.log('Mock: Creating order for $planType plan (₹${amount ~/ 100})');

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    final orderId = 'mock_order_${DateTime.now().millisecondsSinceEpoch}';

    return {
      'success': true,
      'orderId': orderId,
      'amount': amount,
      'currency': 'INR',
    };
  }

  /// Open checkout (mock)
  void openCheckout({
    required String orderId,
    required int amount,
    required String userPhone,
    String? userName,
  }) {
    AppConfig.log('Mock: Opening payment checkout');
    AppConfig.log('Mock: Order ID: $orderId');
    AppConfig.log('Mock: Amount: ₹${amount ~/ 100}');

    // Simulate payment process
    Future.delayed(const Duration(seconds: 2), () {
      if (AppConfig.mockPaymentSuccess) {
        // Simulate success
        final paymentId = 'mock_payment_${DateTime.now().millisecondsSinceEpoch}';
        final signature = 'mock_signature_${DateTime.now().millisecondsSinceEpoch}';

        AppConfig.log('Mock: Payment SUCCESS');

        _onSuccess?.call({
          'orderId': orderId,
          'paymentId': paymentId,
          'signature': signature,
        });
      } else {
        // Simulate failure
        AppConfig.log('Mock: Payment FAILED');

        _onFailure?.call({
          'code': 'PAYMENT_CANCELLED',
          'message': 'Payment was cancelled by user (mock)',
        });
      }
    });
  }

  /// Verify payment (mock)
  Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required String userId,
    required String planType,
  }) async {
    AppConfig.log('Mock: Verifying payment');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Always succeed in mock mode
    AppConfig.log('Mock: Payment verified successfully');
    return true;
  }

  /// Save payment (mock)
  Future<void> savePayment({
    required String paymentId,
    required String orderId,
    required String userId,
    required int amount,
    required String plan,
    required String status,
    String? razorpaySignature,
  }) async {
    AppConfig.log('Mock: Saving payment record');
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Log payment error (mock)
  Future<void> logPaymentError({
    required String userId,
    required String orderId,
    required String errorCode,
    required String errorMessage,
  }) async {
    AppConfig.log('Mock: Logging payment error: $errorMessage');
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// Dispose (mock)
  void dispose() {
    AppConfig.log('Mock: Payment service disposed');
    _onSuccess = null;
    _onFailure = null;
  }
}
