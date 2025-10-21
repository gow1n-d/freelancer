import 'constants.dart';

/// Validation utilities for form inputs
class Validators {
  /// Validates name field (freelancer name, customer name)
  /// Must be 2-100 characters, no special characters except space, hyphen, period
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }

    final trimmed = value.trim();

    if (trimmed.length < AppConstants.minNameLength) {
      return 'Name must be at least ${AppConstants.minNameLength} characters';
    }

    if (trimmed.length > AppConstants.maxNameLength) {
      return 'Name must not exceed ${AppConstants.maxNameLength} characters';
    }

    // Allow only letters, spaces, hyphens, and periods
    final nameRegex = RegExp(r'^[a-zA-Z\s\-\.]+$');
    if (!nameRegex.hasMatch(trimmed)) {
      return 'Name can only contain letters, spaces, hyphens, and periods';
    }

    return null;
  }

  /// Validates Indian mobile phone number
  /// Must be exactly 10 digits
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Remove any spaces, dashes, or parentheses
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Remove +91 prefix if present
    final withoutPrefix = cleaned.startsWith('+91')
        ? cleaned.substring(3)
        : cleaned.startsWith('91')
            ? cleaned.substring(2)
            : cleaned;

    if (withoutPrefix.length != AppConstants.phoneNumberLength) {
      return 'Phone number must be ${AppConstants.phoneNumberLength} digits';
    }

    // Check if all digits
    final digitRegex = RegExp(r'^\d+$');
    if (!digitRegex.hasMatch(withoutPrefix)) {
      return 'Phone number must contain only digits';
    }

    // Check if starts with valid Indian mobile prefix (6-9)
    if (!['6', '7', '8', '9'].contains(withoutPrefix[0])) {
      return 'Invalid phone number';
    }

    return null;
  }

  /// Validates rate amount
  /// Must be between minRate and maxRate (₹50 - ₹10,000)
  static String? validateRate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Rate is required';
    }

    final rate = int.tryParse(value.trim());
    if (rate == null) {
      return 'Rate must be a valid number';
    }

    if (rate < AppConstants.minRate) {
      return 'Rate must be at least ₹${AppConstants.minRate}';
    }

    if (rate > AppConstants.maxRate) {
      return 'Rate must not exceed ₹${AppConstants.maxRate}';
    }

    return null;
  }

  /// Validates service address
  /// Must be 10-500 characters
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }

    final trimmed = value.trim();

    if (trimmed.length < AppConstants.minAddressLength) {
      return 'Address must be at least ${AppConstants.minAddressLength} characters';
    }

    if (trimmed.length > AppConstants.maxAddressLength) {
      return 'Address must not exceed ${AppConstants.maxAddressLength} characters';
    }

    return null;
  }

  /// Validates problem description / service description
  /// Must be 10-1000 characters
  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }

    final trimmed = value.trim();

    if (trimmed.length < AppConstants.minDescriptionLength) {
      return 'Description must be at least ${AppConstants.minDescriptionLength} characters';
    }

    if (trimmed.length > AppConstants.maxDescriptionLength) {
      return 'Description must not exceed ${AppConstants.maxDescriptionLength} characters';
    }

    return null;
  }

  /// Validates city name
  /// Must be 2-100 characters
  static String? validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'City is required';
    }

    final trimmed = value.trim();

    if (trimmed.length < 2) {
      return 'City name must be at least 2 characters';
    }

    if (trimmed.length > 100) {
      return 'City name must not exceed 100 characters';
    }

    return null;
  }

  /// Validates service category selection
  /// Must select 1-5 categories
  static String? validateServiceCategories(List<String>? categories) {
    if (categories == null || categories.isEmpty) {
      return 'Please select at least one service category';
    }

    if (categories.length < AppConstants.minServiceCategories) {
      return 'Please select at least ${AppConstants.minServiceCategories} category';
    }

    if (categories.length > AppConstants.maxServiceCategories) {
      return 'You can select up to ${AppConstants.maxServiceCategories} categories only';
    }

    return null;
  }

  /// Validates email address (optional, for future use)
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validates OTP code (6 digits)
  static String? validateOTP(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }

    if (value.trim().length != 6) {
      return 'OTP must be 6 digits';
    }

    final digitRegex = RegExp(r'^\d+$');
    if (!digitRegex.hasMatch(value.trim())) {
      return 'OTP must contain only digits';
    }

    return null;
  }

  /// Validates date is not in the past
  static String? validateFutureDate(DateTime? date) {
    if (date == null) {
      return 'Date is required';
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final selectedDate = DateTime(date.year, date.month, date.day);

    if (selectedDate.isBefore(todayDate)) {
      return 'Date cannot be in the past';
    }

    // Check max booking days in future
    final maxDate = todayDate.add(
      Duration(days: AppConstants.maxBookingDaysInFuture),
    );

    if (selectedDate.isAfter(maxDate)) {
      return 'Date cannot be more than ${AppConstants.maxBookingDaysInFuture} days in future';
    }

    return null;
  }

  /// Validates time is not in the past (if date is today)
  static String? validateTime(DateTime? date, String? time) {
    if (time == null || time.trim().isEmpty) {
      return 'Time is required';
    }

    if (date == null) {
      return 'Please select a date first';
    }

    // If date is today, check if time is not in the past
    final today = DateTime.now();
    final selectedDate = DateTime(date.year, date.month, date.day);
    final todayDate = DateTime(today.year, today.month, today.day);

    if (selectedDate.isAtSameMomentAs(todayDate)) {
      // Parse time (HH:mm format)
      try {
        final timeParts = time.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        final selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );

        if (selectedDateTime.isBefore(today)) {
          return 'Time cannot be in the past';
        }
      } catch (e) {
        return 'Invalid time format';
      }
    }

    return null;
  }

  /// Formats phone number to +91 XXXXX XXXXX format
  static String formatPhoneNumber(String phone) {
    // Remove any non-digit characters
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');

    // Remove +91 prefix if present
    final withoutPrefix = cleaned.startsWith('91') && cleaned.length > 10
        ? cleaned.substring(2)
        : cleaned;

    // Format as +91 XXXXX XXXXX
    if (withoutPrefix.length == 10) {
      return '+91 ${withoutPrefix.substring(0, 5)} ${withoutPrefix.substring(5)}';
    }

    return '+91 $withoutPrefix';
  }

  /// Extracts clean 10-digit phone number
  static String cleanPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    return cleaned.startsWith('91') && cleaned.length > 10
        ? cleaned.substring(2)
        : cleaned;
  }
}
