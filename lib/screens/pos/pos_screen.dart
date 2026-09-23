import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../models/sale.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/barcode_scanner_view.dart';
import '../../widgets/cart_panel.dart';
import '../../widgets/product_card.dart';
import '../../widgets/usb_barcode_listener.dart';
import '../sales/bill_view_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();

  bool get _isDesktopLike => !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().load();
      context.read<ServiceProvider>().load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanWithCamera() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerView()),
    );
    if (code != null) _handleBarcode(code);
  }

  Future<void> _handleBarcode(String code) async {
    final product = await context.read<ProductProvider>().findByBarcode(code);
    if (!mounted) return;
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No product found for barcode "$code"')),
      );
      return;
    }
    context.read<CartProvider>().addProduct(product);
  }

  Future<void> _checkout() async {
    final cart = context.read<CartProvider>();
    if (cart.amountPaid <= 0) {
      cart.setAmountPaid(cart.grandTotal);
    }
    try {
      final sale = await cart.checkout();
      if (!mounted) return;
      await context.read<ProductProvider>().load();
      _showCompletedBill(sale);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _showCompletedBill(Sale sale) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BillViewScreen(sale: sale, justCompleted: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currencySymbol;
    final isWide = MediaQuery.of(context).size.width >= 900;

    final leftPanel = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search products or services',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) {
                    context.read<ProductProvider>().setSearch(v);
                    context.read<ServiceProvider>().setSearch(v);
                  },
                ),
              ),
              if (!_isDesktopLike) ...[
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scanWithCamera,
                  tooltip: 'Scan barcode',
                ),
              ],
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Products'), Tab(text: 'Services')],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ProductGrid(currency: currency),
              _ServiceList(currency: currency),
            ],
          ),
        ),
      ],
    );

    final cartPanel = CartPanel(currency: currency, onCheckout: _checkout);

    final body = isWide
        ? Row(
            children: [
              Expanded(flex: 3, child: leftPanel),
              const VerticalDivider(width: 1),
              SizedBox(width: 380, child: cartPanel),
            ],
          )
        : DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(tabs: [Tab(text: 'Shop'), Tab(text: 'Cart')]),
                Expanded(
                  child: TabBarView(children: [leftPanel, cartPanel]),
                ),
              ],
            ),
          );

    final content = _isDesktopLike
        ? UsbBarcodeListener(onBarcodeScanned: _handleBarcode, child: body)
        : body;

    return Scaffold(
      appBar: AppBar(title: const Text('New Sale')),
      body: content,
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final String currency;
  const _ProductGrid({required this.currency});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    if (provider.loading) return const Center(child: CircularProgressIndicator());
    if (provider.products.isEmpty) return const Center(child: Text('No products'));

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: provider.products.length,
      itemBuilder: (context, i) {
        final product = provider.products[i];
        return ProductCard(
          product: product,
          currencySymbol: currency,
          onTap: () => context.read<CartProvider>().addProduct(product),
        );
      },
    );
  }
}

class _ServiceList extends StatelessWidget {
  final String currency;
  const _ServiceList({required this.currency});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServiceProvider>();
    if (provider.loading) return const Center(child: CircularProgressIndicator());
    final services = provider.services.where((s) => s.active).toList();
    if (services.isEmpty) return const Center(child: Text('No services'));

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: services.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final s = services[i];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.miscellaneous_services)),
            title: Text(s.name),
            trailing: Text(AppFormatters.money(s.price, symbol: currency),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            onTap: () => context.read<CartProvider>().addService(s),
          ),
        );
      },
    );
  }
}
