import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/database_helper.dart';
import '../../../domain/auth/user.dart';
import '../../../domain/core/result.dart';
import '../../../domain/core/failures.dart';
import '../infrastructure/auth_local_data_source.dart';
import '../infrastructure/auth_remote_data_source.dart';
import '../infrastructure/auth_repository_impl.dart';

part 'auth_notifier.g.dart';

// ─── Repository Provider ─────────────────────────────────────────────────────

@riverpod
AuthRepositoryImpl authDddRepository(Ref ref) {
  final local = AuthLocalDataSource(DatabaseHelper());
  final remote = AuthRemoteDataSource();
  return AuthRepositoryImpl(local, remote);
}

// ─── Auth State Notifier ─────────────────────────────────────────────────────
/// Manages authentication state using Riverpod 3 AsyncNotifier.
/// State: AsyncValue<User?>
///   - null  → not authenticated
///   - User  → authenticated (carries role for authorization)
///
/// Authorization is enforced by the GoRouter redirect in app_router.dart
/// which reads this state and restricts/allows routes based on user.role.

@riverpod
class AuthStateNotifier extends _$AuthStateNotifier {
  @override
  FutureOr<User?> build() async {
    return _getSignedInUser();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<User?> _getSignedInUser() async {
    final repo = ref.read(authDddRepositoryProvider);
    final result = await repo.getSignedInUser();
    if (result is Success<User?, AuthFailure>) {
      return result.value;
    }
    return null;
  }

  // ── Public methods ─────────────────────────────────────────────────────────

  /// Authenticates user with email/password.
  /// On success: state = AsyncData(User) → router redirects to dashboard/admin.
  /// On failure: state = AsyncData(null) → stays on sign-in screen.
  Future<Result<User, AuthFailure>> login(
    String email,
    String password,
  ) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authDddRepositoryProvider);
    final result = await repo.login(email: email, password: password);

    if (result is Success<User, AuthFailure>) {
      state = AsyncValue.data(result.value);
    } else {
      // Restore null state so router doesn't redirect
      state = const AsyncValue.data(null);
    }
    return result;
  }

  /// Registers a new user account.
  /// On success: state = AsyncData(User) → router redirects to onboarding.
  Future<Result<User, AuthFailure>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authDddRepositoryProvider);
    final result = await repo.register(
      name: name,
      email: email,
      password: password,
    );

    if (result is Success<User, AuthFailure>) {
      state = AsyncValue.data(result.value);
    } else {
      state = const AsyncValue.data(null);
    }
    return result;
  }

  /// Logs out the current user.
  /// Clears session → state = AsyncData(null) → router redirects to landing.
  Future<void> logout() async {
    final repo = ref.read(authDddRepositoryProvider);
    await repo.logout();
    state = const AsyncValue.data(null);
  }

  /// Permanently deletes the authenticated user's account.
  ///
  /// Authorization flow:
  ///   1. Verifies active session exists
  ///   2. Deletes all user-scoped data (workouts, health records)
  ///   3. Deletes the user record from SQLite
  ///   4. Clears the session
  ///   5. Sets state = null → router redirect fires → lands on root
  ///
  /// Returns Success(null) on success, Failure(AuthFailure) on error.
  Future<Result<void, AuthFailure>> deleteAccount() async {
    final repo = ref.read(authDddRepositoryProvider);
    final result = await repo.deleteAccount();

    if (result is Success<void, AuthFailure>) {
      // Session cleared by repo — set state to null to trigger router redirect
      state = const AsyncValue.data(null);
    }
    return result;
  }

  // ── Convenience getters ───────────────────────────────────────────────────

  User? get currentUser => state.valueOrNull;

  /// True only for authenticated admin users.
  /// Used by admin UI widgets for conditional rendering.
  bool get isAdmin => state.valueOrNull?.role == UserRole.admin;
}
