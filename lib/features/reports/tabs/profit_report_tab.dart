import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/report_provider.dart';

class ProfitReportTab extends StatelessWidget {
  const ProfitReportTab({super.key});

  String _formatRupees(int paise) {
    return '₹${(paise / 100).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final profit = provider.profitReport;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (profit == null) {
      return const Center(child: Text('No profit data available.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Profit Highlight Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estimated Profit',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                _formatRupees(profit.estimatedProfitPaise),
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Margin: ${profit.profitMarginPercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Text(
                    '*Based on historical buying prices',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Breakdown Cards
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildRow(context, 'Gross Sales Revenue', _formatRupees(profit.grossSalesPaise), Colors.blue),
                const Divider(height: 24),
                _buildRow(context, 'Cost of Goods Sold (COGS)', _formatRupees(profit.costOfGoodsSoldPaise), Colors.orange),
                const Divider(height: 24),
                _buildRow(context, 'Net Estimated Profit', _formatRupees(profit.estimatedProfitPaise), Colors.green, isBold: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(BuildContext context, String title, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
