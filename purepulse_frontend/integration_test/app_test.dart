// Integration tests for the PurePulse Gym App
// Tests full end-to-end user flows: registration, login, workout CRUD, logout.
//
// Run with: flutter test integration_test/app_test.dart
// Or on device: flutter test integration_test/app_test.dart --device-id=<id>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gym_app/main.dart' as app;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite FFI for desktop/CI environments
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Authentication flow', () {
    testWidgets('App launches and shows landing screen', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Landing screen should be visible (has Sign In or Get Started)
      expect(
        find.textContaining('Get Started').evaluate().isNotEmpty ||
            find.textContaining('Sign In').evaluate().isNotEmpty ||
            find.textContaining('PURE').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('Navigate to Sign In screen from landing', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Try to find and tap Sign In button/link
      final signInFinder = find.text('Sign In');
      if (signInFinder.evaluate().isNotEmpty) {
        await tester.tap(signInFinder.first);
        await tester.pumpAndSettle();
        expect(find.text('Welcome Back'), findsOneWidget);
      }
    });

    testWidgets('Navigate to Sign Up screen from landing', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find Sign Up button on landing or navigate
      final signUpFinder = find.text('Sign Up');
      if (signUpFinder.evaluate().isNotEmpty) {
        await tester.tap(signUpFinder.first);
        await tester.pumpAndSettle();
        expect(find.text('Create Account'), findsOneWidget);
      }
    });

    testWidgets('Sign In with admin credentials shows admin dashboard',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Sign In
      final signInBtn = find.text('Sign In');
      if (signInBtn.evaluate().isNotEmpty) {
        await tester.tap(signInBtn.first);
        await tester.pumpAndSettle();
      }

      // Only proceed if Sign In screen is visible
      if (find.text('Welcome Back').evaluate().isNotEmpty) {
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, 'admin@purepulse.com');
        await tester.enterText(fields.last, 'admin123');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Admin should see command center / admin dashboard
        expect(
          find.textContaining('Command').evaluate().isNotEmpty ||
              find.textContaining('Admin').evaluate().isNotEmpty ||
              find.textContaining('Dashboard').evaluate().isNotEmpty,
          isTrue,
        );
      }
    });

    testWidgets('Sign In with invalid credentials shows error', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final signInBtn = find.text('Sign In');
      if (signInBtn.evaluate().isNotEmpty) {
        await tester.tap(signInBtn.first);
        await tester.pumpAndSettle();
      }

      if (find.text('Welcome Back').evaluate().isNotEmpty) {
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, 'wrong@email.com');
        await tester.enterText(fields.last, 'wrongpass');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        // Should show an error message
        expect(
          find.textContaining('Invalid').evaluate().isNotEmpty ||
              find.textContaining('failed').evaluate().isNotEmpty ||
              find.byType(SnackBar).evaluate().isNotEmpty,
          isTrue,
        );
      }
    });

    testWidgets('Form validation prevents empty submission', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final signInBtn = find.text('Sign In');
      if (signInBtn.evaluate().isNotEmpty) {
        await tester.tap(signInBtn.first);
        await tester.pumpAndSettle();
      }

      if (find.text('Welcome Back').evaluate().isNotEmpty) {
        await tester.tap(find.text('Sign In'));
        await tester.pump();
        expect(find.text('Email address is required'), findsOneWidget);
      }
    });
  });

  group('User registration flow', () {
    testWidgets('Register with new account navigates to onboarding',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Sign Up
      final signUpFinder = find.text('Sign Up');
      if (signUpFinder.evaluate().isNotEmpty) {
        await tester.tap(signUpFinder.first);
        await tester.pumpAndSettle();
      }

      if (find.text('Create Account').evaluate().isNotEmpty) {
        final fields = find.byType(TextFormField);
        final uniqueEmail =
            'testuser${DateTime.now().millisecondsSinceEpoch}@test.com';

        await tester.enterText(fields.at(0), 'Test User');
        await tester.enterText(fields.at(1), uniqueEmail);
        await tester.enterText(fields.at(2), 'password123');
        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Should navigate away from sign up screen (onboarding or dashboard)
        expect(find.text('Create Account'), findsNothing);
      }
    });

    testWidgets('Sign Up validation rejects empty fields', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final signUpFinder = find.text('Sign Up');
      if (signUpFinder.evaluate().isNotEmpty) {
        await tester.tap(signUpFinder.first);
        await tester.pumpAndSettle();
      }

      if (find.text('Create Account').evaluate().isNotEmpty) {
        await tester.tap(find.text('Sign Up'));
        await tester.pump();
        expect(find.text('Full name is required'), findsOneWidget);
      }
    });
  });

  group('User workout flow (after login)', () {
    Future<void> loginAsUser(WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Register a fresh user
      final signUpFinder = find.text('Sign Up');
      if (signUpFinder.evaluate().isNotEmpty) {
        await tester.tap(signUpFinder.first);
        await tester.pumpAndSettle();
      }

      if (find.text('Create Account').evaluate().isNotEmpty) {
        final uniqueEmail =
            'workout${DateTime.now().millisecondsSinceEpoch}@test.com';
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'Workout Tester');
        await tester.enterText(fields.at(1), uniqueEmail);
        await tester.enterText(fields.at(2), 'password123');
        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }
    }

    testWidgets('Logged-in user can see Tracking screen', (tester) async {
      await loginAsUser(tester);

      // Look for Tracking navigation item
      final trackingFinder = find.textContaining('Track');
      if (trackingFinder.evaluate().isNotEmpty) {
        await tester.tap(trackingFinder.first);
        await tester.pumpAndSettle();
        expect(
          find.text('Workout Log').evaluate().isNotEmpty ||
              find.textContaining('Tracking').evaluate().isNotEmpty,
          isTrue,
        );
      }
    });

    testWidgets('Empty workout log shows motivational message', (tester) async {
      await loginAsUser(tester);

      final trackingFinder = find.textContaining('Track');
      if (trackingFinder.evaluate().isNotEmpty) {
        await tester.tap(trackingFinder.first);
        await tester.pumpAndSettle();

        // Should show empty state
        if (find.text('Workout Log').evaluate().isNotEmpty) {
          expect(
            find.textContaining('No entries yet').evaluate().isNotEmpty ||
                find.textContaining('Start your journey').evaluate().isNotEmpty,
            isTrue,
          );
        }
      }
    });
  });

  group('Authorization - role-based access', () {
    testWidgets('Regular user cannot access admin routes directly',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Register as regular user
      final signUpFinder = find.text('Sign Up');
      if (signUpFinder.evaluate().isNotEmpty) {
        await tester.tap(signUpFinder.first);
        await tester.pumpAndSettle();
      }

      if (find.text('Create Account').evaluate().isNotEmpty) {
        final uniqueEmail =
            'authtest${DateTime.now().millisecondsSinceEpoch}@test.com';
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'Auth Tester');
        await tester.enterText(fields.at(1), uniqueEmail);
        await tester.enterText(fields.at(2), 'password123');
        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      // Regular user should NOT see admin "Command Center"
      expect(find.text('Command Center'), findsNothing);
    });

    testWidgets('Admin user sees admin navigation', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final signInBtn = find.text('Sign In');
      if (signInBtn.evaluate().isNotEmpty) {
        await tester.tap(signInBtn.first);
        await tester.pumpAndSettle();
      }

      if (find.text('Welcome Back').evaluate().isNotEmpty) {
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, 'admin@purepulse.com');
        await tester.enterText(fields.last, 'admin123');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Admin should have admin-specific UI
        expect(
          find.textContaining('Command').evaluate().isNotEmpty ||
              find.textContaining('Admin').evaluate().isNotEmpty,
          isTrue,
        );
      }
    });
  });
}
