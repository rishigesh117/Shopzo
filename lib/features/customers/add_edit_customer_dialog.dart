import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/customer_model.dart';
import '../../core/providers/customer_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_button.dart';
import '../../core/widgets/shopzo_text_field.dart';

class AddEditCustomerDialog extends StatefulWidget {
  final Customer? customer;
  final Function(Customer)? onCustomerCreated;

  const AddEditCustomerDialog({
    super.key,
    this.customer,
    this.onCustomerCreated,
  });

  @override
  State<AddEditCustomerDialog> createState() => _AddEditCustomerDialogState();
}

class _AddEditCustomerDialogState extends State<AddEditCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(text: widget.customer?.phone ?? '');
    _addressController = TextEditingController(text: widget.customer?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final provider = Provider.of<CustomerProvider>(context, listen: false);

    try {
      if (widget.customer == null) {
        final newCust = await provider.addCustomer(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        );
        if (widget.onCustomerCreated != null) {
          widget.onCustomerCreated!(newCust);
        }
      } else {
        final updated = widget.customer!.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        );
        await provider.updateCustomer(updated);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.customer != null;

    return AlertDialog(
      backgroundColor: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEditing ? 'Edit Customer' : 'Add New Customer',
        style: ShopzoTypography.headingMedium(context, isDark: isDark),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: ShopzoColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: ShopzoColors.danger, fontSize: 13),
                  ),
                ),
              ],
              ShopzoTextField(
                label: 'Customer Name *',
                hint: 'e.g. Arun Kumar',
                controller: _nameController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Customer name is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ShopzoTextField(
                label: 'Phone Number *',
                hint: 'e.g. 9876543210',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Phone number is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ShopzoTextField(
                label: 'Address (Optional)',
                hint: 'e.g. MG Road, Sector 4',
                controller: _addressController,
                maxLines: 2,
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
          text: isEditing ? 'Update' : 'Save Customer',
          isLoading: _isSaving,
          onPressed: _save,
        ),
      ],
    );
  }
}
