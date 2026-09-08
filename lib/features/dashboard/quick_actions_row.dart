import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/navigation_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_card.dart';

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);

    final actions = [
      _QuickActionData(
        title: '+ New Bill',
        subtitle: 'Start billing customer',
        icon: Icons.add_shopping_cart_rounded,
        color: ShopzoColors.secondaryGreen,
        isPrimary: true,
        tabIndex: 1, // New Bill / Bills
      ),
      _QuickActionData(
        title: 'Add Product',
        subtitle: 'Update stock catalog',
        icon: Icons.add_box_rounded,
        color: ShopzoColors.primaryNavy,
        isPrimary: false,
        tabIndex: 2, // Products
      ),
      _QuickActionData(
        title: 'Customers',
        subtitle: 'View customer directory',
        icon: Icons.people_alt_rounded,
        color: ShopzoColors.accentBlue,
        isPrimary: false,
        tabIndex: 3, // Customers
      ),
      _QuickActionData(
        title: 'Stock',
        subtitle: 'Inventory alerts',
        icon: Icons.inventory_rounded,
        color: ShopzoColors.warning,
        isPrimary: false,
        tabIndex: 2, // Products / Stock
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: ShopzoTypography.headingMedium(context, isDark: isDark),
        ),
        const SizedBox(height: 12),
        Row(
          children: actions.map((act) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: ShopzoCard(
                  onTap: () => navProvider.navigateToTab(act.tabIndex),
                  backgroundColor: act.isPrimary
                      ? ShopzoColors.secondaryGreen
                      : (isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface),
                  borderColor: act.isPrimary ? ShopzoColors.secondaryGreen : null,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: act.isPrimary
                              ? Colors.white.withOpacity(0.2)
                              : act.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          act.icon,
                          size: 24,
                          color: act.isPrimary ? Colors.white : act.color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              act.title,
                              style: ShopzoTypography.headingSmall(context, isDark: isDark).copyWith(
                                color: act.isPrimary ? Colors.white : null,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              act.subtitle,
                              style: ShopzoTypography.bodySmall(context, isDark: isDark).copyWith(
                                color: act.isPrimary ? Colors.white.withOpacity(0.85) : null,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _QuickActionData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isPrimary;
  final int tabIndex;

  _QuickActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isPrimary,
    required this.tabIndex,
  });
}
