import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/database/bill_repository.dart';
import '../../core/models/bill_model.dart';
import '../../core/providers/navigation_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_badge.dart';
import '../../core/widgets/shopzo_card.dart';
import '../bills/bill_details_screen.dart';

class RecentBillsCard extends StatefulWidget {
  const RecentBillsCard({super.key});

  @override
  State<RecentBillsCard> createState() => _RecentBillsCardState();
}

class _RecentBillsCardState extends State<RecentBillsCard> {
  final BillRepository _repository = BillRepository();
  List<Bill> _bills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentBills();
  }

  Future<void> _loadRecentBills() async {
    try {
      final list = await _repository.getBills();
      if (mounted) {
        setState(() {
          _bills = list.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading recent bills: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final dateFormat = DateFormat('hh:mm a');

    return ShopzoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Bills',
                style: ShopzoTypography.headingMedium(context, isDark: isDark),
              ),
              TextButton(
                onPressed: () => navProvider.navigateToTab(1), // Nav to Bills screen
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_bills.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No recent bills created yet.',
                  style: ShopzoTypography.bodyMedium(context, isDark: isDark),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _bills.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final bill = _bills[index];
                final timeStr = dateFormat.format(bill.createdAt);

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => BillDetailsScreen(billId: bill.id)),
                    ).then((_) => _loadRecentBills());
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? ShopzoColors.darkSurfaceSecondary : ShopzoColors.lightSurfaceSecondary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.receipt_rounded, size: 20, color: ShopzoColors.primaryNavy),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bill ${bill.billNumber}',
                                style: ShopzoTypography.headingMedium(context, isDark: isDark).copyWith(fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${bill.customerNameSnapshot ?? "Walk-in"} • $timeStr',
                                style: ShopzoTypography.bodySmall(context, isDark: isDark),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${bill.totalAmount.toStringAsFixed(2)}',
                          style: ShopzoTypography.moneyText(context, fontSize: 16, isDark: isDark),
                        ),
                        const SizedBox(width: 12),
                        ShopzoBadge(
                          text: bill.paymentStatus,
                          type: bill.paymentStatus == 'Paid'
                              ? BadgeType.success
                              : (bill.paymentStatus == 'Partially Paid' ? BadgeType.warning : BadgeType.danger),
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
