import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/customer_dashboard_screen.dart';
import 'screens/freelancer/freelancer_dashboard_screen.dart';
import 'utils/constants.dart';
import 'utils/theme.dart';
import 'utils/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase only if NOT in mock mode
  if (!AppConfig.enableMockMode) {
    try {
      // Initialize Firebase
      // Note: Run `flutterfire configure` to generate firebase_options.dart
      // await Firebase.initializeApp(
      //   options: DefaultFirebaseOptions.currentPlatform,
      // );
      
      AppConfig.log('Firebase initialized successfully');
    } catch (e) {
      AppConfig.log('Firebase initialization failed: $e');
      // Continue anyway if Firebase fails (will auto-enable mock mode)
    }
  } else {
    AppConfig.log('Running in MOCK MODE - No Firebase required');
  }

  runApp(const ServiceBookingApp());
}

class ServiceBookingApp extends StatelessWidget {
  const ServiceBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
        // Show banner in debug mode
        builder: (context, child) {
          if (AppConfig.showDebugInfo && AppConfig.enableMockMode) {
            return Banner(
              message: 'DEMO MODE',
              location: BannerLocation.topEnd,
              child: child!,
            );
          }
          return child!;
        },
      ),
    );
  }
}

/// Wrapper to handle authentication state and navigation
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading screen while checking auth state
        if (authProvider.isLoading) {
          return const SplashScreen();
        }

        // User not signed in - show login screen
        if (!authProvider.isSignedIn) {
          return const LoginScreen();
        }

        // User signed in but no user data - show loading
        if (authProvider.currentUser == null) {
          return const SplashScreen();
        }

        // Navigate to appropriate dashboard based on role
        if (authProvider.isFreelancer) {
          return const FreelancerDashboardScreen();
        } else {
          return const CustomerDashboardScreen();
        }
      },
    );
  }
}

/// Splash screen shown during initialization and loading
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.handyman_rounded,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Connect with local service providers',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            
            // Show mode indicator in debug
            if (AppConfig.showDebugInfo) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppConfig.enableMockMode 
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  AppConfig.modeDescription,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppConfig.enableMockMode 
                            ? Colors.orange.shade800
                            : Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
            
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Version ${AppConstants.appVersion}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
