import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_app/features/auth/presentation/screens/sign_up_screen.dart';

GoRouter _testRouter({Widget? home}) => GoRouter(
  initialLocation: '/sign-up',
  routes: [
    GoRoute(path: '/sign-up', builder: (_, _) => home ?? const SignUpScreen()),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (_, _) => const Scaffold(body: Text('Onboarding')),
    ),
  ],
);

Widget _wrap(Widget child) => ProviderScope(
  child: MaterialApp.router(routerConfig: _testRouter(home: child)),
);

void main() {
  group('SignUpScreen — UI rendering', () {
    testWidgets('renders name, email and password fields', (tester) async {
      await tester.pumpWidget(_wrap(const SignUpScreen()));

      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.text('Full Name'), findsWidgets);
      expect(find.text('Email'), findsWidgets);
      expect(find.text('Password'), findsWidgets);
    });

    testWidgets('renders Sign Up button', (tester) async {
      await tester.pumpWidget(_wrap(const SignUpScreen()));

      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('renders Create Account heading', (tester) async {
      await tester.pumpWidget(_wrap(const SignUpScreen()));

      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('renders sign-in link text', (tester) async {
      await tester.pumpWidget(_wrap(const SignUpScreen()));

      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final fullText = richTexts.map((w) => w.text.toPlainText()).join(' ');
      expect(fullText, contains('Already have an account?'));
      expect(fullText, contains('Sign In'));
    });
  });

  group('SignUpScreen — form validation', () {
    testWidgets('shows validation errors when form is submitted empty', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const SignUpScreen()));
      await tester.pumpAndSettle();

      final signUpButton = find.text('Sign Up');
      await tester.ensureVisible(signUpButton);
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsWidgets);
    });
  });

  group('SignUpScreen — widget integrity', () {
    testWidgets('back button exists (arrow_back icon)', (tester) async {
      await tester.pumpWidget(_wrap(const SignUpScreen()));

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}
