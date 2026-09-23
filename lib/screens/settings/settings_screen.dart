import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import 'backup_restore_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _shopName;
  late TextEditingController _shopAddress;
  late TextEditingController _shopPhone;
  late TextEditingController _gstin;
  late TextEditingController _currency;
  late TextEditingController _invoicePrefix;
  late TextEditingController _printerName;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final s = context.read<SettingsProvider>();
      _shopName = TextEditingController(text: s.shopName);
      _shopAddress = TextEditingController(text: s.shopAddress);
      _shopPhone = TextEditingController(text: s.shopPhone);
      _gstin = TextEditingController(text: s.gstin);
      _currency = TextEditingController(text: s.currencySymbol);
      _invoicePrefix = TextEditingController(text: s.invoicePrefix);
      _printerName = TextEditingController(text: s.printerName);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    for (final c in [_shopName, _shopAddress, _shopPhone, _gstin, _currency, _invoicePrefix, _printerName]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    await context.read<SettingsProvider>().save(
          shopName: _shopName.text.trim(),
          shopAddress: _shopAddress.text.trim(),
          shopPhone: _shopPhone.text.trim(),
          gstin: _gstin.text.trim(),
          currencySymbol: _currency.text.trim().isEmpty ? '₹' : _currency.text.trim(),
          invoicePrefix: _invoicePrefix.text.trim().isEmpty ? 'INV' : _invoicePrefix.text.trim(),
          printerName: _printerName.text.trim(),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Shop Information', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(controller: _shopName, decoration: const InputDecoration(labelText: 'Shop Name')),
          const SizedBox(height: 12),
          TextField(controller: _shopAddress, decoration: const InputDecoration(labelText: 'Shop Address'), maxLines: 2),
          const SizedBox(height: 12),
          TextField(controller: _shopPhone, decoration: const InputDecoration(labelText: 'Phone Number')),
          const SizedBox(height: 12),
          TextField(controller: _gstin, decoration: const InputDecoration(labelText: 'GSTIN (optional)')),
          const SizedBox(height: 24),
          Text('Billing', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(controller: _currency, decoration: const InputDecoration(labelText: 'Currency Symbol')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(controller: _invoicePrefix, decoration: const InputDecoration(labelText: 'Invoice Prefix')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(controller: _printerName, decoration: const InputDecoration(labelText: 'Default Printer Name (optional)')),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('Save Settings')),
          const SizedBox(height: 32),
          Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto)),
              ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined)),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) => context.read<SettingsProvider>().setThemeMode(s.first),
          ),
          const SizedBox(height: 32),
          Text('Data', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Backup & Restore'),
              subtitle: const Text('Move your POS data between devices, no cloud needed'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
