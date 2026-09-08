import 'package:flutter/material.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_badge.dart';
import '../../core/widgets/shopzo_card.dart';
import '../../core/widgets/shopzo_header.dart';

class CustomersPlaceholderScreen extends StatelessWidget {
  const CustomersPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mockCustomers = [
      _CustomerItem('Arun Kumar', '+91 98765 12345', '₹400 Due', '14 Orders', ShopzoBadgeType.warning),
      _CustomerItem('Priya Sundaram', '+91 98765 67890', 'No Dues', '8 Orders', ShopzoBadgeType.success),
      _CustomerItem('Rahul Verma', '+91 98765 99999', 'No Dues', '22 Orders', ShopzoBadgeType.success),
      _CustomerItem('Rajesh Sharma', '+91 98123 45678', '₹850 Overdue', '5 Orders', ShopzoBadgeType.danger),
      _CustomerItem('Meena Reddy', '+91 97654 32109', '₹650 Due', '11 Orders', ShopzoBadgeType.warning),
    ];

    return Scaffold(
      body: Column(
        children: [
          ShopzoHeader(
            title: 'Customer Directory',
            subtitle: 'Customer profiles, transaction history, and credit ledger',
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ShopzoColors.secondaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Add Customer'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Customer ledger will be enabled in Phase 2')),
                );
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search customer by name or phone...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      fillColor: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ShopzoCard(
                    padding: const EdgeInsets.all(0),
                    child: Column(
                      children: mockCustomers.map((c) {
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
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: ShopzoColors.primaryNavy.withOpacity(0.12),
                                child: Text(
                                  c.name.substring(0, 1),
                                  style: ShopzoTypography.headingSmall(context, isDark: isDark).copyWith(
                                    color: ShopzoColors.primaryNavy,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: ShopzoTypography.headingSmall(context, isDark: isDark).copyWith(fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${c.phone} • ${c.orders}',
                                      style: ShopzoTypography.bodySmall(context, isDark: isDark),
                                    ),
                                  ],
                                ),
                              ),
                              ShopzoBadge(label: c.dueStatus, type: c.badgeType),
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

class _CustomerItem {
  final String name;
  final String phone;
  final String dueStatus;
  final String orders;
  final ShopzoBadgeType badgeType;

  _CustomerItem(this.name, this.phone, this.dueStatus, this.orders, this.badgeType);
}
