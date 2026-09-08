import 'package:flutter/material.dart';
import '../../core/widgets/shopzo_header.dart';
import 'low_stock_card.dart';
import 'pending_payments_card.dart';
import 'quick_actions_row.dart';
import 'recent_bills_card.dart';
import 'sales_summary_grid.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 840;

    return Scaffold(
      body: Column(
        children: [
          const ShopzoHeader(
            title: 'Good Morning 👋',
            subtitle: 'Supermarket POS Dashboard',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SalesSummaryGrid(),
                  const SizedBox(height: 20),
                  const QuickActionsRow(),
                  const SizedBox(height: 20),
                  if (isDesktop) ...[
                    // Desktop Layout: 2 Columns
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: const [
                              RecentBillsCard(),
                              SizedBox(height: 20),
                              PendingPaymentsCard(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: const [
                              LowStockCard(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Mobile Layout: Single Column Stack
                    const RecentBillsCard(),
                    const SizedBox(height: 20),
                    const LowStockCard(),
                    const SizedBox(height: 20),
                    const PendingPaymentsCard(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
