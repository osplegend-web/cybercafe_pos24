import 'package:flutter/foundation.dart';

import '../models/category.dart' as category_model;
import '../services/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  final _repo = CategoryRepository();
  List<category_model.Category> categories = [];
  bool loading = false;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    categories = await _repo.getAll();
    loading = false;
    notifyListeners();
  }

  Future<void> add(String name) async {
    await _repo.add(name);
    await load();
  }

  Future<void> update(category_model.Category category) async {
    await _repo.update(category);
    await load();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await load();
  }
}
