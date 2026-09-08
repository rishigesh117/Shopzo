import 'package:sqflite/sqflite.dart';
import '../database/local_database.dart';

enum DateRangePreset {
  today,
  yesterday,
  thisWeek,
  thisMonth,
  lastMonth,
  custom,
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;
  final DateRangePreset preset;

  DateTimeRange({
    required this.start,
    required this.end,
    this.preset = DateRangePreset.today,
  });

  factory DateTimeRange.preset(DateRangePreset preset, {DateTime? customStart, DateTime? customEnd}) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    switch (preset) {
      case DateRangePreset.today:
        return DateTimeRange(start: todayStart, end: todayEnd, preset: preset);
      case DateRangePreset.yesterday:
        final yest = now.subtract(const Duration(days: 1));
        final yestStart = DateTime(yest.year, yest.month, yest.day);
        final yestEnd = DateTime(yest.year, yest.month, yest.day, 23, 59, 59, 999);
        return DateTimeRange(start: yestStart, end: yestEnd, preset: preset);
      case DateRangePreset.thisWeek:
        final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(start: weekStart, end: todayEnd, preset: preset);
      case DateRangePreset.thisMonth:
        final monthStart = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: monthStart, end: todayEnd, preset: preset);
      case DateRangePreset.lastMonth:
        final lastMonthStart = DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59, 999);
        return DateTimeRange(start: lastMonthStart, end: lastMonthEnd, preset: preset);
      case DateRangePreset.custom:
        return DateTimeRange(
          start: customStart ?? todayStart,
          end: customEnd ?? todayEnd,
          preset: preset,
        );
    }
  }
}

class SalesReportData {
  final int totalSalesPaise;
  final int billCount;
  final double productsSoldCount;
  final int averageBillValuePaise;
  final int paidAmountPaise;
  final int pendingAmountPaise;
  final int returnedAmountPaise;

  SalesReportData({
    required this.totalSalesPaise,
    required this.billCount,
    required this.productsSoldCount,
    required this.averageBillValuePaise,
    required this.paidAmountPaise,
    required this.pendingAmountPaise,
    required this.returnedAmountPaise,
  });
}

class ProfitReportData {
  final int grossSalesPaise;
  final int costOfGoodsSoldPaise;
  final int estimatedProfitPaise;
  final double profitMarginPercentage;

  ProfitReportData({
    required this.grossSalesPaise,
    required this.costOfGoodsSoldPaise,
    required this.estimatedProfitPaise,
    required this.profitMarginPercentage,
  });
}

class StockReportData {
  final int totalProducts;
  final int inStockCount;
  final int lowStockCount;
  final int outOfStockCount;
  final int totalStockValueBuyingPaise;
  final int totalStockValueSellingPaise;
  final int potentialProfitPaise;
  final List<Map<String, dynamic>> recentlyRestocked;

  StockReportData({
    required this.totalProducts,
    required this.inStockCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.totalStockValueBuyingPaise,
    required this.totalStockValueSellingPaise,
    required this.potentialProfitPaise,
    required this.recentlyRestocked,
  });
}

class ReturnReportData {
  final double totalReturnedItemsQuantity;
  final int totalRefundAmountPaise;
  final int returnCount;
  final List<Map<String, dynamic>> returnItems;

  ReturnReportData({
    required this.totalReturnedItemsQuantity,
    required this.totalRefundAmountPaise,
    required this.returnCount,
    required this.returnItems,
  });
}

class PendingPaymentReportData {
  final int totalOutstandingPaise;
  final int pendingCustomerCount;
  final List<Map<String, dynamic>> pendingBills;

  PendingPaymentReportData({
    required this.totalOutstandingPaise,
    required this.pendingCustomerCount,
    required this.pendingBills,
  });
}

class BestSellerItem {
  final String productId;
  final String productName;
  final double totalQuantitySold;
  final int totalRevenuePaise;
  final int totalProfitPaise;
  final int billCount;

  BestSellerItem({
    required this.productId,
    required this.productName,
    required this.totalQuantitySold,
    required this.totalRevenuePaise,
    required this.totalProfitPaise,
    required this.billCount,
  });
}

class SalesTrendPoint {
  final String label;
  final int salesPaise;
  final int billCount;

  SalesTrendPoint({
    required this.label,
    required this.salesPaise,
    required this.billCount,
  });
}

class BusinessInsight {
  final String title;
  final String description;
  final String category; // 'sales', 'stock', 'returns', 'payments'
  final String type; // 'positive', 'warning', 'info'

  BusinessInsight({
    required this.title,
    required this.description,
    required this.category,
    required this.type,
  });
}

class ReportService {
  final LocalDatabase _localDb = LocalDatabase.instance;

  // 1. Sales Report
  Future<SalesReportData> getSalesReport(DateTimeRange range) async {
    final db = await _localDb.database;
    final startIso = range.start.toIso8601String();
    final endIso = range.end.toIso8601String();

    // Query active bills in range
    final billRes = await db.rawQuery('''
      SELECT 
        COUNT(id) as bill_count,
        COALESCE(SUM(total_amount_paise), 0) as total_sales,
        COALESCE(SUM(amount_received_paise), 0) as paid_amount,
        COALESCE(SUM(pending_amount_paise), 0) as pending_amount
      FROM bills
      WHERE is_cancelled = 0
        AND created_at >= ? AND created_at <= ?
    ''', [startIso, endIso]);

    final billCount = (billRes.first['bill_count'] as int?) ?? 0;
    final totalSales = (billRes.first['total_sales'] as num?)?.toInt() ?? 0;
    final paidAmount = (billRes.first['paid_amount'] as num?)?.toInt() ?? 0;
    final pendingAmount = (billRes.first['pending_amount'] as num?)?.toInt() ?? 0;

    // Items sold in range
    final itemRes = await db.rawQuery('''
      SELECT COALESCE(SUM(bi.quantity), 0) as total_qty
      FROM bill_items bi
      JOIN bills b ON bi.bill_id = b.id
      WHERE b.is_cancelled = 0
        AND b.created_at >= ? AND b.created_at <= ?
    ''', [startIso, endIso]);

    final productsSold = (itemRes.first['total_qty'] as num?)?.toDouble() ?? 0.0;

    // Returns in range
    final returnRes = await db.rawQuery('''
      SELECT COALESCE(SUM(refund_amount_paise), 0) as returned_amount
      FROM returns
      WHERE created_at >= ? AND created_at <= ?
    ''', [startIso, endIso]);

    final returnedAmount = (returnRes.first['returned_amount'] as num?)?.toInt() ?? 0;

    final avgBillValue = billCount > 0 ? (totalSales / billCount).round() : 0;

    return SalesReportData(
      totalSalesPaise: totalSales,
      billCount: billCount,
      productsSoldCount: productsSold,
      averageBillValuePaise: avgBillValue,
      paidAmountPaise: paidAmount,
      pendingAmountPaise: pendingAmount,
      returnedAmountPaise: returnedAmount,
    );
  }

  // 2. Profit Report
  Future<ProfitReportData> getProfitReport(DateTimeRange range) async {
    final db = await _localDb.database;
    final startIso = range.start.toIso8601String();
    final endIso = range.end.toIso8601String();

    // Sum line totals and cost of goods sold from bill_items (using historical buying price)
    final profitRes = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(bi.line_total_paise), 0) as gross_sales,
        COALESCE(SUM(bi.buying_price_paise * bi.quantity), 0) as cogs,
        COALESCE(SUM(bi.profit_paise), 0) as gross_profit
      FROM bill_items bi
      JOIN bills b ON bi.bill_id = b.id
      WHERE b.is_cancelled = 0
        AND b.created_at >= ? AND b.created_at <= ?
    ''', [startIso, endIso]);

    final grossSales = (profitRes.first['gross_sales'] as num?)?.toInt() ?? 0;
    final cogs = (profitRes.first['cogs'] as num?)?.toInt() ?? 0;

    // Returns deduction
    final returnRes = await db.rawQuery('''
      SELECT COALESCE(SUM(refund_amount_paise), 0) as returned_amount
      FROM returns
      WHERE created_at >= ? AND created_at <= ?
    ''', [startIso, endIso]);
    final returnedAmount = (returnRes.first['returned_amount'] as num?)?.toInt() ?? 0;

    final netSales = grossSales - returnedAmount;
    final netProfit = netSales - cogs;
    final profitMargin = netSales > 0 ? (netProfit / netSales) * 100 : 0.0;

    return ProfitReportData(
      grossSalesPaise: grossSales,
      costOfGoodsSoldPaise: cogs,
      estimatedProfitPaise: netProfit > 0 ? netProfit : 0,
      profitMarginPercentage: profitMargin > 0 ? profitMargin : 0.0,
    );
  }

  // 3. Stock Report
  Future<StockReportData> getStockReport() async {
    final db = await _localDb.database;

    final products = await db.query('products', where: 'is_active = 1');
    final totalProducts = products.length;

    int inStock = 0;
    int lowStock = 0;
    int outOfStock = 0;
    int totalValueBuying = 0;
    int totalValueSelling = 0;

    for (final p in products) {
      final qty = (p['quantity'] as num).toDouble();
      final minStock = (p['min_stock_level'] as num).toDouble();
      final buyPrice = (p['buying_price_paise'] as num).toInt();
      final sellPrice = (p['selling_price_paise'] as num).toInt();

      if (qty <= 0) {
        outOfStock++;
      } else if (qty <= minStock) {
        lowStock++;
      } else {
        inStock++;
      }

      totalValueBuying += (buyPrice * qty).round();
      totalValueSelling += (sellPrice * qty).round();
    }

    final potentialProfit = totalValueSelling - totalValueBuying;

    // Recently restocked (last 10 RESTOCK movements)
    final restockedRes = await db.query(
      'stock_movements',
      where: 'movement_type = ?',
      whereArgs: ['RESTOCK'],
      orderBy: 'created_at DESC',
      limit: 10,
    );

    return StockReportData(
      totalProducts: totalProducts,
      inStockCount: inStock,
      lowStockCount: lowStock,
      outOfStockCount: outOfStock,
      totalStockValueBuyingPaise: totalValueBuying,
      totalStockValueSellingPaise: totalValueSelling,
      potentialProfitPaise: potentialProfit > 0 ? potentialProfit : 0,
      recentlyRestocked: restockedRes,
    );
  }

  // 4. Return Report
  Future<ReturnReportData> getReturnReport(DateTimeRange range) async {
    final db = await _localDb.database;
    final startIso = range.start.toIso8601String();
    final endIso = range.end.toIso8601String();

    final returns = await db.query(
      'returns',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [startIso, endIso],
      orderBy: 'created_at DESC',
    );

    double totalQty = 0.0;
    int totalRefund = 0;

    for (final r in returns) {
      totalQty += (r['quantity'] as num).toDouble();
      totalRefund += (r['refund_amount_paise'] as num).toInt();
    }

    return ReturnReportData(
      totalReturnedItemsQuantity: totalQty,
      totalRefundAmountPaise: totalRefund,
      returnCount: returns.length,
      returnItems: returns,
    );
  }

  // 5. Pending Payment Report
  Future<PendingPaymentReportData> getPendingPaymentsReport() async {
    final db = await _localDb.database;

    final pendingBills = await db.rawQuery('''
      SELECT b.*, c.name as customer_name, c.phone as customer_phone
      FROM bills b
      LEFT JOIN customers c ON b.customer_id = c.id
      WHERE b.is_cancelled = 0 AND b.pending_amount_paise > 0
      ORDER BY b.created_at DESC
    ''');

    int totalOutstanding = 0;
    final customerIds = <String>{};

    for (final b in pendingBills) {
      totalOutstanding += (b['pending_amount_paise'] as num).toInt();
      if (b['customer_id'] != null) {
        customerIds.add(b['customer_id'] as String);
      }
    }

    return PendingPaymentReportData(
      totalOutstandingPaise: totalOutstanding,
      pendingCustomerCount: customerIds.length,
      pendingBills: pendingBills,
    );
  }

  // 6. Best Sellers
  Future<List<BestSellerItem>> getBestSellers(DateTimeRange range, {int limit = 10}) async {
    final db = await _localDb.database;
    final startIso = range.start.toIso8601String();
    final endIso = range.end.toIso8601String();

    final res = await db.rawQuery('''
      SELECT 
        bi.product_id,
        bi.product_name_snapshot as product_name,
        SUM(bi.quantity) as total_qty,
        SUM(bi.line_total_paise) as total_revenue,
        SUM(bi.profit_paise) as total_profit,
        COUNT(DISTINCT bi.bill_id) as bill_count
      FROM bill_items bi
      JOIN bills b ON bi.bill_id = b.id
      WHERE b.is_cancelled = 0
        AND b.created_at >= ? AND b.created_at <= ?
      GROUP BY bi.product_id, bi.product_name_snapshot
      ORDER BY total_qty DESC
      LIMIT ?
    ''', [startIso, endIso, limit]);

    return res.map((r) => BestSellerItem(
      productId: r['product_id'] as String,
      productName: r['product_name'] as String,
      totalQuantitySold: (r['total_qty'] as num).toDouble(),
      totalRevenuePaise: (r['total_revenue'] as num).toInt(),
      totalProfitPaise: (r['total_profit'] as num).toInt(),
      billCount: (r['bill_count'] as num).toInt(),
    )).toList();
  }

  // 7. Sales Trends
  Future<List<SalesTrendPoint>> getSalesTrends(DateTimeRange range) async {
    final db = await _localDb.database;
    final startIso = range.start.toIso8601String();
    final endIso = range.end.toIso8601String();

    final res = await db.rawQuery('''
      SELECT 
        substr(created_at, 1, 10) as date_label,
        SUM(total_amount_paise) as daily_sales,
        COUNT(id) as bill_count
      FROM bills
      WHERE is_cancelled = 0
        AND created_at >= ? AND created_at <= ?
      GROUP BY date_label
      ORDER BY date_label ASC
    ''', [startIso, endIso]);

    return res.map((r) => SalesTrendPoint(
      label: r['date_label'] as String,
      salesPaise: (r['daily_sales'] as num).toInt(),
      billCount: (r['bill_count'] as num).toInt(),
    )).toList();
  }

  // 8. Business Insights Engine
  Future<List<BusinessInsight>> getBusinessInsights(DateTimeRange range) async {
    final insights = <BusinessInsight>[];

    final bestSellers = await getBestSellers(range, limit: 1);
    if (bestSellers.isNotEmpty) {
      final top = bestSellers.first;
      insights.add(BusinessInsight(
        title: 'Top Performing Product',
        description: '${top.productName} is your #1 seller with ${top.totalQuantitySold.toStringAsFixed(0)} units sold across ${top.billCount} bills.',
        category: 'sales',
        type: 'positive',
      ));
    }

    final stock = await getStockReport();
    if (stock.outOfStockCount > 0) {
      insights.add(BusinessInsight(
        title: 'Out of Stock Alert',
        description: '${stock.outOfStockCount} products are completely out of stock. Restock soon to prevent lost sales.',
        category: 'stock',
        type: 'warning',
      ));
    }

    if (stock.lowStockCount > 0) {
      insights.add(BusinessInsight(
        title: 'Low Stock Warning',
        description: '${stock.lowStockCount} products have dropped below their minimum stock threshold.',
        category: 'stock',
        type: 'warning',
      ));
    }

    final pending = await getPendingPaymentsReport();
    if (pending.totalOutstandingPaise > 0) {
      final amt = (pending.totalOutstandingPaise / 100).toStringAsFixed(2);
      insights.add(BusinessInsight(
        title: 'Pending Customer Dues',
        description: 'You have ₹$amt pending across ${pending.pendingCustomerCount} customers.',
        category: 'payments',
        type: 'info',
      ));
    }

    final returns = await getReturnReport(range);
    if (returns.returnCount > 0) {
      insights.add(BusinessInsight(
        title: 'Product Returns Recorded',
        description: '${returns.returnCount} product return(s) processed amounting to ₹${(returns.totalRefundAmountPaise / 100).toStringAsFixed(2)}.',
        category: 'returns',
        type: 'info',
      ));
    }

    return insights;
  }
}
