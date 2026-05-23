import 'package:uuid/uuid.dart';

import '../../../domain/auth/auth_facade.dart';
import '../../../domain/auth/user.dart';
import '../../../domain/core/result.dart';
import '../../../domain/core/failures.dart';
import 'auth_local_data_source.dart';
import 'auth_remote_data_source.dart';

/// Repository implementation for authentication.
///
/// Architecture (DDD / Clean Architecture):
///   Presentation → Application (Notifier) → [this] Repository → DataSources
///
/// Cache strategy:
///   - Login: Remote first (simulated API), falls back to local SQLite.
///   - Session: Local SQLite only (SharedPreferences for token).
///   - Register: Local SQLite (remote is simulated and always fails gracefully).
///   - Delete: Local SQLite only (removes all user-scoped data).
class AuthRepositoryImpl implements AuthFacade {
  final AuthLocalDataSource _localDataSource;
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._localDataSource, this._remoteDataSource);

  // ── getSignedInUser ────────────────────────────────────────────────────────
  /// Cache-first: reads session from SharedPreferences, then loads user from SQLite.

  @override
  Future<Result<User?, AuthFailure>> getSignedInUser() async {
    await _localDataSource.ensureAdminUser();
    try {
      final email = await _localDataSource.getSessionEmail();
      if (email == null) return const Success(null);

      final userMap = await _localDataSource.getUserByEmail(email);
      if (userMap == null) {
        // Session exists but user was deleted — clear stale session
        await _localDataSource.clearSession();
        return const Success(null);
      }

      return Success(_mapToUser(userMap));
    } catch (e) {
      return Failure(AuthFailure('Failed to restore session: $e'));
    }
  }

  // ── login ──────────────────────────────────────────────────────────────────
  /// Remote-first with local fallback.
  /// 1. Try remote API (simulated; will throw UnimplementedError)
  /// 2. Fall back to local SQLite credential check
  /// 3. Persist session on success

  @override
  Future<Result<User, AuthFailure>> login({
    required String email,
    required String password,
  }) async {
    await _localDataSource.ensureAdminUser();
    try {
      // Attempt remote authentication first (gracefully degrades to local)
      try {
        await _remoteDataSource.login(email, password);
      } catch (_) {
        // Remote unavailable → use local SQLite (expected for local-only setup)
      }

      final normalizedEmail = email.toLowerCase().trim();
      final userMap = await _localDataSource.getUserByCredentials(
        normalizedEmail,
        password,
      );

      if (userMap == null) {
        return const Failure(AuthFailure('Invalid email or password.'));
      }

      await _localDataSource.saveSession(normalizedEmail);
      return Success(_mapToUser(userMap));
    } catch (e) {
      return Failure(AuthFailure('Login failed: $e'));
    }
  }

  // ── register ───────────────────────────────────────────────────────────────
  /// Saves user to local SQLite (remote is simulated for architecture compliance).
  /// Assigns admin role automatically if email matches admin@purepulse.com.

  @override
  Future<Result<User, AuthFailure>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.toLowerCase().trim();

      // Check for duplicate registration
      final existing = await _localDataSource.getUserByEmail(normalizedEmail);
      if (existing != null) {
        return const Failure(
          AuthFailure('An account with this email already exists.'),
        );
      }

      // Attempt remote registration (gracefully ignored if unavailable)
      try {
        await _remoteDataSource.register(name, email, password);
      } catch (_) {}

      final id = const Uuid().v4();
      final role = normalizedEmail == 'admin@purepulse.com' ? 'admin' : 'user';

      await _localDataSource.insertUser({
        'id': id,
        'name': name,
        'email': normalizedEmail,
        'password': password,
        'role': role,
      });

      await _localDataSource.saveSession(normalizedEmail);

      return Success(
        User(
          id: id,
          name: name,
          email: normalizedEmail,
          role: role == 'admin' ? UserRole.admin : UserRole.user,
        ),
      );
    } catch (e) {
      return Failure(AuthFailure('Registration failed: $e'));
    }
  }

  // ── logout ─────────────────────────────────────────────────────────────────
  /// Clears the SharedPreferences session token.

  @override
  Future<void> logout() async {
    await _localDataSource.clearSession();
  }

  // ── deleteAccount ──────────────────────────────────────────────────────────
  /// Permanently removes the authenticated user and ALL their data.
  ///
  /// Authorization: Only the currently signed-in user can delete their own account.
  /// The repository verifies the active session before proceeding.
  ///
  /// Data deleted (in order to respect no FK constraint cascades):
  ///   1. workouts      WHERE userId = ?
  ///   2. health_records WHERE userId = ?
  ///   3. users          WHERE id = ?
  ///   4. SharedPreferences session

  @override
  Future<Result<void, AuthFailure>> deleteAccount() async {
    try {
      final email = await _localDataSource.getSessionEmail();
      if (email == null) {
        return const Failure(AuthFailure('No active user session found.'));
      }

      final userMap = await _localDataSource.getUserByEmail(email);
      if (userMap != null) {
        final userId = userMap['id'] as String;

        // Delete all user-scoped data before removing the user record
        await _localDataSource.deleteUserWorkouts(userId);
        await _localDataSource.deleteUserHealthRecords(userId);
        await _localDataSource.deleteUser(userId);
      }

      // Clear session regardless
      await logout();
      return const Success(null);
    } catch (e) {
      return Failure(AuthFailure('Failed to delete account: $e'));
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  User _mapToUser(Map<String, dynamic> map) {
    final role = map['role'] == 'admin' ? UserRole.admin : UserRole.user;
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      role: role,
    );
  }
}
