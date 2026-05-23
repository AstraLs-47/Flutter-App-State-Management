import '../../../core/data/local_data_source.dart';
import '../../../core/models/activity_model.dart';
import '../../../core/services/database_helper.dart';

class ExerciseLocalDataSource implements LocalDataSource<Activity> {
  final DatabaseHelper _dbHelper;

  ExerciseLocalDataSource(this._dbHelper);

  @override
  Future<void> clear() async {
    final db = await _dbHelper.database;
    await db.delete('activities');
  }

  @override
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('activities', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Activity>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('activities');
    return maps.map((p) => Activity.fromJson(p)).toList();
  }

  @override
  Future<void> save(Activity item) async {
    final db = await _dbHelper.database;
    await db.insert(
      'activities',
      item.toJson().map((k, v) => MapEntry(k, v.toString())),
    );
  }

  @override
  Future<void> saveAll(List<Activity> items) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var item in items) {
      batch.insert(
        'activities',
        item.toJson().map((k, v) => MapEntry(k, v.toString())),
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> update(Activity item) async {
    final db = await _dbHelper.database;
    await db.update(
      'activities',
      item.toJson().map((k, v) => MapEntry(k, v.toString())),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }
}
