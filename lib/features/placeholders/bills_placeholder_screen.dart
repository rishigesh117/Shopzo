import 'package:flutter/material.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_badge.dart';
import '../../core/widgets/shopzo_card.dart';
import '../../core/widgets/shopzo_header.dart';

class BillsPlaceholderScreen extends StatelessWidget {
  const BillsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mockBills = [
      _BillItem('#1025', 'Walk-in Customer', '₹450', '5:32 PM', 'Paid', ShopzoBadgeType.success, '3 Items'),
      _BillItem('#1024', 'Arun Kumar', '₹820', '4:18 PM', 'Paid', ShopzoBadgeType.success, '6 Items'),
      _BillItem('#1023', 'Priya S', '₹310', '3:45 PM', 'Paid', ShopzoBadgeType.success, '2 Items'),
      _BillItem('#1022', 'Rajesh Sharma', '₹1,250', '2:15 PM', 'Partial', ShopzoBadgeType.warning, '12 Items'),
      _BillItem('#1021', 'Walk-in Customer', '₹180', '1:05 PM', 'Paid', ShopzoBadgeType.success, '1 Item'),
    ];

    return Scaffold(
      body: Column(
        children: [
          ShopzoHeader(
            title: 'Billing & History',
            subtitle: 'Supermarket checkout and receipt management',
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ShopzoColors.secondaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
              label: const Text('+ New Bill'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New Billing engine will be enabled in Phase 2')),
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
                            hintText: 'Search bill number or customer...',
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
                        child: const Icon(Icons.filter_list_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ShopzoCard(
                    padding: const EdgeInsets.all(0),
                    child: Column(
                      children: mockBills.map((bill) {
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
                                  color: ShopzoColors.primaryNavy.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.receipt_long_rounded, color: ShopzoColors.primaryNavy),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bill ${bill.id} • ${bill.customer}',
                                      style: ShopzoTypography.headingSmall(context, isDark: isDark).copyWith(fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${bill.items} • ${bill.time}',
                                      style: ShopzoTypography.bodySmall(context, isDark: isDark),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                bill.total,
                                style: ShopzoTypography.moneyText(context, fontSize: 16, isDark: isDark),
                              ),
                              const SizedBox(width: 12),
                              ShopzoBadge(label: bill.status, type: bill.badgeType),
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

class _BillItem {
  final String id;
  final String customer;
  final String total;
  final String time;
  final String status;
  final ShopzoBadgeType badgeType;
  final String items;

  _BillItem(this.id, this.customer, this.total, this.time, this.status, this.badgeType, this.items);
}
