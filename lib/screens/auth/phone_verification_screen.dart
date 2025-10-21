import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';
import 'role_selection_screen.dart';
import '../customer/customer_dashboard_screen.dart';
import '../freelancer/freelancer_dashboard_screen.dart';

/// Phone verification screen for OTP input
class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const PhoneVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _canResend = false;
  int _resendCountdown = 30;
  Timer? _resendTimer;
  String _currentVerificationId = '';

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _startResendTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  /// Start countdown timer for resend OTP
  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendCountdown = 30;
    });

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  /// Handle verify OTP button press
  Future<void> _handleVerifyOTP() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Verify OTP
      final userCredential = await _authService.verifyOTP(
        verificationId: _currentVerificationId,
        otp: _otpController.text.trim(),
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Authentication failed');
      }

      // Check if user document exists
      final userExists = await _authService.userDocumentExists(user.uid);

      if (!mounted) return;

      if (userExists) {
        // Existing user - fetch user data and navigate to appropriate dashboard
        final userData = await _authService.getUserDocument(user.uid);

        if (!mounted) return;

        if (userData == null) {
          throw Exception('Failed to load user data');
        }

        // Navigate to dashboard based on role
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => userData.isFreelancer
                ? const FreelancerDashboardScreen()
                : const CustomerDashboardScreen(),
          ),
          (route) => false,
        );
      } else {
        // New user - navigate to role selection
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RoleSelectionScreen(
              phoneNumber: widget.phoneNumber,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  /// Handle resend OTP button press
  Future<void> _handleResendOTP() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.resendOTP(
        phoneNumber: widget.phoneNumber,
        codeSent: (verificationId) {
          setState(() {
            _currentVerificationId = verificationId;
            _isLoading = false;
          });

          _startResendTimer();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        },
        verificationFailed: (error) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resend OTP: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Phone Number'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Icon
                Icon(
                  Icons.message_rounded,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Enter Verification Code',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'We sent a 6-digit code to\n${Validators.formatPhoneNumber(widget.phoneNumber)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 40),

                // OTP input
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                      ),
                  decoration: const InputDecoration(
                    labelText: 'OTP Code',
                    hintText: '123456',
                    prefixIcon: Icon(Icons.lock_rounded),
                  ),
                  validator: Validators.validateOTP,
                  enabled: !_isLoading,
                  autofocus: true,
                ),
                const SizedBox(height: 24),

                // Verify button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerifyOTP,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Verify & Continue'),
                ),
                const SizedBox(height: 24),

                // Resend OTP section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive code? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_canResend)
                      TextButton(
                        onPressed: _isLoading ? null : _handleResendOTP,
                        child: const Text('Resend'),
                      )
                    else
                      Text(
                        'Resend in ${_resendCountdown}s',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textDisabled,
                                ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Change phone number
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  child: const Text('Change Phone Number'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
