import 'package:flutter/material.dart';
import '../models/shop_model.dart';

class ShopProvider extends ChangeNotifier {
  Shop? _currentShop;
  bool _hasShop = false;
  String _mockCode = 'SHP-482913';

  Shop? get currentShop => _currentShop;
  bool get hasShop => _hasShop;
  String get mockCode => _mockCode;

  void createShop({
    required String name,
    required String ownerName,
    required String phone,
    required String address,
    String? logoUrl,
  }) {
    _currentShop = Shop(
      id: 'shp_001',
      name: name.isEmpty ? 'SuperMart Supermarket' : name,
      ownerName: ownerName.isEmpty ? 'Arun Kumar' : ownerName,
      phone: phone.isEmpty ? '+91 98765 43210' : phone,
      address: address.isEmpty ? '123 Main Bazaar Road, Central City' : address,
      shopCode: _mockCode,
      logoUrl: logoUrl,
      createdAt: DateTime.now(),
    );
    _hasShop = true;
    notifyListeners();
  }

  void joinShop(String code) {
    _mockCode = code;
    _currentShop = Shop(
      id: 'shp_002',
      name: 'Central Supermarket',
      ownerName: 'Rajesh Sharma',
      phone: '+91 98123 45678',
      address: '45 Commercial Street',
      shopCode: code,
      createdAt: DateTime.now(),
    );
    _hasShop = true;
    notifyListeners();
  }

  void setMockShop() {
    if (_currentShop == null) {
      createShop(
        name: 'SuperMart Supermarket',
        ownerName: 'Arun Kumar',
        phone: '+91 98765 43210',
        address: '123 Main Bazaar Road, Central City',
      );
    }
  }
}
