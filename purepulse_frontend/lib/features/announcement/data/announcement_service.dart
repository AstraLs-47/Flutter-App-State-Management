import '../../../core/services/database_helper.dart';
import '../../../core/models/announcement_model.dart';

class AnnouncementService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Announcement>> fetchAnnouncements() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('announcements');
    return maps.map((a) => Announcement.fromJson(a)).toList();
  }

  Future<void> addAnnouncement(Announcement announcement) async {
    final db = await _dbHelper.database;
    await db.insert(
      'announcements',
      announcement.toJson().map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Future<void> deleteAnnouncement(String id) async {
    final db = await _dbHelper.database;
    await db.delete('announcements', where: 'id = ?', whereArgs: [id]);
  }
}
