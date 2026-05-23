import '../../../core/data/local_data_source.dart';
import '../../../core/models/announcement_model.dart';
import '../../../core/services/database_helper.dart';

class AnnouncementLocalDataSource implements LocalDataSource<Announcement> {
  final DatabaseHelper _dbHelper;

  AnnouncementLocalDataSource(this._dbHelper);

  @override
  Future<void> clear() async {
    final db = await _dbHelper.database;
    await db.delete('announcements');
  }

  @override
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('announcements', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Announcement>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('announcements');
    return maps.map((p) => Announcement.fromJson(p)).toList();
  }

  @override
  Future<void> save(Announcement item) async {
    final db = await _dbHelper.database;
    await db.insert(
      'announcements',
      item.toJson().map((k, v) => MapEntry(k, v.toString())),
    );
  }

  @override
  Future<void> saveAll(List<Announcement> items) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var item in items) {
      batch.insert(
        'announcements',
        item.toJson().map((k, v) => MapEntry(k, v.toString())),
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> update(Announcement item) async {
    final db = await _dbHelper.database;
    await db.update(
      'announcements',
      item.toJson().map((k, v) => MapEntry(k, v.toString())),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }
}
