import 'package:flutter/material.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_badge.dart';
import '../../core/widgets/shopzo_card.dart';
import '../../core/widgets/shopzo_header.dart';

class PaymentsPlaceholderScreen extends StatelessWidget {
  const PaymentsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mockPayments = [
      _PaymentItem('Arun Kumar', 'Bill #1019', '₹400', 'Sep 7, 2026', '10:42 AM', 'Pending Dues', ShopzoBadgeType.warning),
      _PaymentItem('Rajesh Sharma', 'Bill #1015', '₹850', 'Sep 6, 2026', '04:15 PM', 'Overdue', ShopzoBadgeType.danger),
      _PaymentItem('Meena Reddy', 'Bill #1012', '₹650', 'Sep 5, 2026', '11:20 AM', 'Pending Dues', ShopzoBadgeType.warning),
      _PaymentItem('Suresh Patel', 'Bill #1008', '₹500', 'Sep 4, 2026', '06:30 PM', 'Partial Payment', ShopzoBadgeType.info),
    ];

    return Scaffold(
      body: Column(
        children: [
          ShopzoHeader(
            title: 'Payment & Credit Ledger',
            subtitle: 'Track pending dues, bill numbers, date/time, and collections',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShopzoCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Outstanding Dues',
                              style: ShopzoTypography.bodyMedium(context, isDark: isDark),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹2,400',
                              style: ShopzoTypography.moneyText(context, fontSize: 26, isDark: isDark, color: ShopzoColors.warning),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ShopzoColors.secondaryGreen,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.add_card_rounded, size: 18),
                          label: const Text('Record Payment'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Payment collection will be enabled in Phase 2')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Pending Payment Entries',
                    style: ShopzoTypography.headingMedium(context, isDark: isDark),
                  ),
                  const SizedBox(height: 12),
                  ShopzoCard(
                    padding: const EdgeInsets.all(0),
                    child: Column(
                      children: mockPayments.map((p) {
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
                                radius: 18,
                                backgroundColor: ShopzoColors.warning.withOpacity(0.15),
                                child: Text(
                                  p.customer.substring(0, 1),
                                  style: ShopzoTypography.headingSmall(context, isDark: isDark).copyWith(
                                    color: ShopzoColors.warning,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.customer,
                                      style: ShopzoTypography.headingSmall(context, isDark: isDark).copyWith(fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${p.billNo} • ${p.date} at ${p.time}',
                                      style: ShopzoTypography.bodySmall(context, isDark: isDark),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    p.amount,
                                    style: ShopzoTypography.moneyText(context, fontSize: 16, isDark: isDark, color: ShopzoColors.warning),
                                  ),
                                  const SizedBox(height: 2),
                                  ShopzoBadge(label: p.status, type: p.badgeType),
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

class _PaymentItem {
  final String customer;
  final String billNo;
  final String amount;
  final String date;
  final String time;
  final String status;
  final ShopzoBadgeType badgeType;

  _PaymentItem(this.customer, this.billNo, this.amount, this.date, this.time, this.status, this.badgeType);
}
