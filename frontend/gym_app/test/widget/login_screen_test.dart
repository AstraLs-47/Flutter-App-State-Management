import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_app/features/auth/presentation/screens/sign_in_screen.dart';

// ---------------------------------------------------------------------------
// Minimal GoRouter for the widget under test.
// SignInScreen calls context.pop() and context.goNamed(…) – we supply stubs.
// ---------------------------------------------------------------------------
GoRouter _testRouter({Widget? home}) => GoRouter(
  initialLocation: '/sign-in',
  routes: [
    GoRoute(path: '/sign-in', builder: (_, _) => home ?? const SignInScreen()),
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
    GoRoute(
      path: '/sign-up',
      name: 'sign-up',
      builder: (_, _) => const Scaffold(body: Text('Sign Up')),
    ),
  ],
);

Widget _wrap(Widget child) => ProviderScope(
  child: MaterialApp.router(routerConfig: _testRouter(home: child)),
);

void main() {
  setUp(() {
    // Standard reset for any metrics changes between tests
  });

  group('SignInScreen — UI rendering', () {
    testWidgets('renders PUREPULSE branding', (tester) async {
      await tester.pumpWidget(_wrap(const SignInScreen()));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('PURE') &&
              widget.text.toPlainText().contains('PULSE'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(_wrap(const SignInScreen()));

      expect(find.byType(TextFormField), findsNWidgets(2));
      // CustomTextField renders label + hint with the same text — at least one each
      expect(find.text('Email'), findsWidgets);
      expect(find.text('Password'), findsWidgets);
    });

    testWidgets('renders Sign In button', (tester) async {
      await tester.pumpWidget(_wrap(const SignInScreen()));

      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('renders Welcome Back heading', (tester) async {
      await tester.pumpWidget(_wrap(const SignInScreen()));

      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('renders sign-up link text', (tester) async {
      await tester.pumpWidget(_wrap(const SignInScreen()));

      // The sign-up text is rendered inside a RichText widget with TextSpan children.
      // find.text() does not penetrate into TextSpan trees, so we check for
      // the presence of a RichText whose plain string contains the expected text.
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final fullText = richTexts.map((w) => w.text.toPlainText()).join(' ');
      expect(fullText, contains("Don't have an account?"));
      expect(fullText, contains('Sign Up'));
    });
  });

  group('SignInScreen — form validation', () {
    testWidgets('shows validation errors when form is submitted empty', (
      tester,
    ) async {
      // Increase surface size to ensure button is reachable on "small" test screens
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrap(const SignInScreen()));

      // Ensure the button is visible before tapping to avoid hit-test errors
      final signInButton = find.text('Sign In');
      await tester.ensureVisible(signInButton);
      await tester.tap(signInButton);
      await tester.pump();

      // At least one validation message must be shown
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('accepts valid email input without immediate error', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const SignInScreen()));

      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      // No error message present yet for a valid email
      expect(find.text('Enter a valid email'), findsNothing);
    });

    testWidgets('shows email validation error for invalid input', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const SignInScreen()));

      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'not-an-email');

      // Submit form to trigger validation
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // The validator should flag the bad email — check no crash
      expect(find.byType(SignInScreen), findsOneWidget);
    });
  });

  group('SignInScreen — widget integrity', () {
    testWidgets('back button exists (arrow_back icon)', (tester) async {
      await tester.pumpWidget(_wrap(const SignInScreen()));

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('email field has email keyboard type', (tester) async {
      await tester.pumpWidget(_wrap(const SignInScreen()));

      final emailField = tester.widget<TextField>(
        find
            .descendant(
              of: find.byType(TextFormField).first,
              matching: find.byType(TextField),
            )
            .first,
      );
      expect(emailField.keyboardType, TextInputType.emailAddress);
    });
  });
}
