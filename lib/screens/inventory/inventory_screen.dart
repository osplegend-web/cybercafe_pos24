import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../models/product.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import 'product_form_screen.dart';

class InventoryScreen extends StatefulWidget {
  final bool lowStockOnly;
  const InventoryScreen({super.key, this.lowStockOnly = false});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().load();
      context.read<ProductProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final settings = context.watch<SettingsProvider>();

    final products =
        widget.lowStockOnly ? productProvider.lowStock : productProvider.products;

    return Scaffold(
      appBar: AppBar(title: Text(widget.lowStockOnly ? 'Low Stock Products' : 'Inventory')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProductFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: Column(
        children: [
          if (!widget.lowStockOnly)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Search by name, SKU or barcode',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: productProvider.setSearch,
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<int?>(
                    hint: const Text('Category'),
                    value: productProvider.filterCategoryId,
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('All Categories')),
                      ...categoryProvider.categories.map(
                        (c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
                      ),
                    ],
                    onChanged: productProvider.setCategoryFilter,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: productProvider.loading
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                    ? const Center(child: Text('No products found'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _ProductTile(
                          product: products[i],
                          currency: settings.currencySymbol,
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final String currency;
  const _ProductTile({required this.product, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: product.isLowStock ? Colors.orange.shade100 : Colors.grey.shade200,
          child: Icon(
            Icons.inventory_2_outlined,
            color: product.isLowStock ? Colors.orange.shade800 : Colors.grey.shade700,
          ),
        ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${product.categoryName ?? 'Uncategorized'} • Stock: ${_qty(product.stockQty)} ${product.unit}'
          '${product.isLowStock ? ' (LOW)' : ''}',
          style: TextStyle(color: product.isLowStock ? Colors.orange.shade800 : null),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(AppFormatters.money(product.sellingPrice, symbol: currency),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  onPressed: () => _showAdjustDialog(context, product, increase: false),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: () => _showAdjustDialog(context, product, increase: true),
                ),
              ],
            ),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
        ),
        onLongPress: () => _confirmDelete(context, product),
      ),
    );
  }

  String _qty(double q) => q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(1);

  void _showAdjustDialog(BuildContext context, Product product, {required bool increase}) {
    final ctrl = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(increase ? 'Increase Stock' : 'Decrease Stock'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Quantity'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final qty = double.tryParse(ctrl.text) ?? 0;
              if (qty > 0) {
                final provider = dialogCtx.read<ProductProvider>();
                if (increase) {
                  provider.increaseStock(product.id!, qty);
                } else {
                  provider.decreaseStock(product.id!, qty);
                }
              }
              Navigator.pop(dialogCtx);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${product.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              dialogCtx.read<ProductProvider>().deleteProduct(product.id!);
              Navigator.pop(dialogCtx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
