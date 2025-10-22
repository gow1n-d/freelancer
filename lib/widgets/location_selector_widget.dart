import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../utils/theme.dart';

/// Widget for selecting service location (city, state, radius)
class LocationSelectorWidget extends StatefulWidget {
  final ServiceLocation? initialLocation;
  final Function(ServiceLocation?) onChanged;
  final String? cityErrorText;

  const LocationSelectorWidget({
    super.key,
    this.initialLocation,
    required this.onChanged,
    this.cityErrorText,
  });

  @override
  State<LocationSelectorWidget> createState() => _LocationSelectorWidgetState();
}

class _LocationSelectorWidgetState extends State<LocationSelectorWidget> {
  late TextEditingController _cityController;
  late String _selectedState;
  late int _selectedRadius;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(
      text: widget.initialLocation?.city ?? '',
    );
    _selectedState = widget.initialLocation?.state ?? AppConstants.indianStates.first;
    _selectedRadius = widget.initialLocation?.radius ?? 5;

    _cityController.addListener(_notifyChange);
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    if (_cityController.text.trim().isNotEmpty) {
      widget.onChanged(
        ServiceLocation(
          city: _cityController.text.trim(),
          state: _selectedState,
          radius: _selectedRadius,
        ),
      );
    } else {
      widget.onChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          'Service Location',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),

        // City input
        TextFormField(
          controller: _cityController,
          decoration: InputDecoration(
            labelText: 'City/Area',
            hintText: 'e.g., Pune, Mumbai, Bangalore',
            prefixIcon: const Icon(Icons.location_city_rounded),
            errorText: widget.cityErrorText,
          ),
          validator: Validators.validateCity,
        ),
        const SizedBox(height: 16),

        // State dropdown
        DropdownButtonFormField<String>(
          value: _selectedState,
          decoration: const InputDecoration(
            labelText: 'State',
            prefixIcon: Icon(Icons.map_rounded),
          ),
          items: AppConstants.indianStates.map((state) {
            return DropdownMenuItem(
              value: state,
              child: Text(state),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedState = value;
              });
              _notifyChange();
            }
          },
        ),
        const SizedBox(height: 16),

        // Service radius
        Row(
          children: [
            Icon(
              Icons.radio_button_checked_rounded,
              size: 20,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Service Radius: ${_selectedRadius}km',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Radius chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.serviceRadiusOptions.map((radius) {
            final isSelected = _selectedRadius == radius;
            return ChoiceChip(
              label: Text('${radius}km'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedRadius = radius;
                  });
                  _notifyChange();
                }
              },
              backgroundColor: AppTheme.backgroundColor,
              selectedColor: AppTheme.primaryColor,
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

        // Preview
        if (_cityController.text.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryLight.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Preview: ${_cityController.text.trim()}, $_selectedState ($_selectedRadius km radius)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
