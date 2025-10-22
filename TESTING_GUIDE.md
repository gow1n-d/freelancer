# 📱 Freelancer App - Complete Testing Guide

**Last Updated**: October 22, 2025
**App Version**: 1.0.0
**Mode**: Demo/Mock Mode Ready

## 🎯 Quick Start

This app can run in **two modes**:

### 1. **DEMO MODE** (No Firebase Required) ✨
- Perfect for testing UI and flows
- No backend setup needed
- Works immediately after `flutter run`
- All features fully functional with mock data

### 2. **PRODUCTION MODE** (Full Firebase)
- Real authentication and database
- Requires Firebase project setup
- Production-ready configuration

---

## 🚀 Running in Demo Mode

### Prerequisites
- Flutter SDK installed (3.0.0+)
- Android emulator or iOS simulator running
- OR physical device connected

### Steps

**1. Clone and Navigate:**
```bash
cd freelancer
```

**2. Install Dependencies:**
```bash
flutter pub get
```

**3. Verify Demo Mode is Enabled:**

Open `lib/utils/app_config.dart`:
```dart
static const bool enableMockMode = true; // ✅ Should be true
```

**4. Run the App:**
```bash
flutter run
```

That's it! The app will launch in DEMO MODE with a banner showing "DEMO MODE".

---

## 📋 Testing Checklist

### Phase 1: Authentication Flow

#### Test 1.1: Login Screen
**Steps:**
1. Launch app
2. You should see login screen with phone input
3. Notice orange "DEMO MODE" banner at top
4. Notice hint box showing OTP: 123456

**Expected:**
- ✅ Clean login UI with phone input
- ✅ "+91" prefix shown
- ✅ Demo mode hints visible
- ✅ "Send OTP" button enabled

**Test Data:**
- Phone: Any 10 digits (e.g., 9876543210)

---

#### Test 1.2: OTP Verification
**Steps:**
1. Enter any 10-digit phone number
2. Tap "Send OTP"
3. Wait 1 second (mock delay)
4. You'll see verification screen
5. Enter OTP: **123456**
6. Tap "Verify & Continue"

**Expected:**
- ✅ Navigation to OTP screen
- ✅ Phone number displayed correctly
- ✅ OTP hint showing "123456"
- ✅ 30-second countdown for resend
- ✅ Successful verification (new users → role selection, existing → dashboard)

**Edge Cases to Test:**
- ❌ Wrong OTP (e.g., 111111) → Should show error
- ✅ Resend OTP after 30s → Should work
- ✅ Back button → Returns to login

---

#### Test 1.3: Role Selection (New Users Only)
**Steps:**
1. After OTP verification (first time)
2. See role selection screen
3. Tap "I'm a Freelancer"
4. Tap "Continue"

**Expected:**
- ✅ Two role cards visible
- ✅ Selected role highlighted in blue
- ✅ Freelancer note about subscription visible
- ✅ Navigates to freelancer dashboard

**Alternatively:**
- Select "I'm a Customer" → Goes to customer dashboard

---

### Phase 2: Freelancer Dashboard

#### Test 2.1: Initial Dashboard View
**Steps:**
1. Log in as freelancer (or if already logged in)
2. View dashboard

**Expected:**
- ✅ Welcome card with avatar and phone number
- ✅ Profile completion warning (if incomplete)
- ✅ Progress bar showing completion percentage
- ✅ Subscription section showing trial or no subscription
- ✅ "Coming Next" features listed
- ✅ Sign out button in app bar

**Mock Data:**
- User: Demo Freelancer
- Phone: +919876543210
- Profile: ~40% complete (missing fields shown)
- Subscription: 7-day trial (5 days remaining)

---

#### Test 2.2: Profile Completion
**Steps:**
1. Tap "Complete Profile" button
2. Fill out profile form:
   - Name: "John Doe"
   - Email: "john@example.com"
   - Service Categories: Select 2-3 (e.g., Plumber, Electrician)
   - Rate: 500
   - Rate Type: per hour
   - Description: "Experienced professional"
   - City: Mumbai
   - State: Maharashtra
   - Service Radius: 10 km
3. Tap "Save Profile"

**Expected:**
- ✅ All form fields editable
- ✅ Category selector allows 1-5 selections
- ✅ Rate validation (₹50 - ₹10,000)
- ✅ Location dropdowns populated
- ✅ Save successful message
- ✅ Returns to dashboard
- ✅ Dashboard now shows "Profile Complete!" in green
- ✅ "Edit Profile" and "View Profile" buttons visible

**Edge Cases:**
- ❌ Empty name → Error
- ❌ Invalid email → Error
- ❌ No categories selected → Error
- ❌ Rate below ₹50 or above ₹10,000 → Error

---

#### Test 2.3: Profile Preview
**Steps:**
1. Complete profile (Test 2.2)
2. Tap "View Profile" button
3. Review customer-facing profile view

**Expected:**
- ✅ Profile shown as customer would see it
- ✅ All entered data displayed correctly
- ✅ Service categories as chips
- ✅ Rate formatted (₹500/hour)
- ✅ Location shown (City, State)
- ✅ Service radius displayed
- ✅ Back button returns to dashboard

---

### Phase 3: Subscription System

#### Test 3.1: Subscription Status Display
**Steps:**
1. View dashboard subscription section
2. Check current status

**Demo Mode States (configurable in app_config.dart):**

**A. No Subscription:**
```dart
mockIsInTrial = false
mockHasActiveSubscription = false
```
- ✅ Shows "Subscribe to Get Bookings" card
- ✅ "View Plans" button visible

**B. Trial Active (Default):**
```dart
mockIsInTrial = true
```
- ✅ Shows "Free Trial" status in blue
- ✅ Days remaining displayed (e.g., "5 days remaining")
- ✅ "Manage Subscription" button visible

**C. Active Subscription:**
```dart
mockIsInTrial = false
mockHasActiveSubscription = true
mockSubscriptionPlan = 'monthly' // or 'yearly'
```
- ✅ Shows "Active" status in green
- ✅ Plan type badge (Monthly/Yearly)
- ✅ Days remaining shown
- ✅ "Manage Subscription" button visible

---

#### Test 3.2: View Subscription Plans
**Steps:**
1. Tap "View Plans" or "Manage Subscription"
2. View subscription screen

**Expected:**
- ✅ "Choose Your Plan" header
- ✅ Trial banner (if eligible) with "Start Free Trial" button
- ✅ Monthly plan card: ₹299/month
- ✅ Yearly plan card: ₹2,990/year with "BEST VALUE" badge
- ✅ Savings calculation shown (Save 17%, ₹600/year)
- ✅ Premium features list (8 features)
- ✅ Professional UI with clear pricing

---

#### Test 3.3: Start Free Trial (Mock Mode)
**Steps:**
1. On subscription screen
2. See trial banner (orange/purple gradient)
3. Tap "Start Free Trial"
4. Wait 1 second (mock delay)

**Expected:**
- ✅ Success message: "7-day trial started!"
- ✅ Returns to dashboard
- ✅ Dashboard now shows trial status
- ✅ Days remaining: 7 days

---

#### Test 3.4: Mock Payment Flow
**Steps:**
1. On subscription screen
2. Tap "Subscribe" on Monthly or Yearly plan
3. Wait 2-3 seconds for mock payment processing
4. Auto-payment success triggered

**Expected:**
- ✅ Loading indicator during processing
- ✅ Simulated payment modal (2 seconds)
- ✅ Success message: "Subscription activated successfully!"
- ✅ Returns to dashboard
- ✅ Dashboard shows "Active" subscription
- ✅ Plan type updated (Monthly/Yearly)

**Mock Payment Configuration (app_config.dart):**
```dart
static const bool mockPaymentSuccess = true; // Auto-succeed
// Set to false to test payment failures
```

---

#### Test 3.5: Subscription Management
**Steps:**
1. Have active subscription (or trial)
2. Tap "Manage Subscription" on dashboard
3. View subscription management screen

**Expected:**
- ✅ Current plan card showing:
  - Status badge (Trial/Active/Cancelled)
  - Plan type (Monthly/Yearly)
  - Start date
  - Valid until date
  - Days remaining
  - Auto-renewal status
- ✅ Warning if expiring soon (< 7 days)
- ✅ Payment history list (if any payments made)
- ✅ "Cancel Subscription" button

---

#### Test 3.6: Cancel Subscription
**Steps:**
1. On subscription management screen
2. Tap "Cancel Subscription"
3. Confirm in dialog
4. Wait for processing

**Expected:**
- ✅ Confirmation dialog appears
- ✅ Dialog explains subscription remains active until end date
- ✅ After confirm: Success message
- ✅ Status changes to "Cancelled"
- ✅ Auto-renewal disabled
- ✅ Subscription still active until end date
- ✅ "Renew Subscription" button now shown

---

#### Test 3.7: Payment History
**Steps:**
1. Make a subscription payment (Test 3.4)
2. View subscription management screen
3. Scroll to "Payment History" section

**Expected:**
- ✅ Payment records listed (most recent first)
- ✅ Each record shows:
  - Amount (₹299 or ₹2,990)
  - Plan type (Monthly/Yearly)
  - Date
  - Status badge (SUCCESS/FAILED/PENDING)
- ✅ Status color-coded (green/red/yellow)

---

### Phase 4: Sign Out & Re-login

#### Test 4.1: Sign Out
**Steps:**
1. On any dashboard
2. Tap logout icon (top right)
3. Confirm sign out

**Expected:**
- ✅ Confirmation dialog
- ✅ Returns to login screen
- ✅ User data cleared
- ✅ Demo mode banner still visible

---

#### Test 4.2: Re-login as Existing User
**Steps:**
1. Sign out (Test 4.1)
2. Log in again with same phone number
3. Use OTP: 123456

**Expected:**
- ✅ Skips role selection (existing user)
- ✅ Goes directly to dashboard
- ✅ Previous data still present:
  - Profile data
  - Subscription status
  - Payment history

---

### Phase 5: Edge Cases & Error Handling

#### Test 5.1: Invalid Phone Numbers
**Test Data:**
- Empty: "" → Error
- Too short: "123" → Error
- Too long: "12345678901" → Error
- Non-digits: "abcd123456" → Filtered out
- Valid: "9876543210" → ✅ Success

---

#### Test 5.2: Invalid OTP
**Test Data:**
- Wrong OTP: "111111" → Error message
- Too short: "123" → Validation error
- Empty: "" → Validation error
- Correct: "123456" → ✅ Success

---

#### Test 5.3: Profile Validation
**Invalid Cases:**
- Empty name → "Please enter your name"
- Invalid email → "Please enter a valid email"
- No categories → "Please select at least one category"
- Rate < ₹50 → "Rate must be between ₹50 and ₹10,000"
- Rate > ₹10,000 → Same error
- No city/state → "Please select your city/state"
- No service radius → "Please select service radius"

---

#### Test 5.4: Network Simulation (Mock Delays)
**Mock Delays:**
- Sign in: 1 second
- OTP verify: 0.5 seconds
- Create user: 0.5 seconds
- Load subscription: 0.3 seconds
- Start trial: 0.5 seconds
- Payment processing: 2 seconds

**Purpose:** Simulates real network latency for realistic testing

---

## 🎨 UI/UX Testing Checklist

### Visual Consistency
- ✅ Primary color (blue) used consistently
- ✅ Secondary color (orange) for accents
- ✅ Success/warning/error colors appropriate
- ✅ Typography hierarchy clear
- ✅ Spacing and padding consistent
- ✅ Icons meaningful and recognizable
- ✅ Button states (enabled/disabled/loading) clear

### Interactions
- ✅ Tap targets ≥ 48x48 dp
- ✅ Loading indicators during async operations
- ✅ Success/error snackbars appear and dismiss
- ✅ Form validation real-time and on submit
- ✅ Animations smooth (not tested in mock mode)
- ✅ Scroll behavior smooth
- ✅ Back button navigation works correctly

### Accessibility (Manual Check)
- ✅ Text readable (sufficient contrast)
- ✅ Font sizes appropriate
- ✅ Touch targets large enough
- ✅ Error messages clear and helpful
- ✅ Loading states announced

---

## 📊 Demo Mode Configuration

Edit `lib/utils/app_config.dart` to test different scenarios:

### Scenario 1: New User (No Subscription)
```dart
static const bool mockIsInTrial = false;
static const bool mockHasActiveSubscription = false;
```
**Result:** Shows "Subscribe to Get Bookings"

### Scenario 2: User on Free Trial
```dart
static const bool mockIsInTrial = true;
static const int mockTrialDaysRemaining = 5;
```
**Result:** Shows trial status with countdown

### Scenario 3: Active Monthly Subscriber
```dart
static const bool mockIsInTrial = false;
static const bool mockHasActiveSubscription = true;
static const String mockSubscriptionPlan = 'monthly';
```
**Result:** Shows active monthly subscription

### Scenario 4: Active Yearly Subscriber
```dart
static const bool mockIsInTrial = false;
static const bool mockHasActiveSubscription = true;
static const String mockSubscriptionPlan = 'yearly';
```
**Result:** Shows active yearly subscription

### Scenario 5: Payment Failure Testing
```dart
static const bool mockPaymentSuccess = false;
```
**Result:** Payment always fails (for error handling testing)

---

## 🐛 Known Issues & Limitations (Demo Mode)

### Limitations
1. **No real authentication** - Any phone number works
2. **No persistence** - Data resets on app restart
3. **No real payments** - Razorpay not actually called
4. **No push notifications** - FCM not configured
5. **No real-time updates** - Streams return static data
6. **No image uploads** - Profile pictures not functional
7. **Single device** - No data sync across devices

### What Works Perfectly
- ✅ All UI screens and navigation
- ✅ Form validation and user input
- ✅ State management and data flow
- ✅ Profile management (except images)
- ✅ Subscription status tracking
- ✅ Payment flow simulation
- ✅ Error handling and edge cases
- ✅ Role-based dashboards

---

## 🚀 Testing for Production

To test with **real Firebase**:

1. **Disable Mock Mode:**
```dart
// lib/utils/app_config.dart
static const bool enableMockMode = false; // ❌ Set to false
```

2. **Set Up Firebase:**
- Follow setup guide in `README.md`
- Run `flutterfire configure`
- Enable Phone Authentication
- Create Firestore database
- Deploy Cloud Functions

3. **Configure Razorpay:**
- Get API keys from Razorpay Dashboard
- Update `lib/services/payment_service.dart`
- Set Cloud Function environment variables

4. **Test Again:**
- Use real phone numbers
- Receive actual SMS OTP
- Make test payments (test mode)
- Verify Firestore data

---

## 📈 Performance Testing

### Load Time Benchmarks (Demo Mode)
- **App Launch:** < 2 seconds
- **Login → Dashboard:** < 2 seconds
- **Profile Load:** < 1 second
- **Subscription Load:** < 1 second
- **Payment Flow:** ~3 seconds (includes mock delay)

### Memory Usage (Target)
- **Idle:** < 150 MB
- **Active Use:** < 200 MB
- **Heavy Use:** < 300 MB

### Battery Usage (Target)
- **Light Use:** < 2% per hour
- **Moderate Use:** < 5% per hour

---

## 🎯 User Acceptance Testing (UAT) Checklist

### As a New Freelancer
- ✅ I can sign up with my phone number
- ✅ I receive an OTP to verify my number
- ✅ I can choose "Freelancer" as my role
- ✅ I see my dashboard with incomplete profile warning
- ✅ I can complete my profile with services and rates
- ✅ I can start a free trial
- ✅ I can view subscription plans
- ✅ I can subscribe to a plan
- ✅ I can see my subscription status
- ✅ I can manage/cancel my subscription
- ✅ I can view my payment history
- ✅ I can sign out and sign back in

### As an Existing Freelancer
- ✅ I can log back in with my phone number
- ✅ I go directly to my dashboard (skip role selection)
- ✅ My profile data is still there
- ✅ My subscription status is preserved
- ✅ I can edit my profile
- ✅ I can preview how my profile looks to customers
- ✅ I can upgrade/downgrade subscription plans
- ✅ I can see my complete payment history

---

## 📝 Bug Reporting Template

If you find issues during testing:

```
**Bug Title:** [Short description]

**Severity:** Critical / Major / Minor / Cosmetic

**Steps to Reproduce:**
1.
2.
3.

**Expected Result:**
[What should happen]

**Actual Result:**
[What actually happened]

**Environment:**
- Mode: Demo / Production
- Device: [Android/iOS, Version]
- Flutter Version: [x.x.x]
- App Version: [1.0.0]

**Screenshots/Videos:**
[If applicable]

**Additional Context:**
[Any other relevant information]
```

---

## ✅ Pre-Release Checklist

Before releasing to production:

### Code Quality
- [ ] All tests passing
- [ ] No console warnings
- [ ] No TODO comments left
- [ ] Code formatted (`flutter format .`)
- [ ] Code analyzed (`flutter analyze`)

### Configuration
- [ ] Mock mode disabled (`enableMockMode = false`)
- [ ] Firebase configured
- [ ] Razorpay production keys set
- [ ] Cloud Functions deployed
- [ ] Firestore rules deployed
- [ ] Storage rules deployed

### Testing
- [ ] All test cases passed
- [ ] Edge cases handled
- [ ] Error messages user-friendly
- [ ] Performance acceptable
- [ ] No memory leaks

### Documentation
- [ ] README updated
- [ ] API keys documented
- [ ] Deployment guide complete
- [ ] User guide available

---

## 📞 Support

**Issues:** Report bugs on GitHub Issues
**Questions:** Check README.md and documentation
**Demo Mode Help:** See `DEMO_MODE.md`

---

**Happy Testing! 🎉**
