import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/subscription_model.dart';
import '../../services/auth_provider.dart';
import '../../services/subscription_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import 'subscription_screen.dart';
import 'package:intl/intl.dart';

/// Screen for viewing and managing current subscription
class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends State<SubscriptionManagementScreen> {
  final _subscriptionService = SubscriptionService();

  SubscriptionModel? _subscription;
  List<PaymentModel> _paymentHistory = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.firebaseUser?.uid;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final results = await Future.wait([
        _subscriptionService.getSubscription(userId),
        _subscriptionService.getPaymentHistory(userId),
      ]);

      setState(() {
        _subscription = results[0] as SubscriptionModel?;
        _paymentHistory = results[1] as List<PaymentModel>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load subscription data: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _handleCancelSubscription() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription?'),
        content: const Text(
          'Your subscription will remain active until the end of the current billing period. You will not be charged again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.firebaseUser?.uid;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _subscriptionService.cancelSubscription(userId);
      await authProvider.refreshUserData();

      // Reload data
      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription cancelled successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel subscription: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleRenewSubscription() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SubscriptionScreen(),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Current subscription status
                    _buildSubscriptionCard(),
                    const SizedBox(height: 24),

                    // Payment history
                    if (_paymentHistory.isNotEmpty) ...[
                      _buildPaymentHistory(),
                      const SizedBox(height: 24),
                    ],

                    // Actions
                    _buildActions(),

                    // Processing indicator
                    if (_isProcessing)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSubscriptionCard() {
    if (_subscription == null || !_subscription!.hasSubscription) {
      return _buildNoSubscriptionCard();
    }

    final statusColor = _getStatusColor(_subscription!.status);
    final daysRemaining = _subscription!.daysRemaining;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Plan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _subscriptionService.formatStatus(_subscription!.status),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Plan details
            _buildDetailRow(
              icon: Icons.card_membership_rounded,
              label: 'Plan Type',
              value: _subscriptionService.formatPlan(_subscription!.plan),
            ),
            const SizedBox(height: 12),

            if (_subscription!.startDate != null)
              _buildDetailRow(
                icon: Icons.calendar_today_rounded,
                label: 'Started On',
                value: DateFormat('MMM dd, yyyy').format(_subscription!.startDate!),
              ),
            const SizedBox(height: 12),

            if (_subscription!.endDate != null)
              _buildDetailRow(
                icon: Icons.event_rounded,
                label: 'Valid Until',
                value: DateFormat('MMM dd, yyyy').format(_subscription!.endDate!),
              ),
            const SizedBox(height: 12),

            // Days remaining (if active)
            if (daysRemaining != null && daysRemaining > 0) ...[
              _buildDetailRow(
                icon: Icons.timer_rounded,
                label: 'Days Remaining',
                value: '$daysRemaining days',
              ),
              const SizedBox(height: 12),
            ],

            // Auto-renewal status
            _buildDetailRow(
              icon: _subscription!.autoRenewal
                  ? Icons.autorenew_rounded
                  : Icons.cancel_rounded,
              label: 'Auto-Renewal',
              value: _subscription!.autoRenewal ? 'Enabled' : 'Disabled',
              valueColor: _subscription!.autoRenewal
                  ? AppTheme.successColor
                  : AppTheme.warningColor,
            ),

            // Warning for expiring soon
            if (_subscription!.isExpiringSoon) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.warningColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: AppTheme.warningColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your subscription is expiring soon!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoSubscriptionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.card_membership_rounded,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Active Subscription',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Subscribe to unlock all features and start receiving bookings',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _handleRenewSubscription,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('View Plans'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppTheme.textPrimary,
              ),
        ),
      ],
    );
  }

  Widget _buildPaymentHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment History',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _paymentHistory.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final payment = _paymentHistory[index];
              return _buildPaymentItem(payment);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentItem(PaymentModel payment) {
    final statusColor = payment.status == 'success'
        ? AppTheme.successColor
        : payment.status == 'failed'
            ? AppTheme.errorColor
            : AppTheme.warningColor;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          payment.status == 'success'
              ? Icons.check_circle_rounded
              : payment.status == 'failed'
                  ? Icons.error_rounded
                  : Icons.pending_rounded,
          color: statusColor,
        ),
      ),
      title: Text(
        '₹${payment.amount}',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            _subscriptionService.formatPlan(payment.plan),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat('MMM dd, yyyy').format(payment.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          payment.status.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    if (_subscription == null || !_subscription!.hasSubscription) {
      return const SizedBox.shrink();
    }

    final isActive = _subscription!.isActive;
    final isCancelled = _subscription!.status == AppConstants.subscriptionCancelled;
    final isExpired = _subscription!.isExpired;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isActive && !isCancelled)
          OutlinedButton(
            onPressed: _isProcessing ? null : _handleCancelSubscription,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              side: BorderSide(color: AppTheme.errorColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Cancel Subscription'),
          ),
        if (isCancelled || isExpired) ...[
          ElevatedButton(
            onPressed: _isProcessing ? null : _handleRenewSubscription,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Renew Subscription'),
          ),
        ],
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.subscriptionActive:
        return AppTheme.successColor;
      case AppConstants.subscriptionTrial:
        return AppTheme.infoColor;
      case AppConstants.subscriptionExpired:
        return AppTheme.errorColor;
      case AppConstants.subscriptionCancelled:
        return AppTheme.warningColor;
      default:
        return AppTheme.textSecondary;
    }
  }
}
