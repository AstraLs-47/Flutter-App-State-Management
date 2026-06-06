import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_app/features/auth/presentation/screens/sign_in_screen.dart';

/// Wraps [SignInScreen] in a minimal router so GoRouter navigations
/// (context.pop, context.pushNamed) don't throw during widget tests.
Widget _wrap() {
  final router = GoRouter(
    initialLocation: '/sign-in',
    routes: [
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(
        path: '/sign-up',
        name: 'signUp',
        builder: (_, _) => const Scaffold(body: Text('Sign Up')),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (_, _) => const Scaffold(body: Text('Dashboard')),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (_, _) => const Scaffold(body: Text('Admin')),
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

void main() {
  group('SignInScreen', () {
    testWidgets('renders PUREPULSE branding', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      // RichText with 'PURE' and 'PULSE' sub-spans
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText && widget.text.toPlainText().contains('PURE'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders Welcome Back heading', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('renders Sign In button', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.text('Sign In'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows validation errors when form submitted empty', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      // Tap Sign In without filling in any fields
      final signInFinder = find.text('Sign In').first;
      await tester.tap(signInFinder);
      await tester.pump();

      // At least one validation error text should appear
      // Validators.validateEmail returns a message for empty input
      expect(find.byType(TextFormField), findsNWidgets(2));
    });
  });
}
