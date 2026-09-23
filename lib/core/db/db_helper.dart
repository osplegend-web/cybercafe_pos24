import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/product.dart';
import '../../models/sale.dart';
import '../../models/sale_item.dart';
import '../utils/constants.dart';

/// Singleton wrapper around the local SQLite database.
/// Works identically on Android and Windows - on Windows, main.dart
/// initializes `databaseFactory` to the FFI factory before this is used.
class DBHelper {
  DBHelper._internal();
  static final DBHelper instance = DBHelper._internal();

  static Database? _db;
  static const int _dbVersion = 1;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  /// Absolute path of the underlying .db file - used by backup/restore.
  Future<String> getDbPath() async {
    final Directory dir = await getApplicationSupportDirectory();
    return join(dir.path, 'cybercafe_pos.db');
  }

  Future<Database> _initDb() async {
    final path = await getDbPath();
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category_id INTEGER,
        sku TEXT,
        barcode TEXT,
        purchase_price REAL NOT NULL DEFAULT 0,
        selling_price REAL NOT NULL DEFAULT 0,
        stock_qty REAL NOT NULL DEFAULT 0,
        min_stock REAL NOT NULL DEFAULT 0,
        unit TEXT NOT NULL DEFAULT 'pcs',
        image_path TEXT,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
    await db.execute('CREATE INDEX idx_products_name ON products(name)');

    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL DEFAULT 0,
        description TEXT,
        active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        total_purchases REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL UNIQUE,
        customer_id INTEGER,
        subtotal REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        grand_total REAL NOT NULL,
        amount_paid REAL NOT NULL,
        change_amount REAL NOT NULL DEFAULT 0,
        payment_method TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_voided INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        item_type TEXT NOT NULL,
        item_id INTEGER NOT NULL,
        item_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        purchase_price REAL NOT NULL DEFAULT 0,
        total_price REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await _seedDefaults(db);
  }

  Future<void> _seedDefaults(Database db) async {
    final batch = db.batch();
    for (final c in DefaultData.defaultCategories) {
      batch.insert('categories', {'name': c});
    }
    for (final s in DefaultData.defaultServices) {
      batch.insert('services', {'name': s, 'price': 0, 'active': 1});
    }
    batch.insert('settings', {'key': AppSettingsKeys.shopName, 'value': 'CyberCafe POS'});
    batch.insert('settings', {'key': AppSettingsKeys.shopAddress, 'value': ''});
    batch.insert('settings', {'key': AppSettingsKeys.shopPhone, 'value': ''});
    batch.insert('settings', {'key': AppSettingsKeys.gstin, 'value': ''});
    batch.insert('settings', {'key': AppSettingsKeys.currencySymbol, 'value': '₹'});
    batch.insert('settings', {'key': AppSettingsKeys.invoicePrefix, 'value': 'INV'});
    batch.insert('settings', {'key': AppSettingsKeys.lastInvoiceNumber, 'value': '0'});
    batch.insert('settings', {'key': AppSettingsKeys.themeMode, 'value': 'system'});
    await batch.commit(noResult: true);
  }

  /// Records a full sale atomically:
  /// inserts the sale + all line items, deducts product stock,
  /// and bumps the customer's lifetime total - all or nothing.
  Future<int> recordSale(Sale sale) async {
    final db = await database;
    return db.transaction<int>((txn) async {
      final saleId = await txn.insert('sales', sale.toMap());

      for (final item in sale.items) {
        await txn.insert('sale_items', item.toMap()..['sale_id'] = saleId);

        if (item.itemType == SaleItemType.product) {
          await txn.rawUpdate(
            'UPDATE products SET stock_qty = stock_qty - ?, updated_at = ? WHERE id = ?',
            [item.quantity, DateTime.now().toIso8601String(), item.itemId],
          );
        }
      }

      if (sale.customerId != null) {
        await txn.rawUpdate(
          'UPDATE customers SET total_purchases = total_purchases + ? WHERE id = ?',
          [sale.grandTotal, sale.customerId],
        );
      }

      return saleId;
    });
  }

  /// Voids a sale: marks it voided and restores stock for any products sold.
  Future<void> voidSale(int saleId) async {
    final db = await database;
    await db.transaction((txn) async {
      final items = await txn.query('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
      for (final row in items) {
        final item = SaleItem.fromMap(row);
        if (item.itemType == SaleItemType.product) {
          await txn.rawUpdate(
            'UPDATE products SET stock_qty = stock_qty + ? WHERE id = ?',
            [item.quantity, item.itemId],
          );
        }
      }
      await txn.update('sales', {'is_voided': 1}, where: 'id = ?', whereArgs: [saleId]);
    });
  }

  /// Directly adjusts a product's stock (manual increase/decrease from Inventory screen).
  Future<void> adjustStock(int productId, double delta) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE products SET stock_qty = stock_qty + ?, updated_at = ? WHERE id = ?',
      [delta, DateTime.now().toIso8601String(), productId],
    );
  }

  Future<Product?> findProductByBarcode(String barcode) async {
    final db = await database;
    final rows = await db.query('products', where: 'barcode = ?', whereArgs: [barcode], limit: 1);
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  /// Generates the next sequential invoice number using the configured prefix,
  /// e.g. INV-000042. Persists the counter in settings so it survives restarts.
  Future<String> nextInvoiceNumber() async {
    final db = await database;
    return db.transaction<String>((txn) async {
      final prefixRows = await txn.query('settings',
          where: 'key = ?', whereArgs: [AppSettingsKeys.invoicePrefix]);
      final counterRows = await txn.query('settings',
          where: 'key = ?', whereArgs: [AppSettingsKeys.lastInvoiceNumber]);

      final prefix = prefixRows.isNotEmpty ? (prefixRows.first['value'] as String? ?? 'INV') : 'INV';
      final current = counterRows.isNotEmpty
          ? int.tryParse(counterRows.first['value'] as String? ?? '0') ?? 0
          : 0;
      final next = current + 1;

      await txn.update(
        'settings',
        {'value': next.toString()},
        where: 'key = ?',
        whereArgs: [AppSettingsKeys.lastInvoiceNumber],
      );

      return '$prefix-${next.toString().padLeft(6, '0')}';
    });
  }

  Future<void> closeDb() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }

  /// Forces the singleton to reopen the db file next time it's accessed -
  /// used right after a restore overwrites the underlying file.
  void resetConnectionCache() {
    _db = null;
  }
}
