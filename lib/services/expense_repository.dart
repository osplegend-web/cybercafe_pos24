import '../core/db/db_helper.dart';
import '../models/expense.dart';

class ExpenseRepository {
  final _db = DBHelper.instance;

  Future<List<Expense>> getAll({DateTime? from, DateTime? to}) async {
    final db = await _db.database;
    final where = <String>[];
    final args = <Object?>[];
    if (from != null) {
      where.add('date >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where.add('date <= ?');
      args.add(to.toIso8601String());
    }
    final rows = await db.query(
      'expenses',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC',
    );
    return rows.map((e) => Expense.fromMap(e)).toList();
  }

  Future<double> totalBetween(DateTime from, DateTime to) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as s FROM expenses WHERE date >= ? AND date <= ?',
      [from.toIso8601String(), to.toIso8601String()],
    );
    return (result.first['s'] as num?)?.toDouble() ?? 0;
  }

  Future<int> add(Expense expense) async {
    final db = await _db.database;
    return db.insert('expenses', expense.toMap());
  }

  Future<void> update(Expense expense) async {
    final db = await _db.database;
    await db.update('expenses', expense.toMap(), where: 'id = ?', whereArgs: [expense.id]);
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
}
