import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/providers/payment_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_badge.dart';
import '../../core/widgets/shopzo_card.dart';
import '../../core/widgets/shopzo_header.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PaymentProvider>(context, listen: false).loadPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paymentProvider = Provider.of<PaymentProvider>(context);
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShopzoHeader(
                title: 'Payment Receipts',
                subtitle: 'Offline payment log & collection history',
              ),
              const SizedBox(height: 24),

              if (paymentProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (paymentProvider.payments.isEmpty)
                ShopzoCard(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 48,
                          color: isDark ? ShopzoColors.darkTextMuted : ShopzoColors.lightTextMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No payment transactions recorded yet',
                          style: ShopzoTypography.headingMedium(context, isDark: isDark),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Payments received during billing or customer due collections will be logged here.',
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
                  itemCount: paymentProvider.payments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final pay = paymentProvider.payments[i];
                    final dateStr = dateFormat.format(pay.createdAt);

                    return ShopzoCard(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: ShopzoColors.secondaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.payment_rounded, color: ShopzoColors.secondaryGreen, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Payment via ${pay.paymentMethod}',
                                      style: ShopzoTypography.headingMedium(context, isDark: isDark).copyWith(fontSize: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    ShopzoBadge(
                                      text: pay.paymentMethod,
                                      type: BadgeType.navy,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateStr,
                                  style: ShopzoTypography.bodySmall(context, isDark: isDark),
                                ),
                                if (pay.notes != null && pay.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Notes: ${pay.notes}',
                                    style: ShopzoTypography.bodySmall(context, isDark: isDark).copyWith(fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            '+₹${pay.amount.toStringAsFixed(2)}',
                            style: ShopzoTypography.moneyText(context, fontSize: 18, isDark: isDark, color: ShopzoColors.secondaryGreen),
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
