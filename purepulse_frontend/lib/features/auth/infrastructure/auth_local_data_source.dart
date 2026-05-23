import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/database_helper.dart';

/// Local data source for authentication.
/// Handles SQLite user table operations and SharedPreferences session management.
class AuthLocalDataSource {
  final DatabaseHelper _dbHelper;
  static const String _keySessionEmail = 'active_user_email';

  AuthLocalDataSource(this._dbHelper);

  // ── Session Management ──────────────────────────────────────────────

  Future<String?> getSessionEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySessionEmail);
  }

  Future<void> saveSession(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySessionEmail, email);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySessionEmail);
  }

  // ── User Table Operations ───────────────────────────────────────────

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<Map<String, dynamic>?> getUserByCredentials(
    String email,
    String password,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<void> insertUser(Map<String, dynamic> data) async {
    final db = await _dbHelper.database;
    await db.insert('users', data);
  }

  Future<void> deleteUser(String id) async {
    final db = await _dbHelper.database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteUserWorkouts(String userId) async {
    final db = await _dbHelper.database;
    await db.delete('workouts', where: 'userId = ?', whereArgs: [userId]);
  }

  Future<void> deleteUserHealthRecords(String userId) async {
    final db = await _dbHelper.database;
    await db.delete('health_records', where: 'userId = ?', whereArgs: [userId]);
  }

  /// Ensures the default admin user exists in the local database.
  Future<void> ensureAdminUser() async {
    final existing = await getUserByEmail('admin@purepulse.com');
    if (existing == null) {
      final id = 'admin-uuid-default';
      await insertUser({
        'id': id,
        'name': 'Admin',
        'email': 'admin@purepulse.com',
        'password': 'admin123',
        'role': 'admin',
      });
    }
  }
}
