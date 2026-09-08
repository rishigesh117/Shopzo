import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/shop_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_button.dart';
import '../../core/widgets/shopzo_card.dart';
import '../../core/widgets/shopzo_text_field.dart';
import 'shop_code_screen.dart';

class CreateShopScreen extends StatefulWidget {
  const CreateShopScreen({super.key});

  @override
  State<CreateShopScreen> createState() => _CreateShopScreenState();
}

class _CreateShopScreenState extends State<CreateShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _handleCreateShop() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          final shopProvider = Provider.of<ShopProvider>(context, listen: false);
          shopProvider.createShop(
            name: _shopNameController.text.trim(),
            ownerName: _ownerNameController.text.trim(),
            phone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
          );

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ShopCodeScreen()),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Shop'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ShopzoCard(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set Up Your Shop',
                        style: ShopzoTypography.headingLarge(context, isDark: isDark),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter your supermarket details below',
                        style: ShopzoTypography.bodyMedium(context, isDark: isDark),
                      ),
                      const SizedBox(height: 24),
                      // Shop Logo Placeholder
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: isDark ? ShopzoColors.darkSurfaceSecondary : ShopzoColors.lightSurfaceSecondary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? ShopzoColors.darkBorder : ShopzoColors.lightBorder,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.storefront_rounded,
                                size: 40,
                                color: isDark ? ShopzoColors.darkTextSecondary : ShopzoColors.lightTextSecondary,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: ShopzoColors.primaryNavy,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ShopzoTextField(
                        label: 'Shop Name',
                        hint: 'SuperMart Supermarket',
                        controller: _shopNameController,
                        prefixIcon: Icons.store_rounded,
                        validator: (val) => (val == null || val.isEmpty) ? 'Enter shop name' : null,
                      ),
                      const SizedBox(height: 16),
                      ShopzoTextField(
                        label: 'Owner Name',
                        hint: 'Arun Kumar',
                        controller: _ownerNameController,
                        prefixIcon: Icons.person_rounded,
                        validator: (val) => (val == null || val.isEmpty) ? 'Enter owner name' : null,
                      ),
                      const SizedBox(height: 16),
                      ShopzoTextField(
                        label: 'Phone Number',
                        hint: '98765 43210',
                        controller: _phoneController,
                        isPhone: true,
                        validator: (val) => (val == null || val.length < 10) ? 'Enter valid phone number' : null,
                      ),
                      const SizedBox(height: 16),
                      ShopzoTextField(
                        label: 'Address',
                        hint: '123 Main Bazaar Road, Central City',
                        controller: _addressController,
                        prefixIcon: Icons.location_on_rounded,
                        validator: (val) => (val == null || val.isEmpty) ? 'Enter shop address' : null,
                      ),
                      const SizedBox(height: 28),
                      ShopzoButton(
                        text: 'Create Shop',
                        isLoading: _isLoading,
                        onPressed: _handleCreateShop,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
