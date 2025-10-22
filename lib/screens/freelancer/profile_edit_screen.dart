import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_provider.dart';
import '../../services/profile_service.dart';
import '../../utils/validators.dart';
import '../../utils/theme.dart';
import '../../widgets/service_category_selector.dart';
import '../../widgets/rate_input_widget.dart';
import '../../widgets/location_selector_widget.dart';
import 'profile_preview_screen.dart';

/// Profile edit screen for freelancers
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _profileService = ProfileService();

  List<String> _selectedCategories = [];
  RateInfo? _rate;
  ServiceLocation? _location;

  bool _isLoading = false;
  bool _isSaving = false;

  String? _categoriesError;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentProfile() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      _nameController.text = user.name;
      _selectedCategories = user.serviceCategories ?? [];
      _rate = user.rate;
      _location = user.serviceLocation;
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleSave() async {
    // Validate categories
    final categoryError = Validators.validateServiceCategories(_selectedCategories);
    setState(() {
      _categoriesError = categoryError;
    });

    if (!_formKey.currentState!.validate() || categoryError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix all errors before saving'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.firebaseUser?.uid;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _profileService.updateProfile(
        userId: userId,
        name: _nameController.text.trim(),
        serviceCategories: _selectedCategories,
        rate: _rate,
        serviceLocation: _location,
      );

      // Refresh user data
      await authProvider.refreshUserData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _handlePreview() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) return;

    // Create temporary user with current form data
    final previewUser = user.copyWith(
      name: _nameController.text.trim(),
      serviceCategories: _selectedCategories,
      rate: _rate,
      serviceLocation: _location,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePreviewScreen(user: previewUser),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading || _isSaving ? null : _handlePreview,
            icon: const Icon(Icons.visibility_rounded),
            label: const Text('Preview'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile completion notice
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        final user = authProvider.currentUser;
                        if (user == null) return const SizedBox.shrink();

                        final completion =
                            _profileService.calculateProfileCompletion(user);

                        if (completion == 100) {
                          return const SizedBox.shrink();
                        }

                        return Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 24),
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
                                    Icons.info_rounded,
                                    color: AppTheme.warningColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Profile ${completion}% Complete',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: AppTheme.warningColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: completion / 100,
                                backgroundColor:
                                    AppTheme.warningColor.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.warningColor),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Complete all required fields to appear in customer search',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textPrimary,
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'Enter your name',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                      validator: Validators.validateName,
                      enabled: !_isSaving,
                    ),
                    const SizedBox(height: 24),

                    // Service categories
                    ServiceCategorySelector(
                      selectedCategories: _selectedCategories,
                      onChanged: (categories) {
                        setState(() {
                          _selectedCategories = categories;
                          _categoriesError =
                              Validators.validateServiceCategories(categories);
                        });
                      },
                      errorText: _categoriesError,
                    ),
                    const SizedBox(height: 24),

                    // Rate
                    RateInputWidget(
                      initialRate: _rate,
                      onChanged: (rate) {
                        setState(() {
                          _rate = rate;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Location
                    LocationSelectorWidget(
                      initialLocation: _location,
                      onChanged: (location) {
                        setState(() {
                          _location = location;
                        });
                      },
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Save Profile'),
                    ),
                    const SizedBox(height: 16),

                    // Required fields note
                    Text(
                      '* All fields are required to appear in customer search',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
