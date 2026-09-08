import 'package:flutter_test/flutter_test.dart';
import 'package:shopzo/core/models/product_model.dart';

void main() {
  test('Product model status calculation test', () {
    final product = Product(
      id: 'prod_test',
      name: 'Test Rice',
      categoryId: 'cat_1',
      categoryName: 'Grocery',
      buyingPricePaise: 4000, // ₹40.00
      sellingPricePaise: 5000, // ₹50.00
      quantity: 4.0,
      unit: 'Kg',
      minStockLevel: 5.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    expect(product.buyingPrice, 40.00);
    expect(product.sellingPrice, 50.00);
    expect(product.isLowStock, true);
    expect(product.stockStatusText, 'Low Stock');
    expect(product.stockStatusBadgeType, 'warning');
  });
}
