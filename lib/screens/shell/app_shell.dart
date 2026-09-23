import 'package:flutter/material.dart';

import '../customers/customers_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../expenses/expenses_screen.dart';
import '../inventory/inventory_screen.dart';
import '../pos/pos_screen.dart';
import '../reports/reports_screen.dart';
import '../sales/sales_history_screen.dart';
import '../services/services_screen.dart';
import '../settings/settings_screen.dart';

class NavItem {
  final String label;
  final IconData icon;
  final Widget screen;
  const NavItem(this.label, this.icon, this.screen);
}

final List<NavItem> _navItems = [
  const NavItem('Dashboard', Icons.dashboard_outlined, DashboardScreen()),
  const NavItem('New Sale', Icons.point_of_sale_outlined, PosScreen()),
  const NavItem('Inventory', Icons.inventory_2_outlined, InventoryScreen()),
  const NavItem('Services', Icons.miscellaneous_services_outlined, ServicesScreen()),
  const NavItem('Sales History', Icons.receipt_long_outlined, SalesHistoryScreen()),
  const NavItem('Expenses', Icons.payments_outlined, ExpensesScreen()),
  const NavItem('Customers', Icons.people_outline, CustomersScreen()),
  const NavItem('Reports', Icons.bar_chart_outlined, ReportsScreen()),
  const NavItem('Settings', Icons.settings_outlined, SettingsScreen()),
];

/// Global key so any screen can jump straight to "New Sale" (e.g. dashboard
/// quick action) without threading callbacks everywhere.
final GlobalKey<_AppShellState> appShellKey = GlobalKey<_AppShellState>();

class AppShell extends StatefulWidget {
  AppShell({Key? key}) : super(key: key ?? appShellKey);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void navigateTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: navigateTo,
              extended: MediaQuery.of(context).size.width >= 1200,
              labelType: MediaQuery.of(context).size.width >= 1200
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Icon(Icons.point_of_sale, color: Colors.white, size: 32),
              ),
              destinations: _navItems
                  .map((n) => NavigationRailDestination(
                        icon: Icon(n.icon),
                        label: Text(n.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _navItems[_index].screen),
          ],
        ),
      );
    }

    // Mobile: bottom nav shows the 5 most-used sections; the rest are
    // reachable from the Dashboard's quick actions and a "More" tab.
    final mobileItems = [
      _navItems[0], // Dashboard
      _navItems[1], // New Sale
      _navItems[2], // Inventory
      _navItems[4], // Sales history
      _navItems[8], // Settings (acts as the "more" hub via its own links)
    ];
    final mobileIndexMap = [0, 1, 2, 4, 8];

    return Scaffold(
      body: mobileItems[mobileIndexMap.indexOf(_resolveMobileIndex(mobileIndexMap))].screen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: mobileIndexMap.indexOf(_resolveMobileIndex(mobileIndexMap)),
        onDestinationSelected: (i) => navigateTo(mobileIndexMap[i]),
        destinations: mobileItems
            .map((n) => NavigationDestination(icon: Icon(n.icon), label: n.label))
            .toList(),
      ),
    );
  }

  int _resolveMobileIndex(List<int> mobileIndexMap) {
    return mobileIndexMap.contains(_index) ? _index : 0;
  }
}
