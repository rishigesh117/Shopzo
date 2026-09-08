import 'package:flutter/material.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_card.dart';
import '../../core/widgets/shopzo_logo.dart';
import 'create_shop_screen.dart';
import 'join_shop_screen.dart';

class ShopSetupChoiceScreen extends StatelessWidget {
  const ShopSetupChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const ShopzoLogo(iconSize: 44, showTagline: false),
                  const SizedBox(height: 32),
                  Text(
                    "Let's get your shop started",
                    style: ShopzoTypography.headingLarge(context, isDark: isDark),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Select an option to begin using Shopzo",
                    style: ShopzoTypography.bodyMedium(context, isDark: isDark),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  ShopzoCard(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const CreateShopScreen()),
                      );
                    },
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ShopzoColors.primaryNavy.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            size: 32,
                            color: ShopzoColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create a Shop',
                                style: ShopzoTypography.headingMedium(context, isDark: isDark),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Create and manage your own supermarket',
                                style: ShopzoTypography.bodyMedium(context, isDark: isDark),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 18,
                          color: isDark ? ShopzoColors.darkTextMuted : ShopzoColors.lightTextMuted,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ShopzoCard(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const JoinShopScreen()),
                      );
                    },
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ShopzoColors.secondaryGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.group_add_rounded,
                            size: 32,
                            color: ShopzoColors.secondaryGreen,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Join a Shop',
                                style: ShopzoTypography.headingMedium(context, isDark: isDark),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Join an existing shop using a Shop Code',
                                style: ShopzoTypography.bodyMedium(context, isDark: isDark),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 18,
                          color: isDark ? ShopzoColors.darkTextMuted : ShopzoColors.lightTextMuted,
                        ),
                      ],
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
