import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/main_shell.dart';
import '../../core/providers/shop_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_button.dart';
import '../../core/widgets/shopzo_card.dart';
import '../../core/widgets/shopzo_text_field.dart';

class JoinShopScreen extends StatefulWidget {
  const JoinShopScreen({super.key});

  @override
  State<JoinShopScreen> createState() => _JoinShopScreenState();
}

class _JoinShopScreenState extends State<JoinShopScreen> {
  final _codeController = TextEditingController();
  bool _requestSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _handleSendRequest() {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        final shopProvider = Provider.of<ShopProvider>(context, listen: false);
        shopProvider.joinShop(code);

        setState(() {
          _isLoading = false;
          _requestSent = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Join a Shop'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ShopzoCard(
                padding: const EdgeInsets.all(32),
                child: _requestSent
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: ShopzoColors.warning.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.hourglass_top_rounded,
                              size: 48,
                              color: ShopzoColors.warning,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Request Sent!',
                            style: ShopzoTypography.headingMedium(context, isDark: isDark),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Waiting for the shop owner to approve your request.',
                            style: ShopzoTypography.bodyMedium(context, isDark: isDark),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          ShopzoButton(
                            text: 'Enter Shop (Demo Access)',
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const MainShell()),
                                (route) => false,
                              );
                            },
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Join a Shop',
                            style: ShopzoTypography.headingLarge(context, isDark: isDark),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Enter the 9-character code shared by your shop owner.',
                            style: ShopzoTypography.bodyMedium(context, isDark: isDark),
                          ),
                          const SizedBox(height: 24),
                          ShopzoTextField(
                            label: 'Enter Shop Code',
                            hint: 'e.g. SHP-482913',
                            controller: _codeController,
                            prefixIcon: Icons.qr_code_rounded,
                          ),
                          const SizedBox(height: 28),
                          ShopzoButton(
                            text: 'Send Request',
                            isLoading: _isLoading,
                            onPressed: _handleSendRequest,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
