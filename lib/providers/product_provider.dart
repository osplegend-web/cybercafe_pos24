import 'package:flutter/foundation.dart';

import '../core/db/db_helper.dart';
import '../models/product.dart';
import '../services/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final _repo = ProductRepository();

  List<Product> products = [];
  List<Product> lowStock = [];
  bool loading = false;

  int? filterCategoryId;
  String searchQuery = '';

  Future<void> load() async {
    loading = true;
    notifyListeners();
    products = await _repo.getAll(categoryId: filterCategoryId, query: searchQuery);
    lowStock = await _repo.getLowStock();
    loading = false;
    notifyListeners();
  }

  void setSearch(String query) {
    searchQuery = query;
    load();
  }

  void setCategoryFilter(int? categoryId) {
    filterCategoryId = categoryId;
    load();
  }

  Future<Product?> getById(int id) => _repo.getById(id);

  Future<int> addProduct(Product product) async {
    final id = await _repo.add(product);
    await load();
    return id;
  }

  Future<void> updateProduct(Product product) async {
    await _repo.update(product);
    await load();
  }

  Future<void> deleteProduct(int id) async {
    await _repo.delete(id);
    await load();
  }

  Future<void> increaseStock(int id, double qty) async {
    await _repo.adjustStock(id, qty);
    await load();
  }

  Future<void> decreaseStock(int id, double qty) async {
    await _repo.adjustStock(id, -qty);
    await load();
  }

  Future<int> totalProductCount() => _repo.count();

  Future<double> totalStockValue() => _repo.totalStockValue();

  Future<Product?> findByBarcode(String barcode) {
    return DBHelper.instance.findProductByBarcode(barcode);
  }
}
