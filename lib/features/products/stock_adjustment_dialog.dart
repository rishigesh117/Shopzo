import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/product_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_button.dart';
import '../../core/widgets/shopzo_text_field.dart';

class StockAdjustmentDialog extends StatefulWidget {
  final Product product;

  const StockAdjustmentDialog({super.key, required this.product});

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newQuantityController = TextEditingController();
  final _reasonController = TextEditingController();
  String _selectedReason = 'Damaged / Stock Count Correction';
  bool _isLoading = false;

  final List<String> _commonReasons = [
    'Damaged / Stock Count Correction',
    'Expired Product',
    'Spill / Loss',
    'Inventory Audit Adjustment',
    'Other Reason',
  ];

  @override
  void initState() {
    super.initState();
    _newQuantityController.text = widget.product.quantity.toString();
  }

  @override
  void dispose() {
    _newQuantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _handleAdjust() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final newQty = double.tryParse(_newQuantityController.text.trim()) ?? 0.0;
    final reasonText = _selectedReason == 'Other Reason'
        ? (_reasonController.text.trim().isEmpty ? 'Manual Adjustment' : _reasonController.text.trim())
        : _selectedReason;

    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    await productProvider.adjustStock(
      productId: widget.product.id,
      newQuantity: newQty,
      reason: reasonText,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Adjusted stock for ${widget.product.name} to ${newQty} ${widget.product.unit}'),
          backgroundColor: ShopzoColors.primaryNavy,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    return Dialog(
      backgroundColor: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Manual Stock Adjustment',
                    style: ShopzoTypography.headingMedium(context, isDark: isDark),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ShopzoColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded, color: ShopzoColors.warning),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: ShopzoTypography.bodyLarge(context, isDark: isDark).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Current Stock: ${widget.product.quantity} ${widget.product.unit}',
                          style: ShopzoTypography.bodySmall(context, isDark: isDark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ShopzoTextField(
                label: 'New Quantity (${widget.product.unit}) *',
                hint: 'e.g. 10',
                controller: _newQuantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.edit_note_rounded,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter new quantity';
                  final num = double.tryParse(val);
                  if (num == null || num < 0) return 'Cannot be negative';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Reason for Adjustment *',
                style: ShopzoTypography.bodyMedium(context, isDark: isDark).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? ShopzoColors.darkSurfaceSecondary : ShopzoColors.lightSurfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? ShopzoColors.darkBorder : ShopzoColors.lightBorder,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedReason,
                    isExpanded: true,
                    dropdownColor: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
                    style: ShopzoTypography.bodyLarge(context, isDark: isDark),
                    items: _commonReasons.map((r) {
                      return DropdownMenuItem<String>(
                        value: r,
                        child: Text(r),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedReason = val;
                        });
                      }
                    },
                  ),
                ),
              ),
              if (_selectedReason == 'Other Reason') ...[
                const SizedBox(height: 12),
                ShopzoTextField(
                  label: 'Specify Reason *',
                  hint: 'Enter reason details',
                  controller: _reasonController,
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 16, color: isDark ? ShopzoColors.darkTextMuted : ShopzoColors.lightTextMuted),
                  const SizedBox(width: 8),
                  Text(
                    'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(now)}',
                    style: ShopzoTypography.bodySmall(context, isDark: isDark),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ShopzoButton(
                text: 'Save Stock Adjustment',
                isLoading: _isLoading,
                onPressed: _handleAdjust,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
