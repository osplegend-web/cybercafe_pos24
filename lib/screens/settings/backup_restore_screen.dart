import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../services/backup_service.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final _backupService = BackupService();
  bool _busy = false;

  bool get _isDesktop => !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  Future<void> _run(Future<void> Function() action, {String? successMessage}) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmRestore(Future<bool> Function() restoreAction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
          'This will REPLACE all current data (products, sales, customers, everything) '
          'with the contents of the selected backup file. This cannot be undone.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore & Replace'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _run(() async {
      final restored = await restoreAction();
      if (restored && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup restored. Restart the app to see all changes.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Opacity(
          opacity: _busy ? 0.6 : 1,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blueGrey),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Backups are plain database files stored on this device. '
                          'No internet or cloud account is required - just copy the '
                          'file to a USB drive or share it to move to another device.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Backup', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_isDesktop)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: const Text('Export Backup to Folder'),
                    subtitle: const Text('Choose a folder on this PC or a USB drive'),
                    onTap: () => _run(
                      () async {
                        final path = await _backupService.exportBackupToFolder();
                        if (path != null && mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('Backup saved to $path')));
                        }
                      },
                    ),
                  ),
                )
              else
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.share_outlined),
                    title: const Text('Share Backup'),
                    subtitle: const Text('Send via email, Drive, Bluetooth, etc.'),
                    onTap: () => _run(() => _backupService.shareBackup()),
                  ),
                ),
              const SizedBox(height: 20),
              Text('Restore', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.restore_outlined),
                  title: const Text('Import Backup File'),
                  subtitle: const Text('Select a .db backup file to restore'),
                  onTap: () => _confirmRestore(() => _backupService.importBackup()),
                ),
              ),
              if (_busy) const Padding(padding: EdgeInsets.only(top: 24), child: Center(child: CircularProgressIndicator())),
            ],
          ),
        ),
      ),
    );
  }
}
