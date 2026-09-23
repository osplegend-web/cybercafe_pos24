import 'package:flutter/foundation.dart';

import '../models/customer.dart';
import '../services/customer_repository.dart';

class CustomerProvider extends ChangeNotifier {
  final _repo = CustomerRepository();
  List<Customer> customers = [];
  bool loading = false;
  String searchQuery = '';

  Future<void> load() async {
    loading = true;
    notifyListeners();
    customers = await _repo.getAll(query: searchQuery);
    loading = false;
    notifyListeners();
  }

  void setSearch(String query) {
    searchQuery = query;
    load();
  }

  Future<int> add(Customer customer) async {
    final id = await _repo.add(customer);
    await load();
    return id;
  }

  Future<void> update(Customer customer) async {
    await _repo.update(customer);
    await load();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await load();
  }
}
