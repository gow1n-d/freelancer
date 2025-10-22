import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/subscription_model.dart';
import '../utils/constants.dart';

/// Service for handling payments via Razorpay
class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  late Razorpay _razorpay;

  /// Initialize Razorpay
  void initializeRazorpay({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (response) {
      onSuccess(response as PaymentSuccessResponse);
    });
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (response) {
      onFailure(response as PaymentFailureResponse);
    });
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (response) {
      onExternalWallet(response as ExternalWalletResponse);
    });
  }

  /// Dispose Razorpay instance
  void dispose() {
    _razorpay.clear();
  }

  /// Create Razorpay order via Cloud Function
  Future<Map<String, dynamic>> createOrder({
    required String userId,
    required String planType,
    required int amount,
  }) async {
    try {
      final callable = _functions.httpsCallable('createRazorpayOrder');
      final result = await callable.call({
        'userId': userId,
        'planType': planType,
        'amount': amount,
      });

      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return {
          'orderId': data['orderId'],
          'amount': data['amount'],
          'currency': data['currency'],
        };
      } else {
        throw Exception(data['message'] ?? 'Failed to create order');
      }
    } catch (e) {
      throw Exception('Failed to create Razorpay order: $e');
    }
  }

  /// Open Razorpay checkout
  void openCheckout({
    required String orderId,
    required int amount,
    required String userPhone,
    String? userName,
  }) {
    final options = {
      'key': 'YOUR_RAZORPAY_KEY_ID', // This will be replaced by Cloud Function
      'amount': amount,
      'currency': 'INR',
      'name': AppConstants.appName,
      'description': 'Subscription Payment',
      'order_id': orderId,
      'prefill': {
        'contact': userPhone,
        if (userName != null) 'name': userName,
      },
      'theme': {
        'color': '#2563EB', // Primary color
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      throw Exception('Failed to open Razorpay checkout: $e');
    }
  }

  /// Verify payment via Cloud Function
  Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required String userId,
    required String planType,
  }) async {
    try {
      final callable = _functions.httpsCallable('verifyPayment');
      final result = await callable.call({
        'orderId': orderId,
        'paymentId': paymentId,
        'signature': signature,
        'userId': userId,
        'planType': planType,
      });

      final data = result.data as Map<String, dynamic>;
      return data['success'] == true;
    } catch (e) {
      throw Exception('Failed to verify payment: $e');
    }
  }

  /// Save payment record
  Future<void> savePayment({
    required String paymentId,
    required String orderId,
    required String userId,
    required int amount,
    required String plan,
    required String status,
    String? razorpaySignature,
  }) async {
    try {
      final payment = PaymentModel(
        paymentId: paymentId,
        orderId: orderId,
        userId: userId,
        amount: amount,
        currency: 'INR',
        plan: plan,
        status: status,
        razorpaySignature: razorpaySignature,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.paymentsCollection)
          .doc(paymentId)
          .set(payment.toFirestore());
    } catch (e) {
      throw Exception('Failed to save payment: $e');
    }
  }

  /// Log payment error
  Future<void> logPaymentError({
    required String userId,
    required String orderId,
    required String errorCode,
    required String errorMessage,
  }) async {
    try {
      await _firestore.collection('payment_logs').add({
        'userId': userId,
        'orderId': orderId,
        'errorCode': errorCode,
        'errorMessage': errorMessage,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      // Silent fail for logging
    }
  }
}
