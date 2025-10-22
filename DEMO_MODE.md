# 🎭 Demo Mode Documentation

**Version**: 1.0.0
**Last Updated**: October 22, 2025

## 📖 Overview

**Demo Mode** (also called Mock Mode) allows you to run the Freelancer App **without any Firebase backend setup**. This is perfect for:

- 🎨 **UI/UX testing** - Test all screens and user flows
- 🚀 **Quick demos** - Show the app to stakeholders immediately
- 🧪 **Development** - Build features without backend dependencies
- 📱 **Prototyping** - Validate ideas before production setup
- 🎓 **Learning** - Understand the app architecture without complexity

---

## ✨ What Works in Demo Mode

### ✅ Fully Functional

| Feature | Status | Notes |
|---------|--------|-------|
| Phone authentication | ✅ | Any 10-digit number works |
| OTP verification | ✅ | Always use OTP: 123456 |
| Role selection | ✅ | Customer or Freelancer |
| Profile management | ✅ | Create and edit profiles |
| Profile preview | ✅ | See customer-facing view |
| Subscription status | ✅ | Trial, Active, Expired states |
| Subscription plans | ✅ | View pricing and features |
| Payment simulation | ✅ | Mock Razorpay integration |
| Trial activation | ✅ | Start 7-day trial |
| Subscription management | ✅ | View, cancel, renew |
| Payment history | ✅ | View mock transactions |
| Dashboard navigation | ✅ | All screens accessible |
| Form validation | ✅ | All inputs validated |
| Error handling | ✅ | Error messages shown |
| State management | ✅ | Provider state updates |
| Sign in/out | ✅ | Full auth flow |

### ⚠️ Limitations

| Feature | Status | Workaround |
|---------|--------|------------|
| Data persistence | ❌ | Resets on app restart | Use production mode |
| Real SMS OTP | ❌ | Always use 123456 | Use production mode |
| Actual payments | ❌ | Auto-succeeds after 2s | Use Razorpay test mode |
| Image uploads | ❌ | Profile pictures disabled | Use Firebase Storage |
| Push notifications | ❌ | FCM not configured | Enable FCM |
| Real-time sync | ❌ | No Firestore streams | Use production mode |
| Multi-device sync | ❌ | Local data only | Use production mode |

---

## 🚀 Quick Start

### 1. Enable Demo Mode

Edit `lib/utils/app_config.dart`:

```dart
class AppConfig {
  /// Enable mock/demo mode (no Firebase required)
  static const bool enableMockMode = true; // ✅ true = Demo Mode

  // ... rest of config
}
```

### 2. Run the App

```bash
cd freelancer
flutter pub get
flutter run
```

### 3. Look for Indicators

**Visual Indicators:**
- 🏷️ **"DEMO MODE" banner** in top-right corner
- 🟠 **Orange info boxes** on login and OTP screens
- 📝 **Hints showing** mock credentials (OTP: 123456)
- 🔔 **Splash screen badge** showing mode (if `showDebugInfo = true`)

---

## 🎮 Demo Credentials

### Login
- **Phone Number**: Any 10 digits (e.g., 9876543210)
- **OTP**: Always **123456**

### Users
| Role | Name | Phone | Profile Status |
|------|------|-------|----------------|
| Freelancer | Demo Freelancer | +919876543210 | 40% complete |
| Customer | Demo Customer | +919876543210 | Not applicable |

### Subscriptions
Configurable in `app_config.dart`:
```dart
// Trial user (default)
static const bool mockIsInTrial = true;
static const int mockTrialDaysRemaining = 5;

// Or active subscriber
static const bool mockHasActiveSubscription = true;
static const String mockSubscriptionPlan = 'monthly';
```

### Payments
```dart
// Auto-succeed payments (default)
static const bool mockPaymentSuccess = true;

// Or test failures
static const bool mockPaymentSuccess = false;
```

---

## 🛠️ Configuration Options

All demo mode settings are in `lib/utils/app_config.dart`:

### Basic Settings

```dart
class AppConfig {
  // Core mode toggle
  static const bool enableMockMode = true;

  // Show debug info (banners, hints, mode badges)
  static const bool showDebugInfo = true;

  // Enable console logging
  static const bool enableLogging = true;

  // ... more settings
}
```

### Mock User Settings

```dart
// Default mock user
static const String mockPhoneNumber = '+919876543210';
static const String mockOTP = '123456';
static const String mockUserName = 'Demo Freelancer';
static const String mockUserId = 'demo_user_123';
```

### Mock Subscription Settings

```dart
// Subscription state
static const bool mockHasActiveSubscription = false;
static const String mockSubscriptionPlan = 'monthly'; // or 'yearly'
static const bool mockIsInTrial = true;
static const int mockTrialDaysRemaining = 5;
```

### Payment Settings

```dart
// Payment behavior
static const bool mockPaymentSuccess = true;
```

### Firebase Emulator Settings (Advanced)

```dart
// Use local Firebase emulator instead of mock
static const bool useFirebaseEmulator = false;
static const String emulatorHost = 'localhost';
static const int firestoreEmulatorPort = 8080;
static const int authEmulatorPort = 9099;
static const int functionsEmulatorPort = 5001;
```

---

## 📂 Architecture

### Mock Services

Demo mode uses dedicated mock services that simulate Firebase:

```
lib/services/mock/
├── mock_auth_service.dart       # Simulates Firebase Auth
├── mock_firestore_service.dart  # Simulates Firestore
└── mock_payment_service.dart    # Simulates Razorpay
```

### Service Routing

The app automatically routes to the correct service:

```dart
// In AuthProvider
if (AppConfig.enableMockMode) {
  // Use MockAuthService
  await _mockAuthService.signInWithPhoneNumber(...);
} else {
  // Use real Firebase AuthService
  await _authService.signInWithPhoneNumber(...);
}
```

### Data Storage

Mock mode uses **in-memory storage**:

```dart
class MockFirestoreService {
  // In-memory maps
  final Map<String, UserModel> _users = {};
  final Map<String, SubscriptionModel> _subscriptions = {};
  final Map<String, PaymentModel> _payments = {};

  // Data initializes on app start
  // Data clears on app restart
}
```

---

## 🎯 Testing Scenarios

### Scenario 1: New User Flow

**Config:**
```dart
static const bool mockIsInTrial = false;
static const bool mockHasActiveSubscription = false;
```

**Test:**
1. Login with any phone
2. Enter OTP: 123456
3. Select role (Customer/Freelancer)
4. See dashboard with empty profile
5. Complete profile
6. View subscription options
7. Start trial or subscribe

**Expected:** Full onboarding flow

---

### Scenario 2: Existing User with Trial

**Config:**
```dart
static const bool mockIsInTrial = true;
static const int mockTrialDaysRemaining = 3;
```

**Test:**
1. Login with same phone
2. Enter OTP: 123456
3. Skip role selection (existing user)
4. See dashboard immediately
5. Profile data persists (within session)
6. Subscription shows "Free Trial - 3 days remaining"

**Expected:** Returning user with trial

---

### Scenario 3: Active Subscriber

**Config:**
```dart
static const bool mockIsInTrial = false;
static const bool mockHasActiveSubscription = true;
static const String mockSubscriptionPlan = 'yearly';
```

**Test:**
1. Login
2. Dashboard shows "Active" subscription
3. Subscription management shows yearly plan
4. Can view payment history
5. Can cancel subscription

**Expected:** Fully subscribed user

---

### Scenario 4: Payment Failure Testing

**Config:**
```dart
static const bool mockPaymentSuccess = false;
```

**Test:**
1. Try to subscribe to any plan
2. Wait 2 seconds
3. Payment automatically fails
4. Error message shown
5. Subscription not activated
6. User can retry

**Expected:** Payment error handling

---

## 🐛 Debugging

### Enable Detailed Logging

```dart
// app_config.dart
static const bool enableLogging = true;
```

**Output:**
```
[AppConfig] Running in MOCK MODE - No Firebase required
[AppConfig] Mock: Sign in with phone +919876543210
[AppConfig] Mock: OTP sent (use 123456)
[AppConfig] Mock: Verifying OTP 123456
[AppConfig] Mock: OTP verified successfully
[AppConfig] Mock: Creating user document for freelancer
```

### Show Debug Info

```dart
// app_config.dart
static const bool showDebugInfo = true;
```

**Enables:**
- Demo mode banner
- Mode indicators on splash screen
- OTP hints on login/verification screens
- Configuration badges

### Check Current Mode

```dart
// Anywhere in code
print('Mode: ${AppConfig.modeDescription}');
// Output: "DEMO MODE - No Firebase Required"

print('Is Production: ${AppConfig.isProduction}');
// Output: false
```

---

## 🔄 Switching Modes

### From Demo → Production

1. **Update Configuration:**
```dart
// app_config.dart
static const bool enableMockMode = false; // ❌ Disable demo
```

2. **Set Up Firebase:**
```bash
flutterfire configure
firebase deploy --only firestore:rules
firebase deploy --only functions
```

3. **Configure Services:**
- Enable Phone Authentication in Firebase Console
- Add Razorpay API keys
- Set up Cloud Functions environment variables

4. **Rebuild and Run:**
```bash
flutter clean
flutter pub get
flutter run
```

### From Production → Demo

1. **Update Configuration:**
```dart
// app_config.dart
static const bool enableMockMode = true; // ✅ Enable demo
```

2. **Rebuild and Run:**
```bash
flutter run
```

No other changes needed!

---

## 📊 Mock Data Overview

### Users

```dart
UserModel(
  userId: 'demo_user_123',
  phoneNumber: '+919876543210',
  role: 'freelancer',
  name: 'Demo Freelancer',
  email: '',
  serviceCategories: ['Plumber', 'Electrician'],
  rate: 500,
  rateType: 'hour',
  city: 'Mumbai',
  state: 'Maharashtra',
  serviceRadius: 10,
  description: 'Experienced professional with 5+ years',
  subscriptionStatus: 'trial', // or 'active', 'none', etc.
  // ... other fields
)
```

### Subscriptions

```dart
SubscriptionModel(
  userId: 'demo_user_123',
  status: 'trial', // or 'active', 'expired', 'cancelled'
  plan: null, // or 'monthly', 'yearly'
  startDate: DateTime.now(),
  endDate: DateTime.now().add(Duration(days: 7)),
  autoRenewal: false,
)
```

### Pricing

```dart
SubscriptionPricing(
  monthlyPrice: 299, // ₹299/month
  yearlyPrice: 2990, // ₹2990/year
  currency: 'INR',
)

// Yearly saves: 17% (₹600/year)
```

### Trial Settings

```dart
TrialSettings(
  enabled: true,
  days: 7,
)
```

---

## ⚙️ Advanced Configuration

### Custom Mock Data

Edit `mock_auth_service.dart` to customize user data:

```dart
final user = UserModel(
  // ... customize fields
  name: 'Your Custom Name',
  serviceCategories: ['Custom Category'],
  rate: 1000,
  // ... etc
);
```

### Custom Delays

Edit mock services to change delays:

```dart
// mock_auth_service.dart
await Future.delayed(const Duration(seconds: 2)); // Slower
await Future.delayed(const Duration(milliseconds: 100)); // Faster
```

### Multiple Mock Users

Add logic to switch users:

```dart
// Based on phone number
if (phoneNumber.endsWith('1111')) {
  return mockUserA;
} else if (phoneNumber.endsWith('2222')) {
  return mockUserB;
}
```

---

## 🎓 Learning Resources

### Understanding the Code

1. **Start with:** `lib/utils/app_config.dart` - Configuration
2. **Then read:** `lib/services/auth_provider.dart` - Service routing
3. **Explore:** `lib/services/mock/` - Mock implementations
4. **See usage:** `lib/screens/auth/login_screen.dart` - Integration example

### Key Concepts

**Dependency Injection:**
```dart
SubscriptionService({MockFirestoreService? mockFirestore})
  : _firestore = AppConfig.enableMockMode ? null : FirebaseFirestore.instance,
    _mockFirestore = AppConfig.enableMockMode ? mockFirestore : null;
```

**Conditional Logic:**
```dart
if (AppConfig.enableMockMode) {
  return await _mockFirestore!.getSubscription(userId);
} else {
  return await _firestore!.collection('subscriptions').doc(userId).get();
}
```

**State Management:**
```dart
// Provider handles both mock and real data
Provider.of<AuthProvider>(context).currentUser;
```

---

## 🚨 Common Issues

### Issue: App crashes on launch

**Cause:** Trying to use Firebase when mock mode is enabled incorrectly

**Solution:**
1. Check `app_config.dart`: `enableMockMode = true`
2. Ensure mock services are imported
3. Check for hardcoded Firebase calls

---

### Issue: Data doesn't persist

**Expected Behavior:** Demo mode data is temporary and resets on restart

**Solution:** Use production mode for persistence

---

### Issue: OTP doesn't work

**Solution:** Always use `123456` in demo mode (shown in orange hint)

---

### Issue: Payment fails

**Cause:** `mockPaymentSuccess = false`

**Solution:**
```dart
// app_config.dart
static const bool mockPaymentSuccess = true;
```

---

### Issue: No demo mode indicators

**Cause:** `showDebugInfo = false`

**Solution:**
```dart
// app_config.dart
static const bool showDebugInfo = true;
```

---

## ✅ Best Practices

### DO:
- ✅ Use demo mode for UI/UX testing
- ✅ Test all user flows in demo mode first
- ✅ Customize mock data for different scenarios
- ✅ Use it for quick demos and prototypes
- ✅ Keep `showDebugInfo = true` during development
- ✅ Document any custom mock data changes

### DON'T:
- ❌ Use demo mode in production
- ❌ Expect data to persist across sessions
- ❌ Use demo mode for performance testing
- ❌ Commit with `enableMockMode = true`
- ❌ Test real payments in demo mode
- ❌ Expect push notifications to work

---

## 📝 Checklist: Before Switching to Production

- [ ] Disable mock mode (`enableMockMode = false`)
- [ ] Firebase project created and configured
- [ ] Phone authentication enabled in Firebase
- [ ] Firestore database created with rules
- [ ] Cloud Functions deployed
- [ ] Razorpay production keys configured
- [ ] All environment variables set
- [ ] Test with real phone numbers
- [ ] Verify OTP delivery
- [ ] Test real payment flow (test mode)
- [ ] Check Firestore data writing correctly
- [ ] Verify Cloud Functions executing
- [ ] Test on multiple devices
- [ ] Performance testing completed
- [ ] Security review done

---

## 🎉 Summary

Demo Mode provides a **complete, functional experience** without any backend setup. It's perfect for development, testing, and demonstrations. When ready for production, simply flip the switch and configure Firebase!

**Key Takeaway:** Demo mode lets you build and test the entire app while backend setup happens in parallel.

---

## 📞 Support

- **Issues:** GitHub Issues
- **Questions:** README.md
- **Testing:** TESTING_GUIDE.md
- **Setup:** README.md (Firebase section)

---

**Enjoy building with Demo Mode! 🚀**
