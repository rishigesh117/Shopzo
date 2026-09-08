import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/theme_provider.dart';
import '../core/theme/shopzo_theme.dart';
import '../features/auth/login_screen.dart';
import 'main_shell.dart';

class ShopzoApp extends StatelessWidget {
  const ShopzoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return MaterialApp(
      title: 'Shopzo',
      debugShowCheckedModeBanner: false,
      theme: ShopzoTheme.lightTheme,
      darkTheme: ShopzoTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: authProvider.isLoggedIn ? const MainShell() : const LoginScreen(),
    );
  }
}
