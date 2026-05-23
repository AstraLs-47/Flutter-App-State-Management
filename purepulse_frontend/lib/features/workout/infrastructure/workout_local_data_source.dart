import '../../../core/data/local_data_source.dart';
import '../domain/workout_entry_model.dart';
import '../../../core/services/database_helper.dart';

class WorkoutLocalDataSource implements LocalDataSource<WorkoutEntry> {
  final DatabaseHelper _dbHelper;
  String _currentUserId = '';

  WorkoutLocalDataSource(this._dbHelper);

  void setUserId(String userId) {
    _currentUserId = userId;
  }

  @override
  Future<void> clear() async {
    final db = await _dbHelper.database;
    if (_currentUserId.isNotEmpty) {
      await db.delete('workouts', where: 'userId = ?', whereArgs: [_currentUserId]);
    } else {
      await db.delete('workouts');
    }
  }

  @override
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('workouts', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<WorkoutEntry>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = _currentUserId.isNotEmpty
        ? await db.query(
            'workouts',
            where: 'userId = ?',
            whereArgs: [_currentUserId],
          )
        : await db.query('workouts');
    return maps.map((p) => WorkoutEntry.fromJson(p)).toList();
  }

  @override
  Future<void> save(WorkoutEntry item) async {
    final db = await _dbHelper.database;
    final map = item.toJson().map((k, v) => MapEntry(k, v?.toString() ?? ''));
    if (_currentUserId.isNotEmpty) {
      map['userId'] = _currentUserId;
    } else {
      map['userId'] = 'default-user-id'; // Fallback
    }
    await db.insert('workouts', map);
  }

  @override
  Future<void> saveAll(List<WorkoutEntry> items) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var item in items) {
      final map = item.toJson().map((k, v) => MapEntry(k, v?.toString() ?? ''));
      if (_currentUserId.isNotEmpty) {
        map['userId'] = _currentUserId;
      } else {
        map['userId'] = 'default-user-id'; // Fallback
      }
      batch.insert('workouts', map);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> update(WorkoutEntry item) async {
    final db = await _dbHelper.database;
    final map = item.toJson().map((k, v) => MapEntry(k, v?.toString() ?? ''));
    if (_currentUserId.isNotEmpty) {
      map['userId'] = _currentUserId;
    }
    await db.update('workouts', map, where: 'id = ?', whereArgs: [item.id]);
  }
}
