import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/quick_action_button.dart';
import '../../widgets/stat_card.dart';
import '../inventory/inventory_screen.dart';
import '../inventory/product_form_screen.dart';
import '../pos/pos_screen.dart';
import '../reports/reports_screen.dart';
import '../sales/sales_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
      context.read<ProductProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currencySymbol;

    return Scaffold(
      appBar: AppBar(title: Text(settings.shopName.isEmpty ? 'CyberCafe POS' : settings.shopName)),
      body: RefreshIndicator(
        onRefresh: () => context.read<DashboardProvider>().load(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Today's Overview", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.of(context).size.width >= 900 ? 3 : 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.4,
                children: [
                  StatCard(
                    title: "Today's Sales",
                    value: AppFormatters.money(dashboard.todaySales, symbol: currency),
                    icon: Icons.trending_up,
                    color: Colors.green,
                  ),
                  StatCard(
                    title: "Today's Profit",
                    value: AppFormatters.money(dashboard.todayProfit, symbol: currency),
                    icon: Icons.savings_outlined,
                    color: Colors.teal,
                  ),
                  StatCard(
                    title: "Today's Bills",
                    value: '${dashboard.todayBills}',
                    icon: Icons.receipt_outlined,
                    color: Colors.indigo,
                  ),
                  StatCard(
                    title: 'Total Products',
                    value: '${dashboard.totalProducts}',
                    icon: Icons.inventory_2_outlined,
                    color: Colors.blue,
                  ),
                  StatCard(
                    title: 'Low Stock Products',
                    value: '${dashboard.lowStockCount}',
                    icon: Icons.warning_amber_outlined,
                    color: Colors.orange,
                    onTap: () => _goTo(context, const InventoryScreen(lowStockOnly: true)),
                  ),
                  StatCard(
                    title: 'Total Stock Value',
                    value: AppFormatters.money(dashboard.totalStockValue, symbol: currency),
                    icon: Icons.account_balance_wallet_outlined,
                    color: Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  QuickActionButton(
                    label: 'New Sale',
                    icon: Icons.point_of_sale,
                    onTap: () => _goTo(context, const PosScreen()),
                  ),
                  QuickActionButton(
                    label: 'Add Product',
                    icon: Icons.add_box_outlined,
                    onTap: () => _goTo(context, const ProductFormScreen()),
                  ),
                  QuickActionButton(
                    label: 'Inventory',
                    icon: Icons.inventory_2_outlined,
                    onTap: () => _goTo(context, const InventoryScreen()),
                  ),
                  QuickActionButton(
                    label: 'Sales History',
                    icon: Icons.receipt_long_outlined,
                    onTap: () => _goTo(context, const SalesHistoryScreen()),
                  ),
                  QuickActionButton(
                    label: 'Reports',
                    icon: Icons.bar_chart_outlined,
                    onTap: () => _goTo(context, const ReportsScreen()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goTo(BuildContext context, Widget screen) {
    // On wide (desktop) layout, prefer switching the shell's selected tab so
    // the sidebar highlight stays in sync; fall back to a normal push.
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}
