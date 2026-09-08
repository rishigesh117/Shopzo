import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/product_model.dart';
import '../../core/models/stock_movement_model.dart';
import '../../core/providers/product_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_badge.dart';
import '../../core/widgets/shopzo_button.dart';
import '../../core/widgets/shopzo_card.dart';
import 'add_edit_product_screen.dart';
import 'restock_dialog.dart';
import 'stock_adjustment_dialog.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  List<StockMovement> _movements = [];
  bool _isLoadingMovements = true;

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  Future<void> _loadMovements() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final movements = await productProvider.getStockMovements(widget.productId);
    if (mounted) {
      setState(() {
        _movements = movements;
        _isLoadingMovements = false;
      });
    }
  }

  void _confirmDelete(Product product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
        title: Text('Delete Product?', style: ShopzoTypography.headingMedium(ctx, isDark: isDark)),
        content: Text(
          '${product.name} will be removed from the active product catalog. Historical data will be preserved.',
          style: ShopzoTypography.bodyMedium(ctx, isDark: isDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ShopzoButton(
            text: 'Delete',
            isSecondary: true,
            onPressed: () async {
              final productProvider = Provider.of<ProductProvider>(context, listen: false);
              await productProvider.deleteProduct(product.id);
              if (mounted) {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Exit details screen
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productProvider = Provider.of<ProductProvider>(context);

    final productList = productProvider.products.where((p) => p.id == widget.productId).toList();
    if (productList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(child: Text('Product not found or has been deleted.')),
      );
    }

    final product = productList.first;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddEditProductScreen(product: product)),
              ).then((_) => _loadMovements());
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: ShopzoColors.danger),
            onPressed: () => _confirmDelete(product),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Primary Info Card
              ShopzoCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                style: ShopzoTypography.headingLarge(context, isDark: isDark),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${product.categoryName}${product.brand != null && product.brand!.isNotEmpty ? " • ${product.brand}" : ""}',
                                style: ShopzoTypography.bodyMedium(context, isDark: isDark),
                              ),
                            ],
                          ),
                        ),
                        ShopzoBadge(
                          text: product.stockStatusText,
                          type: product.stockStatusBadgeType,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    // Price & Stock Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            context,
                            label: 'Selling Price',
                            value: '₹${product.sellingPrice.toStringAsFixed(2)} / ${product.unit}',
                            isDark: isDark,
                            color: ShopzoColors.secondaryGreen,
                          ),
                        ),
                        Expanded(
                          child: _buildMetricTile(
                            context,
                            label: 'Buying Price',
                            value: '₹${product.buyingPrice.toStringAsFixed(2)} / ${product.unit}',
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            context,
                            label: 'Current Quantity',
                            value: '${product.quantity} ${product.unit}',
                            isDark: isDark,
                          ),
                        ),
                        Expanded(
                          child: _buildMetricTile(
                            context,
                            label: 'Min Stock Warning Level',
                            value: '${product.minStockLevel} ${product.unit}',
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ShopzoButton(
                            text: 'Restock Product',
                            icon: Icons.add_circle_outline_rounded,
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => RestockDialog(product: product),
                              ).then((_) => _loadMovements());
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ShopzoButton(
                            text: 'Adjust Stock',
                            isSecondary: true,
                            icon: Icons.tune_rounded,
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => StockAdjustmentDialog(product: product),
                              ).then((_) => _loadMovements());
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Stock Movement Audit History',
                style: ShopzoTypography.headingMedium(context, isDark: isDark),
              ),
              const SizedBox(height: 12),
              if (_isLoadingMovements)
                const Center(child: CircularProgressIndicator())
              else if (_movements.isEmpty)
                ShopzoCard(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No stock movement history recorded yet.',
                      style: ShopzoTypography.bodyMedium(context, isDark: isDark),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _movements.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final m = _movements[i];
                    final isRestock = m.movementType == StockMovementType.restock;
                    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(m.createdAt);

                    return ShopzoCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (isRestock ? ShopzoColors.secondaryGreen : ShopzoColors.warning).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isRestock ? Icons.add_rounded : Icons.tune_rounded,
                              color: isRestock ? ShopzoColors.secondaryGreen : ShopzoColors.warning,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      isRestock ? 'RESTOCK' : 'STOCK ADJUSTMENT',
                                      style: ShopzoTypography.bodyMedium(context, isDark: isDark).copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isRestock ? ShopzoColors.secondaryGreen : ShopzoColors.warning,
                                      ),
                                    ),
                                    Text(
                                      '${m.quantityChange >= 0 ? "+" : ""}${m.quantityChange} ${product.unit}',
                                      style: ShopzoTypography.headingMedium(context, isDark: isDark).copyWith(
                                        color: m.quantityChange >= 0 ? ShopzoColors.secondaryGreen : ShopzoColors.danger,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Prev: ${m.previousQuantity} ${product.unit} ➔ New: ${m.newQuantity} ${product.unit}',
                                  style: ShopzoTypography.bodySmall(context, isDark: isDark),
                                ),
                                if (m.supplier != null && m.supplier!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Supplier: ${m.supplier}',
                                    style: ShopzoTypography.bodySmall(context, isDark: isDark),
                                  ),
                                ],
                                if (m.reason != null && m.reason!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Reason: ${m.reason}',
                                    style: ShopzoTypography.bodySmall(context, isDark: isDark).copyWith(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  dateStr,
                                  style: ShopzoTypography.bodySmall(context, isDark: isDark).copyWith(
                                    fontSize: 11,
                                    color: isDark ? ShopzoColors.darkTextMuted : ShopzoColors.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
    required bool isDark,
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ShopzoTypography.bodySmall(context, isDark: isDark),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: ShopzoTypography.headingMedium(context, isDark: isDark).copyWith(
            color: color,
          ),
        ),
      ],
    );
  }
}
