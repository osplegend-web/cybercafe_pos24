import '../core/db/db_helper.dart';
import '../models/category.dart';

class CategoryRepository {
  final _db = DBHelper.instance;

  Future<List<Category>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('categories', orderBy: 'name ASC');
    return rows.map((e) => Category.fromMap(e)).toList();
  }

  Future<int> add(String name) async {
    final db = await _db.database;
    return db.insert('categories', {'name': name});
  }

  Future<void> update(Category category) async {
    final db = await _db.database;
    await db.update('categories', category.toMap(), where: 'id = ?', whereArgs: [category.id]);
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
