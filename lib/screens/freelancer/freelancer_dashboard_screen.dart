import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/auth_provider.dart';
import '../../services/profile_service.dart';
import '../../services/subscription_service.dart';
import '../../models/subscription_model.dart';
import '../../utils/theme.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import 'profile_edit_screen.dart';
import 'profile_preview_screen.dart';
import 'subscription_screen.dart';
import 'subscription_management_screen.dart';

/// Freelancer dashboard screen with profile management
class FreelancerDashboardScreen extends StatefulWidget {
  const FreelancerDashboardScreen({super.key});

  @override
  State<FreelancerDashboardScreen> createState() =>
      _FreelancerDashboardScreenState();
}

class _FreelancerDashboardScreenState extends State<FreelancerDashboardScreen> {
  final _authService = AuthService();
  final _profileService = ProfileService();
  
  SubscriptionService? _subscriptionService;
  
  SubscriptionModel? _subscription;
  bool _isLoadingSubscription = true;

  @override
  void initState() {
    super.initState();
    // Initialize subscription service after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _subscriptionService = SubscriptionService(
        mockFirestore: AppConfig.enableMockMode ? authProvider.mockFirestore : null,
      );
      _loadSubscriptionData();
    });
  }

  Future<void> _loadSubscriptionData() async {
    if (_subscriptionService == null) return;
    
    setState(() {
      _isLoadingSubscription = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId;

      if (userId != null) {
        final subscription = await _subscriptionService!.getSubscription(userId);
        setState(() {
          _subscription = subscription;
          _isLoadingSubscription = false;
        });
      } else {
        setState(() {
          _isLoadingSubscription = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingSubscription = false;
      });
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _navigateToProfileEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileEditScreen(),
      ),
    );

    // Refresh user data after returning from profile edit
    if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUserData();
    }
  }

  void _navigateToProfilePreview(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePreviewScreen(user: user),
      ),
    );
  }

  Future<void> _navigateToSubscription() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SubscriptionScreen(),
      ),
    );

    if (result == true && mounted) {
      _loadSubscriptionData();
    }
  }

  Future<void> _navigateToSubscriptionManagement() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SubscriptionManagementScreen(),
      ),
    );

    if (result == true && mounted) {
      _loadSubscriptionData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Freelancer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _handleSignOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;

          if (authProvider.isLoading || user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final profileCompletion = _profileService.calculateProfileCompletion(user);
          final isProfileComplete = _profileService.isProfileComplete(user);
          final missingFields = _profileService.getMissingFields(user);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome card
                Card(
                  color: AppTheme.secondaryColor,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'F',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: AppTheme.secondaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name.isNotEmpty ? 'Welcome, ${user.name}!' : 'Welcome, Freelancer!',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.phoneNumber,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Profile completion card
                if (!isProfileComplete)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.warningColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_rounded,
                              color: AppTheme.warningColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Complete Your Profile',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: AppTheme.warningColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            Text(
                              '$profileCompletion%',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: AppTheme.warningColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: profileCompletion / 100,
                          backgroundColor: AppTheme.warningColor.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.warningColor),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Missing fields: ${missingFields.join(', ')}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _navigateToProfileEdit,
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Complete Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.warningColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.successColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.successColor,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Profile Complete!',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: AppTheme.successColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your profile is live and visible to customers',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _navigateToProfileEdit,
                                icon: const Icon(Icons.edit_rounded),
                                label: const Text('Edit Profile'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _navigateToProfilePreview(user),
                                icon: const Icon(Icons.visibility_rounded),
                                label: const Text('View Profile'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Subscription section
                if (!_isLoadingSubscription) ...[
                  Text(
                    'Subscription',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildSubscriptionCard(),
                  const SizedBox(height: 24),
                ],

                // Coming soon features
                Text(
                  'Coming Next',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                _FeatureCard(
                  icon: Icons.calendar_month_rounded,
                  title: 'Manage Bookings',
                  phase: 'Phase 3 Week 4',
                  description: 'Accept, reject, and complete service requests',
                ),
                _FeatureCard(
                  icon: Icons.star_rounded,
                  title: 'View Ratings',
                  phase: 'Phase 3 Week 5',
                  description: 'See your reviews and average rating',
                ),
                _FeatureCard(
                  icon: Icons.analytics_rounded,
                  title: 'Earnings Dashboard',
                  phase: 'Future',
                  description: 'Track your bookings and revenue',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    if (_isLoadingSubscription) {
      return const Center(child: CircularProgressIndicator());
    }

    // No subscription or inactive
    if (_subscription == null || !_subscription!.hasSubscription) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.card_membership_rounded,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Subscribe to Get Bookings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Activate your subscription to appear in customer searches and start receiving booking requests',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _navigateToSubscription,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('View Plans'),
            ),
          ],
        ),
      );
    }

    // Has active subscription
    final statusColor = _subscription!.isActive
        ? AppTheme.successColor
        : _subscription!.status == AppConstants.subscriptionCancelled
            ? AppTheme.warningColor
            : AppTheme.errorColor;

    final daysRemaining = _subscription!.daysRemaining;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _subscription!.isActive
                        ? Icons.check_circle_rounded
                        : Icons.info_rounded,
                    color: statusColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _subscriptionService!.formatStatus(_subscription!.status),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _subscriptionService!.formatPlan(_subscription!.plan),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Days remaining (if active)
          if (daysRemaining != null && daysRemaining > 0) ...[
            Row(
              children: [
                Icon(
                  Icons.timer_rounded,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '$daysRemaining days remaining',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Manage button
          ElevatedButton(
            onPressed: _navigateToSubscriptionManagement,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Manage Subscription'),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String phase;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.phase,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.secondaryLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.secondaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          phase,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
