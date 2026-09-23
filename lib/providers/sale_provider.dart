import 'package:flutter/foundation.dart';

import '../models/sale.dart';
import '../services/sale_repository.dart';

class SaleProvider extends ChangeNotifier {
  final _repo = SaleRepository();

  List<Sale> sales = [];
  bool loading = false;

  DateTime? from;
  DateTime? to;
  String invoiceQuery = '';
  String productQuery = '';

  Future<void> load() async {
    loading = true;
    notifyListeners();
    sales = await _repo.getHistory(
      from: from,
      to: to,
      invoiceQuery: invoiceQuery,
      productQuery: productQuery,
    );
    loading = false;
    notifyListeners();
  }

  void setDateRange(DateTime? f, DateTime? t) {
    from = f;
    to = t;
    load();
  }

  void setInvoiceQuery(String q) {
    invoiceQuery = q;
    load();
  }

  void setProductQuery(String q) {
    productQuery = q;
    load();
  }

  Future<void> voidSale(int id) async {
    await _repo.voidSale(id);
    await load();
  }

  Future<Sale?> getById(int id) => _repo.getById(id);
}
