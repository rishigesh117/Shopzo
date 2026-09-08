import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_button.dart';
import '../../core/widgets/shopzo_card.dart';
import '../../core/widgets/shopzo_logo.dart';
import '../../core/widgets/shopzo_text_field.dart';
import '../shop_setup/shop_setup_choice_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    setState(() {
      _errorMessage = null;
    });

    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      setState(() {
        _errorMessage = 'Please enter a valid 10-digit mobile number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.mockLogin(phone);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ShopSetupChoiceScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const ShopzoLogo(iconSize: 48, showTagline: false),
                  const SizedBox(height: 36),
                  ShopzoCard(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome to Shopzo',
                            style: ShopzoTypography.headingLarge(context, isDark: isDark),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Manage your shop. Sell smarter.',
                            style: ShopzoTypography.bodyMedium(context, isDark: isDark),
                          ),
                          const SizedBox(height: 28),
                          ShopzoTextField(
                            label: 'Mobile Number',
                            hint: '98765 43210',
                            controller: _phoneController,
                            isPhone: true,
                            onChanged: (val) {
                              if (_errorMessage != null) {
                                setState(() {
                                  _errorMessage = null;
                                });
                              }
                            },
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage!,
                              style: ShopzoTypography.bodySmall(context, isDark: isDark).copyWith(
                                color: ShopzoColors.danger,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          ShopzoButton(
                            text: 'Continue',
                            isLoading: _isLoading,
                            onPressed: _handleContinue,
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              'Offline-First Supermarket Solution',
                              style: ShopzoTypography.bodySmall(context, isDark: isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
