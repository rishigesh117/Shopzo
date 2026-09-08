import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/navigation_provider.dart';
import '../core/providers/theme_provider.dart';
import '../core/theme/shopzo_colors.dart';
import '../core/theme/shopzo_typography.dart';
import '../core/widgets/shopzo_logo.dart';
import '../features/billing/new_bill_screen.dart';
import '../features/bills/bills_screen.dart';
import '../features/customers/customers_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/members/members_screen.dart';
import '../features/payments/payments_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/products/products_screen.dart';
import '../features/returns/returns_screen.dart';
import '../features/settings/settings_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 840;

    final pages = [
      const DashboardScreen(), // 0
      const BillsScreen(), // 1
      const ProductsScreen(), // 2
      const CustomersScreen(), // 3
      const PaymentsScreen(), // 4
      const ReturnsScreen(), // 5
      const ReportsScreen(), // 6
      const MembersScreen(), // 7
      const SettingsScreen(), // 8
    ];

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Desktop Sidebar Navigation
            Container(
              width: 250,
              decoration: BoxDecoration(
                color: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
                border: Border(
                  right: BorderSide(
                    color: isDark ? ShopzoColors.darkBorder : ShopzoColors.lightBorder,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  const ShopzoLogo(iconSize: 32, showTagline: true),
                  const SizedBox(height: 28),
                  // New Bill Quick Action Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ShopzoColors.secondaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                        label: const Text('New Bill', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NewBillScreen()),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      children: [
                        _SidebarTile(
                          icon: Icons.dashboard_rounded,
                          label: 'Dashboard',
                          isSelected: navProvider.selectedIndex == 0,
                          onTap: () => navProvider.setIndex(0),
                        ),
                        _SidebarTile(
                          icon: Icons.receipt_long_rounded,
                          label: 'Bills',
                          isSelected: navProvider.selectedIndex == 1,
                          onTap: () => navProvider.setIndex(1),
                        ),
                        _SidebarTile(
                          icon: Icons.inventory_2_rounded,
                          label: 'Products',
                          isSelected: navProvider.selectedIndex == 2,
                          onTap: () => navProvider.setIndex(2),
                        ),
                        _SidebarTile(
                          icon: Icons.people_rounded,
                          label: 'Customers',
                          isSelected: navProvider.selectedIndex == 3,
                          onTap: () => navProvider.setIndex(3),
                        ),
                        _SidebarTile(
                          icon: Icons.payment_rounded,
                          label: 'Payments',
                          isSelected: navProvider.selectedIndex == 4,
                          onTap: () => navProvider.setIndex(4),
                        ),
                        _SidebarTile(
                          icon: Icons.assignment_return_rounded,
                          label: 'Returns',
                          isSelected: navProvider.selectedIndex == 5,
                          onTap: () => navProvider.setIndex(5),
                        ),
                        _SidebarTile(
                          icon: Icons.bar_chart_rounded,
                          label: 'Reports',
                          isSelected: navProvider.selectedIndex == 6,
                          onTap: () => navProvider.setIndex(6),
                        ),
                        _SidebarTile(
                          icon: Icons.group_rounded,
                          label: 'Members',
                          isSelected: navProvider.selectedIndex == 7,
                          onTap: () => navProvider.setIndex(7),
                        ),
                        _SidebarTile(
                          icon: Icons.settings_rounded,
                          label: 'Settings',
                          isSelected: navProvider.selectedIndex == 8,
                          onTap: () => navProvider.setIndex(8),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('v1.0.0 Phase 3', style: ShopzoTypography.bodySmall(context, isDark: isDark)),
                        IconButton(
                          icon: Icon(
                            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            size: 20,
                          ),
                          onPressed: () => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content Area
            Expanded(
              child: IndexedStack(
                index: navProvider.selectedIndex,
                children: pages,
              ),
            ),
          ],
        ),
      );
    }

    // Mobile Navigation: Bottom Navigation Bar
    return Scaffold(
      body: IndexedStack(
        index: navProvider.selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark ? ShopzoColors.darkBorder : ShopzoColors.lightBorder,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: navProvider.selectedIndex > 3 ? 4 : navProvider.selectedIndex,
          onTap: (index) {
            if (index == 4) {
              _showMobileMoreMenu(context);
            } else {
              navProvider.setIndex(index);
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
          selectedItemColor: isDark ? ShopzoColors.secondaryGreen : ShopzoColors.primaryNavy,
          unselectedItemColor: isDark ? ShopzoColors.darkTextMuted : ShopzoColors.lightTextMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Bills'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: 'Products'),
            BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Customers'),
            BottomNavigationBarItem(icon: Icon(Icons.more_horiz_rounded), label: 'More'),
          ],
        ),
      ),
    );
  }

  void _showMobileMoreMenu(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? ShopzoColors.darkBorder : ShopzoColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.payment_rounded, color: ShopzoColors.warning),
                title: const Text('Payments & Ledger'),
                onTap: () {
                  Navigator.pop(ctx);
                  navProvider.setIndex(4);
                },
              ),
              ListTile(
                leading: const Icon(Icons.assignment_return_rounded, color: ShopzoColors.accentBlue),
                title: const Text('Returns'),
                onTap: () {
                  Navigator.pop(ctx);
                  navProvider.setIndex(5);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart_rounded, color: ShopzoColors.secondaryGreen),
                title: const Text('Reports'),
                onTap: () {
                  Navigator.pop(ctx);
                  navProvider.setIndex(6);
                },
              ),
              ListTile(
                leading: const Icon(Icons.group_rounded, color: ShopzoColors.primaryNavy),
                title: const Text('Members & Permissions'),
                onTap: () {
                  Navigator.pop(ctx);
                  navProvider.setIndex(7);
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_rounded),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(ctx);
                  navProvider.setIndex(8);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isSelected
        ? (isDark ? ShopzoColors.secondaryGreen.withOpacity(0.18) : ShopzoColors.primaryNavy.withOpacity(0.1))
        : Colors.transparent;

    final fg = isSelected
        ? (isDark ? ShopzoColors.secondaryGreen : ShopzoColors.primaryNavy)
        : (isDark ? ShopzoColors.darkTextSecondary : ShopzoColors.lightTextSecondary);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 14),
              Text(
                label,
                style: ShopzoTypography.bodyLarge(context, isDark: isDark).copyWith(
                  color: fg,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
