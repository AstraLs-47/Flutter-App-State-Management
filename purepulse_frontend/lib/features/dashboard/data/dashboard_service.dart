import '../../../core/services/database_helper.dart';

class DashboardService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Map<String, dynamic>> fetchDashboardStats() async {
    final db = await _dbHelper.database;

    final activities = await db.query('activities');
    final healthRecords = await db.query('health_records');
    final announcements = await db.query('announcements');

    double avgBmi = 0.0;
    double avgHr = 0.0;
    if (healthRecords.isNotEmpty) {
      double totalBmi = 0.0;
      double totalHr = 0.0;
      for (var r in healthRecords) {
        totalBmi += (r['bmi'] as num).toDouble();
        totalHr += (r['heartRate'] as num).toDouble();
      }
      avgBmi = totalBmi / healthRecords.length;
      avgHr = totalHr / healthRecords.length;
    }

    return {
      'avgBmi': avgBmi,
      'avgHr': avgHr,
      'totalActivities': activities.length,
      'hasNewAnnouncements': announcements.isNotEmpty,
    };
  }
}
