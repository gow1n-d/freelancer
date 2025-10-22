import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

/// Service for managing freelancer profiles
class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update freelancer profile
  Future<void> updateProfile({
    required String userId,
    String? name,
    List<String>? serviceCategories,
    RateInfo? rate,
    ServiceLocation? serviceLocation,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (name != null) {
        updates['name'] = name;
      }

      if (serviceCategories != null) {
        updates['serviceCategories'] = serviceCategories;
      }

      if (rate != null) {
        updates['rate'] = rate.toMap();
      }

      if (serviceLocation != null) {
        updates['serviceLocation'] = serviceLocation.toMap();
      }

      // Check if profile is now complete
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        final user = UserModel.fromFirestore(doc);

        // Check all required fields
        final hasName = (name ?? user.name).isNotEmpty;
        final hasCategories = (serviceCategories ?? user.serviceCategories)?.isNotEmpty ?? false;
        final hasRate = rate != null || user.rate != null;
        final hasLocation = serviceLocation != null || user.serviceLocation != null;

        updates['profileComplete'] = hasName && hasCategories && hasRate && hasLocation;
      }

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Calculate profile completion percentage
  int calculateProfileCompletion(UserModel user) {
    if (!user.isFreelancer) return 100;

    int completed = 0;
    const int totalFields = 4; // name, categories, rate, location

    if (user.name.isNotEmpty) completed++;
    if (user.serviceCategories != null && user.serviceCategories!.isNotEmpty) {
      completed++;
    }
    if (user.rate != null) completed++;
    if (user.serviceLocation != null) completed++;

    return ((completed / totalFields) * 100).round();
  }

  /// Get missing profile fields
  List<String> getMissingFields(UserModel user) {
    final missing = <String>[];

    if (user.name.isEmpty) {
      missing.add('Name');
    }
    if (user.serviceCategories == null || user.serviceCategories!.isEmpty) {
      missing.add('Service Categories');
    }
    if (user.rate == null) {
      missing.add('Rate');
    }
    if (user.serviceLocation == null) {
      missing.add('Service Location');
    }

    return missing;
  }

  /// Check if profile is complete
  bool isProfileComplete(UserModel user) {
    return user.name.isNotEmpty &&
        user.serviceCategories != null &&
        user.serviceCategories!.isNotEmpty &&
        user.rate != null &&
        user.serviceLocation != null;
  }
}
