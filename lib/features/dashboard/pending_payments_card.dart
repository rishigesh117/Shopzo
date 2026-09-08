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

class PendingPaymentsCard extends StatefulWidget {
  const PendingPaymentsCard({super.key});

  @override
  State<PendingPaymentsCard> createState() => _PendingPaymentsCardState();
}

class _PendingPaymentsCardState extends State<PendingPaymentsCard> {
  final BillRepository _repository = BillRepository();
  List<Bill> _pendingBills = [];
  int _totalPendingPaise = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingBills();
  }

  Future<void> _loadPendingBills() async {
    try {
      final allBills = await _repository.getBills();
      final pending = allBills.where((b) => b.pendingAmountPaise > 0).toList();
      int total = 0;
      for (var b in pending) {
        total += b.pendingAmountPaise;
      }
      if (mounted) {
        setState(() {
          _pendingBills = pending.take(5).toList();
          _totalPendingPaise = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading pending bills: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final dateFormat = DateFormat('MMM dd • hh:mm a');
    final totalPendingDouble = _totalPendingPaise / 100.0;

    return ShopzoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.pending_actions_rounded, color: ShopzoColors.warning, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Pending Payments',
                    style: ShopzoTypography.headingMedium(context, isDark: isDark),
                  ),
                ],
              ),
              ShopzoBadge(
                text: 'Total ₹${totalPendingDouble.toStringAsFixed(2)} Due',
                type: BadgeType.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_pendingBills.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No pending dues! All bills are fully paid.',
                  style: ShopzoTypography.bodyMedium(context, isDark: isDark).copyWith(color: ShopzoColors.secondaryGreen, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pendingBills.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final bill = _pendingBills[index];
                final dateStr = dateFormat.format(bill.createdAt);
                final custName = bill.customerNameSnapshot ?? 'Walk-in Customer';

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => BillDetailsScreen(billId: bill.id)),
                    ).then((_) => _loadPendingBills());
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: ShopzoColors.warning.withOpacity(0.15),
                          child: Text(
                            custName.substring(0, 1).toUpperCase(),
                            style: ShopzoTypography.headingMedium(context, isDark: isDark).copyWith(
                              color: ShopzoColors.warning,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                custName,
                                style: ShopzoTypography.headingMedium(context, isDark: isDark).copyWith(fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Bill ${bill.billNumber} • $dateStr',
                                style: ShopzoTypography.bodySmall(context, isDark: isDark),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${bill.pendingAmount.toStringAsFixed(2)}',
                              style: ShopzoTypography.moneyText(
                                context,
                                fontSize: 16,
                                isDark: isDark,
                                color: ShopzoColors.warning,
                              ),
                            ),
                            const SizedBox(height: 2),
                            ShopzoBadge(
                              text: bill.paymentStatus,
                              type: bill.paymentStatus == 'Partially Paid' ? BadgeType.warning : BadgeType.danger,
                            ),
                          ],
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
