import 'package:flutter/foundation.dart';

import '../models/service_item.dart';
import '../services/service_repository.dart';

class ServiceProvider extends ChangeNotifier {
  final _repo = ServiceRepository();
  List<ServiceItem> services = [];
  bool loading = false;
  String searchQuery = '';

  Future<void> load() async {
    loading = true;
    notifyListeners();
    services = await _repo.getAll(query: searchQuery);
    loading = false;
    notifyListeners();
  }

  void setSearch(String query) {
    searchQuery = query;
    load();
  }

  Future<void> add(ServiceItem service) async {
    await _repo.add(service);
    await load();
  }

  Future<void> update(ServiceItem service) async {
    await _repo.update(service);
    await load();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await load();
  }
}
