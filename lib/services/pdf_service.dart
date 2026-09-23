import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../core/utils/formatters.dart';
import '../core/utils/constants.dart';
import '../models/sale.dart';

class PdfService {
  /// Builds a printable A5-ish receipt document for the given sale.
  Future<pw.Document> buildInvoice({
    required Sale sale,
    required String shopName,
    required String shopAddress,
    required String shopPhone,
    required String gstin,
    required String currencySymbol,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // works well for thermal printers too
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(shopName,
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ),
              if (shopAddress.isNotEmpty)
                pw.Center(child: pw.Text(shopAddress, style: const pw.TextStyle(fontSize: 9))),
              if (shopPhone.isNotEmpty)
                pw.Center(child: pw.Text('Ph: $shopPhone', style: const pw.TextStyle(fontSize: 9))),
              if (gstin.isNotEmpty)
                pw.Center(child: pw.Text('GSTIN: $gstin', style: const pw.TextStyle(fontSize: 9))),
              pw.SizedBox(height: 6),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Invoice: ${sale.invoiceNumber}', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.Text(AppFormatters.dateTime(sale.createdAt), style: const pw.TextStyle(fontSize: 9)),
              if (sale.customerName != null)
                pw.Text('Customer: ${sale.customerName}', style: const pw.TextStyle(fontSize: 9)),
              pw.Divider(),
              pw.Row(children: [
                pw.Expanded(flex: 4, child: pw.Text('Item', style: _headStyle)),
                pw.Expanded(flex: 1, child: pw.Text('Qty', style: _headStyle)),
                pw.Expanded(flex: 2, child: pw.Text('Price', style: _headStyle)),
                pw.Expanded(flex: 2, child: pw.Text('Total', style: _headStyle)),
              ]),
              pw.Divider(),
              ...sale.items.map((item) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(children: [
                      pw.Expanded(flex: 4, child: pw.Text(item.itemName, style: _rowStyle)),
                      pw.Expanded(flex: 1, child: pw.Text(_qty(item.quantity), style: _rowStyle)),
                      pw.Expanded(
                          flex: 2,
                          child: pw.Text(item.unitPrice.toStringAsFixed(2), style: _rowStyle)),
                      pw.Expanded(
                          flex: 2, child: pw.Text(item.totalPrice.toStringAsFixed(2), style: _rowStyle)),
                    ]),
                  )),
              pw.Divider(),
              _totalsRow('Subtotal', sale.subtotal, currencySymbol),
              if (sale.discount > 0) _totalsRow('Discount', -sale.discount, currencySymbol),
              pw.Divider(),
              _totalsRow('Grand Total', sale.grandTotal, currencySymbol, bold: true),
              _totalsRow('Paid (${sale.paymentMethod.label})', sale.amountPaid, currencySymbol),
              _totalsRow('Change', sale.changeAmount, currencySymbol),
              pw.SizedBox(height: 10),
              pw.Center(child: pw.Text('Thank you for your visit!', style: const pw.TextStyle(fontSize: 9))),
            ],
          );
        },
      ),
    );

    return doc;
  }

  String _qty(double q) => q == q.roundToDouble() ? q.toInt().toString() : q.toString();

  static final _headStyle = pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold);
  static const _rowStyle = pw.TextStyle(fontSize: 8);

  pw.Widget _totalsRow(String label, double value, String symbol, {bool bold = false}) {
    final style = pw.TextStyle(fontSize: bold ? 11 : 9, fontWeight: bold ? pw.FontWeight.bold : null);
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text('$symbol ${value.toStringAsFixed(2)}', style: style),
      ],
    );
  }

  /// Sends the document to the system print dialog - works with any
  /// Windows-installed printer (including thermal printers via their driver)
  /// and Android's print service.
  Future<void> printInvoice(pw.Document doc) async {
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  /// Saves the invoice to a PDF file in app documents and returns the path.
  Future<File> saveAsPdf(pw.Document doc, String invoiceNumber) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/invoice_$invoiceNumber.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  /// Shares the invoice PDF (Android share sheet / Windows share).
  Future<void> shareInvoice(pw.Document doc, String invoiceNumber) async {
    final file = await saveAsPdf(doc, invoiceNumber);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Invoice $invoiceNumber'),
    );
  }
}
