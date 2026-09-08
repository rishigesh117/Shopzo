import 'package:sqflite/sqflite.dart';
import '../models/payment_model.dart';
import '../services/sync_service.dart';
import 'local_database.dart';

class PaymentRepository {
  final LocalDatabase _dbHelper = LocalDatabase.instance;

  /// Record full or partial payment against a bill
  Future<Payment> recordPayment({
    required String? customerId,
    required String? billId,
    required int amountPaise,
    required String paymentMethod,
    String? notes,
  }) async {
    final db = await _dbHelper.database;

    return await db.transaction((txn) async {
      final now = DateTime.now();
      final nowIso = now.toIso8601String();
      final paymentId = 'pay_${now.millisecondsSinceEpoch}';

      final paymentMap = {
        'id': paymentId,
        'customer_id': customerId,
        'bill_id': billId,
        'amount_paise': amountPaise,
        'payment_method': paymentMethod,
        'notes': notes,
        'created_at': nowIso,
      };

      await txn.insert('payments', paymentMap);

      // If tied to a bill, update bill pending amount, amount received, and payment status
      if (billId != null) {
        final billRes = await txn.query('bills', where: 'id = ?', whereArgs: [billId]);
        if (billRes.isNotEmpty) {
          final bMap = billRes.first;
          final totalAmountPaise = bMap['total_amount_paise'] as int;
          final prevAmountReceivedPaise = bMap['amount_received_paise'] as int;
          final newAmountReceivedPaise = prevAmountReceivedPaise + amountPaise;

          int newPendingPaise = totalAmountPaise - newAmountReceivedPaise;
          if (newPendingPaise < 0) newPendingPaise = 0;

          int newChangePaise = 0;
          if (newAmountReceivedPaise > totalAmountPaise) {
            newChangePaise = newAmountReceivedPaise - totalAmountPaise;
          }

          String newStatus = 'Pending';
          if (newPendingPaise == 0) {
            newStatus = 'Paid';
          } else if (newAmountReceivedPaise > 0) {
            newStatus = 'Partially Paid';
          }

          await txn.update(
            'bills',
            {
              'amount_received_paise': newAmountReceivedPaise,
              'pending_amount_paise': newPendingPaise,
              'change_amount_paise': newChangePaise,
              'payment_status': newStatus,
              'updated_at': nowIso,
            },
            where: 'id = ?',
            whereArgs: [billId],
          );
        }
      }

      final payment = Payment.fromMap(paymentMap);

      await SyncService.instance.enqueueChange(
        shopId: 'local_shop',
        tableName: 'payments',
        recordId: paymentId,
        action: 'INSERT',
        payload: paymentMap,
      );

      return payment;
    });
  }

  Future<List<Payment>> getPayments({String? customerId, String? billId}) async {
    final db = await _dbHelper.database;
    String whereClause = '1 = 1';
    List<dynamic> whereArgs = [];

    if (customerId != null) {
      whereClause += ' AND customer_id = ?';
      whereArgs.add(customerId);
    }
    if (billId != null) {
      whereClause += ' AND bill_id = ?';
      whereArgs.add(billId);
    }

    final maps = await db.query(
      'payments',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    return maps.map((m) => Payment.fromMap(m)).toList();
  }
}
