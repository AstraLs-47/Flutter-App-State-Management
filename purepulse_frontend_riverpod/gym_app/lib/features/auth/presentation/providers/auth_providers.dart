// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// Project imports:
import '../../../../core/models/user_model.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/auth_repository.dart';
import '../../data/auth_service.dart';
import '../../domain/auth_state.dart';
import '../../domain/user_role.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState.initial()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final loggedIn = await _repository.isLoggedIn();
    if (loggedIn) {
      final user = await _repository.getCurrentUser();
      final role = await _repository.getStoredRole();
      if (user != null) {
        state = AuthState(isAuthenticated: true, user: user, role: role);
      } else {
        state = AuthState.initial();
      }
    } else {
      state = AuthState.initial();
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      final role = await _repository.signIn(email, password);
      final user = await _repository.getCurrentUser();
      state = AuthState(isAuthenticated: true, user: user, role: role);
      return null; // Return null on success
    } catch (e) {
      final errorMsg = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('ApiException: ', '');
      state = state.copyWith(error: errorMsg);
      return errorMsg;
    }
  }

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await _repository.signUp(name: name, email: email, password: password);
      final user = await _repository.getCurrentUser();
      final role = await _repository.getStoredRole();
      state = AuthState(isAuthenticated: true, user: user, role: role);
      return null;
    } catch (e) {
      final errorMsg = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('ApiException: ', '');
      state = state.copyWith(error: errorMsg);
      return errorMsg;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    AuthService.currentUserName = 'User';
    AuthService.currentUserEmail = 'user@example.com';
    state = AuthState.initial();
  }

  Future<void> deleteAccount() async {
    await _repository.deleteAccount();
    AuthService.currentUserName = 'User';
    AuthService.currentUserEmail = 'user@example.com';
    state = AuthState.initial();
  }
}

// Provider Definitions
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final userRoleProvider = Provider<UserRole>((ref) {
  return ref.watch(authProvider).role;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
