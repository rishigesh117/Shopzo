import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/providers/return_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_badge.dart';
import '../../core/widgets/shopzo_card.dart';
import '../../core/widgets/shopzo_header.dart';

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReturnProvider>(context, listen: false).loadReturns();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final returnProvider = Provider.of<ReturnProvider>(context);
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShopzoHeader(
                title: 'Product Returns & Refunds',
                subtitle: 'Offline product return log, refund audit & stock restoration',
              ),
              const SizedBox(height: 24),

              if (returnProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (returnProvider.returns.isEmpty)
                ShopzoCard(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.assignment_return_outlined,
                          size: 48,
                          color: isDark ? ShopzoColors.darkTextMuted : ShopzoColors.lightTextMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No product returns processed yet',
                          style: ShopzoTypography.headingMedium(context, isDark: isDark),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'When items are returned from customer bills, return logs and stock adjustments will appear here.',
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
                  itemCount: returnProvider.returns.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final ret = returnProvider.returns[i];
                    final dateStr = dateFormat.format(ret.createdAt);

                    return ShopzoCard(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: ShopzoColors.danger.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.assignment_return_rounded, color: ShopzoColors.danger, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      ret.productNameSnapshot,
                                      style: ShopzoTypography.headingMedium(context, isDark: isDark).copyWith(fontSize: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    ShopzoBadge(
                                      text: ret.stockAction,
                                      type: ret.stockAction == 'Restocked' ? BadgeType.success : BadgeType.warning,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Reason: ${ret.reason} • Returned: ${ret.quantity} ${ret.unit}',
                                  style: ShopzoTypography.bodySmall(context, isDark: isDark).copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  dateStr,
                                  style: ShopzoTypography.bodySmall(context, isDark: isDark),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '-₹${ret.refundAmount.toStringAsFixed(2)}',
                                style: ShopzoTypography.moneyText(context, fontSize: 18, isDark: isDark, color: ShopzoColors.danger),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Refund Paid',
                                style: ShopzoTypography.bodySmall(context, isDark: isDark),
                              ),
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
