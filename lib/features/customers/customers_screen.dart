import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/customer_model.dart';
import '../../core/providers/customer_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_badge.dart';
import '../../core/widgets/shopzo_button.dart';
import '../../core/widgets/shopzo_card.dart';
import '../../core/widgets/shopzo_header.dart';
import '../../core/widgets/shopzo_text_field.dart';
import '../payments/record_payment_dialog.dart';
import 'add_edit_customer_dialog.dart';
import 'customer_details_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customerProvider = Provider.of<CustomerProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShopzoHeader(
                title: 'Customer Directory & Dues',
                subtitle: 'Manage customer accounts, track balances & record payments',
                actions: [
                  ShopzoButton(
                    text: '+ Add Customer',
                    icon: Icons.person_add_rounded,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AddEditCustomerDialog(),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search Bar
              ShopzoTextField(
                label: 'Search Customers',
                hint: 'Search by customer name or phone number...',
                prefixIcon: Icons.search_rounded,
                controller: _searchController,
                onChanged: (val) => customerProvider.setSearchQuery(val),
              ),
              const SizedBox(height: 20),

              // Customers List
              if (customerProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (customerProvider.customers.isEmpty)
                ShopzoCard(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 48,
                          color: isDark ? ShopzoColors.darkTextMuted : ShopzoColors.lightTextMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No customers found',
                          style: ShopzoTypography.headingMedium(context, isDark: isDark),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap "+ Add Customer" to create your first customer account.',
                          style: ShopzoTypography.bodyMedium(context, isDark: isDark),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: customerProvider.customers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final customer = customerProvider.customers[i];
                    final duePaise = customerProvider.getCustomerDuePaise(customer.id);
                    final dueDouble = duePaise / 100.0;
                    final totalPurchases = customerProvider.getCustomerTotalPurchases(customer.id);

                    return ShopzoCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CustomerDetailsScreen(customerId: customer.id)),
                        );
                      },
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: ShopzoColors.primaryNavy.withOpacity(0.1),
                            child: Text(
                              customer.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: ShopzoColors.primaryNavy,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer.name,
                                  style: ShopzoTypography.headingMedium(context, isDark: isDark).copyWith(fontSize: 16),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Phone: ${customer.phone} ${customer.address != null ? "• ${customer.address}" : ""}',
                                  style: ShopzoTypography.bodySmall(context, isDark: isDark),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Total: ₹${totalPurchases.toStringAsFixed(2)}',
                                style: ShopzoTypography.bodySmall(context, isDark: isDark),
                              ),
                              const SizedBox(height: 4),
                              if (duePaise > 0) ...[
                                Row(
                                  children: [
                                    Text(
                                      'Due: ₹${dueDouble.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: ShopzoColors.danger, fontSize: 14),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      tooltip: 'Record Payment',
                                      icon: const Icon(Icons.payment_rounded, color: ShopzoColors.accentBlue, size: 20),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => RecordPaymentDialog(
                                            customerId: customer.id,
                                            pendingAmountPaise: duePaise,
                                            onPaymentRecorded: () => customerProvider.loadCustomers(),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ] else ...[
                                const ShopzoBadge(
                                  text: 'No Dues',
                                  type: BadgeType.success,
                                ),
                              ],
                            ],
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
}
