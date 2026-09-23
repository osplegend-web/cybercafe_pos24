import '../core/db/db_helper.dart';
import '../models/service_item.dart';

class ServiceRepository {
  final _db = DBHelper.instance;

  Future<List<ServiceItem>> getAll({bool activeOnly = false, String? query}) async {
    final db = await _db.database;
    final where = <String>[];
    final args = <Object?>[];
    if (activeOnly) where.add('active = 1');
    if (query != null && query.trim().isNotEmpty) {
      where.add('name LIKE ?');
      args.add('%${query.trim()}%');
    }
    final rows = await db.query(
      'services',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'name ASC',
    );
    return rows.map((e) => ServiceItem.fromMap(e)).toList();
  }

  Future<int> add(ServiceItem service) async {
    final db = await _db.database;
    return db.insert('services', service.toMap());
  }

  Future<void> update(ServiceItem service) async {
    final db = await _db.database;
    await db.update('services', service.toMap(), where: 'id = ?', whereArgs: [service.id]);
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('services', where: 'id = ?', whereArgs: [id]);
  }
}
