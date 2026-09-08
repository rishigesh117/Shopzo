import 'package:flutter/material.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_badge.dart';
import '../../core/widgets/shopzo_card.dart';
import '../../core/widgets/shopzo_header.dart';

class ProductsPlaceholderScreen extends StatelessWidget {
  const ProductsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mockProducts = [
      _ProductItem('Basmati Rice 5kg', 'Grains', 'Fortune', '₹380', '₹450', '4 Kg', ShopzoBadgeType.danger),
      _ProductItem('Refined Sugar 1kg', 'Groceries', 'Madhur', '₹42', '₹48', '2 Kg', ShopzoBadgeType.danger),
      _ProductItem('Toned Milk 500ml', 'Dairy', 'Amul', '₹26', '₹29', '3 Packets', ShopzoBadgeType.warning),
      _ProductItem('Sunflower Oil 1L', 'Oils', 'Sunrich', '₹135', '₹155', '12 Liters', ShopzoBadgeType.success),
      _ProductItem('Wheat Flour (Atta) 10kg', 'Staples', 'Aashirvaad', '₹340', '₹390', '18 Packets', ShopzoBadgeType.success),
    ];

    return Scaffold(
      body: Column(
        children: [
          ShopzoHeader(
            title: 'Inventory & Products',
            subtitle: 'Stock management, buying/selling prices, and restocking',
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ShopzoColors.secondaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Product'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product Management will be enabled in Phase 2')),
                );
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search by product name, category, or brand...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            fillColor: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? ShopzoColors.darkBorder : ShopzoColors.lightBorder),
                        ),
                        child: const Icon(Icons.tune_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ShopzoCard(
                    padding: const EdgeInsets.all(0),
                    child: Column(
                      children: mockProducts.map((p) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isDark ? ShopzoColors.darkBorder : ShopzoColors.lightBorder,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: ShopzoColors.secondaryGreen.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.inventory_2_rounded, color: ShopzoColors.secondaryGreen),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: ShopzoTypography.headingSmall(context, isDark: isDark).copyWith(fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${p.category} • Brand: ${p.brand} • Buy: ${p.buyingPrice}',
                                      style: ShopzoTypography.bodySmall(context, isDark: isDark),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    p.sellingPrice,
                                    style: ShopzoTypography.moneyText(context, fontSize: 16, isDark: isDark),
                                  ),
                                  const SizedBox(height: 2),
                                  ShopzoBadge(label: 'Stock: ${p.quantity}', type: p.stockBadge),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductItem {
  final String name;
  final String category;
  final String brand;
  final String buyingPrice;
  final String sellingPrice;
  final String quantity;
  final ShopzoBadgeType stockBadge;

  _ProductItem(this.name, this.category, this.brand, this.buyingPrice, this.sellingPrice, this.quantity, this.stockBadge);
}
