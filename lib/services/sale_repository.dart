import '../core/db/db_helper.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';

class SaleRepository {
  final _db = DBHelper.instance;

  Future<int> recordSale(Sale sale) => _db.recordSale(sale);

  Future<String> recordSaleInvoiceNumber() => _db.nextInvoiceNumber();

  Future<void> voidSale(int saleId) => _db.voidSale(saleId);

  Future<List<Sale>> getHistory({
    DateTime? from,
    DateTime? to,
    String? invoiceQuery,
    String? productQuery,
    bool includeVoided = true,
  }) async {
    final db = await _db.database;
    final where = <String>[];
    final args = <Object?>[];

    if (from != null) {
      where.add('s.created_at >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where.add('s.created_at <= ?');
      args.add(to.toIso8601String());
    }
    if (invoiceQuery != null && invoiceQuery.trim().isNotEmpty) {
      where.add('s.invoice_number LIKE ?');
      args.add('%${invoiceQuery.trim()}%');
    }
    if (!includeVoided) {
      where.add('s.is_voided = 0');
    }
    if (productQuery != null && productQuery.trim().isNotEmpty) {
      where.add('''s.id IN (
        SELECT sale_id FROM sale_items WHERE item_name LIKE ?
      )''');
      args.add('%${productQuery.trim()}%');
    }

    final sql = '''
      SELECT s.*, c.name AS customer_name
      FROM sales s
      LEFT JOIN customers c ON c.id = s.customer_id
      ${where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : ''}
      ORDER BY s.created_at DESC
    ''';

    final rows = await db.rawQuery(sql, args);
    final sales = <Sale>[];
    for (final row in rows) {
      final items = await getItemsForSale(row['id'] as int);
      sales.add(Sale.fromMap(row, items: items));
    }
    return sales;
  }

  Future<Sale?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT s.*, c.name AS customer_name
      FROM sales s LEFT JOIN customers c ON c.id = s.customer_id
      WHERE s.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;
    final items = await getItemsForSale(id);
    return Sale.fromMap(rows.first, items: items);
  }

  Future<List<SaleItem>> getItemsForSale(int saleId) async {
    final db = await _db.database;
    final rows = await db.query('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
    return rows.map((e) => SaleItem.fromMap(e)).toList();
  }

  // ---------------- Dashboard & report aggregations ----------------

  Future<double> totalSalesBetween(DateTime from, DateTime to) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT SUM(grand_total) as s FROM sales WHERE is_voided = 0 AND created_at >= ? AND created_at <= ?',
      [from.toIso8601String(), to.toIso8601String()],
    );
    return (result.first['s'] as num?)?.toDouble() ?? 0;
  }

  Future<int> billCountBetween(DateTime from, DateTime to) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM sales WHERE is_voided = 0 AND created_at >= ? AND created_at <= ?',
      [from.toIso8601String(), to.toIso8601String()],
    );
    return (result.first['c'] as int?) ?? 0;
  }

  /// Profit = sum((unit_price - purchase_price) * quantity) for all non-voided sale items in range.
  Future<double> totalProfitBetween(DateTime from, DateTime to) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT SUM((si.unit_price - si.purchase_price) * si.quantity) as p
      FROM sale_items si
      JOIN sales s ON s.id = si.sale_id
      WHERE s.is_voided = 0 AND s.created_at >= ? AND s.created_at <= ?
    ''', [from.toIso8601String(), to.toIso8601String()]);
    return (result.first['p'] as num?)?.toDouble() ?? 0;
  }

  /// Daily sales totals for the last [days] days (for line chart).
  Future<Map<DateTime, double>> dailySales(int days) async {
    final db = await _db.database;
    final from = DateTime.now().subtract(Duration(days: days - 1));
    final fromDay = DateTime(from.year, from.month, from.day);
    final rows = await db.rawQuery('''
      SELECT date(created_at) as d, SUM(grand_total) as total
      FROM sales
      WHERE is_voided = 0 AND created_at >= ?
      GROUP BY date(created_at)
      ORDER BY d ASC
    ''', [fromDay.toIso8601String()]);

    final map = <DateTime, double>{};
    for (var i = 0; i < days; i++) {
      final day = DateTime(fromDay.year, fromDay.month, fromDay.day + i);
      map[day] = 0;
    }
    for (final row in rows) {
      final d = DateTime.parse(row['d'] as String);
      final key = DateTime(d.year, d.month, d.day);
      if (map.containsKey(key)) {
        map[key] = (row['total'] as num?)?.toDouble() ?? 0;
      }
    }
    return map;
  }

  Future<List<Map<String, dynamic>>> productWiseSales(DateTime from, DateTime to) async {
    final db = await _db.database;
    return db.rawQuery('''
      SELECT si.item_name as name, SUM(si.quantity) as qty, SUM(si.total_price) as total
      FROM sale_items si
      JOIN sales s ON s.id = si.sale_id
      WHERE s.is_voided = 0 AND si.item_type = 'product' AND s.created_at >= ? AND s.created_at <= ?
      GROUP BY si.item_id, si.item_name
      ORDER BY total DESC
    ''', [from.toIso8601String(), to.toIso8601String()]);
  }

  Future<List<Map<String, dynamic>>> categoryWiseSales(DateTime from, DateTime to) async {
    final db = await _db.database;
    return db.rawQuery('''
      SELECT COALESCE(c.name, 'Uncategorized') as category, SUM(si.total_price) as total
      FROM sale_items si
      JOIN sales s ON s.id = si.sale_id
      JOIN products p ON p.id = si.item_id AND si.item_type = 'product'
      LEFT JOIN categories c ON c.id = p.category_id
      WHERE s.is_voided = 0 AND s.created_at >= ? AND s.created_at <= ?
      GROUP BY category
      ORDER BY total DESC
    ''', [from.toIso8601String(), to.toIso8601String()]);
  }

  Future<List<Map<String, dynamic>>> mostSoldProducts(DateTime from, DateTime to, {int limit = 10}) async {
    final rows = await productWiseSales(from, to);
    rows.sort((a, b) => ((b['qty'] as num?) ?? 0).compareTo((a['qty'] as num?) ?? 0));
    return rows.take(limit).toList();
  }

  Future<List<Map<String, dynamic>>> serviceWiseSales(DateTime from, DateTime to) async {
    final db = await _db.database;
    return db.rawQuery('''
      SELECT si.item_name as name, SUM(si.quantity) as qty, SUM(si.total_price) as total
      FROM sale_items si
      JOIN sales s ON s.id = si.sale_id
      WHERE s.is_voided = 0 AND si.item_type = 'service' AND s.created_at >= ? AND s.created_at <= ?
      GROUP BY si.item_id, si.item_name
      ORDER BY total DESC
    ''', [from.toIso8601String(), to.toIso8601String()]);
  }
}
