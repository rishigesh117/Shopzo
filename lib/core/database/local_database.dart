import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('shopzo_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String path;
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      path = filePath;
    } else {
      // Initialize FFI for Windows / Desktop
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final dbFolder = await getApplicationDocumentsDirectory();
      path = join(dbFolder.path, filePath);
    }

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 2. Products Table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category_id TEXT NOT NULL,
        category_name TEXT NOT NULL,
        brand TEXT,
        buying_price_paise INTEGER NOT NULL,
        selling_price_paise INTEGER NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        min_stock_level REAL NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 3. Stock Movements Table
    await db.execute('''
      CREATE TABLE stock_movements (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        previous_quantity REAL NOT NULL,
        quantity_change REAL NOT NULL,
        new_quantity REAL NOT NULL,
        purchase_price_paise INTEGER NOT NULL DEFAULT 0,
        movement_type TEXT NOT NULL,
        reason TEXT,
        supplier TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Phase 3 & 4 Tables
    await _createPhase3Tables(db);
    await _createPhase4Tables(db);

    // Seed Default Categories
    final now = DateTime.now().toIso8601String();
    final defaultCategories = [
      'Grocery',
      'Beverages',
      'Snacks',
      'Dairy',
      'Personal Care',
      'Household',
      'Stationery',
      'Fruits & Vegetables',
      'Cosmetics',
      'Others',
    ];

    for (int i = 0; i < defaultCategories.length; i++) {
      await db.insert('categories', {
        'id': 'cat_${i + 1}',
        'name': defaultCategories[i],
        'is_default': 1,
        'created_at': now,
        'updated_at': now,
      });
    }

    // Seed Demo Products
    final seedProducts = [
      {
        'id': 'prod_1',
        'name': 'Basmati Rice',
        'category_id': 'cat_1',
        'category_name': 'Grocery',
        'brand': 'India Gate',
        'buying_price_paise': 4500, // ₹45.00
        'selling_price_paise': 5200, // ₹52.00
        'quantity': 18.0,
        'unit': 'Kg',
        'min_stock_level': 5.0,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'prod_2',
        'name': 'Refined Sugar',
        'category_id': 'cat_1',
        'category_name': 'Grocery',
        'brand': 'Madhur',
        'buying_price_paise': 3800, // ₹38.00
        'selling_price_paise': 4200, // ₹42.00
        'quantity': 2.0, // Low stock
        'unit': 'Kg',
        'min_stock_level': 5.0,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'prod_3',
        'name': 'Toned Milk',
        'category_id': 'cat_4',
        'category_name': 'Dairy',
        'brand': 'Amul',
        'buying_price_paise': 2400, // ₹24.00
        'selling_price_paise': 2800, // ₹28.00
        'quantity': 3.0, // Low stock
        'unit': 'Packet',
        'min_stock_level': 10.0,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'prod_4',
        'name': 'Wheat Flour (Atta)',
        'category_id': 'cat_1',
        'category_name': 'Grocery',
        'brand': 'Aashirvaad',
        'buying_price_paise': 3200, // ₹32.00
        'selling_price_paise': 3800, // ₹38.00
        'quantity': 5.0, // Low stock
        'unit': 'Kg',
        'min_stock_level': 8.0,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'prod_5',
        'name': 'Sunflower Oil',
        'category_id': 'cat_1',
        'category_name': 'Grocery',
        'brand': 'Fortune',
        'buying_price_paise': 11000, // ₹110.00
        'selling_price_paise': 12500, // ₹125.00
        'quantity': 0.0, // Out of stock
        'unit': 'Litre',
        'min_stock_level': 5.0,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      },
    ];

    for (var prod in seedProducts) {
      await db.insert('products', prod);
    }

    // Seed Demo Customers
    final seedCustomers = [
      {
        'id': 'cust_1',
        'name': 'Arun Kumar',
        'phone': '9876543210',
        'address': 'MG Road, Sector 4, City',
        'is_deleted': 0,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'cust_2',
        'name': 'Priya Sharma',
        'phone': '9812345678',
        'address': 'Green Park, Block B, City',
        'is_deleted': 0,
        'created_at': now,
        'updated_at': now,
      },
    ];

    for (var cust in seedCustomers) {
      await db.insert('customers', cust);
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createPhase3Tables(db);
    }
    if (oldVersion < 3) {
      await _createPhase4Tables(db);
    }
  }

  Future<void> _createPhase3Tables(Database db) async {
    // 4. Customers Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 5. Bills Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bills (
        id TEXT PRIMARY KEY,
        bill_number TEXT NOT NULL UNIQUE,
        customer_id TEXT,
        customer_name_snapshot TEXT,
        customer_phone_snapshot TEXT,
        subtotal_paise INTEGER NOT NULL,
        total_amount_paise INTEGER NOT NULL,
        amount_received_paise INTEGER NOT NULL,
        change_amount_paise INTEGER NOT NULL,
        pending_amount_paise INTEGER NOT NULL,
        payment_status TEXT NOT NULL,
        is_cancelled INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 6. Bill Items Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bill_items (
        id TEXT PRIMARY KEY,
        bill_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name_snapshot TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        selling_price_paise INTEGER NOT NULL,
        buying_price_paise INTEGER NOT NULL,
        line_total_paise INTEGER NOT NULL,
        profit_paise INTEGER NOT NULL,
        FOREIGN KEY (bill_id) REFERENCES bills (id) ON DELETE CASCADE
      )
    ''');

    // 7. Payments Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id TEXT PRIMARY KEY,
        customer_id TEXT,
        bill_id TEXT,
        amount_paise INTEGER NOT NULL,
        payment_method TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 8. Returns Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS returns (
        id TEXT PRIMARY KEY,
        bill_id TEXT NOT NULL,
        customer_id TEXT,
        product_id TEXT NOT NULL,
        product_name_snapshot TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        refund_amount_paise INTEGER NOT NULL,
        reason TEXT NOT NULL,
        status TEXT NOT NULL,
        stock_action TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Indexes for high performance queries
    await db.execute('CREATE INDEX IF NOT EXISTS idx_bills_customer ON bills(customer_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_bill_items_bill ON bill_items(bill_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_payments_customer ON payments(customer_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_payments_bill ON payments(bill_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_returns_bill ON returns(bill_id)');
  }

  Future<void> _createPhase4Tables(Database db) async {
    // 9. Sync Metadata
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_metadata (
        id TEXT PRIMARY KEY,
        shop_id TEXT,
        user_id TEXT,
        last_synced_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'OFFLINE',
        last_error TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 10. Sync Queue
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        action TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'PENDING',
        retry_count INTEGER NOT NULL DEFAULT 0,
        error_message TEXT
      )
    ''');

    // 11. Sync Conflicts
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_conflicts (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        local_payload_json TEXT,
        server_payload_json TEXT,
        resolution_strategy TEXT,
        resolved_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON sync_queue(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_queue_shop ON sync_queue(shop_id)');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
