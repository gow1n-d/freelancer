import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../models/user_model.dart';
import '../../utils/app_config.dart';

/// Mock authentication service for demo mode (no Firebase required)
class MockAuthService {
  // Simulate current user
  MockUser? _currentUser;

  // Simulate user data storage
  final Map<String, UserModel> _mockUsers = {};

  // Verification ID for OTP flow
  String? _verificationId;

  /// Get current mock user
  MockUser? get currentUser => _currentUser;

  /// Get stream of auth state changes
  Stream<MockUser?> authStateChanges() {
    // Return a stream that emits the current user
    return Stream.value(_currentUser);
  }

  /// Sign in with phone number (mock)
  Future<String> signInWithPhoneNumber({
    required String phoneNumber,
    required Duration timeout,
  }) async {
    AppConfig.log('Mock: Sign in with phone $phoneNumber');

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Generate mock verification ID
    _verificationId = 'mock_verification_${DateTime.now().millisecondsSinceEpoch}';

    AppConfig.log('Mock: OTP sent (use ${AppConfig.mockOTP})');

    return _verificationId!;
  }

  /// Verify OTP (mock)
  Future<MockUserCredential> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    AppConfig.log('Mock: Verifying OTP $smsCode');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if verification ID matches
    if (verificationId != _verificationId) {
      throw Exception('Invalid verification ID');
    }

    // Check OTP (accept mock OTP or any 6-digit code in demo mode)
    if (smsCode != AppConfig.mockOTP && smsCode.length != 6) {
      throw Exception('Invalid OTP');
    }

    // Create mock user
    final mockUser = MockUser(
      uid: AppConfig.mockUserId,
      phoneNumber: AppConfig.mockPhoneNumber,
    );

    _currentUser = mockUser;

    AppConfig.log('Mock: OTP verified successfully');

    return MockUserCredential(user: mockUser);
  }

  /// Check if user document exists (mock)
  Future<bool> checkUserExists(String uid) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockUsers.containsKey(uid);
  }

  /// Create user document (mock)
  Future<UserModel> createUserDocument({
    required String userId,
    required String phoneNumber,
    required String role,
  }) async {
    AppConfig.log('Mock: Creating user document for $role');

    await Future.delayed(const Duration(milliseconds: 500));

    final user = UserModel(
      userId: userId,
      phoneNumber: phoneNumber,
      role: role,
      name: role == 'freelancer' ? AppConfig.mockUserName : 'Demo Customer',
      email: '',
      profilePictureUrl: null,
      // Freelancer fields
      serviceCategories: role == 'freelancer' ? ['Plumber', 'Electrician'] : [],
      rate: role == 'freelancer' ? 500 : null,
      rateType: role == 'freelancer' ? 'hour' : null,
      city: role == 'freelancer' ? 'Mumbai' : '',
      state: role == 'freelancer' ? 'Maharashtra' : '',
      serviceRadius: role == 'freelancer' ? 10 : null,
      description: role == 'freelancer' ? 'Experienced professional with 5+ years of experience' : '',
      // Subscription fields
      subscriptionStatus: AppConfig.mockIsInTrial ? 'trial' : 'none',
      subscriptionPlan: null,
      autoRenewal: false,
      // Metadata
      rating: role == 'freelancer' ? 4.5 : null,
      totalBookings: role == 'freelancer' ? 0 : null,
      completedBookings: role == 'freelancer' ? 0 : null,
      isAvailable: role == 'freelancer' ? true : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _mockUsers[userId] = user;

    return user;
  }

  /// Get user document (mock)
  Future<UserModel?> getUserDocument(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockUsers[userId];
  }

  /// Sign out (mock)
  Future<void> signOut() async {
    AppConfig.log('Mock: Signing out');
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _verificationId = null;
  }
}

/// Mock User class (simulates FirebaseAuth User)
class MockUser {
  final String uid;
  final String? phoneNumber;
  final String? email;
  final String? displayName;

  MockUser({
    required this.uid,
    this.phoneNumber,
    this.email,
    this.displayName,
  });
}

/// Mock UserCredential class (simulates FirebaseAuth UserCredential)
class MockUserCredential {
  final MockUser user;

  MockUserCredential({required this.user});
}
