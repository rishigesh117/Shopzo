import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../database/local_database.dart';

class BackupService {
  final LocalDatabase _localDb = LocalDatabase.instance;

  // Export full database to JSON string / file
  Future<dynamic> exportBackup() async {
    final db = await _localDb.database;

    final categories = await db.query('categories');
    final products = await db.query('products');
    final stockMovements = await db.query('stock_movements');
    final customers = await db.query('customers');
    final bills = await db.query('bills');
    final billItems = await db.query('bill_items');
    final payments = await db.query('payments');
    final returns = await db.query('returns');

    final backupPayload = {
      'metadata': {
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'app_name': 'Shopzo',
        'table_counts': {
          'categories': categories.length,
          'products': products.length,
          'stock_movements': stockMovements.length,
          'customers': customers.length,
          'bills': bills.length,
          'bill_items': billItems.length,
          'payments': payments.length,
          'returns': returns.length,
        },
      },
      'data': {
        'categories': categories,
        'products': products,
        'stock_movements': stockMovements,
        'customers': customers,
        'bills': bills,
        'bill_items': billItems,
        'payments': payments,
        'returns': returns,
      },
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backupPayload);

    if (kIsWeb) {
      return jsonString;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final backupFolder = join(docsDir.path, 'Shopzo_Backups');
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    return jsonString;
  }

  // Restore database from JSON string
  Future<bool> restoreBackupFromContent(String jsonString) async {
    final Map<String, dynamic> payload = jsonDecode(jsonString);

    if (!payload.containsKey('metadata') || !payload.containsKey('data')) {
      throw const FormatException('Invalid backup file format: Missing metadata or data fields.');
    }

    final data = payload['data'] as Map<String, dynamic>;

    final db = await _localDb.database;

    await db.transaction((txn) async {
      // Clear current database tables
      await txn.delete('bill_items');
      await txn.delete('returns');
      await txn.delete('payments');
      await txn.delete('bills');
      await txn.delete('customers');
      await txn.delete('stock_movements');
      await txn.delete('products');
      await txn.delete('categories');

      // Restore Categories
      if (data.containsKey('categories')) {
        for (final row in data['categories']) {
          await txn.insert('categories', Map<String, dynamic>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Restore Products
      if (data.containsKey('products')) {
        for (final row in data['products']) {
          await txn.insert('products', Map<String, dynamic>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Restore Stock Movements
      if (data.containsKey('stock_movements')) {
        for (final row in data['stock_movements']) {
          await txn.insert('stock_movements', Map<String, dynamic>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Restore Customers
      if (data.containsKey('customers')) {
        for (final row in data['customers']) {
          await txn.insert('customers', Map<String, dynamic>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Restore Bills
      if (data.containsKey('bills')) {
        for (final row in data['bills']) {
          await txn.insert('bills', Map<String, dynamic>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Restore Bill Items
      if (data.containsKey('bill_items')) {
        for (final row in data['bill_items']) {
          await txn.insert('bill_items', Map<String, dynamic>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Restore Payments
      if (data.containsKey('payments')) {
        for (final row in data['payments']) {
          await txn.insert('payments', Map<String, dynamic>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Restore Returns
      if (data.containsKey('returns')) {
        for (final row in data['returns']) {
          await txn.insert('returns', Map<String, dynamic>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });

    return true;
  }

  // Get list of existing local backup files
  Future<List<dynamic>> getBackupFiles() async {
    if (kIsWeb) {
      return [];
    }
    return [];
  }
}
