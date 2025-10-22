import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../utils/app_config.dart';
import 'auth_service.dart';
import 'mock/mock_auth_service.dart';
import 'mock/mock_firestore_service.dart';

/// Authentication state provider using ChangeNotifier
class AuthProvider extends ChangeNotifier {
  // Real Firebase services
  final AuthService _authService = AuthService();
  
  // Mock services
  final MockAuthService _mockAuthService = MockAuthService();
  final MockFirestoreService _mockFirestore = MockFirestoreService();

  User? _firebaseUser;
  MockUser? _mockUser;
  UserModel? _currentUser;
  bool _isLoading = true;

  /// Get current Firebase user (null in mock mode)
  User? get firebaseUser => AppConfig.enableMockMode ? null : _firebaseUser;
  
  /// Get current user ID (works in both modes)
  String? get userId {
    if (AppConfig.enableMockMode) {
      return _mockUser?.uid;
    }
    return _firebaseUser?.uid;
  }

  /// Get current user model
  UserModel? get currentUser => _currentUser;

  /// Check if user is signed in
  bool get isSignedIn {
    if (AppConfig.enableMockMode) {
      return _mockUser != null;
    }
    return _firebaseUser != null;
  }

  /// Check if user data is still loading
  bool get isLoading => _isLoading;

  /// Check if user is a freelancer
  bool get isFreelancer => _currentUser?.isFreelancer ?? false;

  /// Check if user is a customer
  bool get isCustomer => _currentUser?.isCustomer ?? false;

  AuthProvider() {
    _initAuthListener();
  }

  /// Initialize authentication state listener
  void _initAuthListener() {
    if (AppConfig.enableMockMode) {
      // Mock mode: Initialize with no user
      _mockUser = _mockAuthService.currentUser;
      _isLoading = false;
      notifyListeners();
      
      AppConfig.log('AuthProvider initialized in mock mode');
    } else {
      // Real Firebase mode
      _authService.authStateChanges.listen((user) async {
        _firebaseUser = user;

        if (user != null) {
          // User signed in, load user data
          await _loadUserData(user.uid);
        } else {
          // User signed out
          _currentUser = null;
          _isLoading = false;
        }

        notifyListeners();
      });
    }
  }

  /// Load user data from Firestore (or mock)
  Future<void> _loadUserData(String uid) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (AppConfig.enableMockMode) {
        final userData = await _mockFirestore.getUser(uid);
        _currentUser = userData;
      } else {
        final userData = await _authService.getUserDocument(uid);
        _currentUser = userData;
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with phone number and return verification ID
  Future<String> signInWithPhone(String phoneNumber) async {
    if (AppConfig.enableMockMode) {
      return await _mockAuthService.signInWithPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
      );
    } else {
      return await _authService.signInWithPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
      );
    }
  }

  /// Verify OTP and sign in
  Future<void> verifyOTP(String verificationId, String otp) async {
    if (AppConfig.enableMockMode) {
      final credential = await _mockAuthService.verifyOTP(
        verificationId: verificationId,
        smsCode: otp,
      );
      _mockUser = credential.user;
      
      // Check if user exists
      final userExists = await _mockFirestore.getUser(credential.user.uid) != null;
      
      if (userExists) {
        await _loadUserData(credential.user.uid);
      } else {
        _currentUser = null;
      }
      
      _isLoading = false;
      notifyListeners();
    } else {
      // Real Firebase handled by auth state listener
      await _authService.verifyOTP(
        verificationId: verificationId,
        smsCode: otp,
      );
    }
  }

  /// Create new user with role
  Future<void> createUser(String role) async {
    final uid = userId;
    final phone = AppConfig.enableMockMode 
        ? AppConfig.mockPhoneNumber 
        : _firebaseUser?.phoneNumber ?? '';
    
    if (uid == null) {
      throw Exception('No authenticated user');
    }

    if (AppConfig.enableMockMode) {
      final user = await _mockAuthService.createUserDocument(
        userId: uid,
        phoneNumber: phone,
        role: role,
      );
      _mockFirestore.setUser(uid, user);
      _currentUser = user;
    } else {
      _currentUser = await _authService.createUserDocument(
        userId: uid,
        phoneNumber: phone,
        role: role,
      );
    }
    
    notifyListeners();
  }

  /// Check if user document exists
  Future<bool> userExists() async {
    final uid = userId;
    if (uid == null) return false;

    if (AppConfig.enableMockMode) {
      return await _mockAuthService.checkUserExists(uid);
    } else {
      return await _authService.checkUserExists(uid);
    }
  }

  /// Refresh current user data
  Future<void> refreshUserData() async {
    final uid = userId;
    if (uid != null) {
      await _loadUserData(uid);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      if (AppConfig.enableMockMode) {
        await _mockAuthService.signOut();
        _mockUser = null;
      } else {
        await _authService.signOut();
        _firebaseUser = null;
      }
      
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  /// Stream user document from Firestore (not implemented for mock mode)
  Stream<UserModel?> streamUserData() {
    if (AppConfig.enableMockMode) {
      return Stream.value(_currentUser);
    }
    
    if (_firebaseUser == null) {
      return Stream.value(null);
    }
    return _authService.streamUserDocument(_firebaseUser!.uid);
  }
  
  /// Get mock firestore service (for other services to use)
  MockFirestoreService get mockFirestore => _mockFirestore;
}
