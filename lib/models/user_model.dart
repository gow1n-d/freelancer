import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

/// User model representing both Customer and Freelancer users
class UserModel {
  final String userId;
  final String phoneNumber;
  final String role; // 'customer' or 'freelancer'
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Freelancer-specific fields
  final List<String>? serviceCategories;
  final RateInfo? rate;
  final ServiceLocation? serviceLocation;
  final bool? profileComplete;
  final String? subscriptionStatus;
  final String? subscriptionPlan;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final double? averageRating;
  final int? totalRatings;

  // Customer-specific fields
  final String? selectedCity;

  UserModel({
    required this.userId,
    required this.phoneNumber,
    required this.role,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.serviceCategories,
    this.rate,
    this.serviceLocation,
    this.profileComplete,
    this.subscriptionStatus,
    this.subscriptionPlan,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.averageRating,
    this.totalRatings,
    this.selectedCity,
  });

  /// Check if user is a freelancer
  bool get isFreelancer => role == AppConstants.roleFreelancer;

  /// Check if user is a customer
  bool get isCustomer => role == AppConstants.roleCustomer;

  /// Check if freelancer profile is complete
  bool get isProfileComplete => profileComplete ?? false;

  /// Check if freelancer has active subscription
  bool get hasActiveSubscription =>
      subscriptionStatus == AppConstants.subscriptionActive ||
      subscriptionStatus == AppConstants.subscriptionTrial;

  /// Check if freelancer profile is visible to customers
  bool get isVisibleInSearch =>
      isFreelancer && isProfileComplete && hasActiveSubscription;

  /// Factory constructor to create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      userId: doc.id,
      phoneNumber: data['phoneNumber'] ?? '',
      role: data['role'] ?? AppConstants.roleCustomer,
      name: data['name'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      serviceCategories: data['serviceCategories'] != null
          ? List<String>.from(data['serviceCategories'])
          : null,
      rate: data['rate'] != null ? RateInfo.fromMap(data['rate']) : null,
      serviceLocation: data['serviceLocation'] != null
          ? ServiceLocation.fromMap(data['serviceLocation'])
          : null,
      profileComplete: data['profileComplete'],
      subscriptionStatus: data['subscriptionStatus'],
      subscriptionPlan: data['subscriptionPlan'],
      subscriptionStartDate:
          (data['subscriptionStartDate'] as Timestamp?)?.toDate(),
      subscriptionEndDate:
          (data['subscriptionEndDate'] as Timestamp?)?.toDate(),
      averageRating: data['averageRating']?.toDouble(),
      totalRatings: data['totalRatings'],
      selectedCity: data['selectedCity'],
    );
  }

  /// Convert UserModel to Firestore document map
  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'phoneNumber': phoneNumber,
      'role': role,
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };

    // Add freelancer-specific fields if role is freelancer
    if (isFreelancer) {
      map['serviceCategories'] = serviceCategories ?? [];
      map['rate'] = rate?.toMap();
      map['serviceLocation'] = serviceLocation?.toMap();
      map['profileComplete'] = profileComplete ?? false;
      map['subscriptionStatus'] =
          subscriptionStatus ?? AppConstants.subscriptionNone;
      map['subscriptionPlan'] = subscriptionPlan;
      map['subscriptionStartDate'] = subscriptionStartDate != null
          ? Timestamp.fromDate(subscriptionStartDate!)
          : null;
      map['subscriptionEndDate'] = subscriptionEndDate != null
          ? Timestamp.fromDate(subscriptionEndDate!)
          : null;
      map['averageRating'] = averageRating ?? 0.0;
      map['totalRatings'] = totalRatings ?? 0;
    }

    // Add customer-specific fields if role is customer
    if (isCustomer) {
      map['selectedCity'] = selectedCity;
    }

    return map;
  }

  /// Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? userId,
    String? phoneNumber,
    String? role,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? serviceCategories,
    RateInfo? rate,
    ServiceLocation? serviceLocation,
    bool? profileComplete,
    String? subscriptionStatus,
    String? subscriptionPlan,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    double? averageRating,
    int? totalRatings,
    String? selectedCity,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      serviceCategories: serviceCategories ?? this.serviceCategories,
      rate: rate ?? this.rate,
      serviceLocation: serviceLocation ?? this.serviceLocation,
      profileComplete: profileComplete ?? this.profileComplete,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionStartDate:
          subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      selectedCity: selectedCity ?? this.selectedCity,
    );
  }
}

/// Rate information for freelancers
class RateInfo {
  final int amount;
  final String type; // 'hour' or 'visit'

  RateInfo({
    required this.amount,
    required this.type,
  });

  factory RateInfo.fromMap(Map<String, dynamic> map) {
    return RateInfo(
      amount: map['amount'] ?? 0,
      type: map['type'] ?? AppConstants.rateTypeHour,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'type': type,
    };
  }

  String get displayText {
    return '₹$amount/${type == AppConstants.rateTypeHour ? 'hour' : 'visit'}';
  }
}

/// Service location information for freelancers
class ServiceLocation {
  final String city;
  final String state;
  final int radius; // in km

  ServiceLocation({
    required this.city,
    required this.state,
    required this.radius,
  });

  factory ServiceLocation.fromMap(Map<String, dynamic> map) {
    return ServiceLocation(
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      radius: map['radius'] ?? 5,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'city': city,
      'state': state,
      'radius': radius,
    };
  }

  String get displayText {
    return '$city, $state (${radius}km radius)';
  }
}
