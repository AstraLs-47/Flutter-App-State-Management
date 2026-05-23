// Widget tests for authentication screens
// Tests UI elements, form validation, and basic interactions.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/domain/auth/user.dart';
import 'package:gym_app/domain/core/failures.dart';
import 'package:gym_app/domain/core/result.dart';
import 'package:gym_app/features/auth/application/auth_notifier.dart';
import 'package:gym_app/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:gym_app/features/auth/presentation/screens/sign_up_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fake AuthStateNotifier for widget tests (no DB/network)
// ─────────────────────────────────────────────────────────────────────────────

class FakeAuthNotifier extends AuthStateNotifier {
  Result<User, AuthFailure>? loginResult;
  Result<User, AuthFailure>? registerResult;

  FakeAuthNotifier({this.loginResult, this.registerResult});

  @override
  FutureOr<User?> build() async => null;

  @override
  Future<Result<User, AuthFailure>> login(String email, String password) async {
    final result = loginResult ??
        const Failure<User, AuthFailure>(AuthFailure('Login failed'));
    if (result is Success<User, AuthFailure>) {
      state = AsyncValue.data(result.value);
    }
    return result;
  }

  @override
  Future<Result<User, AuthFailure>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final result = registerResult ??
        const Failure<User, AuthFailure>(AuthFailure('Register failed'));
    if (result is Success<User, AuthFailure>) {
      state = AsyncValue.data(result.value);
    }
    return result;
  }

  @override
  Future<void> logout() async {
    state = const AsyncValue.data(null);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget buildSignInScreen({FakeAuthNotifier? notifier}) {
  final fakeNotifier = notifier ?? FakeAuthNotifier();
  return ProviderScope(
    overrides: [
      authStateNotifierProvider.overrideWith(() => fakeNotifier),
    ],
    child: const MaterialApp(home: SignInScreen()),
  );
}

Widget buildSignUpScreen({FakeAuthNotifier? notifier}) {
  final fakeNotifier = notifier ?? FakeAuthNotifier();
  return ProviderScope(
    overrides: [
      authStateNotifierProvider.overrideWith(() => fakeNotifier),
    ],
    child: const MaterialApp(home: SignUpScreen()),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('SignInScreen', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(buildSignInScreen());
      await tester.pump();

      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('renders Sign In button', (tester) async {
      await tester.pumpWidget(buildSignInScreen());
      await tester.pump();
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('shows PUREPULSE branding', (tester) async {
      await tester.pumpWidget(buildSignInScreen());
      await tester.pump();
      expect(find.textContaining('PURE'), findsOneWidget);
    });

    testWidgets('shows Welcome Back heading', (tester) async {
      await tester.pumpWidget(buildSignInScreen());
      await tester.pump();
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('shows validation error when submitting empty form',
        (tester) async {
      await tester.pumpWidget(buildSignInScreen());
      await tester.pump();

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Email address is required'), findsOneWidget);
    });

    testWidgets('shows password validation error for empty password',
        (tester) async {
      await tester.pumpWidget(buildSignInScreen());
      await tester.pump();

      await tester.enterText(
        find.byType(TextFormField).first,
        'test@test.com',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows link to Sign Up screen', (tester) async {
      await tester.pumpWidget(buildSignInScreen());
      await tester.pump();
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('shows error snackbar on failed login', (tester) async {
      final notifier = FakeAuthNotifier(
        loginResult: const Failure(AuthFailure('Invalid email or password.')),
      );
      await tester.pumpWidget(buildSignInScreen(notifier: notifier));
      await tester.pump();

      await tester.enterText(
          find.byType(TextFormField).first, 'wrong@email.com');
      await tester.enterText(find.byType(TextFormField).last, 'wrongpass');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid email or password.'), findsOneWidget);
    });
  });

  group('SignUpScreen', () {
    testWidgets('renders name, email, password fields', (tester) async {
      await tester.pumpWidget(buildSignUpScreen());
      await tester.pump();

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('renders Sign Up button', (tester) async {
      await tester.pumpWidget(buildSignUpScreen());
      await tester.pump();
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('shows Create Account heading', (tester) async {
      await tester.pumpWidget(buildSignUpScreen());
      await tester.pump();
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('shows tagline text', (tester) async {
      await tester.pumpWidget(buildSignUpScreen());
      await tester.pump();
      expect(find.text('Start your fitness journey today'), findsOneWidget);
    });

    testWidgets('shows name validation error when empty', (tester) async {
      await tester.pumpWidget(buildSignUpScreen());
      await tester.pump();

      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      expect(find.text('Full name is required'), findsOneWidget);
    });

    testWidgets('shows email validation error for invalid format',
        (tester) async {
      await tester.pumpWidget(buildSignUpScreen());
      await tester.pump();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'John Doe');
      await tester.enterText(fields.at(1), 'not-an-email');
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      expect(
          find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('shows password validation error for short password',
        (tester) async {
      await tester.pumpWidget(buildSignUpScreen());
      await tester.pump();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'John Doe');
      await tester.enterText(fields.at(1), 'john@test.com');
      await tester.enterText(fields.at(2), '123');
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      expect(
          find.text('Password must be at least 6 characters long'),
          findsOneWidget);
    });

    testWidgets('shows link to sign in', (tester) async {
      await tester.pumpWidget(buildSignUpScreen());
      await tester.pump();
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('shows error snackbar on failed registration', (tester) async {
      final notifier = FakeAuthNotifier(
        registerResult: const Failure(
            AuthFailure('An account with this email already exists.')),
      );
      await tester.pumpWidget(buildSignUpScreen(notifier: notifier));
      await tester.pump();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'John Doe');
      await tester.enterText(fields.at(1), 'exists@example.com');
      await tester.enterText(fields.at(2), 'password123');
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(
        find.text('An account with this email already exists.'),
        findsOneWidget,
      );
    });
  });
}
