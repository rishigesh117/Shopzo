import 'package:flutter/material.dart';
import '../../core/models/permission_model.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_button.dart';
import '../../core/widgets/shopzo_card.dart';
import '../../core/widgets/shopzo_permission_switch.dart';

class PermissionSelectionScreen extends StatefulWidget {
  final ShopzoPermissions initialPermissions;
  final String memberName;
  final ValueChanged<ShopzoPermissions> onSave;

  const PermissionSelectionScreen({
    super.key,
    required this.initialPermissions,
    required this.memberName,
    required this.onSave,
  });

  @override
  State<PermissionSelectionScreen> createState() => _PermissionSelectionScreenState();
}

class _PermissionSelectionScreenState extends State<PermissionSelectionScreen> {
  late bool _isFullAccess;
  late ShopzoPermissions _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = widget.initialPermissions;
    _isFullAccess = widget.initialPermissions.isFullAccess;
  }

  void _toggleFullAccess(bool full) {
    setState(() {
      _isFullAccess = full;
      if (full) {
        _permissions = ShopzoPermissions.fullAccess();
      } else {
        _permissions = ShopzoPermissions.standardStaff();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Permissions - ${widget.memberName}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShopzoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Access Level',
                      style: ShopzoTypography.headingMedium(context, isDark: isDark),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _toggleFullAccess(true),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _isFullAccess
                                    ? ShopzoColors.primaryNavy.withOpacity(0.12)
                                    : (isDark ? ShopzoColors.darkSurfaceSecondary : ShopzoColors.lightSurfaceSecondary),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isFullAccess ? ShopzoColors.primaryNavy : (isDark ? ShopzoColors.darkBorder : ShopzoColors.lightBorder),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.admin_panel_settings_rounded,
                                    color: _isFullAccess ? ShopzoColors.primaryNavy : (isDark ? ShopzoColors.darkTextMuted : ShopzoColors.lightTextMuted),
                                    size: 28,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Full Access',
                                    style: ShopzoTypography.headingSmall(context, isDark: isDark).copyWith(
                                      color: _isFullAccess ? ShopzoColors.primaryNavy : (isDark ? ShopzoColors.darkTextPrimary : ShopzoColors.lightTextPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _toggleFullAccess(false),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: !_isFullAccess
                                    ? ShopzoColors.secondaryGreen.withOpacity(0.12)
                                    : (isDark ? ShopzoColors.darkSurfaceSecondary : ShopzoColors.lightSurfaceSecondary),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: !_isFullAccess ? ShopzoColors.secondaryGreen : (isDark ? ShopzoColors.darkBorder : ShopzoColors.lightBorder),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    color: !_isFullAccess ? ShopzoColors.secondaryGreen : (isDark ? ShopzoColors.darkTextMuted : ShopzoColors.lightTextMuted),
                                    size: 28,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Custom',
                                    style: ShopzoTypography.headingSmall(context, isDark: isDark).copyWith(
                                      color: !_isFullAccess ? ShopzoColors.secondaryGreen : (isDark ? ShopzoColors.darkTextPrimary : ShopzoColors.lightTextPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ShopzoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Detailed Permissions',
                          style: ShopzoTypography.headingMedium(context, isDark: isDark),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: ShopzoColors.secondaryGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_permissions.enabledCount} / 15 Enabled',
                            style: ShopzoTypography.bodySmall(context, isDark: isDark).copyWith(
                              color: ShopzoColors.secondaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 1. Create Bills
                    ShopzoPermissionSwitch(
                      title: 'Create Bills',
                      subtitle: 'Generate and print customer bills',
                      icon: Icons.receipt_long_rounded,
                      value: _permissions.createBills,
                      onChanged: _isFullAccess ? (v) {} : (v) => setState(() => _permissions = _permissions.copyWith(createBills: v)),
                    ),
                    const Divider(height: 1),
                    // 2. View Bills
                    ShopzoPermissionSwitch(
                      title: 'View Bills',
                      subtitle: 'Access recent and past billing history',
                      icon: Icons.article_rounded,
                      value: _permissions.viewBills,
                      onChanged: _isFullAccess ? (v) {} : (v) => setState(() => _permissions = _permissions.copyWith(viewBills: v)),
                    ),
                    const Divider(height: 1),
                    // 3. Add Products
                    ShopzoPermissionSwitch(
                      title: 'Add Products',
                      subtitle: 'Add new items to the inventory catalog',
                      icon: Icons.add_box_rounded,
                      value: _permissions.addProducts,
                      onChanged: _isFullAccess ? (v) {} : (v) => setState(() => _permissions = _permissions.copyWith(addProducts: v)),
                    ),
                    const Divider(height: 1),
                    // 4. Edit Products
                    ShopzoPermissionSwitch(
                      title: 'Edit Products',
                      subtitle: 'Modify product details and pricing',
                      icon: Icons.edit_rounded,
                      value: _permissions.editProducts,
                      onChanged: _isFullAccess ? (v) {} : (v) => setState(() => _permissions = _permissions.copyWith(editProducts: v)),
                    ),
                    const Divider(height: 1),
                    // 5. Delete Products
                    ShopzoPermissionSwitch(
                      title: 'Delete Products',
                      subtitle: 'Remove items from the inventory',
                      icon: Icons.delete_outline_rounded,
                      value: _permissions.deleteProducts,
                      onChanged: _isFullAccess ? (v) {} : (v) => setState(() => _permissions = _permissions.copyWith(deleteProducts: v)),
                    ),
                    const Divider(height: 1),
                    // 6. Update Stock
                    ShopzoPermissionSwitch(
                      title: 'Update Stock',
                      subtitle: 'Restock and adjust item quantities',
                      icon: Icons.inventory_2_rounded,
                      value: _permissions.updateStock,
                      onChanged: _isFullAccess ? (v) {} : (v) => setState(() => _permissions = _permissions.copyWith(updateStock: v)),
                    ),
                    const Divider(height: 1),
                    // 7. View Customers
                    ShopzoPermissionSwitch(
                      title: 'View Customers',
                      subtitle: 'Browse customer list and contact details',
                      icon: Icons.people_rounded,
                      value: _permissions.viewCustomers,
                      onChanged: _isFullAccess ? (v) {} : (v) => setState(() => _permissions = _permissions.copyWith(viewCustomers: v)),
                    ),
                    const Divider(height: 1),
                    // 8. Manage Customers
                    ShopzoPermissionSwitch(
                      title: 'Manage Customers',
                      subtitle: 'Add, edit, or remove customer profiles',
                      icon: Icons.person_add_rounded,
                      value: _permissions.manageCustomers,
                      onChanged: _isFullAccess ? (v) {} : (v) => setState(() => _permissions = _permissions.copyWith(manageCustomers: v)),
                    ),
                    const Divider(height: 1),
                    // 9. View Payments
                    ShopzoPermissionSwitch(
                      title: 'View Payments',
                      subtitle: 'See pending payments and credit accounts',
                      icon: Icons.payment_rounded,
                      value: _permissions.viewPayments,
                      onChanged: _isFullAccess ? (v) {} : (v) => setState(() => _permissions = _permissions.copyWith(viewPayments: v)),
                    ),
                    const Divider(height: 1),
                    // 10. Manage Payments
                    ShopzoPermissionSwitch(
                      title: 'Manage Payments',
                      subtitle: 'Record payments received and clear pending dues',
                      icon: Icons.account_balance_wallet_rounded,
                      value: _permissions.managePayments,
                      onChanged: _isFullAccess ? (v) {} : (v) => setState(() => _permissions = _permissions.copyWith(managePayments: v)),
                    ),
                    const Divider(height: 1),
                    // 11. Process Returns
                    ShopzoPermissionSwitch(
                      title: 'Process Returns',
                      subtitle: 'Accept product returns and update stock',
                      icon: Icons.assignment_return_rounded,
                      value: _permissions.processReturns,
                      onChanged: _isFullAccess ? (v) {} : (v) => setState(() => _permissions = _permissions.copyWith(processReturns: v)),
                    ),
                    const Divider(height: 1),
                    // 12. View Reports
                    ShopzoPermissionSwitch(
                      title: 'View Reports',
                      subtitle: 'Access sales analytics and business summaries',
                      icon: Icons.bar_chart_rounded,
                      value: _permissions.viewReports,
                      onChanged: _isFullAccess ? (v) {} : (v) => setState(() => _permissions = _permissions.copyWith(viewReports: v)),
                    ),
                    const Divider(height: 1),
                    // 13. View Profit
                    ShopzoPermissionSwitch(
                      title: 'View Profit',
                      subtitle: 'View profit margins and financial summaries',
                      icon: Icons.attach_money_rounded,
                      value: _permissions.viewProfit,
                      onChanged: _isFullAccess ? (v) {} : (v) => setState(() => _permissions = _permissions.copyWith(viewProfit: v)),
                    ),
                    const Divider(height: 1),
                    // 14. Manage Members
                    ShopzoPermissionSwitch(
                      title: 'Manage Members',
                      subtitle: 'Invite staff members and edit permissions',
                      icon: Icons.manage_accounts_rounded,
                      value: _permissions.manageMembers,
                      onChanged: _isFullAccess ? (v) {} : (v) => setState(() => _permissions = _permissions.copyWith(manageMembers: v)),
                    ),
                    const Divider(height: 1),
                    // 15. Shop Settings
                    ShopzoPermissionSwitch(
                      title: 'Shop Settings',
                      subtitle: 'Modify shop profile, info, and preferences',
                      icon: Icons.settings_rounded,
                      value: _permissions.shopSettings,
                      onChanged: _isFullAccess ? (v) {} : (v) => setState(() => _permissions = _permissions.copyWith(shopSettings: v)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ShopzoButton(
                text: 'Save Permissions',
                onPressed: () {
                  widget.onSave(_permissions);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
