// Widget tests for the Profile screen.
// Tests: delete account button exists, confirmation dialog appears,
//        loading state, logout button exists.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/domain/auth/user.dart';
import 'package:gym_app/domain/core/failures.dart';
import 'package:gym_app/domain/core/result.dart';
import 'package:gym_app/features/auth/application/auth_notifier.dart';
import 'package:gym_app/features/profile/presentation/screens/profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fake notifier for profile tests (no DB/network)
// ─────────────────────────────────────────────────────────────────────────────

class FakeProfileAuthNotifier extends AuthStateNotifier {
  final User? _user;
  bool deleteAccountCalled = false;
  bool logoutCalled = false;
  Result<void, AuthFailure> deleteResult;

  FakeProfileAuthNotifier({
    User? user,
    this.deleteResult = const Success(null),
  }) : _user = user;

  @override
  FutureOr<User?> build() async => _user;

  @override
  Future<void> logout() async {
    logoutCalled = true;
    state = const AsyncValue.data(null);
  }

  @override
  Future<Result<void, AuthFailure>> deleteAccount() async {
    deleteAccountCalled = true;
    if (deleteResult is Success) {
      state = const AsyncValue.data(null);
    }
    return deleteResult;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

const _testUser = User(
  id: 'u1',
  name: 'Test User',
  email: 'test@example.com',
  role: UserRole.user,
);

Widget wrapProfileScreen({FakeProfileAuthNotifier? notifier}) {
  final n = notifier ?? FakeProfileAuthNotifier(user: _testUser);
  return ProviderScope(
    overrides: [
      authStateNotifierProvider.overrideWith(() => n),
    ],
    child: const MaterialApp(home: ProfileScreen()),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('ProfileScreen', () {
    testWidgets('renders My Profile heading', (tester) async {
      await tester.pumpWidget(wrapProfileScreen());
      await tester.pump();
      expect(find.text('My Profile'), findsOneWidget);
    });

    testWidgets('shows user name', (tester) async {
      await tester.pumpWidget(wrapProfileScreen());
      await tester.pump();
      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('shows user email', (tester) async {
      await tester.pumpWidget(wrapProfileScreen());
      await tester.pump();
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('shows role badge', (tester) async {
      await tester.pumpWidget(wrapProfileScreen());
      await tester.pump();
      expect(find.text('USER'), findsOneWidget);
    });

    testWidgets('shows Logout button', (tester) async {
      await tester.pumpWidget(wrapProfileScreen());
      await tester.pump();
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('shows Delete Account button', (tester) async {
      await tester.pumpWidget(wrapProfileScreen());
      await tester.pump();
      expect(find.text('Delete Account'), findsOneWidget);
    });

    testWidgets('Delete Account button shows delete_forever icon',
        (tester) async {
      await tester.pumpWidget(wrapProfileScreen());
      await tester.pump();
      expect(find.byIcon(Icons.delete_forever), findsOneWidget);
    });

    testWidgets('tapping Delete Account shows confirmation dialog',
        (tester) async {
      await tester.pumpWidget(wrapProfileScreen());
      await tester.pump();

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Delete Account'), findsWidgets);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('cancelling delete dialog does NOT call deleteAccount',
        (tester) async {
      final notifier = FakeProfileAuthNotifier(user: _testUser);
      await tester.pumpWidget(wrapProfileScreen(notifier: notifier));
      await tester.pump();

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(notifier.deleteAccountCalled, isFalse);
    });

    testWidgets('confirming delete calls deleteAccount', (tester) async {
      final notifier = FakeProfileAuthNotifier(user: _testUser);
      await tester.pumpWidget(wrapProfileScreen(notifier: notifier));
      await tester.pump();

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      // Confirm deletion
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(notifier.deleteAccountCalled, isTrue);
    });

    testWidgets('shows error snackbar when delete fails', (tester) async {
      final notifier = FakeProfileAuthNotifier(
        user: _testUser,
        deleteResult: const Failure(AuthFailure('Failed to delete')),
      );
      await tester.pumpWidget(wrapProfileScreen(notifier: notifier));
      await tester.pump();

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to delete'), findsOneWidget);
    });

    testWidgets('Contact Information card is visible', (tester) async {
      await tester.pumpWidget(wrapProfileScreen());
      await tester.pump();
      expect(find.text('Contact Information'), findsOneWidget);
    });

    testWidgets('Email label is shown in contact card', (tester) async {
      await tester.pumpWidget(wrapProfileScreen());
      await tester.pump();
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('admin role shows ADMIN badge', (tester) async {
      const adminUser = User(
        id: 'admin-1',
        name: 'Admin User',
        email: 'admin@purepulse.com',
        role: UserRole.admin,
      );
      final notifier = FakeProfileAuthNotifier(user: adminUser);
      await tester.pumpWidget(wrapProfileScreen(notifier: notifier));
      await tester.pump();
      expect(find.text('ADMIN'), findsOneWidget);
    });
  });
}
