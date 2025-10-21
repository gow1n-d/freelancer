import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

/// Authentication state provider using ChangeNotifier
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _firebaseUser;
  UserModel? _currentUser;
  bool _isLoading = true;

  /// Get current Firebase user
  User? get firebaseUser => _firebaseUser;

  /// Get current user model
  UserModel? get currentUser => _currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _firebaseUser != null;

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

  /// Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userData = await _authService.getUserDocument(uid);
      _currentUser = userData;
    } catch (e) {
      debugPrint('Error loading user data: $e');
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh current user data
  Future<void> refreshUserData() async {
    if (_firebaseUser != null) {
      await _loadUserData(_firebaseUser!.uid);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _firebaseUser = null;
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  /// Stream user document from Firestore
  Stream<UserModel?> streamUserData() {
    if (_firebaseUser == null) {
      return Stream.value(null);
    }
    return _authService.streamUserDocument(_firebaseUser!.uid);
  }
}
