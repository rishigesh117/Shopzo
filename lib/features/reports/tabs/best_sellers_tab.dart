import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/report_provider.dart';

class BestSellersTab extends StatelessWidget {
  const BestSellersTab({super.key});

  String _formatRupees(int paise) {
    return '₹${(paise / 100).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final bestSellers = provider.bestSellers;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bestSellers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_outline, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text('No best seller data found for this date range.', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Top Selling Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${bestSellers.length} Products', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 8),

        ...bestSellers.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final item = entry.value;

          final rankColor = rank == 1
              ? Colors.amber.shade700
              : rank == 2
                  ? Colors.grey.shade600
                  : rank == 3
                      ? Colors.brown.shade400
                      : Theme.of(context).primaryColor;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: rankColor,
                child: Text('#$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Qty Sold: ${item.totalQuantitySold.toStringAsFixed(1)} | Bills: ${item.billCount}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatRupees(item.totalRevenuePaise), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('Est. Profit: ${_formatRupees(item.totalProfitPaise)}', style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
