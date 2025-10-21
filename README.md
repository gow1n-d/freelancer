# ServiceBooking - Freelancer Marketplace MVP

A subscription-based mobile platform connecting freelancers (mechanics, electricians, plumbers, tutors) with customers. Built with Flutter and Firebase.

## 🚀 Project Status: Phase 1 Complete

**Phase 1: Environment Setup & Foundation** ✅

This is the initial project setup. The foundation is complete with:
- Flutter project structure
- Dependencies configuration
- Firebase configuration files
- Core utilities (constants, theme, validators)
- Basic app entry point

## 📋 What's Included (Phase 1)

### Project Structure
```
freelancer/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── models/                      # Data models (empty, for Phase 2+)
│   ├── screens/                     # UI screens (empty, for Phase 2+)
│   │   ├── auth/
│   │   ├── customer/
│   │   ├── freelancer/
│   │   └── common/
│   ├── services/                    # Business logic (empty, for Phase 2+)
│   ├── widgets/                     # Reusable components (empty, for Phase 2+)
│   └── utils/
│       ├── constants.dart          # App-wide constants
│       ├── theme.dart              # Theme configuration
│       └── validators.dart         # Form validation utilities
├── functions/                       # Cloud Functions (for Phase 3+)
├── firebase.json                    # Firebase configuration
├── firestore.rules                  # Firestore security rules
├── firestore.indexes.json          # Firestore indexes
├── storage.rules                    # Firebase Storage rules
└── pubspec.yaml                    # Flutter dependencies
```

### Dependencies Configured
- **Firebase**: Core, Auth, Firestore, Messaging, Analytics, Storage
- **Payment**: Razorpay Flutter SDK
- **State Management**: Provider
- **UI**: Flutter SVG, Cached Network Image, Intl
- **Utilities**: UUID, HTTP

## 🛠️ Setup Instructions

### Prerequisites
1. **Flutter SDK** (3.0.0 or higher)
   - Download: https://flutter.dev/docs/get-started/install
   - Verify: `flutter doctor`

2. **Firebase CLI**
   - Install: `npm install -g firebase-tools`
   - Login: `firebase login`

3. **Code Editor**
   - VS Code (recommended) with Flutter extension
   - Or Android Studio with Flutter plugin

4. **Device/Emulator**
   - Android: Android Studio emulator or physical device
   - iOS: Xcode simulator or physical device (Mac only)

### Step 1: Install Flutter Dependencies

```bash
cd /workspace/cmh0d3vil003cqyi4gb4zq3ng/freelancer
flutter pub get
```

### Step 2: Firebase Project Setup (Manual)

This must be done manually in the Firebase Console:

1. **Create Firebase Project**
   - Go to: https://console.firebase.google.com
   - Click "Add project"
   - Project name: "ServiceBookingMVP" (or your chosen name)
   - Disable Google Analytics (optional for MVP)
   - Click "Create project"

2. **Register Android App**
   - In Firebase Console, click "Add app" → Android icon
   - Package name: `com.servicebooking.app` (customize if needed)
   - App nickname: "ServiceBooking Android"
   - Download `google-services.json`
   - Save it to: `android/app/google-services.json`

3. **Register iOS App** (if targeting iOS)
   - Click "Add app" → iOS icon
   - Bundle ID: `com.servicebooking.app` (must match Android)
   - App nickname: "ServiceBooking iOS"
   - Download `GoogleService-Info.plist`
   - Save it to: `ios/Runner/GoogleService-Info.plist`

4. **Enable Firebase Services**
   - **Authentication**:
     - Go to: Build → Authentication → Get started
     - Enable "Phone" sign-in method
     - Add test phone number (optional): +91 9999999999 → OTP: 123456

   - **Firestore Database**:
     - Go to: Build → Firestore Database → Create database
     - Start in "Production mode"
     - Select location: asia-south1 (Mumbai) or closest region

   - **Cloud Functions**:
     - Go to: Build → Functions → Get started
     - Enable Cloud Functions API
     - Upgrade to Blaze plan (pay-as-you-go, free tier available)

   - **Cloud Messaging**:
     - Go to: Build → Cloud Messaging
     - Already enabled by default

   - **Storage** (optional for MVP):
     - Go to: Build → Storage → Get started
     - Start in "Production mode"

5. **Generate Firebase Configuration**
   ```bash
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli

   # Generate firebase_options.dart
   flutterfire configure
   ```
   - This creates `lib/firebase_options.dart` with your Firebase config
   - Select your Firebase project
   - Select platforms: Android, iOS

6. **Deploy Firestore Rules**
   ```bash
   firebase init firestore
   # Use existing firestore.rules and firestore.indexes.json

   firebase deploy --only firestore:rules
   firebase deploy --only firestore:indexes
   ```

### Step 3: Configure Android Project

Edit `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        applicationId "com.servicebooking.app"  // Must match Firebase
        minSdkVersion 21  // Required for Firebase
        targetSdkVersion 33
        versionCode 1
        versionName "1.0.0"
        multiDexEnabled true  // Required for Firebase
    }
}

dependencies {
    // Add these if not present
    implementation 'com.google.firebase:firebase-analytics'
    implementation 'com.android.support:multidex:1.0.3'
}

// At the bottom of the file
apply plugin: 'com.google.gms.google-services'
```

Edit `android/build.gradle`:

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'  // Add this
    }
}
```

### Step 4: Configure iOS Project (if targeting iOS)

Run:
```bash
cd ios
pod install
cd ..
```

Edit `ios/Runner/Info.plist` and add:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.servicebooking.app</string>
        </array>
    </dict>
</array>
```

### Step 5: Update main.dart

After `firebase_options.dart` is generated, update `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';  // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,  // Uncomment this
  );

  runApp(const ServiceBookingApp());
}
```

### Step 6: Test the Setup

```bash
# Run on Android
flutter run

# Run on iOS (Mac only)
flutter run -d ios

# Run in release mode
flutter run --release
```

You should see a splash screen with the app name and a loading indicator.

## 🧪 Verify Setup

Run these commands to ensure everything is configured correctly:

```bash
# Check Flutter setup
flutter doctor -v

# Check dependencies
flutter pub get

# Run analyzer
flutter analyze

# Run on device
flutter run
```

Expected output:
- ✅ No issues found by `flutter doctor`
- ✅ All dependencies resolved
- ✅ No analysis issues
- ✅ App launches and shows splash screen

## 📦 What's Next: Phase 2

**Phase 2: Authentication System**

The next phase will implement:
- Firebase phone authentication (SMS OTP)
- Login screen with phone number input
- OTP verification screen
- Role selection (Customer vs Freelancer)
- User document creation in Firestore
- Basic navigation flow

To proceed to Phase 2, ensure:
- [ ] Firebase project is fully configured
- [ ] App runs successfully on a device/emulator
- [ ] Firebase console shows no errors
- [ ] You can see logs in Firebase console when app launches

## 🐛 Troubleshooting

### Issue: "Could not find google-services.json"
**Solution**: Download from Firebase Console and place in `android/app/`

### Issue: "Firebase not initialized"
**Solution**: Run `flutterfire configure` to generate `firebase_options.dart`

### Issue: "MultiDex error"
**Solution**: Add `multiDexEnabled true` in `android/app/build.gradle`

### Issue: "Pod install failed" (iOS)
**Solution**:
```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
```

### Issue: "gradle build failed"
**Solution**:
- Check Java version: `java -version` (should be JDK 11 or higher)
- Clear gradle cache: `cd android && ./gradlew clean`

## 📚 Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase for Flutter](https://firebase.google.com/docs/flutter/setup)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli)
- [Razorpay Flutter Plugin](https://razorpay.com/docs/payments/payment-gateway/flutter-integration/)

## 📝 Notes

- This is an MVP (Minimum Viable Product) implementation
- Focus is on core features first, optimizations later
- Security rules are in place but should be reviewed before production
- Test mode is recommended for development (Razorpay, Firebase)

## 🤝 Contributing

This is a private project. Refer to `planning.md` for the complete feature specification and implementation roadmap.

---

**Built with ❤️ using Flutter & Firebase**
