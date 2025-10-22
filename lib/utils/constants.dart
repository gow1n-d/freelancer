/// App-wide constants for the Service Booking application
class AppConstants {
  // App Information
  static const String appName = 'ServiceBooking';
  static const String appVersion = '1.0.0';

  // Service Categories
  static const List<String> serviceCategories = [
    'Electrician',
    'Plumber',
    'Mechanic',
    'Tutor',
    'Carpenter',
    'Painter',
    'AC Repair',
    'Appliance Repair',
    'Pest Control',
    'Cleaning Services',
  ];

  // Indian States
  static const List<String> indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Puducherry',
  ];

  // Service Radius Options (in km)
  static const List<int> serviceRadiusOptions = [1, 3, 5, 10, 15, 20];

  // Rate Types
  static const String rateTypeHour = 'hour';
  static const String rateTypeVisit = 'visit';
  static const List<String> rateTypes = [rateTypeHour, rateTypeVisit];

  // User Roles
  static const String roleCustomer = 'customer';
  static const String roleFreelancer = 'freelancer';

  // Subscription Status
  static const String subscriptionNone = 'none';
  static const String subscriptionTrial = 'trial';
  static const String subscriptionActive = 'active';
  static const String subscriptionExpired = 'expired';
  static const String subscriptionCancelled = 'cancelled';

  // Subscription Plans
  static const String planMonthly = 'monthly';
  static const String planYearly = 'yearly';

  // Booking Status
  static const String bookingPending = 'pending';
  static const String bookingConfirmed = 'confirmed';
  static const String bookingCompleted = 'completed';
  static const String bookingCancelled = 'cancelled';

  // Validation Constraints
  static const int minNameLength = 2;
  static const int maxNameLength = 100;
  static const int minServiceCategories = 1;
  static const int maxServiceCategories = 5;
  static const int minRate = 50;
  static const int maxRate = 10000;
  static const int minAddressLength = 10;
  static const int maxAddressLength = 500;
  static const int minDescriptionLength = 10;
  static const int maxDescriptionLength = 1000;

  // Phone Number
  static const String phonePrefix = '+91';
  static const int phoneNumberLength = 10;

  // Date/Time
  static const int maxBookingDaysInFuture = 90;

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String bookingsCollection = 'bookings';
  static const String ratingsCollection = 'ratings';
  static const String subscriptionsCollection = 'subscriptions';
  static const String paymentsCollection = 'payments';
  static const String appConfigCollection = 'appConfig';

  // Firestore Documents (App Config)
  static const String subscriptionPricingDoc = 'subscription_pricing';
  static const String trialSettingsDoc = 'trial_settings';

  // Storage Paths
  static const String profilePhotosPath = 'profile_photos';

  // Error Messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'No internet connection. Please check your network.';
  static const String errorAuth = 'Authentication failed. Please try again.';
  static const String errorPayment = 'Payment failed. Please try again.';

  // Success Messages
  static const String successProfileUpdated = 'Profile updated successfully';
  static const String successBookingCreated = 'Booking request sent successfully';
  static const String successPaymentCompleted = 'Payment completed successfully';
  static const String successRatingSubmitted = 'Thank you for your rating!';
}
