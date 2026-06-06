import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_app/features/profile/presentation/screens/contact_us_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
GoRouter _router() => GoRouter(
  initialLocation: '/contact-us',
  routes: [
    GoRoute(
      path: '/contact-us',
      name: 'contactUs',
      builder: (_, _) => const ContactUsScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (_, _) => const Scaffold(body: Text('Profile')),
    ),
  ],
);

Widget _buildApp() =>
    ProviderScope(child: MaterialApp.router(routerConfig: _router()));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  group('ContactUsScreen widget tests', () {
    testWidgets('renders the Contact Us heading', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      // The heading is a RichText with "Contact " + "Us"
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final allText = richTexts.map((w) => w.text.toPlainText()).join(' ');
      expect(allText, contains('Contact'));
      expect(allText, contains('Us'));
    });

    testWidgets('displays the phone contact item', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.text('Phone'), findsOneWidget);
    });

    testWidgets('displays the email contact item', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('displays the location contact item', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.text('Location'), findsOneWidget);
    });

    testWidgets('back button (arrow_back icon) is present', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}
