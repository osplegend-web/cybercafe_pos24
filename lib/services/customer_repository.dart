import '../core/db/db_helper.dart';
import '../models/customer.dart';

class CustomerRepository {
  final _db = DBHelper.instance;

  Future<List<Customer>> getAll({String? query}) async {
    final db = await _db.database;
    final where = (query != null && query.trim().isNotEmpty)
        ? '(name LIKE ? OR phone LIKE ?)'
        : null;
    final args = (query != null && query.trim().isNotEmpty)
        ? ['%${query.trim()}%', '%${query.trim()}%']
        : null;
    final rows = await db.query('customers', where: where, whereArgs: args, orderBy: 'name ASC');
    return rows.map((e) => Customer.fromMap(e)).toList();
  }

  Future<Customer?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Customer.fromMap(rows.first);
  }

  Future<int> add(Customer customer) async {
    final db = await _db.database;
    return db.insert('customers', customer.toMap());
  }

  Future<void> update(Customer customer) async {
    final db = await _db.database;
    await db.update('customers', customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }
}
