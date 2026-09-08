import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoggedIn = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  void mockLogin(String phoneNumber) {
    _currentUser = User(
      id: 'usr_001',
      name: 'Owner / Admin',
      phone: phoneNumber,
      role: UserRole.owner,
      shopId: 'shp_482913',
    );
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
