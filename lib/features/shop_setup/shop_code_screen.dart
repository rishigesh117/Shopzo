import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/main_shell.dart';
import '../../core/providers/shop_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_button.dart';
import '../../core/widgets/shopzo_card.dart';

class ShopCodeScreen extends StatefulWidget {
  const ShopCodeScreen({super.key});

  @override
  State<ShopCodeScreen> createState() => _ShopCodeScreenState();
}

class _ShopCodeScreenState extends State<ShopCodeScreen> {
  bool _copied = false;

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() {
      _copied = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shop Code copied to clipboard!'),
        backgroundColor: ShopzoColors.secondaryGreen,
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shopProvider = Provider.of<ShopProvider>(context);
    final code = shopProvider.mockCode;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ShopzoCard(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ShopzoColors.secondaryGreen.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 48,
                        color: ShopzoColors.secondaryGreen,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Shop Created Successfully!',
                      style: ShopzoTypography.headingMedium(context, isDark: isDark),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your Shop Code',
                      style: ShopzoTypography.bodyMedium(context, isDark: isDark),
                    ),
                    const SizedBox(height: 20),
                    // Code Display Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      decoration: BoxDecoration(
                        color: isDark ? ShopzoColors.darkSurfaceSecondary : ShopzoColors.lightSurfaceSecondary,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: ShopzoColors.secondaryGreen.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            code,
                            style: ShopzoTypography.moneyText(
                              context,
                              fontSize: 28,
                              isDark: isDark,
                              color: ShopzoColors.secondaryGreen,
                            ).copyWith(letterSpacing: 3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Share this code with your shop members so they can request to join your shop.',
                      style: ShopzoTypography.bodyMedium(context, isDark: isDark),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    ShopzoButton(
                      text: _copied ? 'Copied!' : 'Copy Code',
                      isSecondary: true,
                      icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
                      onPressed: () => _copyCode(code),
                    ),
                    const SizedBox(height: 12),
                    ShopzoButton(
                      text: 'Continue to Shop',
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const MainShell()),
                          (route) => false,
                        );
                      },
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
