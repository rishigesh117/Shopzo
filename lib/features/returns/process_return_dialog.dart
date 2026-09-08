import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/product_provider.dart';
import '../../core/providers/return_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_button.dart';
import '../../core/widgets/shopzo_text_field.dart';

class ProcessReturnDialog extends StatefulWidget {
  final String billId;
  final String? customerId;
  final String productId;
  final String productNameSnapshot;
  final double purchasedQuantity;
  final String unit;
  final int sellingPricePaise;
  final VoidCallback? onReturnProcessed;

  const ProcessReturnDialog({
    super.key,
    required this.billId,
    this.customerId,
    required this.productId,
    required this.productNameSnapshot,
    required this.purchasedQuantity,
    required this.unit,
    required this.sellingPricePaise,
    this.onReturnProcessed,
  });

  @override
  State<ProcessReturnDialog> createState() => _ProcessReturnDialogState();
}

class _ProcessReturnDialogState extends State<ProcessReturnDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quantityController;
  double _alreadyReturnedQty = 0.0;
  bool _isLoadingReturnedQty = true;

  String _reason = 'Customer Return';
  String _stockAction = 'Restocked';
  bool _isSaving = false;
  String? _error;

  double get sellingPrice => widget.sellingPricePaise / 100.0;
  double get remainingReturnable => widget.purchasedQuantity - _alreadyReturnedQty;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
    _fetchAlreadyReturned();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _fetchAlreadyReturned() async {
    final returnProvider = Provider.of<ReturnProvider>(context, listen: false);
    final already = await returnProvider.getAlreadyReturnedQuantity(widget.billId, widget.productId);
    if (mounted) {
      setState(() {
        _alreadyReturnedQty = already;
        final maxQty = widget.purchasedQuantity - already;
        final defaultQtyStr = maxQty % 1 == 0 ? maxQty.toInt().toString() : maxQty.toString();
        _quantityController.text = maxQty > 0 ? defaultQtyStr : '0';
        _isLoadingReturnedQty = false;
      });
    }
  }

  Future<void> _submitReturn() async {
    if (!_formKey.currentState!.validate()) return;

    final qtyVal = double.tryParse(_quantityController.text.trim());
    if (qtyVal == null || qtyVal <= 0) {
      setState(() => _error = 'Enter a valid positive return quantity');
      return;
    }

    if (qtyVal > remainingReturnable) {
      setState(() => _error = 'Cannot return more than remaining returnable quantity ($remainingReturnable ${widget.unit})');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final returnProvider = Provider.of<ReturnProvider>(context, listen: false);
      final productProvider = Provider.of<ProductProvider>(context, listen: false);

      await returnProvider.processReturn(
        billId: widget.billId,
        customerId: widget.customerId,
        productId: widget.productId,
        productNameSnapshot: widget.productNameSnapshot,
        returnQuantity: qtyVal,
        unit: widget.unit,
        reason: _reason,
        stockAction: _stockAction,
        productProvider: productProvider,
      );

      if (widget.onReturnProcessed != null) {
        widget.onReturnProcessed!();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully processed return for ${widget.productNameSnapshot}'),
            backgroundColor: ShopzoColors.secondaryGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qtyVal = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    final estimatedRefund = (sellingPrice * qtyVal);

    return AlertDialog(
      backgroundColor: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Return Item — ${widget.productNameSnapshot}',
        style: ShopzoTypography.headingMedium(context, isDark: isDark),
      ),
      content: SingleChildScrollView(
        child: _isLoadingReturnedQty
            ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ShopzoColors.primaryNavy.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Original Purchased Qty:', style: TextStyle(fontSize: 12)),
                              Text('${widget.purchasedQuantity} ${widget.unit}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          if (_alreadyReturnedQty > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Already Returned:', style: TextStyle(fontSize: 12, color: ShopzoColors.danger)),
                                Text('$_alreadyReturnedQty ${widget.unit}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: ShopzoColors.danger)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Max Returnable:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              Text('$remainingReturnable ${widget.unit}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: ShopzoColors.secondaryGreen)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: ShopzoColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_error!, style: const TextStyle(color: ShopzoColors.danger, fontSize: 12)),
                      ),
                    ],

                    ShopzoTextField(
                      label: 'Return Quantity (${widget.unit}) *',
                      hint: 'e.g. 1',
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Return quantity is required';
                        final d = double.tryParse(val.trim());
                        if (d == null || d <= 0) return 'Enter a valid quantity';
                        if (d > remainingReturnable) return 'Cannot exceed $remainingReturnable ${widget.unit}';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    Text('Return Reason', style: ShopzoTypography.bodySmall(context, isDark: isDark).copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? ShopzoColors.darkSurfaceSecondary : ShopzoColors.lightSurfaceSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? ShopzoColors.darkBorder : ShopzoColors.lightBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _reason,
                          isExpanded: true,
                          dropdownColor: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
                          style: ShopzoTypography.bodyMedium(context, isDark: isDark),
                          items: const [
                            DropdownMenuItem(value: 'Customer Return', child: Text('Customer Return')),
                            DropdownMenuItem(value: 'Damaged', child: Text('Damaged Item')),
                            DropdownMenuItem(value: 'Expired', child: Text('Expired Item')),
                            DropdownMenuItem(value: 'Other', child: Text('Other Reason')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _reason = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text('Stock Action', style: ShopzoTypography.bodySmall(context, isDark: isDark).copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? ShopzoColors.darkSurfaceSecondary : ShopzoColors.lightSurfaceSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? ShopzoColors.darkBorder : ShopzoColors.lightBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _stockAction,
                          isExpanded: true,
                          dropdownColor: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
                          style: ShopzoTypography.bodyMedium(context, isDark: isDark),
                          items: const [
                            DropdownMenuItem(value: 'Restocked', child: Text('Restock (Add back to available stock)')),
                            DropdownMenuItem(value: 'Scrapped', child: Text('Scrap / Waste (Do not add back to stock)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _stockAction = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ShopzoColors.secondaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Refund Amount:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(
                            '₹${estimatedRefund.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ShopzoColors.secondaryGreen),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
        ),
        ShopzoButton(
          text: 'Process Return',
          isLoading: _isSaving,
          isDisabled: remainingReturnable <= 0,
          onPressed: _submitReturn,
        ),
      ],
    );
  }
}
