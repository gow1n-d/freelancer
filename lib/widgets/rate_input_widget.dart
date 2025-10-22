import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../utils/theme.dart';

/// Widget for inputting rate (amount + type)
class RateInputWidget extends StatefulWidget {
  final RateInfo? initialRate;
  final Function(RateInfo?) onChanged;
  final String? errorText;

  const RateInputWidget({
    super.key,
    this.initialRate,
    required this.onChanged,
    this.errorText,
  });

  @override
  State<RateInputWidget> createState() => _RateInputWidgetState();
}

class _RateInputWidgetState extends State<RateInputWidget> {
  late TextEditingController _amountController;
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialRate?.amount.toString() ?? '',
    );
    _selectedType = widget.initialRate?.type ?? AppConstants.rateTypeHour;

    _amountController.addListener(_notifyChange);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    final amount = int.tryParse(_amountController.text);
    if (amount != null) {
      widget.onChanged(RateInfo(amount: amount, type: _selectedType));
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
          'Your Rate',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),

        // Amount and type in row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount input
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹',
                  hintText: '500',
                  errorText: widget.errorText,
                ),
                validator: Validators.validateRate,
              ),
            ),
            const SizedBox(width: 12),

            // Type dropdown
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                ),
                items: [
                  DropdownMenuItem(
                    value: AppConstants.rateTypeHour,
                    child: const Text('Per Hour'),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.rateTypeVisit,
                    child: const Text('Per Visit'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                    _notifyChange();
                  }
                },
              ),
            ),
          ],
        ),

        // Preview
        if (_amountController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.currency_rupee,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Preview: ₹${_amountController.text}/${_selectedType == AppConstants.rateTypeHour ? 'hour' : 'visit'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),

        // Hint text
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 12),
          child: Text(
            'Range: ₹${AppConstants.minRate} - ₹${AppConstants.maxRate}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ),
      ],
    );
  }
}
