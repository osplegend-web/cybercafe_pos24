import '../core/db/db_helper.dart';
import '../models/product.dart';

class ProductRepository {
  final _db = DBHelper.instance;

  static const _joinSelect = '''
    SELECT p.*, c.name AS category_name
    FROM products p
    LEFT JOIN categories c ON c.id = p.category_id
  ''';

  Future<List<Product>> getAll({int? categoryId, String? query}) async {
    final db = await _db.database;
    final where = <String>[];
    final args = <Object?>[];

    if (categoryId != null) {
      where.add('p.category_id = ?');
      args.add(categoryId);
    }
    if (query != null && query.trim().isNotEmpty) {
      where.add('(p.name LIKE ? OR p.sku LIKE ? OR p.barcode LIKE ?)');
      final q = '%${query.trim()}%';
      args.addAll([q, q, q]);
    }

    final sql = _joinSelect +
        (where.isNotEmpty ? ' WHERE ${where.join(' AND ')}' : '') +
        ' ORDER BY p.name ASC';

    final rows = await db.rawQuery(sql, args);
    return rows.map((e) => Product.fromMap(e)).toList();
  }

  Future<Product?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.rawQuery('$_joinSelect WHERE p.id = ?', [id]);
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<List<Product>> getLowStock() async {
    final db = await _db.database;
    final rows = await db.rawQuery('$_joinSelect WHERE p.stock_qty <= p.min_stock ORDER BY p.stock_qty ASC');
    return rows.map((e) => Product.fromMap(e)).toList();
  }

  Future<int> count() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM products');
    return (result.first['c'] as int?) ?? 0;
  }

  Future<double> totalStockValue() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT SUM(stock_qty * purchase_price) as v FROM products');
    return (result.first['v'] as num?)?.toDouble() ?? 0;
  }

  Future<int> add(Product product) async {
    final db = await _db.database;
    return db.insert('products', product.toMap());
  }

  Future<void> update(Product product) async {
    final db = await _db.database;
    await db.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> adjustStock(int id, double delta) => _db.adjustStock(id, delta);
}
