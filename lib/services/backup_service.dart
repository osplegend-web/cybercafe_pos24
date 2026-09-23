import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../core/db/db_helper.dart';

class BackupService {
  final _db = DBHelper.instance;

  /// Creates a timestamped copy of the live database file, e.g.
  /// cybercafe_pos_backup_2026-09-22_1830.db, and returns its path.
  /// The caller can then let the user save/share it wherever they like.
  Future<File> createBackupFile() async {
    await _db.closeDb(); // flush pending writes before copying the file
    final sourcePath = await _db.getDbPath();
    final source = File(sourcePath);
    final tempDir = source.parent;
    final stamp = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
    final backupPath = '${tempDir.path}/cybercafe_pos_backup_$stamp.db';
    final backupFile = await source.copy(backupPath);
    // Reopen the live db for normal use.
    await _db.database;
    return backupFile;
  }

  /// Lets the user pick a destination folder (Windows) and copies the backup there.
  Future<String?> exportBackupToFolder() async {
    final backup = await createBackupFile();
    final dirPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose a folder to save the backup',
    );
    if (dirPath == null) return null;
    final destPath = '$dirPath/${backup.uri.pathSegments.last}';
    await backup.copy(destPath);
    return destPath;
  }

  /// Shares the backup file via the Android share sheet (email, Drive, Bluetooth, etc.).
  Future<void> shareBackup() async {
    final backup = await createBackupFile();
    await SharePlus.instance.share(
      ShareParams(files: [XFile(backup.path)], text: 'CyberCafe POS backup'),
    );
  }

  /// Lets the user pick a .db backup file and restores it, replacing all current data.
  /// Returns true if a restore was performed.
  Future<bool> importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select a CyberCafe POS backup file',
      type: FileType.custom,
      allowedExtensions: ['db'],
    );
    if (result == null || result.files.single.path == null) return false;

    final pickedPath = result.files.single.path!;
    return restoreFromPath(pickedPath);
  }

  Future<bool> restoreFromPath(String pickedPath) async {
    await _db.closeDb();
    final targetPath = await _db.getDbPath();
    final picked = File(pickedPath);
    await picked.copy(targetPath);
    _db.resetConnectionCache();
    await _db.database; // reopen with restored data
    return true;
  }
}
