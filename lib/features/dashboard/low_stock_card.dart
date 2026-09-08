import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/navigation_provider.dart';
import '../../core/providers/product_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_badge.dart';
import '../../core/widgets/shopzo_card.dart';

class LowStockCard extends StatelessWidget {
  const LowStockCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productProvider = Provider.of<ProductProvider>(context);
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);

    // Get low stock and out of stock items
    final lowStockItems = productProvider.products
        .where((p) => p.isLowStock || p.isOutOfStock)
        .toList();

    return ShopzoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              productProvider.setStockFilter('low_stock');
              navProvider.setIndex(2); // Navigate to Products tab
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: ShopzoColors.warning, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Low Stock Alerts',
                      style: ShopzoTypography.headingMedium(context, isDark: isDark),
                    ),
                  ],
                ),
                ShopzoBadge(
                  text: '${lowStockItems.length} Items Low',
                  type: lowStockItems.isEmpty ? 'success' : 'warning',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (lowStockItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: ShopzoColors.secondaryGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'All products have sufficient stock!',
                      style: ShopzoTypography.bodyMedium(context, isDark: isDark).copyWith(
                        color: ShopzoColors.secondaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lowStockItems.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = lowStockItems[index];
                final isOut = item.isOutOfStock;

                return InkWell(
                  onTap: () {
                    productProvider.setStockFilter(isOut ? 'out_of_stock' : 'low_stock');
                    navProvider.setIndex(2);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isOut ? ShopzoColors.danger : ShopzoColors.warning).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.inventory_2_rounded,
                            size: 18,
                            color: isOut ? ShopzoColors.danger : ShopzoColors.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: ShopzoTypography.headingMedium(context, isDark: isDark).copyWith(fontSize: 14),
                              ),
                              Text(
                                '${item.categoryName}${item.brand != null && item.brand!.isNotEmpty ? " • ${item.brand}" : ""}',
                                style: ShopzoTypography.bodySmall(context, isDark: isDark),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isOut ? ShopzoColors.danger : ShopzoColors.warning).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item.quantity} ${item.unit}',
                            style: ShopzoTypography.bodySmall(context, isDark: isDark).copyWith(
                              color: isOut ? ShopzoColors.danger : ShopzoColors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
