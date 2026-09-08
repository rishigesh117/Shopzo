import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/product_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_badge.dart';
import '../../core/widgets/shopzo_button.dart';
import '../../core/widgets/shopzo_card.dart';
import '../../core/widgets/shopzo_header.dart';
import '../../core/widgets/shopzo_text_field.dart';
import 'add_edit_product_screen.dart';
import 'categories_management_dialog.dart';
import 'product_details_screen.dart';
import 'restock_dialog.dart';
import 'stock_adjustment_dialog.dart';

class ProductsScreen extends StatelessWidget {
  final String? initialStockFilter;

  const ProductsScreen({super.key, this.initialStockFilter});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productProvider = Provider.of<ProductProvider>(context);

    if (initialStockFilter != null && productProvider.selectedStockFilter != initialStockFilter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        productProvider.setStockFilter(initialStockFilter!);
      });
    }

    final products = productProvider.products;
    final categories = productProvider.categories;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShopzoHeader(
                title: 'Products & Stock',
                subtitle: 'Offline product catalog and inventory management',
                actions: [
                  ShopzoButton(
                    text: 'Categories',
                    isSecondary: true,
                    icon: Icons.category_rounded,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const CategoriesManagementDialog(),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  ShopzoButton(
                    text: '+ Add Product',
                    icon: Icons.add_rounded,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search & Filter controls
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ShopzoTextField(
                      label: 'Search Products',
                      hint: 'Search products by name, category, or brand...',
                      prefixIcon: Icons.search_rounded,
                      onChanged: (val) => productProvider.setSearchQuery(val),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? ShopzoColors.darkSurfaceSecondary : ShopzoColors.lightSurfaceSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? ShopzoColors.darkBorder : ShopzoColors.lightBorder,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: productProvider.selectedCategoryId,
                          isExpanded: true,
                          dropdownColor: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
                          style: ShopzoTypography.bodyLarge(context, isDark: isDark),
                          items: [
                            const DropdownMenuItem(value: 'all', child: Text('All Categories')),
                            ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                          ],
                          onChanged: (val) {
                            if (val != null) productProvider.setCategoryFilter(val);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stock Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      context,
                      label: 'All Products (${productProvider.totalProductCount})',
                      value: 'all',
                      selectedValue: productProvider.selectedStockFilter,
                      isDark: isDark,
                      onSelect: (v) => productProvider.setStockFilter(v),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      context,
                      label: 'In Stock',
                      value: 'in_stock',
                      selectedValue: productProvider.selectedStockFilter,
                      isDark: isDark,
                      badgeColor: ShopzoColors.secondaryGreen,
                      onSelect: (v) => productProvider.setStockFilter(v),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      context,
                      label: 'Low Stock (${productProvider.lowStockCount})',
                      value: 'low_stock',
                      selectedValue: productProvider.selectedStockFilter,
                      isDark: isDark,
                      badgeColor: ShopzoColors.warning,
                      onSelect: (v) => productProvider.setStockFilter(v),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      context,
                      label: 'Out of Stock (${productProvider.outOfStockCount})',
                      value: 'out_of_stock',
                      selectedValue: productProvider.selectedStockFilter,
                      isDark: isDark,
                      badgeColor: ShopzoColors.danger,
                      onSelect: (v) => productProvider.setStockFilter(v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Product Catalog List
              if (productProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (products.isEmpty)
                ShopzoCard(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: isDark ? ShopzoColors.darkTextMuted : ShopzoColors.lightTextMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: ShopzoTypography.headingMedium(context, isDark: isDark),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Try adjusting your search query or stock filters, or add a new product.',
                          style: ShopzoTypography.bodyMedium(context, isDark: isDark),
                        ),
                      ],
                    ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 720;

                    if (isDesktop) {
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: products.length,
                        itemBuilder: (ctx, i) => _buildProductCard(ctx, products[i], isDark),
                      );
                    } else {
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) => _buildProductCard(ctx, products[i], isDark),
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required String value,
    required String selectedValue,
    required bool isDark,
    Color? badgeColor,
    required Function(String) onSelect,
  }) {
    final isSelected = selectedValue == value;

    return InkWell(
      onTap: () => onSelect(value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? ShopzoColors.primaryNavy
              : (isDark ? ShopzoColors.darkSurfaceSecondary : ShopzoColors.lightSurfaceSecondary),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? ShopzoColors.primaryNavy
                : (isDark ? ShopzoColors.darkBorder : ShopzoColors.lightBorder),
          ),
        ),
        child: Row(
          children: [
            if (badgeColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: ShopzoTypography.bodyMedium(context, isDark: isDark).copyWith(
                color: isSelected ? Colors.white : (isDark ? ShopzoColors.darkTextPrimary : ShopzoColors.lightTextPrimary),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product, bool isDark) {
    return ShopzoCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailsScreen(productId: product.id)),
        );
      },
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: ShopzoTypography.headingMedium(context, isDark: isDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${product.categoryName}${product.brand != null && product.brand!.isNotEmpty ? " • ${product.brand}" : ""}',
                      style: ShopzoTypography.bodySmall(context, isDark: isDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ShopzoBadge(
                text: product.stockStatusText,
                type: product.stockStatusBadgeType,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onSelected: (val) {
                  if (val == 'details') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProductDetailsScreen(productId: product.id)),
                    );
                  } else if (val == 'restock') {
                    showDialog(
                      context: context,
                      builder: (_) => RestockDialog(product: product),
                    );
                  } else if (val == 'adjust') {
                    showDialog(
                      context: context,
                      builder: (_) => StockAdjustmentDialog(product: product),
                    );
                  } else if (val == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddEditProductScreen(product: product)),
                    );
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'details', child: Text('View Details')),
                  const PopupMenuItem(value: 'restock', child: Text('Restock')),
                  const PopupMenuItem(value: 'adjust', child: Text('Adjust Stock')),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${product.sellingPrice.toStringAsFixed(2)} / ${product.unit}',
                    style: ShopzoTypography.moneyText(
                      context,
                      fontSize: 18,
                      isDark: isDark,
                      color: ShopzoColors.secondaryGreen,
                    ),
                  ),
                  Text(
                    'Cost: ₹${product.buyingPrice.toStringAsFixed(2)}',
                    style: ShopzoTypography.bodySmall(context, isDark: isDark).copyWith(fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? ShopzoColors.darkSurfaceSecondary : ShopzoColors.lightSurfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Stock: ${product.quantity} ${product.unit}',
                  style: ShopzoTypography.bodyMedium(context, isDark: isDark).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
