import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/report_provider.dart';

class ReturnsReportTab extends StatelessWidget {
  const ReturnsReportTab({super.key});

  String _formatRupees(int paise) {
    return '₹${(paise / 100).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final returns = provider.returnReport;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (returns == null || returns.returnCount == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_return_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text('No product returns recorded for this period.', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Summary Header
        Card(
          elevation: 2,
          color: Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeaderStat('Total Returns', '${returns.returnCount}', Colors.orange.shade900),
                _buildHeaderStat('Items Returned', returns.totalReturnedItemsQuantity.toStringAsFixed(1), Colors.orange.shade900),
                _buildHeaderStat('Total Refunded', _formatRupees(returns.totalRefundAmountPaise), Colors.red.shade800),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text('Return Transactions Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        ...returns.returnItems.map((ret) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orangeAccent,
                  child: Icon(Icons.replay, color: Colors.white),
                ),
                title: Text(ret['product_name_snapshot'] ?? 'Product'),
                subtitle: Text('Qty: ${ret['quantity']} | Reason: ${ret['reason']} | Action: ${ret['stock_action']}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatRupees((ret['refund_amount_paise'] as num).toInt()), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    Text(ret['created_at'].toString().split('T').first, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildHeaderStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
      ],
    );
  }
}
