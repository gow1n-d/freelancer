import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

/// Authentication service handling phone auth and user management
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Get current user's UID
  String? get currentUserId => currentUser?.uid;

  /// Initiate phone number authentication
  /// Returns verification ID that will be used to verify OTP
  Future<String> signInWithPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(String error) verificationFailed,
    required Function() codeAutoRetrievalTimeout,
  }) async {
    String? verificationIdResult;

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-verification (Android only)
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        String errorMessage = 'Verification failed. Please try again.';

        if (e.code == 'invalid-phone-number') {
          errorMessage = 'Invalid phone number format.';
        } else if (e.code == 'too-many-requests') {
          errorMessage = 'Too many requests. Please try again later.';
        } else if (e.code == 'quota-exceeded') {
          errorMessage = 'SMS quota exceeded. Please try again tomorrow.';
        }

        verificationFailed(errorMessage);
      },
      codeSent: (String verificationId, int? resendToken) {
        verificationIdResult = verificationId;
        codeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        verificationIdResult = verificationId;
        codeAutoRetrievalTimeout();
      },
    );

    return verificationIdResult ?? '';
  }

  /// Verify OTP and sign in user
  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Invalid OTP. Please try again.';

      if (e.code == 'invalid-verification-code') {
        errorMessage = 'Invalid OTP code.';
      } else if (e.code == 'session-expired') {
        errorMessage = 'OTP expired. Please request a new one.';
      }

      throw Exception(errorMessage);
    }
  }

  /// Check if user document exists in Firestore
  Future<bool> userDocumentExists(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get user document from Firestore
  Future<UserModel?> getUserDocument(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  /// Create new user document in Firestore after role selection
  Future<UserModel> createUserDocument({
    required String uid,
    required String phoneNumber,
    required String role,
  }) async {
    try {
      final now = DateTime.now();

      final userData = UserModel(
        userId: uid,
        phoneNumber: phoneNumber,
        role: role,
        name: '', // Empty initially, will be filled in profile setup
        createdAt: now,
        updatedAt: now,
        // Freelancer-specific fields initialized based on role
        serviceCategories: role == AppConstants.roleFreelancer ? [] : null,
        rate: null,
        serviceLocation: null,
        profileComplete: role == AppConstants.roleFreelancer ? false : null,
        subscriptionStatus: role == AppConstants.roleFreelancer
            ? AppConstants.subscriptionNone
            : null,
        subscriptionPlan: null,
        subscriptionStartDate: null,
        subscriptionEndDate: null,
        averageRating: role == AppConstants.roleFreelancer ? 0.0 : null,
        totalRatings: role == AppConstants.roleFreelancer ? 0 : null,
        // Customer-specific fields
        selectedCity: role == AppConstants.roleCustomer ? '' : null,
      );

      // Save to Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(userData.toFirestore());

      return userData;
    } catch (e) {
      throw Exception('Failed to create user document: $e');
    }
  }

  /// Update user document in Firestore
  Future<void> updateUserDocument({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      data['updatedAt'] = Timestamp.now();

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update(data);
    } catch (e) {
      throw Exception('Failed to update user document: $e');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Delete current user account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user != null) {
        // Delete user document from Firestore
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .delete();

        // Delete Firebase Auth account
        await user.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  /// Stream user document from Firestore
  Stream<UserModel?> streamUserDocument(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Resend OTP (re-initiate phone verification)
  Future<String> resendOTP({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(String error) verificationFailed,
  }) async {
    return await signInWithPhoneNumber(
      phoneNumber: phoneNumber,
      codeSent: codeSent,
      verificationFailed: verificationFailed,
      codeAutoRetrievalTimeout: () {},
    );
  }
}
