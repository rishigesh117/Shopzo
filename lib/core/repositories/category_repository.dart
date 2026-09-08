import 'package:sqflite/sqflite.dart';
import '../database/local_database.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final LocalDatabase _dbHelper = LocalDatabase.instance;

  Future<List<Category>> getAllCategories() async {
    final db = await _dbHelper.database;
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<Category> addCategory(String name) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final category = Category(
      id: 'cat_${now.millisecondsSinceEpoch}',
      name: name.trim(),
      isDefault: false,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return category;
  }

  Future<void> renameCategory(String id, String newName) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'categories',
      {
        'name': newName.trim(),
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    // Also update category_name in products table
    await db.update(
      'products',
      {
        'category_name': newName.trim(),
        'updated_at': now,
      },
      where: 'category_id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> canDeleteCategory(String id) async {
    final db = await _dbHelper.database;
    final countResult = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM products WHERE category_id = ? AND is_active = 1',
        [id],
      ),
    );
    return (countResult ?? 0) == 0;
  }

  Future<bool> deleteCategory(String id) async {
    final db = await _dbHelper.database;
    final canDelete = await canDeleteCategory(id);
    if (!canDelete) return false;

    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    return true;
  }
}
