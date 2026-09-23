import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../services/expense_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  final _repo = ExpenseRepository();
  List<Expense> expenses = [];
  bool loading = false;

  Future<void> load({DateTime? from, DateTime? to}) async {
    loading = true;
    notifyListeners();
    expenses = await _repo.getAll(from: from, to: to);
    loading = false;
    notifyListeners();
  }

  Future<void> add(Expense expense) async {
    await _repo.add(expense);
    await load();
  }

  Future<void> update(Expense expense) async {
    await _repo.update(expense);
    await load();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await load();
  }

  Future<double> totalBetween(DateTime from, DateTime to) => _repo.totalBetween(from, to);
}
