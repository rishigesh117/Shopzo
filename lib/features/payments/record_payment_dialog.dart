import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/customer_provider.dart';
import '../../core/providers/payment_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_button.dart';
import '../../core/widgets/shopzo_text_field.dart';

class RecordPaymentDialog extends StatefulWidget {
  final String? customerId;
  final String? billId;
  final int pendingAmountPaise;
  final VoidCallback? onPaymentRecorded;

  const RecordPaymentDialog({
    super.key,
    this.customerId,
    this.billId,
    required this.pendingAmountPaise,
    this.onPaymentRecorded,
  });

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  String _paymentMethod = 'Cash';
  bool _isSaving = false;
  String? _error;

  double get pendingAmount => widget.pendingAmountPaise / 100.0;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: pendingAmount.toStringAsFixed(2));
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    final amountStr = _amountController.text.trim();
    final amount = double.tryParse(amountStr);

    if (amount == null || amount <= 0) {
      setState(() => _error = 'Please enter a valid positive payment amount');
      return;
    }

    if (amount > pendingAmount) {
      setState(() => _error = 'Payment cannot exceed pending due amount (₹${pendingAmount.toStringAsFixed(2)})');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);

      await paymentProvider.recordPayment(
        customerId: widget.customerId,
        billId: widget.billId,
        amount: amount,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        customerProvider: customerProvider,
      );

      if (widget.onPaymentRecorded != null) {
        widget.onPaymentRecorded!();
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Record Due Payment',
        style: ShopzoTypography.headingMedium(context, isDark: isDark),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ShopzoColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Outstanding Due Balance:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      '₹${pendingAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ShopzoColors.danger),
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
                label: 'Payment Amount (₹) *',
                hint: '0.00',
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Amount is required';
                  final d = double.tryParse(val.trim());
                  if (d == null || d <= 0) return 'Enter a valid positive amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text('Payment Method', style: ShopzoTypography.bodySmall(context, isDark: isDark).copyWith(fontWeight: FontWeight.bold)),
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
                    value: _paymentMethod,
                    isExpanded: true,
                    dropdownColor: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
                    style: ShopzoTypography.bodyMedium(context, isDark: isDark),
                    items: const [
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                      DropdownMenuItem(value: 'Card', child: Text('Card')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _paymentMethod = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ShopzoTextField(
                label: 'Notes / Reference (Optional)',
                hint: 'e.g. Received via GPay or cash partial payment',
                controller: _notesController,
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
          text: 'Record Payment',
          isLoading: _isSaving,
          onPressed: _savePayment,
        ),
      ],
    );
  }
}
