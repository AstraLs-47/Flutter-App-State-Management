import '../../../core/data/local_data_source.dart';
import '../domain/health_record_model.dart';
import '../../../core/services/database_helper.dart';

class HealthLocalDataSource implements LocalDataSource<HealthRecord> {
  final DatabaseHelper _dbHelper;
  String _currentUserId = '';

  HealthLocalDataSource(this._dbHelper);

  void setUserId(String userId) {
    _currentUserId = userId;
  }

  @override
  Future<void> clear() async {
    final db = await _dbHelper.database;
    if (_currentUserId.isNotEmpty) {
      await db.delete('health_records', where: 'userId = ?', whereArgs: [_currentUserId]);
    } else {
      await db.delete('health_records');
    }
  }

  @override
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('health_records', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<HealthRecord>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = _currentUserId.isNotEmpty
        ? await db.query(
            'health_records',
            where: 'userId = ?',
            whereArgs: [_currentUserId],
            orderBy: 'date DESC',
          )
        : await db.query('health_records', orderBy: 'date DESC');
    return maps.map((p) => HealthRecord.fromJson(p)).toList();
  }

  @override
  Future<void> save(HealthRecord item) async {
    final db = await _dbHelper.database;
    final map = item.toJson();
    if (_currentUserId.isNotEmpty) {
      map['userId'] = _currentUserId;
    } else {
      map['userId'] = 'default-user-id'; // Fallback
    }
    await db.insert('health_records', map);
  }

  @override
  Future<void> saveAll(List<HealthRecord> items) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var item in items) {
      final map = item.toJson();
      if (_currentUserId.isNotEmpty) {
        map['userId'] = _currentUserId;
      } else {
        map['userId'] = 'default-user-id'; // Fallback
      }
      batch.insert('health_records', map);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> update(HealthRecord item) async {
    final db = await _dbHelper.database;
    final map = item.toJson();
    if (_currentUserId.isNotEmpty) {
      map['userId'] = _currentUserId;
    }
    await db.update(
      'health_records',
      map,
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }
}
