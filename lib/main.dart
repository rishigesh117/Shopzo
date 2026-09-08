import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/shopzo_app.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/billing_provider.dart';
import 'core/providers/customer_provider.dart';
import 'core/providers/member_provider.dart';
import 'core/providers/navigation_provider.dart';
import 'core/providers/payment_provider.dart';
import 'core/providers/product_provider.dart';
import 'core/providers/report_provider.dart';
import 'core/providers/return_provider.dart';
import 'core/providers/shop_provider.dart';
import 'core/providers/sync_provider.dart';
import 'core/providers/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => MemberProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => BillingProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => ReturnProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
      ],
      child: const ShopzoApp(),
    ),
  );
}
