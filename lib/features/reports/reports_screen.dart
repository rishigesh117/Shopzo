import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/report_provider.dart';
import '../../core/services/report_service.dart';
import 'tabs/sales_report_tab.dart';
import 'tabs/profit_report_tab.dart';
import 'tabs/stock_report_tab.dart';
import 'tabs/returns_report_tab.dart';
import 'tabs/pending_payments_report_tab.dart';
import 'tabs/best_sellers_tab.dart';
import 'tabs/trends_insights_tab.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectCustomDateRange(BuildContext context) async {
    final provider = context.read<ReportProvider>();
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: provider.currentRange.start,
        end: provider.currentRange.end,
      ),
    );

    if (picked != null) {
      provider.setPreset(
        DateRangePreset.custom,
        customStart: picked.start,
        customEnd: DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59, 999),
      );
    }
  }

  String _getPresetLabel(DateRangePreset preset) {
    switch (preset) {
      case DateRangePreset.today:
        return 'Today';
      case DateRangePreset.yesterday:
        return 'Yesterday';
      case DateRangePreset.thisWeek:
        return 'This Week';
      case DateRangePreset.thisMonth:
        return 'This Month';
      case DateRangePreset.lastMonth:
        return 'Last Month';
      case DateRangePreset.custom:
        return 'Custom Range';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<DateRangePreset>(
            initialValue: provider.selectedPreset,
            onSelected: (preset) {
              if (preset == DateRangePreset.custom) {
                _selectCustomDateRange(context);
              } else {
                provider.setPreset(preset);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 6),
                  Text(_getPresetLabel(provider.selectedPreset), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(value: DateRangePreset.today, child: Text('Today')),
              const PopupMenuItem(value: DateRangePreset.yesterday, child: Text('Yesterday')),
              const PopupMenuItem(value: DateRangePreset.thisWeek, child: Text('This Week')),
              const PopupMenuItem(value: DateRangePreset.thisMonth, child: Text('This Month')),
              const PopupMenuItem(value: DateRangePreset.lastMonth, child: Text('Last Month')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: DateRangePreset.custom, child: Text('Custom Date Range...')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.show_chart), text: 'Sales'),
            Tab(icon: Icon(Icons.monetization_on_outlined), text: 'Profit'),
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Stock'),
            Tab(icon: Icon(Icons.replay), text: 'Returns'),
            Tab(icon: Icon(Icons.pending_actions), text: 'Pending'),
            Tab(icon: Icon(Icons.star_outline), text: 'Best Sellers'),
            Tab(icon: Icon(Icons.lightbulb_outline), text: 'Trends & Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SalesReportTab(),
          ProfitReportTab(),
          StockReportTab(),
          ReturnsReportTab(),
          PendingPaymentsReportTab(),
          BestSellersTab(),
          TrendsInsightsTab(),
        ],
      ),
    );
  }
}
