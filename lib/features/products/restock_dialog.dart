import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/product_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_button.dart';
import '../../core/widgets/shopzo_text_field.dart';

class RestockDialog extends StatefulWidget {
  final Product product;

  const RestockDialog({super.key, required this.product});

  @override
  State<RestockDialog> createState() => _RestockDialogState();
}

class _RestockDialogState extends State<RestockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _addQuantityController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _supplierController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _purchasePriceController.text = widget.product.buyingPrice.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _addQuantityController.dispose();
    _purchasePriceController.dispose();
    _supplierController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleRestock() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final addQty = double.tryParse(_addQuantityController.text.trim()) ?? 0.0;
    final price = double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
    final pricePaise = (price * 100).round();

    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    await productProvider.restockProduct(
      productId: widget.product.id,
      addQuantity: addQty,
      purchasePricePaise: pricePaise,
      supplier: _supplierController.text.trim().isEmpty ? null : _supplierController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restocked ${widget.product.name} (+${addQty} ${widget.product.unit})!'),
          backgroundColor: ShopzoColors.secondaryGreen,
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
                    'Restock Product',
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
                  color: ShopzoColors.secondaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_rounded, color: ShopzoColors.secondaryGreen),
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
              Row(
                children: [
                  Expanded(
                    child: ShopzoTextField(
                      label: 'Add Quantity (${widget.product.unit}) *',
                      hint: 'e.g. 25',
                      controller: _addQuantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.add_circle_outline_rounded,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter quantity';
                        final num = double.tryParse(val);
                        if (num == null || num <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ShopzoTextField(
                      label: 'Purchase Price (₹) *',
                      hint: '48.00',
                      controller: _purchasePriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.currency_rupee_rounded,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter price';
                        final num = double.tryParse(val);
                        if (num == null || num < 0) return 'Invalid price';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
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
              const SizedBox(height: 16),
              ShopzoTextField(
                label: 'Supplier (Optional)',
                hint: 'e.g. Metro Wholesalers',
                controller: _supplierController,
                prefixIcon: Icons.local_shipping_rounded,
              ),
              const SizedBox(height: 16),
              ShopzoTextField(
                label: 'Notes (Optional)',
                hint: 'e.g. Batch #4092 received',
                controller: _notesController,
                prefixIcon: Icons.notes_rounded,
              ),
              const SizedBox(height: 24),
              ShopzoButton(
                text: 'Restock Product',
                isLoading: _isLoading,
                onPressed: _handleRestock,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
