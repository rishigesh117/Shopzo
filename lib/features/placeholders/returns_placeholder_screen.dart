import 'package:flutter/material.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_badge.dart';
import '../../core/widgets/shopzo_card.dart';
import '../../core/widgets/shopzo_header.dart';

class ReturnsPlaceholderScreen extends StatelessWidget {
  const ReturnsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mockReturns = [
      _ReturnItem('#RET-104', 'Sunflower Oil 1L', '1 Liter', '₹155', 'Bill #1021', 'Sep 7, 2026', 'Restocked', ShopzoBadgeType.success),
      _ReturnItem('#RET-103', 'Toned Milk 500ml', '1 Packet', '₹29', 'Bill #1018', 'Sep 6, 2026', 'Damaged/Discarded', ShopzoBadgeType.danger),
      _ReturnItem('#RET-102', 'Basmati Rice 5kg', '1 Pack', '₹450', 'Bill #1012', 'Sep 5, 2026', 'Restocked', ShopzoBadgeType.success),
    ];

    return Scaffold(
      body: Column(
        children: [
          ShopzoHeader(
            title: 'Product Returns',
            subtitle: 'Record customer returns, store date/time, and adjust inventory',
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ShopzoColors.secondaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.assignment_return_rounded, size: 18),
              label: const Text('Process Return'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product Return processing will be enabled in Phase 2')),
                );
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ShopzoCard(
                    padding: const EdgeInsets.all(0),
                    child: Column(
                      children: mockReturns.map((r) {
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
                                  color: ShopzoColors.warning.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.assignment_return_rounded, color: ShopzoColors.warning),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${r.returnId} • ${r.product}',
                                      style: ShopzoTypography.headingSmall(context, isDark: isDark).copyWith(fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Qty: ${r.qty} • Original ${r.billNo} • ${r.date}',
                                      style: ShopzoTypography.bodySmall(context, isDark: isDark),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    r.amount,
                                    style: ShopzoTypography.moneyText(context, fontSize: 16, isDark: isDark),
                                  ),
                                  const SizedBox(height: 2),
                                  ShopzoBadge(label: r.status, type: r.badgeType),
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

class _ReturnItem {
  final String returnId;
  final String product;
  final String qty;
  final String amount;
  final String billNo;
  final String date;
  final String status;
  final ShopzoBadgeType badgeType;

  _ReturnItem(this.returnId, this.product, this.qty, this.amount, this.billNo, this.date, this.status, this.badgeType);
}
