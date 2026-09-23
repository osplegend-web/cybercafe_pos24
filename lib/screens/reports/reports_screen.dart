import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../providers/settings_provider.dart';
import '../../services/expense_repository.dart';
import '../../services/product_repository.dart';
import '../../services/sale_repository.dart';

enum ReportPeriod { daily, weekly, monthly }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _saleRepo = SaleRepository();
  final _productRepo = ProductRepository();
  final _expenseRepo = ExpenseRepository();

  ReportPeriod _period = ReportPeriod.daily;
  bool _loading = true;

  double _totalSales = 0;
  double _totalProfit = 0;
  double _totalExpenses = 0;
  int _billCount = 0;
  Map<DateTime, double> _dailySeries = {};
  List<Map<String, dynamic>> _productWise = [];
  List<Map<String, dynamic>> _categoryWise = [];
  List<Map<String, dynamic>> _mostSold = [];
  List<Map<String, dynamic>> _serviceWise = [];
  int _lowStockCount = 0;

  DateTime get _from {
    final now = DateTime.now();
    switch (_period) {
      case ReportPeriod.daily:
        return DateTime(now.year, now.month, now.day);
      case ReportPeriod.weekly:
        return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      case ReportPeriod.monthly:
        return DateTime(now.year, now.month, 1);
    }
  }

  DateTime get _to {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final from = _from;
    final to = _to;

    final results = await Future.wait([
      _saleRepo.totalSalesBetween(from, to),
      _saleRepo.totalProfitBetween(from, to),
      _expenseRepo.totalBetween(from, to),
      _saleRepo.billCountBetween(from, to),
      _saleRepo.dailySales(_period == ReportPeriod.monthly ? 30 : 7),
      _saleRepo.productWiseSales(from, to),
      _saleRepo.categoryWiseSales(from, to),
      _saleRepo.mostSoldProducts(from, to),
      _saleRepo.serviceWiseSales(from, to),
      _productRepo.getLowStock(),
    ]);

    setState(() {
      _totalSales = results[0] as double;
      _totalProfit = results[1] as double;
      _totalExpenses = results[2] as double;
      _billCount = results[3] as int;
      _dailySeries = results[4] as Map<DateTime, double>;
      _productWise = results[5] as List<Map<String, dynamic>>;
      _categoryWise = results[6] as List<Map<String, dynamic>>;
      _mostSold = results[7] as List<Map<String, dynamic>>;
      _serviceWise = results[8] as List<Map<String, dynamic>>;
      _lowStockCount = (results[9] as List).length;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currencySymbol;
    final netProfit = _totalProfit - _totalExpenses;

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<ReportPeriod>(
                      segments: const [
                        ButtonSegment(value: ReportPeriod.daily, label: Text('Daily')),
                        ButtonSegment(value: ReportPeriod.weekly, label: Text('Weekly')),
                        ButtonSegment(value: ReportPeriod.monthly, label: Text('Monthly')),
                      ],
                      selected: {_period},
                      onSelectionChanged: (s) {
                        setState(() => _period = s.first);
                        _load();
                      },
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _summaryChip('Total Sales', AppFormatters.money(_totalSales, symbol: currency), Colors.green),
                        _summaryChip('Bills', '$_billCount', Colors.indigo),
                        _summaryChip('Gross Profit', AppFormatters.money(_totalProfit, symbol: currency), Colors.teal),
                        _summaryChip('Expenses', AppFormatters.money(_totalExpenses, symbol: currency), Colors.orange),
                        _summaryChip('Net Profit', AppFormatters.money(netProfit, symbol: currency),
                            netProfit >= 0 ? Colors.green : Colors.red),
                        _summaryChip('Low Stock', '$_lowStockCount', Colors.red),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Sales Trend', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SizedBox(height: 220, child: _buildLineChart()),
                    const SizedBox(height: 24),
                    Text('Category-wise Sales', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SizedBox(height: 220, child: _buildCategoryPie()),
                    const SizedBox(height: 24),
                    Text('Most Sold Products', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _buildRankedList(_mostSold, currency, qtyLabel: true),
                    const SizedBox(height: 24),
                    Text('Product-wise Sales', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _buildRankedList(_productWise, currency),
                    const SizedBox(height: 24),
                    Text('Service-wise Sales', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _buildRankedList(_serviceWise, currency),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.9))),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    if (_dailySeries.isEmpty) return const Center(child: Text('No data'));
    final entries = _dailySeries.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final spots = <FlSpot>[
      for (var i = 0; i < entries.length; i++) FlSpot(i.toDouble(), entries[i].value),
    ];
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (entries.length / 5).clamp(1, entries.length).toDouble(),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= entries.length) return const SizedBox.shrink();
                final d = entries[idx].key;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${d.day}/${d.month}', style: const TextStyle(fontSize: 9)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: Colors.teal.withOpacity(0.15)),
            color: Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPie() {
    if (_categoryWise.isEmpty) return const Center(child: Text('No data'));
    final colors = [
      Colors.teal, Colors.indigo, Colors.orange, Colors.purple, Colors.pink, Colors.blue, Colors.brown,
    ];
    final total = _categoryWise.fold<double>(0, (s, e) => s + ((e['total'] as num?)?.toDouble() ?? 0));
    if (total == 0) return const Center(child: Text('No data'));

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: [
                for (var i = 0; i < _categoryWise.length; i++)
                  PieChartSectionData(
                    value: (_categoryWise[i]['total'] as num?)?.toDouble() ?? 0,
                    color: colors[i % colors.length],
                    title: '',
                    radius: 60,
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _categoryWise.length,
            itemBuilder: (context, i) {
              final pct = (((_categoryWise[i]['total'] as num?)?.toDouble() ?? 0) / total * 100);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, color: colors[i % colors.length]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('${_categoryWise[i]['category']} (${pct.toStringAsFixed(0)}%)',
                          style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRankedList(List<Map<String, dynamic>> rows, String currency, {bool qtyLabel = false}) {
    if (rows.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No data for this period'));
    }
    return Column(
      children: rows.take(10).map((r) {
        final qty = (r['qty'] as num?)?.toDouble() ?? 0;
        final total = (r['total'] as num?)?.toDouble() ?? 0;
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text('${r['name']}'),
          subtitle: Text('Qty: ${qty == qty.roundToDouble() ? qty.toInt() : qty}'),
          trailing: Text(AppFormatters.money(total, symbol: currency), style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      }).toList(),
    );
  }
}
