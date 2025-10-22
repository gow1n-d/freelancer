/// Application configuration for demo and production modes
class AppConfig {
  /// Enable mock/demo mode (no Firebase required)
  /// Set to true to run app without Firebase backend
  /// Set to false for production with real Firebase
  static const bool enableMockMode = true;

  /// Mock user configuration
  static const String mockPhoneNumber = '+919876543210';
  static const String mockOTP = '123456';
  static const String mockUserName = 'Demo Freelancer';
  static const String mockUserId = 'demo_user_123';

  /// Mock subscription configuration
  static const bool mockHasActiveSubscription = false;
  static const String mockSubscriptionPlan = 'monthly'; // 'monthly' or 'yearly'
  static const bool mockIsInTrial = true;
  static const int mockTrialDaysRemaining = 5;

  /// Firebase emulator configuration (for local testing)
  static const bool useFirebaseEmulator = false;
  static const String emulatorHost = 'localhost';
  static const int firestoreEmulatorPort = 8080;
  static const int authEmulatorPort = 9099;
  static const int functionsEmulatorPort = 5001;

  /// Payment configuration
  static const bool mockPaymentSuccess = true; // Auto-succeed payments in mock mode

  /// App behavior flags
  static const bool showDebugInfo = true; // Show debug banners/info
  static const bool enableLogging = true; // Console logging

  /// Get current mode description
  static String get modeDescription {
    if (enableMockMode) {
      return 'DEMO MODE - No Firebase Required';
    } else if (useFirebaseEmulator) {
      return 'DEVELOPMENT - Using Firebase Emulator';
    } else {
      return 'PRODUCTION - Live Firebase';
    }
  }

  /// Check if using real Firebase
  static bool get isProduction => !enableMockMode && !useFirebaseEmulator;

  /// Log helper
  static void log(String message) {
    if (enableLogging) {
      print('[AppConfig] $message');
    }
  }
}
