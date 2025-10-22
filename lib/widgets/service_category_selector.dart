import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

/// Widget for selecting service categories (multi-select)
class ServiceCategorySelector extends StatefulWidget {
  final List<String> selectedCategories;
  final Function(List<String>) onChanged;
  final String? errorText;

  const ServiceCategorySelector({
    super.key,
    required this.selectedCategories,
    required this.onChanged,
    this.errorText,
  });

  @override
  State<ServiceCategorySelector> createState() =>
      _ServiceCategorySelectorState();
}

class _ServiceCategorySelectorState extends State<ServiceCategorySelector> {
  late List<String> _selectedCategories;

  @override
  void initState() {
    super.initState();
    _selectedCategories = List.from(widget.selectedCategories);
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        // Check max limit
        if (_selectedCategories.length < AppConstants.maxServiceCategories) {
          _selectedCategories.add(category);
        } else {
          // Show warning
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You can select up to ${AppConstants.maxServiceCategories} categories only',
              ),
              backgroundColor: AppTheme.warningColor,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
      }
      widget.onChanged(_selectedCategories);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              'Service Categories',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 8),
            Text(
              '(Select 1-${AppConstants.maxServiceCategories})',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Selected count
        if (_selectedCategories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${_selectedCategories.length} selected',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),

        // Category chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.serviceCategories.map((category) {
            final isSelected = _selectedCategories.contains(category);
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => _toggleCategory(category),
              backgroundColor: AppTheme.backgroundColor,
              selectedColor: AppTheme.primaryColor,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
              ),
            );
          }).toList(),
        ),

        // Error text
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              widget.errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.errorColor,
                  ),
            ),
          ),
      ],
    );
  }
}
