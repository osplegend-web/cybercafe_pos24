import 'package:flutter/foundation.dart';

import '../services/expense_repository.dart';
import '../services/product_repository.dart';
import '../services/sale_repository.dart';

class DashboardProvider extends ChangeNotifier {
  final _saleRepo = SaleRepository();
  final _productRepo = ProductRepository();
  final _expenseRepo = ExpenseRepository();

  double todaySales = 0;
  double todayProfit = 0;
  int todayBills = 0;
  int totalProducts = 0;
  int lowStockCount = 0;
  double totalStockValue = 0;
  double todayExpenses = 0;
  bool loading = false;

  Future<void> load() async {
    loading = true;
    notifyListeners();

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

    final results = await Future.wait([
      _saleRepo.totalSalesBetween(startOfDay, endOfDay),
      _saleRepo.totalProfitBetween(startOfDay, endOfDay),
      _saleRepo.billCountBetween(startOfDay, endOfDay),
      _productRepo.count(),
      _productRepo.getLowStock(),
      _productRepo.totalStockValue(),
      _expenseRepo.totalBetween(startOfDay, endOfDay),
    ]);

    todaySales = results[0] as double;
    todayProfit = results[1] as double;
    todayBills = results[2] as int;
    totalProducts = results[3] as int;
    lowStockCount = (results[4] as List).length;
    totalStockValue = results[5] as double;
    todayExpenses = results[6] as double;

    loading = false;
    notifyListeners();
  }
}
