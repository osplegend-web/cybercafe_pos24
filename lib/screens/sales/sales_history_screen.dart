import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/constants.dart';
import '../../models/sale.dart';
import '../../providers/sale_provider.dart';
import '../../providers/settings_provider.dart';
import 'bill_view_screen.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<SaleProvider>().load());
  }

  Future<void> _pickDateRange() async {
    final provider = context.read<SaleProvider>();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (range != null) {
      provider.setDateRange(
        DateTime(range.start.year, range.start.month, range.start.day),
        DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59),
      );
    }
  }

  void _confirmVoid(Sale sale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void Sale'),
        content: Text('Void invoice ${sale.invoiceNumber}? Stock for any products will be restored.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<SaleProvider>().voidSale(sale.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Void Sale'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SaleProvider>();
    final currency = context.watch<SettingsProvider>().currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        actions: [
          IconButton(icon: const Icon(Icons.date_range_outlined), onPressed: _pickDateRange),
          if (provider.from != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_outlined),
              tooltip: 'Clear date filter',
              onPressed: () => provider.setDateRange(null, null),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(hintText: 'Search invoice #', prefixIcon: Icon(Icons.receipt_long)),
                    onChanged: provider.setInvoiceQuery,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(hintText: 'Search product name', prefixIcon: Icon(Icons.inventory_2_outlined)),
                    onChanged: provider.setProductQuery,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : provider.sales.isEmpty
                    ? const Center(child: Text('No sales found'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: provider.sales.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, i) {
                          final sale = provider.sales[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: sale.isVoided ? Colors.red.shade50 : Colors.green.shade50,
                                child: Icon(
                                  sale.isVoided ? Icons.block : Icons.receipt_outlined,
                                  color: sale.isVoided ? Colors.red : Colors.green,
                                ),
                              ),
                              title: Text(sale.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${AppFormatters.dateTime(sale.createdAt)} • ${sale.paymentMethod.label}'
                                '${sale.customerName != null ? ' • ${sale.customerName}' : ''}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppFormatters.money(sale.grandTotal, symbol: currency),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      decoration: sale.isVoided ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'view') {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(builder: (_) => BillViewScreen(sale: sale)),
                                        );
                                      } else if (value == 'void') {
                                        _confirmVoid(sale);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'view', child: Text('View / Reprint')),
                                      if (!sale.isVoided)
                                        const PopupMenuItem(value: 'void', child: Text('Void Sale')),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => BillViewScreen(sale: sale)),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
