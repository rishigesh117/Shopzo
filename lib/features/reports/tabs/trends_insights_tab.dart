import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/report_provider.dart';

class TrendsInsightsTab extends StatelessWidget {
  const TrendsInsightsTab({super.key});

  String _formatRupees(int paise) {
    return '₹${(paise / 100).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final trends = provider.salesTrends;
    final insights = provider.insights;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Sales Trend Visualizer
        const Text('Sales Trend Over Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        if (trends.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text('No daily sales history available for this period.', style: TextStyle(color: Colors.grey))),
            ),
          )
        else
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(
                    height: 160,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: trends.map((pt) {
                        final maxSales = trends.map((t) => t.salesPaise).reduce((a, b) => a > b ? a : b);
                        final heightPct = maxSales > 0 ? (pt.salesPaise / maxSales) : 0.0;

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  _formatRupees(pt.salesPaise),
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 100 * heightPct,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  pt.label.split('-').last, // Show day number
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 20),

        // Business Insights Section
        const Text('Automated Business Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        if (insights.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text('Add more products and create bills to unlock business insights.', style: TextStyle(color: Colors.grey))),
            ),
          )
        else
          ...insights.map((ins) {
            final color = ins.type == 'positive'
                ? Colors.green
                : ins.type == 'warning'
                    ? Colors.orange
                    : Colors.blue;

            final icon = ins.type == 'positive'
                ? Icons.trending_up
                : ins.type == 'warning'
                    ? Icons.warning_amber
                    : Icons.lightbulb_outline;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(icon, color: color),
                ),
                title: Text(ins.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(ins.description),
              ),
            );
          }),
      ],
    );
  }
}
