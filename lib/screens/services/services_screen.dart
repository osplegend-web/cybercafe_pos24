import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../models/service_item.dart';
import '../../providers/service_provider.dart';
import '../../providers/settings_provider.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ServiceProvider>().load());
  }

  Future<void> _showForm({ServiceItem? service}) async {
    final nameCtrl = TextEditingController(text: service?.name ?? '');
    final priceCtrl = TextEditingController(text: service?.price.toString() ?? '');
    final descCtrl = TextEditingController(text: service?.description ?? '');
    bool active = service?.active ?? true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(service == null ? 'Add Service' : 'Edit Service'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Service Name *')),
                const SizedBox(height: 10),
                TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Price *'),
                ),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)')),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active (billable)'),
                  value: active,
                  onChanged: (v) => setDialogState(() => active = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text) ?? 0;
                if (name.isEmpty) return;
                final provider = context.read<ServiceProvider>();
                if (service == null) {
                  await provider.add(ServiceItem(
                      name: name, price: price, description: descCtrl.text.trim(), active: active));
                } else {
                  await provider.update(service.copyWith(
                      name: name, price: price, description: descCtrl.text.trim(), active: active));
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServiceProvider>();
    final currency = context.watch<SettingsProvider>().currencySymbol;

    return Scaffold(
      appBar: AppBar(title: const Text('Cyber Cafe Services')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Service'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Search services', prefixIcon: Icon(Icons.search)),
              onChanged: provider.setSearch,
            ),
          ),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: provider.services.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final s = provider.services[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: s.active ? Colors.teal.shade50 : Colors.grey.shade200,
                            child: Icon(Icons.miscellaneous_services,
                                color: s.active ? Colors.teal : Colors.grey),
                          ),
                          title: Text(s.name),
                          subtitle: s.description != null && s.description!.isNotEmpty
                              ? Text(s.description!)
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(AppFormatters.money(s.price, symbol: currency),
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showForm(service: s),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => provider.delete(s.id!),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
