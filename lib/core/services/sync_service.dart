import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/local_database.dart';
import '../models/sync_queue_model.dart';
import 'api_service.dart';
import 'connectivity_service.dart';

class SyncService {
  static final SyncService instance = SyncService._internal();

  bool _isSyncing = false;

  SyncService._internal() {
    ConnectivityService.instance.addListener(_onConnectivityChanged);
  }

  bool get isSyncing => _isSyncing;

  void _onConnectivityChanged() {
    if (ConnectivityService.instance.isOnline && !_isSyncing) {
      syncNow();
    }
  }

  /// Enqueue a local database change for synchronization
  Future<void> enqueueChange({
    required String shopId,
    required String tableName,
    required String recordId,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    final db = await LocalDatabase.instance.database;
    final queueItem = SyncQueueItem(
      id: 'sq_${DateTime.now().microsecondsSinceEpoch}',
      shopId: shopId,
      tableName: tableName,
      recordId: recordId,
      action: action,
      payloadJson: jsonEncode(payload),
      createdAt: DateTime.now().toIso8601String(),
    );

    await db.insert('sync_queue', queueItem.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    if (ConnectivityService.instance.isOnline && !_isSyncing) {
      syncNow();
    }
  }

  /// Trigger two-way sync
  Future<bool> syncNow() async {
    if (_isSyncing) return false;
    if (!ConnectivityService.instance.isOnline) {
      ConnectivityService.instance.setStatusState(SyncStatusState.offline);
      return false;
    }

    _isSyncing = true;
    ConnectivityService.instance.setStatusState(SyncStatusState.syncing);

    try {
      final db = await LocalDatabase.instance.database;

      // 1. Push local changes
      final pendingRows = await db.query('sync_queue', where: 'status = ?', whereArgs: ['PENDING']);
      final queueItems = pendingRows.map((r) => SyncQueueItem.fromMap(r)).toList();

      if (queueItems.isNotEmpty) {
        final activeShopId = ApiService.instance.activeShopId ?? (queueItems.first.shopId);
        final operations = queueItems.map((item) => item.toApiJson()).toList();

        final response = await ApiService.instance.post(
          '/sync/push',
          body: {'operations': operations},
        );

        if (response.success) {
          // Remove processed items from local queue
          final processedIds = queueItems.map((i) => i.id).toList();
          for (final id in processedIds) {
            await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
          }
        } else {
          ConnectivityService.instance.setStatusState(SyncStatusState.error, error: response.error);
        }
      }

      // 2. Pull server changes
      final metaRows = await db.query('sync_metadata', where: 'id = ?', whereArgs: ['sync_meta']);
      String? lastSyncedAt;
      if (metaRows.isNotEmpty) {
        lastSyncedAt = metaRows.first['last_synced_at'] as String?;
      }

      final queryParams = lastSyncedAt != null ? {'lastSyncedAt': lastSyncedAt} : <String, String>{};
      final pullResponse = await ApiService.instance.get('/sync/pull', queryParams: queryParams);

      if (pullResponse.success && pullResponse.data != null) {
        final serverData = pullResponse.data['data'] as Map<String, dynamic>?;
        final serverTimestamp = pullResponse.data['serverTimestamp'] as String?;

        if (serverData != null) {
          await _applyServerData(db, serverData);
        }

        // Update metadata
        final now = DateTime.now().toIso8601String();
        await db.insert(
          'sync_metadata',
          {
            'id': 'sync_meta',
            'shop_id': ApiService.instance.activeShopId,
            'last_synced_at': serverTimestamp ?? now,
            'sync_status': 'SYNCED',
            'created_at': now,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        ConnectivityService.instance.setStatusState(SyncStatusState.synced);
      }

      _isSyncing = false;
      return true;
    } catch (e) {
      _isSyncing = false;
      ConnectivityService.instance.setStatusState(SyncStatusState.error, error: e.toString());
      return false;
    }
  }

  Future<void> _applyServerData(Database db, Map<String, dynamic> data) async {
    final categories = (data['categories'] as List?) ?? [];
    for (final c in categories) {
      await db.insert('categories', {
        'id': c['id'],
        'name': c['name'],
        'is_default': c['is_default'] == true ? 1 : 0,
        'created_at': c['created_at'] ?? DateTime.now().toIso8601String(),
        'updated_at': c['updated_at'] ?? DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    final products = (data['products'] as List?) ?? [];
    for (final p in products) {
      await db.insert('products', {
        'id': p['id'],
        'name': p['name'],
        'category_id': p['category_id'],
        'category_name': p['category_name'],
        'brand': p['brand'],
        'buying_price_paise': p['buying_price_paise'],
        'selling_price_paise': p['selling_price_paise'],
        'quantity': (p['quantity'] as num).toDouble(),
        'unit': p['unit'],
        'min_stock_level': (p['min_stock_level'] as num).toDouble(),
        'is_active': p['is_active'] == true ? 1 : 0,
        'created_at': p['created_at'] ?? DateTime.now().toIso8601String(),
        'updated_at': p['updated_at'] ?? DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    final stockMovements = (data['stockMovements'] as List?) ?? [];
    for (final sm in stockMovements) {
      await db.insert('stock_movements', {
        'id': sm['id'],
        'product_id': sm['product_id'],
        'product_name': sm['product_name'],
        'previous_quantity': (sm['previous_quantity'] as num).toDouble(),
        'quantity_change': (sm['quantity_change'] as num).toDouble(),
        'new_quantity': (sm['new_quantity'] as num).toDouble(),
        'purchase_price_paise': sm['purchase_price_paise'] ?? 0,
        'movement_type': sm['movement_type'],
        'reason': sm['reason'],
        'supplier': sm['supplier'],
        'notes': sm['notes'],
        'created_at': sm['created_at'] ?? DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    final customers = (data['customers'] as List?) ?? [];
    for (final cust in customers) {
      await db.insert('customers', {
        'id': cust['id'],
        'name': cust['name'],
        'phone': cust['phone'],
        'address': cust['address'],
        'is_deleted': cust['is_deleted'] == true ? 1 : 0,
        'created_at': cust['created_at'] ?? DateTime.now().toIso8601String(),
        'updated_at': cust['updated_at'] ?? DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    final bills = (data['bills'] as List?) ?? [];
    for (final b in bills) {
      await db.insert('bills', {
        'id': b['id'],
        'bill_number': b['bill_number'],
        'customer_id': b['customer_id'],
        'customer_name_snapshot': b['customer_name_snapshot'],
        'customer_phone_snapshot': b['customer_phone_snapshot'],
        'subtotal_paise': b['subtotal_paise'],
        'total_amount_paise': b['total_amount_paise'],
        'amount_received_paise': b['amount_received_paise'],
        'change_amount_paise': b['change_amount_paise'],
        'pending_amount_paise': b['pending_amount_paise'],
        'payment_status': b['payment_status'],
        'is_cancelled': b['is_cancelled'] == true ? 1 : 0,
        'created_at': b['created_at'] ?? DateTime.now().toIso8601String(),
        'updated_at': b['updated_at'] ?? DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    final billItems = (data['billItems'] as List?) ?? [];
    for (final bi in billItems) {
      await db.insert('bill_items', {
        'id': bi['id'],
        'bill_id': bi['bill_id'],
        'product_id': bi['product_id'],
        'product_name_snapshot': bi['product_name_snapshot'],
        'quantity': (bi['quantity'] as num).toDouble(),
        'unit': bi['unit'],
        'selling_price_paise': bi['selling_price_paise'],
        'buying_price_paise': bi['buying_price_paise'],
        'line_total_paise': bi['line_total_paise'],
        'profit_paise': bi['profit_paise'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    final payments = (data['payments'] as List?) ?? [];
    for (final pay in payments) {
      await db.insert('payments', {
        'id': pay['id'],
        'customer_id': pay['customer_id'],
        'bill_id': pay['bill_id'],
        'amount_paise': pay['amount_paise'],
        'payment_method': pay['payment_method'],
        'notes': pay['notes'],
        'created_at': pay['created_at'] ?? DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    final returnsList = (data['returns'] as List?) ?? [];
    for (final ret in returnsList) {
      await db.insert('returns', {
        'id': ret['id'],
        'bill_id': ret['bill_id'],
        'customer_id': ret['customer_id'],
        'product_id': ret['product_id'],
        'product_name_snapshot': ret['product_name_snapshot'],
        'quantity': (ret['quantity'] as num).toDouble(),
        'unit': ret['unit'],
        'refund_amount_paise': ret['refund_amount_paise'],
        'reason': ret['reason'],
        'status': ret['status'],
        'stock_action': ret['stock_action'],
        'created_at': ret['created_at'] ?? DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
}
