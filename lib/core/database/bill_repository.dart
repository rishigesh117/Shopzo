import 'package:sqflite/sqflite.dart';
import '../models/bill_model.dart';
import '../models/payment_model.dart';
import '../models/stock_movement_model.dart';
import '../services/sync_service.dart';
import 'local_database.dart';

class BillRepository {
  final LocalDatabase _dbHelper = LocalDatabase.instance;

  Future<String> generateNextBillNumber() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM bills');
    final count = (result.first['count'] as int? ?? 0) + 1001;
    return '#$count';
  }

  /// Atomic SQLite transaction to create a bill, update stock, log stock movement, and record initial payment
  Future<Bill> saveBill({
    required String? customerId,
    required String? customerNameSnapshot,
    required String? customerPhoneSnapshot,
    required List<BillItem> cartItems,
    required int amountReceivedPaise,
    required String paymentMethod,
  }) async {
    final db = await _dbHelper.database;

    return await db.transaction((txn) async {
      final now = DateTime.now();
      final nowIso = now.toIso8601String();

      // 1. Validate stock availability for all items before writing
      for (final item in cartItems) {
        final prodResult = await txn.query(
          'products',
          where: 'id = ? AND is_active = 1',
          whereArgs: [item.productId],
        );
        if (prodResult.isEmpty) {
          throw Exception('Product "${item.productNameSnapshot}" is no longer available.');
        }

        final currentQty = (prodResult.first['quantity'] as num).toDouble();
        if (currentQty < item.quantity) {
          throw Exception(
            'Insufficient stock for "${item.productNameSnapshot}". Available: $currentQty ${item.unit}, Requested: ${item.quantity} ${item.unit}.',
          );
        }
      }

      // 2. Generate Bill ID & Number
      final billCountRes = await txn.rawQuery('SELECT COUNT(*) as count FROM bills');
      final billCount = (billCountRes.first['count'] as int? ?? 0) + 1001;
      final billNumber = '#$billCount';
      final billId = 'bill_${now.millisecondsSinceEpoch}';

      // 3. Calculate Totals
      int subtotalPaise = 0;
      for (final item in cartItems) {
        subtotalPaise += item.lineTotalPaise;
      }
      final totalAmountPaise = subtotalPaise;

      int changeAmountPaise = 0;
      int pendingAmountPaise = 0;
      String paymentStatus = 'Pending';

      if (amountReceivedPaise >= totalAmountPaise) {
        changeAmountPaise = amountReceivedPaise - totalAmountPaise;
        pendingAmountPaise = 0;
        paymentStatus = 'Paid';
      } else if (amountReceivedPaise > 0) {
        changeAmountPaise = 0;
        pendingAmountPaise = totalAmountPaise - amountReceivedPaise;
        paymentStatus = 'Partially Paid';
      } else {
        changeAmountPaise = 0;
        pendingAmountPaise = totalAmountPaise;
        paymentStatus = 'Pending';
      }

      // 4. Insert Bill Record
      final billMap = {
        'id': billId,
        'bill_number': billNumber,
        'customer_id': customerId,
        'customer_name_snapshot': customerNameSnapshot,
        'customer_phone_snapshot': customerPhoneSnapshot,
        'subtotal_paise': subtotalPaise,
        'total_amount_paise': totalAmountPaise,
        'amount_received_paise': amountReceivedPaise,
        'change_amount_paise': changeAmountPaise,
        'pending_amount_paise': pendingAmountPaise,
        'payment_status': paymentStatus,
        'is_cancelled': 0,
        'created_at': nowIso,
        'updated_at': nowIso,
      };
      await txn.insert('bills', billMap);

      // 5. Insert Bill Items & Update Product Stock & Log SALE Movement
      final List<BillItem> savedItems = [];

      for (int i = 0; i < cartItems.length; i++) {
        final item = cartItems[i];
        final itemId = 'bitem_${now.millisecondsSinceEpoch}_$i';

        final itemMap = {
          'id': itemId,
          'bill_id': billId,
          'product_id': item.productId,
          'product_name_snapshot': item.productNameSnapshot,
          'quantity': item.quantity,
          'unit': item.unit,
          'selling_price_paise': item.sellingPricePaise,
          'buying_price_paise': item.buyingPricePaise,
          'line_total_paise': item.lineTotalPaise,
          'profit_paise': item.profitPaise,
        };
        await txn.insert('bill_items', itemMap);

        savedItems.add(BillItem.fromMap(itemMap));

        // Fetch product again to get accurate stock level
        final prodRes = await txn.query('products', where: 'id = ?', whereArgs: [item.productId]);
        final prevQty = (prodRes.first['quantity'] as num).toDouble();
        final newQty = prevQty - item.quantity;

        // Decrease stock in products table
        await txn.update(
          'products',
          {
            'quantity': newQty,
            'updated_at': nowIso,
          },
          where: 'id = ?',
          whereArgs: [item.productId],
        );

        // Record SALE stock movement
        final movementId = 'mov_${now.millisecondsSinceEpoch}_$i';
        await txn.insert('stock_movements', {
          'id': movementId,
          'product_id': item.productId,
          'product_name': item.productNameSnapshot,
          'previous_quantity': prevQty,
          'quantity_change': -item.quantity,
          'new_quantity': newQty,
          'purchase_price_paise': item.buyingPricePaise,
          'movement_type': StockMovementType.sale.name,
          'reason': 'Sale Bill $billNumber',
          'supplier': null,
          'notes': 'Bill $billNumber',
          'created_at': nowIso,
        });
      }

      // 6. Record Initial Payment if amountReceivedPaise > 0
      if (amountReceivedPaise > 0) {
        final paymentId = 'pay_${now.millisecondsSinceEpoch}';
        final actualPaymentPaise = amountReceivedPaise >= totalAmountPaise ? totalAmountPaise : amountReceivedPaise;

        await txn.insert('payments', {
          'id': paymentId,
          'customer_id': customerId,
          'bill_id': billId,
          'amount_paise': actualPaymentPaise,
          'payment_method': paymentMethod,
          'notes': 'Initial payment for $billNumber',
          'created_at': nowIso,
        });
      }

      final bill = Bill.fromMap(billMap, items: savedItems);

      // Enqueue for 2-way backend sync
      await SyncService.instance.enqueueChange(
        shopId: 'local_shop',
        tableName: 'bills',
        recordId: bill.id,
        action: 'INSERT',
        payload: {
          ...bill.toMap(),
          'items': savedItems.map((i) => i.toMap()).toList(),
        },
      );

      return bill;
    });
  }

  Future<List<Bill>> getBills({
    String? searchQuery,
    String? statusFilter, // 'all', 'paid', 'partially_paid', 'pending'
    String? customerId,
  }) async {
    final db = await _dbHelper.database;
    String whereClause = 'is_cancelled = 0';
    List<dynamic> whereArgs = [];

    if (customerId != null) {
      whereClause += ' AND customer_id = ?';
      whereArgs.add(customerId);
    }

    if (statusFilter != null && statusFilter != 'all') {
      if (statusFilter == 'paid') {
        whereClause += ' AND payment_status = ?';
        whereArgs.add('Paid');
      } else if (statusFilter == 'partially_paid') {
        whereClause += ' AND payment_status = ?';
        whereArgs.add('Partially Paid');
      } else if (statusFilter == 'pending') {
        whereClause += ' AND payment_status = ?';
        whereArgs.add('Pending');
      }
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim()}%';
      whereClause += ' AND (bill_number LIKE ? OR customer_name_snapshot LIKE ? OR customer_phone_snapshot LIKE ?)';
      whereArgs.addAll([query, query, query]);
    }

    final billMaps = await db.query(
      'bills',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    final List<Bill> bills = [];
    for (var bMap in billMaps) {
      final billId = bMap['id'] as String;
      final itemMaps = await db.query(
        'bill_items',
        where: 'bill_id = ?',
        whereArgs: [billId],
      );
      final items = itemMaps.map((i) => BillItem.fromMap(i)).toList();
      bills.add(Bill.fromMap(bMap, items: items));
    }

    return bills;
  }

  Future<Bill?> getBillById(String billId) async {
    final db = await _dbHelper.database;
    final billMaps = await db.query('bills', where: 'id = ?', whereArgs: [billId]);
    if (billMaps.isEmpty) return null;

    final itemMaps = await db.query('bill_items', where: 'bill_id = ?', whereArgs: [billId]);
    final items = itemMaps.map((i) => BillItem.fromMap(i)).toList();

    return Bill.fromMap(billMaps.first, items: items);
  }

  // Dashboard Aggregation Queries
  Future<int> getTodaySalesPaise() async {
    final db = await _dbHelper.database;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final result = await db.rawQuery(
      "SELECT SUM(total_amount_paise) as total FROM bills WHERE is_cancelled = 0 AND created_at LIKE '$todayStr%'",
    );
    final val = result.first['total'];
    return (val as int?) ?? 0;
  }

  Future<int> getTodayBillsCount() async {
    final db = await _dbHelper.database;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM bills WHERE is_cancelled = 0 AND created_at LIKE '$todayStr%'",
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<double> getTodayProductsSoldCount() async {
    final db = await _dbHelper.database;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final result = await db.rawQuery(
      "SELECT SUM(bi.quantity) as total_qty FROM bill_items bi JOIN bills b ON bi.bill_id = b.id WHERE b.is_cancelled = 0 AND b.created_at LIKE '$todayStr%'",
    );
    final val = result.first['total_qty'];
    return (val as num?)?.toDouble() ?? 0.0;
  }

  Future<int> getPendingPaymentsTotalPaise() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT SUM(pending_amount_paise) as total FROM bills WHERE is_cancelled = 0 AND pending_amount_paise > 0",
    );
    final val = result.first['total'];
    return (val as int?) ?? 0;
  }
}
