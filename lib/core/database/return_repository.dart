import 'package:sqflite/sqflite.dart';
import '../models/return_model.dart';
import '../models/stock_movement_model.dart';
import '../services/sync_service.dart';
import 'local_database.dart';

class ReturnRepository {
  final LocalDatabase _dbHelper = LocalDatabase.instance;

  Future<double> getAlreadyReturnedQuantity(String billId, String productId) async {
    final db = await _dbHelper.database;
    final res = await db.rawQuery(
      'SELECT SUM(quantity) as total FROM returns WHERE bill_id = ? AND product_id = ? AND status = ?',
      [billId, productId, 'Completed'],
    );
    final val = res.first['total'];
    return (val as num?)?.toDouble() ?? 0.0;
  }

  /// Process product return atomically in SQLite transaction
  Future<ProductReturn> processReturn({
    required String billId,
    required String? customerId,
    required String productId,
    required String productNameSnapshot,
    required double returnQuantity,
    required String unit,
    required String reason,
    required String stockAction, // 'Restocked', 'Scrapped'
  }) async {
    final db = await _dbHelper.database;

    return await db.transaction((txn) async {
      final now = DateTime.now();
      final nowIso = now.toIso8601String();

      // 1. Fetch original bill item
      final itemRes = await txn.query(
        'bill_items',
        where: 'bill_id = ? AND product_id = ?',
        whereArgs: [billId, productId],
      );
      if (itemRes.isEmpty) {
        throw Exception('Original bill item not found for product "$productNameSnapshot".');
      }

      final itemMap = itemRes.first;
      final originalQty = (itemMap['quantity'] as num).toDouble();
      final sellingPricePaise = itemMap['selling_price_paise'] as int;

      // 2. Calculate already returned quantity
      final alreadyRetRes = await txn.rawQuery(
        'SELECT SUM(quantity) as total FROM returns WHERE bill_id = ? AND product_id = ? AND status = ?',
        [billId, productId, 'Completed'],
      );
      final alreadyReturnedQty = (alreadyRetRes.first['total'] as num?)?.toDouble() ?? 0.0;
      final remainingReturnable = originalQty - alreadyReturnedQty;

      if (returnQuantity > remainingReturnable) {
        throw Exception(
          'Cannot return more than remaining returnable quantity ($remainingReturnable $unit). Already returned: $alreadyReturnedQty $unit.',
        );
      }

      // 3. Calculate Refund Amount based on original bill selling price
      final refundAmountPaise = (sellingPricePaise * returnQuantity).round();

      // 4. Create Return Record
      final returnId = 'ret_${now.millisecondsSinceEpoch}';
      final returnMap = {
        'id': returnId,
        'bill_id': billId,
        'customer_id': customerId,
        'product_id': productId,
        'product_name_snapshot': productNameSnapshot,
        'quantity': returnQuantity,
        'unit': unit,
        'refund_amount_paise': refundAmountPaise,
        'reason': reason,
        'status': 'Completed',
        'stock_action': stockAction,
        'created_at': nowIso,
      };
      await txn.insert('returns', returnMap);

      // 5. Restore stock if stockAction == 'Restocked'
      if (stockAction == 'Restocked') {
        final prodRes = await txn.query('products', where: 'id = ?', whereArgs: [productId]);
        if (prodRes.isNotEmpty) {
          final prevQty = (prodRes.first['quantity'] as num).toDouble();
          final newQty = prevQty + returnQuantity;

          await txn.update(
            'products',
            {
              'quantity': newQty,
              'updated_at': nowIso,
            },
            where: 'id = ?',
            whereArgs: [productId],
          );

          // Log RETURN stock movement
          final movementId = 'mov_ret_${now.millisecondsSinceEpoch}';
          await txn.insert('stock_movements', {
            'id': movementId,
            'product_id': productId,
            'product_name': productNameSnapshot,
            'previous_quantity': prevQty,
            'quantity_change': returnQuantity,
            'new_quantity': newQty,
            'purchase_price_paise': itemMap['buying_price_paise'],
            'movement_type': StockMovementType.returnStock.name,
            'reason': 'Return from Bill #$billId ($reason)',
            'supplier': null,
            'notes': 'Refund: ₹${(refundAmountPaise / 100).toStringAsFixed(2)}',
            'created_at': nowIso,
          });
        }
      }

      final retObj = ProductReturn.fromMap(returnMap);

      await SyncService.instance.enqueueChange(
        shopId: 'local_shop',
        tableName: 'returns',
        recordId: returnId,
        action: 'INSERT',
        payload: returnMap,
      );

      return retObj;
    });
  }

  Future<List<ProductReturn>> getReturns({String? billId, String? customerId}) async {
    final db = await _dbHelper.database;
    String whereClause = '1 = 1';
    List<dynamic> whereArgs = [];

    if (billId != null) {
      whereClause += ' AND bill_id = ?';
      whereArgs.add(billId);
    }
    if (customerId != null) {
      whereClause += ' AND customer_id = ?';
      whereArgs.add(customerId);
    }

    final maps = await db.query(
      'returns',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    return maps.map((m) => ProductReturn.fromMap(m)).toList();
  }
}
