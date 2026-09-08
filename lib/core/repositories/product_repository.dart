import 'package:sqflite/sqflite.dart';
import '../database/local_database.dart';
import '../models/product_model.dart';
import '../models/stock_movement_model.dart';
import '../services/sync_service.dart';

class ProductRepository {
  final LocalDatabase _dbHelper = LocalDatabase.instance;

  Future<List<Product>> getProducts({
    String? searchQuery,
    String? categoryId,
    String? stockFilter, // 'all', 'in_stock', 'low_stock', 'out_of_stock'
  }) async {
    final db = await _dbHelper.database;

    String whereClause = 'is_active = 1';
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim().toLowerCase()}%';
      whereClause += ' AND (LOWER(name) LIKE ? OR LOWER(category_name) LIKE ? OR LOWER(COALESCE(brand, "")) LIKE ?)';
      whereArgs.addAll([q, q, q]);
    }

    if (categoryId != null && categoryId != 'all' && categoryId.isNotEmpty) {
      whereClause += ' AND category_id = ?';
      whereArgs.add(categoryId);
    }

    final maps = await db.query(
      'products',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    var products = maps.map((m) => Product.fromMap(m)).toList();

    if (stockFilter != null && stockFilter != 'all') {
      if (stockFilter == 'in_stock') {
        products = products.where((p) => p.isInStock).toList();
      } else if (stockFilter == 'low_stock') {
        products = products.where((p) => p.isLowStock).toList();
      } else if (stockFilter == 'out_of_stock') {
        products = products.where((p) => p.isOutOfStock).toList();
      }
    }

    return products;
  }

  Future<Product?> getProductById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'products',
      where: 'id = ? AND is_active = 1',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<Product> addProduct(Product product) async {
    final db = await _dbHelper.database;
    await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await SyncService.instance.enqueueChange(
      shopId: 'local_shop',
      tableName: 'products',
      recordId: product.id,
      action: 'INSERT',
      payload: product.toMap(),
    );
    return product;
  }

  Future<void> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    final updated = product.copyWith(updatedAt: DateTime.now());
    await db.update(
      'products',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
    await SyncService.instance.enqueueChange(
      shopId: 'local_shop',
      tableName: 'products',
      recordId: product.id,
      action: 'UPDATE',
      payload: updated.toMap(),
    );
  }

  Future<void> softDeleteProduct(String id) async {
    final db = await _dbHelper.database;
    final nowStr = DateTime.now().toIso8601String();
    await db.update(
      'products',
      {
        'is_active': 0,
        'updated_at': nowStr,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    final product = await getProductById(id);
    if (product != null) {
      await SyncService.instance.enqueueChange(
        shopId: 'local_shop',
        tableName: 'products',
        recordId: id,
        action: 'UPDATE',
        payload: product.toMap(),
      );
    }
  }

  Future<StockMovement> restockProduct({
    required String productId,
    required double addQuantity,
    required int purchasePricePaise,
    String? supplier,
    String? notes,
  }) async {
    final db = await _dbHelper.database;
    final product = await getProductById(productId);
    if (product == null) throw Exception("Product not found");

    final previousQty = product.quantity;
    final newQty = previousQty + addQuantity;
    final now = DateTime.now();

    final movement = StockMovement(
      id: 'sm_${now.millisecondsSinceEpoch}',
      productId: product.id,
      productName: product.name,
      previousQuantity: previousQty,
      quantityChange: addQuantity,
      newQuantity: newQty,
      purchasePricePaise: purchasePricePaise,
      movementType: StockMovementType.restock,
      supplier: supplier,
      notes: notes,
      createdAt: now,
    );

    await db.transaction((txn) async {
      await txn.insert('stock_movements', movement.toMap());
      await txn.update(
        'products',
        {
          'quantity': newQty,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [productId],
      );
    });

    await SyncService.instance.enqueueChange(
      shopId: 'local_shop',
      tableName: 'stock_movements',
      recordId: movement.id,
      action: 'INSERT',
      payload: movement.toMap(),
    );

    return movement;
  }

  Future<StockMovement> adjustStock({
    required String productId,
    required double newQuantity,
    required String reason,
  }) async {
    final db = await _dbHelper.database;
    final product = await getProductById(productId);
    if (product == null) throw Exception("Product not found");

    final previousQty = product.quantity;
    final change = newQuantity - previousQty;
    final now = DateTime.now();

    final movement = StockMovement(
      id: 'sm_${now.millisecondsSinceEpoch}',
      productId: product.id,
      productName: product.name,
      previousQuantity: previousQty,
      quantityChange: change,
      newQuantity: newQuantity,
      purchasePricePaise: product.buyingPricePaise,
      movementType: StockMovementType.adjustment,
      reason: reason,
      createdAt: now,
    );

    await db.transaction((txn) async {
      await txn.insert('stock_movements', movement.toMap());
      await txn.update(
        'products',
        {
          'quantity': newQuantity,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [productId],
      );
    });

    await SyncService.instance.enqueueChange(
      shopId: 'local_shop',
      tableName: 'stock_movements',
      recordId: movement.id,
      action: 'INSERT',
      payload: movement.toMap(),
    );

    return movement;
  }

  Future<List<StockMovement>> getStockMovements(String productId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'stock_movements',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => StockMovement.fromMap(m)).toList();
  }

  Future<int> getLowStockCount() async {
    final products = await getProducts();
    return products.where((p) => p.isLowStock).length;
  }

  Future<int> getOutOfStockCount() async {
    final products = await getProducts();
    return products.where((p) => p.isOutOfStock).length;
  }
}
