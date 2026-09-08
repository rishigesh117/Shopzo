import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/shop_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/product_provider.dart';
import '../../core/providers/customer_provider.dart';
import '../../core/providers/billing_provider.dart';
import '../../core/providers/payment_provider.dart';
import '../../core/providers/return_provider.dart';
import '../../core/providers/report_provider.dart';
import '../../core/services/backup_service.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_card.dart';
import '../../core/widgets/shopzo_header.dart';
import '../../core/widgets/shopzo_logo.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _lowStockAlerts = true;
  bool _billingSound = true;
  bool _dailySalesSummary = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final shopProvider = Provider.of<ShopProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final shop = shopProvider.currentShop;
    final user = authProvider.currentUser;

    return Scaffold(
      body: Column(
        children: [
          const ShopzoHeader(
            title: 'Application Settings',
            subtitle: 'Shop profile, appearance, preferences, and info',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop Information Card
                  ShopzoCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: ShopzoColors.primaryNavy.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.storefront_rounded, size: 28, color: ShopzoColors.primaryNavy),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shop?.name ?? 'SuperMart Supermarket',
                                style: ShopzoTypography.headingSmall(context, isDark: isDark).copyWith(fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Shop Code: ${shop?.shopCode ?? "SHP-482913"} • Owner: ${shop?.ownerName ?? "Arun Kumar"}',
                                style: ShopzoTypography.bodySmall(context, isDark: isDark),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                shop?.address ?? '123 Main Bazaar Road',
                                style: ShopzoTypography.bodySmall(context, isDark: isDark),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // User Account Card
                  ShopzoCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: ShopzoColors.secondaryGreen.withOpacity(0.15),
                          child: Text(
                            (user?.name ?? 'Owner').substring(0, 1),
                            style: ShopzoTypography.headingSmall(context, isDark: isDark).copyWith(color: ShopzoColors.secondaryGreen),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'Owner / Administrator',
                                style: ShopzoTypography.headingSmall(context, isDark: isDark).copyWith(fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Phone: ${user?.phone ?? "+91 98765 43210"} • Role: Owner',
                                style: ShopzoTypography.bodySmall(context, isDark: isDark),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Appearance Settings
                  Text('Appearance & Theme', style: ShopzoTypography.headingMedium(context, isDark: isDark)),
                  const SizedBox(height: 12),
                  ShopzoCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        RadioListTile<ThemeMode>(
                          title: Text('Light Theme', style: ShopzoTypography.bodyLarge(context, isDark: isDark)),
                          subtitle: Text('Clean, bright interface', style: ShopzoTypography.bodySmall(context, isDark: isDark)),
                          value: ThemeMode.light,
                          groupValue: themeProvider.themeMode,
                          activeColor: ShopzoColors.secondaryGreen,
                          onChanged: (mode) => themeProvider.setThemeMode(mode!),
                        ),
                        const Divider(height: 1),
                        RadioListTile<ThemeMode>(
                          title: Text('Dark Theme', style: ShopzoTypography.bodyLarge(context, isDark: isDark)),
                          subtitle: Text('Comfortable dark surface', style: ShopzoTypography.bodySmall(context, isDark: isDark)),
                          value: ThemeMode.dark,
                          groupValue: themeProvider.themeMode,
                          activeColor: ShopzoColors.secondaryGreen,
                          onChanged: (mode) => themeProvider.setThemeMode(mode!),
                        ),
                        const Divider(height: 1),
                        RadioListTile<ThemeMode>(
                          title: Text('System Default', style: ShopzoTypography.bodyLarge(context, isDark: isDark)),
                          subtitle: Text('Follow device theme settings', style: ShopzoTypography.bodySmall(context, isDark: isDark)),
                          value: ThemeMode.system,
                          groupValue: themeProvider.themeMode,
                          activeColor: ShopzoColors.secondaryGreen,
                          onChanged: (mode) => themeProvider.setThemeMode(mode!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Notification Preferences
                  Text('Notification Preferences', style: ShopzoTypography.headingMedium(context, isDark: isDark)),
                  const SizedBox(height: 12),
                  ShopzoCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text('Low Stock Alerts', style: ShopzoTypography.bodyLarge(context, isDark: isDark)),
                          subtitle: Text('Notify when items reach minimum threshold', style: ShopzoTypography.bodySmall(context, isDark: isDark)),
                          value: _lowStockAlerts,
                          activeColor: ShopzoColors.secondaryGreen,
                          onChanged: (val) => setState(() => _lowStockAlerts = val),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: Text('Billing Sound Effects', style: ShopzoTypography.bodyLarge(context, isDark: isDark)),
                          subtitle: Text('Play audio sound on checkout success', style: ShopzoTypography.bodySmall(context, isDark: isDark)),
                          value: _billingSound,
                          activeColor: ShopzoColors.secondaryGreen,
                          onChanged: (val) => setState(() => _billingSound = val),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: Text('Daily Sales Summary', style: ShopzoTypography.bodyLarge(context, isDark: isDark)),
                          subtitle: Text('Receive daily closing sales report', style: ShopzoTypography.bodySmall(context, isDark: isDark)),
                          value: _dailySalesSummary,
                          activeColor: ShopzoColors.secondaryGreen,
                          onChanged: (val) => setState(() => _dailySalesSummary = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Database Backup & Recovery Card
                  Text('Database Backup & Data Recovery', style: ShopzoTypography.headingMedium(context, isDark: isDark)),
                  const SizedBox(height: 12),
                  ShopzoCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.backup_rounded, color: ShopzoColors.secondaryGreen, size: 24),
                            const SizedBox(width: 12),
                            Text('Local SQLite Database Backup', style: ShopzoTypography.headingSmall(context, isDark: isDark)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create instant JSON backups of all local products, customers, sales bills, payments, and returns. Store them safely on your device.',
                          style: ShopzoTypography.bodySmall(context, isDark: isDark),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ShopzoColors.secondaryGreen,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.download_rounded, size: 18),
                              label: const Text('Export Backup Now'),
                              onPressed: () async {
                                final backupService = BackupService();
                                try {
                                  final file = await backupService.exportBackup();
                                  if (context.mounted) {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.green),
                                            SizedBox(width: 8),
                                            Text('Backup Created'),
                                          ],
                                        ),
                                        content: Text('Database backup exported successfully!\n\nLocation:\n${file.path}'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Backup export failed: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.restore_rounded, size: 18),
                              label: const Text('Restore Backup'),
                              onPressed: () async {
                                final backupService = BackupService();
                                final files = await backupService.getBackupFiles();
                                if (!context.mounted) return;

                                if (files.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('No local backup files found. Create a backup first.')),
                                  );
                                  return;
                                }

                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Select Backup File to Restore'),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: files.length,
                                        itemBuilder: (context, index) {
                                          final file = files[index];
                                          final fileName = file.toString().split(RegExp(r'[/\\]')).last;
                                          return ListTile(
                                            leading: const Icon(Icons.description_outlined),
                                            title: Text(fileName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                            subtitle: const Text('Local Backup File'),
                                            onTap: () async {
                                              Navigator.pop(ctx);
                                              // Confirm Safety Modal
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (c) => AlertDialog(
                                                  title: const Row(
                                                    children: [
                                                      Icon(Icons.warning, color: Colors.orange),
                                                      SizedBox(width: 8),
                                                      Text('Confirm Database Restore'),
                                                    ],
                                                  ),
                                                  content: const Text(
                                                    'Restoring this backup will replace all local data in SQLite.\nAre you sure you want to proceed?',
                                                  ),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                                      onPressed: () => Navigator.pop(c, true),
                                                      child: const Text('Yes, Restore Data'),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirm == true && context.mounted) {
                                                try {
                                                  final jsonStr = await file.readAsString();
                                                  await backupService.restoreBackupFromContent(jsonStr);

                                                  // Refresh providers
                                                  if (context.mounted) {
                                                    context.read<ProductProvider>().loadProducts();
                                                    context.read<CustomerProvider>().loadCustomers();
                                                    context.read<BillingProvider>().clearCart();
                                                    context.read<PaymentProvider>().loadPayments();
                                                    context.read<ReturnProvider>().loadReturns();
                                                    context.read<ReportProvider>().loadAllReports();

                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Database restored successfully! All data updated.'), backgroundColor: Colors.green),
                                                    );
                                                  }
                                                } catch (err) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Restore failed: $err'), backgroundColor: Colors.red),
                                                    );
                                                  }
                                                }
                                              }
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // About Shopzo Card
                  ShopzoCard(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          const ShopzoLogo(iconSize: 40, showTagline: true),
                          const SizedBox(height: 12),
                          Text(
                            'Version 1.0.0 (Phase 1 UI Foundation)',
                            style: ShopzoTypography.bodySmall(context, isDark: isDark),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Offline-First Supermarket Management Application',
                            style: ShopzoTypography.bodySmall(context, isDark: isDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
