import 'package:flutter/material.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_button.dart';
import '../../core/widgets/shopzo_text_field.dart';

class QuantityEditDialog extends StatefulWidget {
  final String productName;
  final double currentQuantity;
  final String unit;
  final double availableStock;
  final Function(double) onSave;

  const QuantityEditDialog({
    super.key,
    required this.productName,
    required this.currentQuantity,
    required this.unit,
    required this.availableStock,
    required this.onSave,
  });

  @override
  State<QuantityEditDialog> createState() => _QuantityEditDialogState();
}

class _QuantityEditDialogState extends State<QuantityEditDialog> {
  late TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Format quantity cleanly without trailing zero if integer
    final qtyStr = widget.currentQuantity % 1 == 0
        ? widget.currentQuantity.toInt().toString()
        : widget.currentQuantity.toString();
    _controller = TextEditingController(text: qtyStr);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    final val = double.tryParse(text);

    if (val == null || val <= 0) {
      setState(() => _error = 'Please enter a valid quantity greater than 0');
      return;
    }

    if (val > widget.availableStock) {
      setState(() => _error = 'Only ${widget.availableStock} ${widget.unit} available in stock');
      return;
    }

    widget.onSave(val);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Enter Quantity — ${widget.productName}',
        style: ShopzoTypography.headingMedium(context, isDark: isDark),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Stock: ${widget.availableStock} ${widget.unit}',
            style: ShopzoTypography.bodyMedium(context, isDark: isDark).copyWith(
              color: ShopzoColors.secondaryGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ShopzoTextField(
            label: 'Quantity (${widget.unit})',
            hint: 'e.g. 2, 2.5, 10',
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            errorText: _error,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
        ),
        ShopzoButton(
          text: 'Set Quantity',
          onPressed: _submit,
        ),
      ],
    );
  }
}
