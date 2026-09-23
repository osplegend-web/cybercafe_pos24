import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/constants.dart';
import '../../models/sale.dart';
import '../../providers/settings_provider.dart';
import '../../services/pdf_service.dart';
import '../pos/pos_screen.dart';

class BillViewScreen extends StatelessWidget {
  final Sale sale;
  final bool justCompleted;

  const BillViewScreen({super.key, required this.sale, this.justCompleted = false});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currencySymbol;
    final pdfService = PdfService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${sale.invoiceNumber}'),
        automaticallyImplyLeading: !justCompleted,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(settings.shopName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (settings.shopAddress.isNotEmpty) Text(settings.shopAddress),
                      if (settings.shopPhone.isNotEmpty) Text('Ph: ${settings.shopPhone}'),
                      if (settings.gstin.isNotEmpty) Text('GSTIN: ${settings.gstin}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Invoice: ${sale.invoiceNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(AppFormatters.dateTime(sale.createdAt)),
                  ],
                ),
                if (sale.customerName != null) Text('Customer: ${sale.customerName}'),
                if (sale.isVoided)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('VOIDED', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                const Divider(),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(4),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(2),
                  },
                  children: [
                    const TableRow(children: [
                      Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                    ]),
                    ...sale.items.map((item) => TableRow(children: [
                          Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(item.itemName)),
                          Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(_qty(item.quantity))),
                          Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(item.unitPrice.toStringAsFixed(2))),
                          Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(item.totalPrice.toStringAsFixed(2))),
                        ])),
                  ],
                ),
                const Divider(),
                _row('Subtotal', AppFormatters.money(sale.subtotal, symbol: currency)),
                if (sale.discount > 0) _row('Discount', '- ${AppFormatters.money(sale.discount, symbol: currency)}'),
                const Divider(),
                _row('Grand Total', AppFormatters.money(sale.grandTotal, symbol: currency), bold: true),
                _row('Paid (${sale.paymentMethod.label})', AppFormatters.money(sale.amountPaid, symbol: currency)),
                _row('Change', AppFormatters.money(sale.changeAmount, symbol: currency)),
                const SizedBox(height: 16),
                const Center(child: Text('Thank you for your visit!')),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Print'),
                  onPressed: () async {
                    final doc = await pdfService.buildInvoice(
                      sale: sale,
                      shopName: settings.shopName,
                      shopAddress: settings.shopAddress,
                      shopPhone: settings.shopPhone,
                      gstin: settings.gstin,
                      currencySymbol: currency,
                    );
                    await pdfService.printInvoice(doc);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Save PDF'),
                  onPressed: () async {
                    final doc = await pdfService.buildInvoice(
                      sale: sale,
                      shopName: settings.shopName,
                      shopAddress: settings.shopAddress,
                      shopPhone: settings.shopPhone,
                      gstin: settings.gstin,
                      currencySymbol: currency,
                    );
                    final file = await pdfService.saveAsPdf(doc, sale.invoiceNumber);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Saved to ${file.path}')));
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share'),
                  onPressed: () async {
                    final doc = await pdfService.buildInvoice(
                      sale: sale,
                      shopName: settings.shopName,
                      shopAddress: settings.shopAddress,
                      shopPhone: settings.shopPhone,
                      gstin: settings.gstin,
                      currencySymbol: currency,
                    );
                    await pdfService.shareInvoice(doc, sale.invoiceNumber);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: justCompleted
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const PosScreen()),
              ),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('New Sale'),
            )
          : null,
    );
  }

  String _qty(double q) => q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(1);

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 16 : 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}
