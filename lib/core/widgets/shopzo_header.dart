import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/members/screens/member_management_screen.dart';
import '../../features/shop/screens/shop_selection_screen.dart';
import '../providers/shop_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/shopzo_colors.dart';
import '../theme/shopzo_typography.dart';
import 'sync_status_badge.dart';

class ShopzoHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget>? actions;

  const ShopzoHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shopProvider = Provider.of<ShopProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final shopName = shopProvider.currentShop?.name ?? 'SuperMart Supermarket';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? ShopzoColors.darkBorder : ShopzoColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: ShopzoTypography.headingMedium(context, isDark: isDark),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ShopzoColors.secondaryGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          shopName,
                          style: ShopzoTypography.bodySmall(context, isDark: isDark).copyWith(
                            color: ShopzoColors.secondaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: ShopzoTypography.bodyMedium(context, isDark: isDark),
                    ),
                  ],
                ],
              ),
            ),
            const SyncStatusBadge(compact: true),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Shop Switcher / Join Shop',
              icon: Icon(
                Icons.store_rounded,
                color: isDark ? ShopzoColors.darkTextPrimary : ShopzoColors.lightTextPrimary,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ShopSelectionScreen()),
                );
              },
            ),
            IconButton(
              tooltip: 'Shop Members & Permissions',
              icon: Icon(
                Icons.people_alt_rounded,
                color: isDark ? ShopzoColors.darkTextPrimary : ShopzoColors.lightTextPrimary,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MemberManagementScreen()),
                );
              },
            ),
            if (actions != null) ...actions!,
            const SizedBox(width: 8),
            IconButton(
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: isDark ? ShopzoColors.darkTextPrimary : ShopzoColors.lightTextPrimary,
              ),
              onPressed: () => themeProvider.toggleTheme(),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
