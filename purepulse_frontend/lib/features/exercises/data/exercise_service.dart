import '../../../core/services/database_helper.dart';
import '../../../core/models/activity_model.dart';

class ExerciseService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Activity>> fetchActivities() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('activities');
    return maps.map((a) => Activity.fromJson(a)).toList();
  }

  Future<void> addActivity(Activity activity) async {
    final db = await _dbHelper.database;
    await db.insert(
      'activities',
      activity.toJson().map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Future<void> updateActivity(Activity activity) async {
    final db = await _dbHelper.database;
    await db.update(
      'activities',
      activity.toJson().map((k, v) => MapEntry(k, v.toString())),
      where: 'id = ?',
      whereArgs: [activity.id],
    );
  }

  Future<void> deleteActivity(String id) async {
    final db = await _dbHelper.database;
    await db.delete('activities', where: 'id = ?', whereArgs: [id]);
  }
}
