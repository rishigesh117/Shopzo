import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/billing_provider.dart';
import '../../core/providers/customer_provider.dart';
import '../../core/providers/product_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_badge.dart';
import '../../core/widgets/shopzo_button.dart';
import '../../core/widgets/shopzo_card.dart';
import '../../core/widgets/shopzo_header.dart';
import '../../core/widgets/shopzo_text_field.dart';
import '../customers/add_edit_customer_dialog.dart';

import '../bills/bill_details_screen.dart';
import 'quantity_edit_dialog.dart';

class NewBillScreen extends StatefulWidget {
  const NewBillScreen({super.key});

  @override
  State<NewBillScreen> createState() => _NewBillScreenState();
}

class _NewBillScreenState extends State<NewBillScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _receivedController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _receivedController.dispose();
    super.dispose();
  }

  void _onCheckout() async {
    final billingProvider = Provider.of<BillingProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    final bill = await billingProvider.checkout(productProvider);

    if (bill != null && mounted) {
      _receivedController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bill ${bill.billNumber} created successfully!'),
          backgroundColor: ShopzoColors.secondaryGreen,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BillDetailsScreen(billId: bill.id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productProvider = Provider.of<ProductProvider>(context);
    final customerProvider = Provider.of<CustomerProvider>(context);
    final billingProvider = Provider.of<BillingProvider>(context);

    final query = billingProvider.productSearchQuery.toLowerCase().trim();
    final filteredProducts = productProvider.products.where((p) {
      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) ||
          p.categoryName.toLowerCase().contains(query) ||
          (p.brand != null && p.brand!.toLowerCase().contains(query));
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ShopzoHeader(
              title: 'New Bill / POS',
              subtitle: 'Create offline supermarket sale and print receipt',
              trailing: billingProvider.cart.isNotEmpty
                  ? TextButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 18, color: ShopzoColors.danger),
                      label: const Text('Clear Cart', style: TextStyle(color: ShopzoColors.danger)),
                      onPressed: () => billingProvider.clearCart(),
                    )
                  : null,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 900;

                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Product Catalog & Search
                        Expanded(
                          flex: 3,
                          child: _buildProductSection(context, filteredProducts, isDark, billingProvider),
                        ),
                        const VerticalDivider(width: 1, thickness: 1),
                        // Right: Billing Cart & Checkout
                        Expanded(
                          flex: 2,
                          child: _buildCartAndCheckoutSection(context, isDark, billingProvider, customerProvider),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildProductSection(context, filteredProducts, isDark, billingProvider, isMobile: true),
                                const Divider(height: 1),
                                _buildCartAndCheckoutSection(context, isDark, billingProvider, customerProvider),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSection(
    BuildContext context,
    List<Product> products,
    bool isDark,
    BillingProvider billingProvider, {
    bool isMobile = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShopzoTextField(
            label: 'Search Catalog',
            hint: 'Search products by name, category, or brand...',
            prefixIcon: Icons.search_rounded,
            controller: _searchController,
            onChanged: (val) => billingProvider.setProductSearchQuery(val),
          ),
          const SizedBox(height: 12),
          Text(
            'Select Products (${products.length})',
            style: ShopzoTypography.bodyMedium(context, isDark: isDark).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (products.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No products found matching "${billingProvider.productSearchQuery}"',
                  style: ShopzoTypography.bodyMedium(context, isDark: isDark),
                ),
              ),
            )
          else if (isMobile)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _buildProductSelectCard(ctx, products[i], isDark, billingProvider),
            )
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (ctx, i) => _buildProductSelectCard(ctx, products[i], isDark, billingProvider),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductSelectCard(BuildContext context, Product product, bool isDark, BillingProvider billingProvider) {
    final isOut = product.isOutOfStock;

    return ShopzoCard(
      onTap: isOut ? null : () => billingProvider.addToCart(product),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isOut ? ShopzoColors.danger.withOpacity(0.1) : ShopzoColors.secondaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isOut ? Icons.block_rounded : Icons.add_shopping_cart_rounded,
              color: isOut ? ShopzoColors.danger : ShopzoColors.secondaryGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  product.name,
                  style: ShopzoTypography.headingMedium(context, isDark: isDark).copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${product.categoryName} • ₹${product.sellingPrice.toStringAsFixed(2)} / ${product.unit}',
                  style: ShopzoTypography.bodySmall(context, isDark: isDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShopzoBadge(
                text: product.stockStatusText,
                type: product.stockStatusBadgeType,
              ),
              const SizedBox(height: 2),
              Text(
                '${product.quantity} ${product.unit}',
                style: ShopzoTypography.bodySmall(context, isDark: isDark).copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartAndCheckoutSection(
    BuildContext context,
    bool isDark,
    BillingProvider billingProvider,
    CustomerProvider customerProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? ShopzoColors.darkSurfaceSecondary : ShopzoColors.lightSurfaceSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Bill Cart',
                style: ShopzoTypography.headingMedium(context, isDark: isDark),
              ),
              ShopzoBadge(
                text: '${billingProvider.cart.length} Items',
                type: BadgeType.navy,
              ),
            ],
          ),
          if (billingProvider.errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ShopzoColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 18, color: ShopzoColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      billingProvider.errorMessage!,
                      style: const TextStyle(color: ShopzoColors.danger, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Cart List
          if (billingProvider.cart.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? ShopzoColors.darkBorder : ShopzoColors.lightBorder),
              ),
              child: Column(
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 48, color: isDark ? ShopzoColors.darkTextMuted : ShopzoColors.lightTextMuted),
                  const SizedBox(height: 12),
                  Text('Your bill cart is empty', style: ShopzoTypography.headingMedium(context, isDark: isDark).copyWith(fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('Tap products on the left to add items.', style: ShopzoTypography.bodySmall(context, isDark: isDark)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: billingProvider.cart.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final item = billingProvider.cart[i];
                final qtyStr = item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString();

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? ShopzoColors.darkBorder : ShopzoColors.lightBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.product.name,
                              style: ShopzoTypography.bodyLarge(context, isDark: isDark).copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '₹${item.lineTotal.toStringAsFixed(2)}',
                            style: ShopzoTypography.moneyText(context, fontSize: 16, isDark: isDark, color: ShopzoColors.secondaryGreen),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: ShopzoColors.danger),
                            onPressed: () => billingProvider.removeFromCart(i),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${item.sellingPrice.toStringAsFixed(2)} / ${item.product.unit}',
                            style: ShopzoTypography.bodySmall(context, isDark: isDark),
                          ),
                          // Quantity Controls: [-] [Qty (Tappable for Direct Typing)] [+]
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                                onPressed: () => billingProvider.decrementQuantity(i),
                              ),
                              InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => QuantityEditDialog(
                                      productName: item.product.name,
                                      currentQuantity: item.quantity,
                                      unit: item.product.unit,
                                      availableStock: item.product.quantity,
                                      onSave: (newQty) => billingProvider.setQuantity(i, newQty),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: ShopzoColors.primaryNavy.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$qtyStr ${item.product.unit}',
                                    style: ShopzoTypography.bodyMedium(context, isDark: isDark).copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: ShopzoColors.primaryNavy,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                                onPressed: () => billingProvider.incrementQuantity(i),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 16),

          // Customer Selector
          Text('Customer', style: ShopzoTypography.bodyMedium(context, isDark: isDark).copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? ShopzoColors.darkBorder : ShopzoColors.lightBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: billingProvider.selectedCustomer?.id ?? 'walkin',
                      isExpanded: true,
                      dropdownColor: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
                      style: ShopzoTypography.bodyMedium(context, isDark: isDark),
                      items: [
                        const DropdownMenuItem(value: 'walkin', child: Text('Walk-in Customer')),
                        ...customerProvider.customers.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} (${c.phone})'))),
                      ],
                      onChanged: (val) {
                        if (val == 'walkin' || val == null) {
                          billingProvider.setSelectedCustomer(null);
                        } else {
                          final cust = customerProvider.customers.firstWhere((c) => c.id == val);
                          billingProvider.setSelectedCustomer(cust);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Add New Customer',
                icon: const Icon(Icons.person_add_rounded, color: ShopzoColors.accentBlue),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AddEditCustomerDialog(
                      onCustomerCreated: (newCust) => billingProvider.setSelectedCustomer(newCust),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Payment Details
          Row(
            children: [
              Expanded(
                child: ShopzoTextField(
                  label: 'Amount Received (₹)',
                  hint: '0.00',
                  controller: _receivedController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (val) {
                    final d = double.tryParse(val) ?? 0.0;
                    billingProvider.setAmountReceived(d);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Method', style: ShopzoTypography.bodySmall(context, isDark: isDark).copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? ShopzoColors.darkBorder : ShopzoColors.lightBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: billingProvider.paymentMethod,
                          isExpanded: true,
                          dropdownColor: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
                          style: ShopzoTypography.bodyMedium(context, isDark: isDark),
                          items: const [
                            DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                            DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                            DropdownMenuItem(value: 'Card', child: Text('Card')),
                            DropdownMenuItem(value: 'Other', child: Text('Other')),
                          ],
                          onChanged: (val) {
                            if (val != null) billingProvider.setPaymentMethod(val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Quick Tender Buttons
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickTenderChip('Exact', billingProvider.totalAmount, billingProvider),
                const SizedBox(width: 6),
                _buildQuickTenderChip('₹100', 100, billingProvider),
                const SizedBox(width: 6),
                _buildQuickTenderChip('₹200', 200, billingProvider),
                const SizedBox(width: 6),
                _buildQuickTenderChip('₹500', 500, billingProvider),
                const SizedBox(width: 6),
                _buildQuickTenderChip('₹1000', 1000, billingProvider),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Summary Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? ShopzoColors.darkBorder : ShopzoColors.lightBorder),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Bill Total:', style: ShopzoTypography.headingMedium(context, isDark: isDark).copyWith(fontSize: 16)),
                    Text(
                      '₹${billingProvider.totalAmount.toStringAsFixed(2)}',
                      style: ShopzoTypography.moneyText(context, fontSize: 20, isDark: isDark, color: ShopzoColors.secondaryGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (billingProvider.changeAmount > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Change Return:', style: ShopzoTypography.bodyMedium(context, isDark: isDark)),
                      Text('₹${billingProvider.changeAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: ShopzoColors.accentBlue)),
                    ],
                  ),
                if (billingProvider.pendingAmount > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pending Due:', style: ShopzoTypography.bodyMedium(context, isDark: isDark).copyWith(color: ShopzoColors.danger, fontWeight: FontWeight.bold)),
                      Text('₹${billingProvider.pendingAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: ShopzoColors.danger)),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Complete Bill Button
          ShopzoButton(
            text: 'Complete Bill (${billingProvider.paymentStatus})',
            icon: Icons.check_circle_outline_rounded,
            isLoading: billingProvider.isProcessing,
            isDisabled: billingProvider.cart.isEmpty,
            onPressed: _onCheckout,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTenderChip(String label, double amount, BillingProvider billingProvider) {
    return InkWell(
      onTap: () {
        _receivedController.text = amount.toStringAsFixed(2);
        billingProvider.setAmountReceived(amount);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: ShopzoColors.accentBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ShopzoColors.accentBlue.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ShopzoColors.accentBlue),
        ),
      ),
    );
  }
}
