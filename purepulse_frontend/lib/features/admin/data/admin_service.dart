import 'package:sqflite/sqflite.dart';
import '../../../core/services/database_helper.dart';
import '../../../core/models/announcement_model.dart';

class AdminService {
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

  Future<void> updateAnnouncement(Announcement announcement) async {
    final db = await _dbHelper.database;
    await db.update(
      'announcements',
      announcement.toJson().map((k, v) => MapEntry(k, v.toString())),
      where: 'id = ?',
      whereArgs: [announcement.id],
    );
  }

  Future<void> deleteAnnouncement(String id) async {
    final db = await _dbHelper.database;
    await db.delete('announcements', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> fetchDashboardStats() async {
    final db = await _dbHelper.database;

    // 1. Get counts
    final productsCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM products'),
        ) ??
        0;

    final activitiesCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM activities'),
        ) ??
        0;

    final announcementsCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM announcements'),
        ) ??
        0;

    // 2. Average BMI & Heart Rate
    final healthRecords = await db.query('health_records');
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

    // 3. Product categories distributions
    final productCategories = [
      'Equipment',
      'Cardio',
      'Accessories',
      'Supplements',
    ];
    final productTypeData = <double>[];
    for (var cat in productCategories) {
      final count =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM products WHERE UPPER(category) = ?',
              [cat.toUpperCase()],
            ),
          ) ??
          0;
      productTypeData.add(count.toDouble());
    }

    // 4. Category distribution for activities
    final activities = await db.query('activities');
    final categoryDistribution = <String, double>{};
    for (var act in activities) {
      final cat = act['category'] as String? ?? 'Other';
      categoryDistribution[cat] = (categoryDistribution[cat] ?? 0.0) + 1.0;
    }

    // 5. Weekly engagement simulation based on actual SQLite counts
    final base = 30.0;
    final weeklyEngagementData = [
      base + activitiesCount,
      base + productsCount + 5,
      base + announcementsCount + 10,
      base + (activitiesCount * 1.5),
      base + (productsCount * 1.2),
      base + (announcementsCount * 2.0),
      base + activitiesCount + productsCount,
    ];

    // 6. Recent activities mapping
    final recentActivities = <Map<String, String>>[];
    final announcementsList = await db.query(
      'announcements',
      limit: 2,
      orderBy: 'date DESC',
    );
    for (var a in announcementsList) {
      recentActivities.add({
        'title': a['title'] as String? ?? 'New Announcement',
        'subtitle': 'News • ${a['date']}',
      });
    }

    final activitiesList = await db.query('activities', limit: 2);
    for (var act in activitiesList) {
      recentActivities.add({
        'title': act['title'] as String? ?? 'New Activity',
        'subtitle': '${act['category']} • Recently added',
      });
    }

    final productsList = await db.query('products', limit: 2);
    for (var p in productsList) {
      recentActivities.add({
        'title': p['title'] as String? ?? 'New Product',
        'subtitle': '${p['category']} • Stock updated',
      });
    }

    if (recentActivities.isEmpty) {
      recentActivities.add({
        'title': 'System Ready',
        'subtitle': 'No recent actions recorded',
      });
    }

    return {
      'avgBmi': avgBmi,
      'avgHr': avgHr,
      'totalProducts': productsCount,
      'totalActivities': activitiesCount,
      'announcementsCount': announcementsCount,
      'productTypeData': productTypeData,
      'categoryDistribution': categoryDistribution,
      'engagementData': weeklyEngagementData,
      'recentActivities': recentActivities,
    };
  }
}
