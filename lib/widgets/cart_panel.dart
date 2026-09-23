import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/constants.dart';
import '../core/utils/formatters.dart';
import '../providers/cart_provider.dart';
import '../providers/customer_provider.dart';

class CartPanel extends StatelessWidget {
  final String currency;
  final VoidCallback onCheckout;

  const CartPanel({super.key, required this.currency, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Container(
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart_outlined),
                const SizedBox(width: 8),
                Text('Cart (${cart.lines.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                if (cart.lines.isNotEmpty)
                  TextButton(onPressed: cart.clear, child: const Text('Clear')),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: cart.lines.isEmpty
                ? const Center(child: Text('Cart is empty\nSearch and tap a product or service', textAlign: TextAlign.center))
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: cart.lines.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final line = cart.lines[i];
                      return ListTile(
                        dense: true,
                        title: Text(line.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${AppFormatters.money(line.unitPrice, symbol: currency)} x ${_qty(line.quantity)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.remove_circle_outline, size: 20),
                              onPressed: () => cart.updateQuantity(i, line.quantity - 1),
                            ),
                            Text(_qty(line.quantity)),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              onPressed: () => cart.updateQuantity(i, line.quantity + 1),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              onPressed: () => cart.removeLine(i),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _CustomerPicker(),
                const SizedBox(height: 10),
                _summaryRow('Subtotal', cart.subtotal, currency),
                Row(
                  children: [
                    const Text('Discount: '),
                    Expanded(
                      child: TextField(
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(isDense: true, hintText: '0'),
                        onChanged: (v) => cart.setDiscount(double.tryParse(v) ?? 0),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                _summaryRow('Grand Total', cart.grandTotal, currency, bold: true),
                const SizedBox(height: 10),
                _PaymentMethodSelector(cart: cart),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: 'Amount Paid',
                          prefixText: '$currency ',
                        ),
                        onChanged: (v) => cart.setAmountPaid(double.tryParse(v) ?? 0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Change: ${AppFormatters.money(cart.changeAmount, symbol: currency)}'),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: cart.isEmpty ? null : onCheckout,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Complete Sale'),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _qty(double q) => q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(1);

  Widget _summaryRow(String label, double value, String currency, {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 16 : 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(AppFormatters.money(value, symbol: currency), style: style),
        ],
      ),
    );
  }
}

class _PaymentMethodSelector extends StatelessWidget {
  final CartProvider cart;
  const _PaymentMethodSelector({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: PaymentMethod.values.map((m) {
        final selected = cart.paymentMethod == m;
        return ChoiceChip(
          label: Text(m.label),
          selected: selected,
          onSelected: (_) => cart.setPaymentMethod(m),
        );
      }).toList(),
    );
  }
}

class _CustomerPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Row(
      children: [
        const Icon(Icons.person_outline, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            cart.customer?.name ?? 'Walk-in customer',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TextButton(
          onPressed: () => _pickCustomer(context),
          child: Text(cart.customer == null ? 'Select' : 'Change'),
        ),
        if (cart.customer != null)
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => cart.setCustomer(null),
          ),
      ],
    );
  }

  Future<void> _pickCustomer(BuildContext context) async {
    final customerProvider = context.read<CustomerProvider>();
    await customerProvider.load();
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (ctx, scrollCtrl) => Consumer<CustomerProvider>(
          builder: (ctx, provider, _) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: const InputDecoration(hintText: 'Search customer', prefixIcon: Icon(Icons.search)),
                  onChanged: provider.setSearch,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: provider.customers.length,
                  itemBuilder: (ctx, i) {
                    final c = provider.customers[i];
                    return ListTile(
                      title: Text(c.name),
                      subtitle: Text(c.phone ?? ''),
                      onTap: () {
                        context.read<CartProvider>().setCustomer(c);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
