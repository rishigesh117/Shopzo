import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/product_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_button.dart';
import '../../core/widgets/shopzo_card.dart';
import '../../core/widgets/shopzo_text_field.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _buyingPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minStockController = TextEditingController();

  String? _selectedCategoryId;
  String _selectedUnit = 'Kg';
  bool _isLoading = false;

  final List<String> _units = [
    'Piece',
    'Kg',
    'Gram',
    'Litre',
    'Ml',
    'Box',
    'Packet',
    'Dozen',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.name;
      _brandController.text = p.brand ?? '';
      _buyingPriceController.text = p.buyingPrice.toStringAsFixed(2);
      _sellingPriceController.text = p.sellingPrice.toStringAsFixed(2);
      _quantityController.text = p.quantity.toString();
      _minStockController.text = p.minStockLevel.toString();
      _selectedCategoryId = p.categoryId;
      _selectedUnit = p.unit;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _buyingPriceController.dispose();
    _sellingPriceController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: ShopzoColors.danger,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final category = productProvider.categories.firstWhere((c) => c.id == _selectedCategoryId);

    final buyingPrice = double.tryParse(_buyingPriceController.text.trim()) ?? 0.0;
    final sellingPrice = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
    final quantity = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    final minStock = double.tryParse(_minStockController.text.trim()) ?? 0.0;

    final buyingPaise = (buyingPrice * 100).round();
    final sellingPaise = (sellingPrice * 100).round();

    final now = DateTime.now();

    if (widget.product == null) {
      final newProd = Product(
        id: 'prod_${now.millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        categoryId: category.id,
        categoryName: category.name,
        brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        buyingPricePaise: buyingPaise,
        sellingPricePaise: sellingPaise,
        quantity: quantity,
        unit: _selectedUnit,
        minStockLevel: minStock,
        createdAt: now,
        updatedAt: now,
      );
      await productProvider.addProduct(newProd);
    } else {
      final updatedProd = widget.product!.copyWith(
        name: _nameController.text.trim(),
        categoryId: category.id,
        categoryName: category.name,
        brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        buyingPricePaise: buyingPaise,
        sellingPricePaise: sellingPaise,
        quantity: quantity,
        unit: _selectedUnit,
        minStockLevel: minStock,
        updatedAt: now,
      );
      await productProvider.updateProduct(updatedProd);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.product == null ? 'Product added successfully!' : 'Product updated!'),
          backgroundColor: ShopzoColors.secondaryGreen,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productProvider = Provider.of<ProductProvider>(context);
    final categories = productProvider.categories;

    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }

    final isEdit = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Product' : 'Add New Product'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ShopzoCard(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Update Product Details' : 'Product Information',
                        style: ShopzoTypography.headingLarge(context, isDark: isDark),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter product details below for permanent offline storage.',
                        style: ShopzoTypography.bodyMedium(context, isDark: isDark),
                      ),
                      const SizedBox(height: 24),
                      ShopzoTextField(
                        label: 'Product Name *',
                        hint: 'e.g. Basmati Rice',
                        controller: _nameController,
                        prefixIcon: Icons.shopping_bag_rounded,
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Product name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      // Category & Brand
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Category *',
                                  style: ShopzoTypography.bodyMedium(context, isDark: isDark).copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? ShopzoColors.darkSurfaceSecondary : ShopzoColors.lightSurfaceSecondary,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? ShopzoColors.darkBorder : ShopzoColors.lightBorder,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedCategoryId,
                                      isExpanded: true,
                                      dropdownColor: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
                                      style: ShopzoTypography.bodyLarge(context, isDark: isDark),
                                      items: categories.map((cat) {
                                        return DropdownMenuItem<String>(
                                          value: cat.id,
                                          child: Text(cat.name),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _selectedCategoryId = val;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ShopzoTextField(
                              label: 'Brand (Optional)',
                              hint: 'e.g. India Gate',
                              controller: _brandController,
                              prefixIcon: Icons.branding_watermark_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Buying & Selling Price
                      Row(
                        children: [
                          Expanded(
                            child: ShopzoTextField(
                              label: 'Buying Price (₹) *',
                              hint: '45.00',
                              controller: _buyingPriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              prefixIcon: Icons.currency_rupee_rounded,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Enter buying price';
                                final num = double.tryParse(val);
                                if (num == null || num < 0) return 'Enter valid price';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ShopzoTextField(
                              label: 'Selling Price (₹) *',
                              hint: '52.00',
                              controller: _sellingPriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              prefixIcon: Icons.sell_rounded,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Enter selling price';
                                final num = double.tryParse(val);
                                if (num == null || num < 0) return 'Enter valid price';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Quantity, Unit & Min Stock
                      Row(
                        children: [
                          Expanded(
                            child: ShopzoTextField(
                              label: 'Initial Quantity *',
                              hint: '18',
                              controller: _quantityController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              prefixIcon: Icons.inventory_2_rounded,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Enter quantity';
                                final num = double.tryParse(val);
                                if (num == null || num < 0) return 'Quantity cannot be negative';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Unit *',
                                  style: ShopzoTypography.bodyMedium(context, isDark: isDark).copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? ShopzoColors.darkSurfaceSecondary : ShopzoColors.lightSurfaceSecondary,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? ShopzoColors.darkBorder : ShopzoColors.lightBorder,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedUnit,
                                      isExpanded: true,
                                      dropdownColor: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
                                      style: ShopzoTypography.bodyLarge(context, isDark: isDark),
                                      items: _units.map((u) {
                                        return DropdownMenuItem<String>(
                                          value: u,
                                          child: Text(u),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _selectedUnit = val;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ShopzoTextField(
                              label: 'Min Stock Level *',
                              hint: '5',
                              controller: _minStockController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              prefixIcon: Icons.warning_amber_rounded,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Enter min stock';
                                final num = double.tryParse(val);
                                if (num == null || num < 0) return 'Min stock cannot be negative';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      ShopzoButton(
                        text: isEdit ? 'Save Changes' : 'Save Product',
                        isLoading: _isLoading,
                        onPressed: _handleSave,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
