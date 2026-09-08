import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/product_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_button.dart';
import '../../core/widgets/shopzo_card.dart';
import '../../core/widgets/shopzo_text_field.dart';

class CategoriesManagementDialog extends StatefulWidget {
  const CategoriesManagementDialog({super.key});

  @override
  State<CategoriesManagementDialog> createState() => _CategoriesManagementDialogState();
}

class _CategoriesManagementDialogState extends State<CategoriesManagementDialog> {
  final _addCategoryController = TextEditingController();
  bool _isAdding = false;
  String? _errorMessage;

  @override
  void dispose() {
    _addCategoryController.dispose();
    super.dispose();
  }

  void _handleAddCategory() async {
    final name = _addCategoryController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isAdding = true;
      _errorMessage = null;
    });

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.addCategory(name);

    _addCategoryController.clear();
    setState(() {
      _isAdding = false;
    });
  }

  void _showRenameDialog(String id, String currentName) {
    final controller = TextEditingController(text: currentName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
        title: Text('Rename Category', style: ShopzoTypography.headingMedium(ctx, isDark: isDark)),
        content: ShopzoTextField(
          label: 'Category Name',
          controller: controller,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ShopzoButton(
            text: 'Save',
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                final productProvider = Provider.of<ProductProvider>(context, listen: false);
                await productProvider.renameCategory(id, newName);
              }
              if (mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _handleDeleteCategory(String id, String name) async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final success = await productProvider.deleteCategory(id);
    if (!success && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
          title: Text('Cannot Delete Category', style: ShopzoTypography.headingMedium(ctx, isDark: isDark)),
          content: Text(
            'Cannot delete "$name" because products are currently assigned to this category. Please reassign or remove the products first.',
            style: ShopzoTypography.bodyMedium(ctx, isDark: isDark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productProvider = Provider.of<ProductProvider>(context);
    final categories = productProvider.categories;

    return Dialog(
      backgroundColor: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Manage Categories',
                  style: ShopzoTypography.headingMedium(context, isDark: isDark),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Add Category input
            Row(
              children: [
                Expanded(
                  child: ShopzoTextField(
                    label: 'New Category',
                    hint: 'e.g. Organic Grains',
                    controller: _addCategoryController,
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: ShopzoButton(
                    text: '+ Add',
                    isLoading: _isAdding,
                    onPressed: _handleAddCategory,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Categories (${categories.length})',
              style: ShopzoTypography.bodySmall(context, isDark: isDark).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: categories.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final cat = categories[i];
                  return ShopzoCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.category_rounded,
                              size: 18,
                              color: ShopzoColors.secondaryGreen,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              cat.name,
                              style: ShopzoTypography.bodyLarge(context, isDark: isDark).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (cat.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? ShopzoColors.darkSurfaceSecondary : ShopzoColors.lightSurfaceSecondary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Default',
                                  style: ShopzoTypography.bodySmall(context, isDark: isDark).copyWith(
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, size: 18),
                              onPressed: () => _showRenameDialog(cat.id, cat.name),
                            ),
                            if (!cat.isDefault)
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: ShopzoColors.danger),
                                onPressed: () => _handleDeleteCategory(cat.id, cat.name),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
