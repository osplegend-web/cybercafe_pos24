import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/utils/constants.dart';
import '../../models/product.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;
  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _name;
  late TextEditingController _sku;
  late TextEditingController _barcode;
  late TextEditingController _purchasePrice;
  late TextEditingController _sellingPrice;
  late TextEditingController _stockQty;
  late TextEditingController _minStock;
  late TextEditingController _description;

  int? _categoryId;
  String _unit = DefaultData.units.first;
  String? _imagePath;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p0 = widget.product;
    _name = TextEditingController(text: p0?.name ?? '');
    _sku = TextEditingController(text: p0?.sku ?? '');
    _barcode = TextEditingController(text: p0?.barcode ?? '');
    _purchasePrice = TextEditingController(text: p0?.purchasePrice.toString() ?? '');
    _sellingPrice = TextEditingController(text: p0?.sellingPrice.toString() ?? '');
    _stockQty = TextEditingController(text: p0?.stockQty.toString() ?? '0');
    _minStock = TextEditingController(text: p0?.minStock.toString() ?? '5');
    _description = TextEditingController(text: p0?.description ?? '');
    _categoryId = p0?.categoryId;
    _unit = p0?.unit ?? DefaultData.units.first;
    _imagePath = p0?.imagePath;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().load();
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _sku, _barcode, _purchasePrice, _sellingPrice, _stockQty, _minStock, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final ext = p.extension(picked.path);
    final destPath = p.join(dir.path, 'product_${DateTime.now().millisecondsSinceEpoch}$ext');
    final saved = await File(picked.path).copy(destPath);
    setState(() => _imagePath = saved.path);
  }

  Future<void> _addCategoryDialog() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(labelText: 'Category name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && mounted) {
      await context.read<CategoryProvider>().add(name);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final product = Product(
      id: widget.product?.id,
      name: _name.text.trim(),
      categoryId: _categoryId,
      sku: _sku.text.trim().isEmpty ? null : _sku.text.trim(),
      barcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
      purchasePrice: double.tryParse(_purchasePrice.text) ?? 0,
      sellingPrice: double.tryParse(_sellingPrice.text) ?? 0,
      stockQty: double.tryParse(_stockQty.text) ?? 0,
      minStock: double.tryParse(_minStock.text) ?? 0,
      unit: _unit,
      imagePath: _imagePath,
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      createdAt: widget.product?.createdAt,
    );

    final provider = context.read<ProductProvider>();
    if (_isEditing) {
      await provider.updateProduct(product);
    } else {
      await provider.addProduct(product);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await context.read<ProductProvider>().deleteProduct(widget.product!.id!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
        actions: [
          if (_isEditing)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    image: _imagePath != null
                        ? DecorationImage(image: FileImage(File(_imagePath!)), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _imagePath == null
                      ? const Icon(Icons.add_a_photo_outlined, size: 36, color: Colors.grey)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Product Name *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    decoration: const InputDecoration(labelText: 'Category'),
                    value: _categoryId,
                    items: categories
                        .map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                ),
                IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _addCategoryDialog),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _sku,
                    decoration: const InputDecoration(labelText: 'SKU'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _barcode,
                    decoration: const InputDecoration(labelText: 'Barcode'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _purchasePrice,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Purchase Price *'),
                    validator: (v) => (double.tryParse(v ?? '') == null) ? 'Invalid' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sellingPrice,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Selling Price *'),
                    validator: (v) => (double.tryParse(v ?? '') == null) ? 'Invalid' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stockQty,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Current Stock *'),
                    validator: (v) => (double.tryParse(v ?? '') == null) ? 'Invalid' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _minStock,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Min Stock Level *'),
                    validator: (v) => (double.tryParse(v ?? '') == null) ? 'Invalid' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Unit'),
              value: _unit,
              items: DefaultData.units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
              onChanged: (v) => setState(() => _unit = v ?? _unit),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_isEditing ? 'Save Changes' : 'Add Product'),
            ),
          ],
        ),
      ),
    );
  }
}
