import 'package:sqflite/sqflite.dart';
import '../models/customer_model.dart';
import '../services/sync_service.dart';
import 'local_database.dart';

class CustomerRepository {
  final LocalDatabase _dbHelper = LocalDatabase.instance;

  Future<List<Customer>> getCustomers({String? searchQuery}) async {
    final db = await _dbHelper.database;
    String whereClause = 'is_deleted = 0';
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim()}%';
      whereClause += ' AND (name LIKE ? OR phone LIKE ?)';
      whereArgs.addAll([query, query]);
    }

    final maps = await db.query(
      'customers',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  Future<Customer?> getCustomerById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'customers',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  Future<void> addCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    await db.insert('customers', customer.toMap());
    await SyncService.instance.enqueueChange(
      shopId: 'local_shop',
      tableName: 'customers',
      recordId: customer.id,
      action: 'INSERT',
      payload: customer.toMap(),
    );
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
    await SyncService.instance.enqueueChange(
      shopId: 'local_shop',
      tableName: 'customers',
      recordId: customer.id,
      action: 'UPDATE',
      payload: customer.toMap(),
    );
  }

  Future<void> softDeleteCustomer(String id) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'customers',
      {
        'is_deleted': 1,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    final customer = await getCustomerById(id);
    if (customer != null) {
      await SyncService.instance.enqueueChange(
        shopId: 'local_shop',
        tableName: 'customers',
        recordId: id,
        action: 'UPDATE',
        payload: {
          ...customer.toMap(),
          'is_deleted': 1,
          'updated_at': now,
        },
      );
    }
  }

  // Calculate total purchases in paise for a customer
  Future<int> getCustomerTotalPurchasesPaise(String customerId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(total_amount_paise) as total FROM bills WHERE customer_id = ? AND is_cancelled = 0',
      [customerId],
    );
    final val = result.first['total'];
    return (val as int?) ?? 0;
  }

  // Calculate pending dues in paise dynamically from database
  Future<int> getCustomerPendingDuePaise(String customerId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(pending_amount_paise) as total FROM bills WHERE customer_id = ? AND is_cancelled = 0',
      [customerId],
    );
    final val = result.first['total'];
    return (val as int?) ?? 0;
  }
}
