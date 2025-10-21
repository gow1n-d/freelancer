import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'utils/constants.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  // Note: firebase_options.dart will be generated after Firebase setup
  // For now, this is a placeholder
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  runApp(const ServiceBookingApp());
}

class ServiceBookingApp extends StatelessWidget {
  const ServiceBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

/// Temporary splash screen - will be replaced with proper authentication flow
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
              'Phase 1: Project Setup Complete',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
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
