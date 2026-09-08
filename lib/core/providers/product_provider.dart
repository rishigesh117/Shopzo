import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/stock_movement_model.dart';
import '../repositories/category_repository.dart';
import '../repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _productRepo = ProductRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();

  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = false;

  String _searchQuery = '';
  String _selectedCategoryId = 'all';
  String _selectedStockFilter = 'all'; // 'all', 'in_stock', 'low_stock', 'out_of_stock'

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  String get searchQuery => _searchQuery;
  String get selectedCategoryId => _selectedCategoryId;
  String get selectedStockFilter => _selectedStockFilter;

  int get totalProductCount => _products.length;
  int get lowStockCount => _products.where((p) => p.isLowStock).length;
  int get outOfStockCount => _products.where((p) => p.isOutOfStock).length;
  List<Product> get lowStockProducts => _products.where((p) => p.isLowStock || p.isOutOfStock).toList();

  ProductProvider() {
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await loadCategories();
    await loadProducts();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _categories = await _categoryRepo.getAllCategories();
    notifyListeners();
  }

  Future<void> loadProducts() async {
    _products = await _productRepo.getProducts(
      searchQuery: _searchQuery,
      categoryId: _selectedCategoryId,
      stockFilter: _selectedStockFilter,
    );
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadProducts();
  }

  void setCategoryFilter(String categoryId) {
    _selectedCategoryId = categoryId;
    loadProducts();
  }

  void setStockFilter(String filter) {
    _selectedStockFilter = filter;
    loadProducts();
  }

  Future<void> addProduct(Product product) async {
    await _productRepo.addProduct(product);
    await loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    await _productRepo.updateProduct(product);
    await loadProducts();
  }

  Future<void> deleteProduct(String id) async {
    await _productRepo.softDeleteProduct(id);
    await loadProducts();
  }

  Future<StockMovement> restockProduct({
    required String productId,
    required double addQuantity,
    required int purchasePricePaise,
    String? supplier,
    String? notes,
  }) async {
    final movement = await _productRepo.restockProduct(
      productId: productId,
      addQuantity: addQuantity,
      purchasePricePaise: purchasePricePaise,
      supplier: supplier,
      notes: notes,
    );
    await loadProducts();
    return movement;
  }

  Future<StockMovement> adjustStock({
    required String productId,
    required double newQuantity,
    required String reason,
  }) async {
    final movement = await _productRepo.adjustStock(
      productId: productId,
      newQuantity: newQuantity,
      reason: reason,
    );
    await loadProducts();
    return movement;
  }

  Future<List<StockMovement>> getStockMovements(String productId) async {
    return await _productRepo.getStockMovements(productId);
  }

  Future<Category> addCategory(String name) async {
    final cat = await _categoryRepo.addCategory(name);
    await loadCategories();
    return cat;
  }

  Future<void> renameCategory(String id, String newName) async {
    await _categoryRepo.renameCategory(id, newName);
    await loadCategories();
    await loadProducts();
  }

  Future<bool> deleteCategory(String id) async {
    final success = await _categoryRepo.deleteCategory(id);
    if (success) {
      await loadCategories();
      if (_selectedCategoryId == id) {
        _selectedCategoryId = 'all';
      }
      await loadProducts();
    }
    return success;
  }
}
