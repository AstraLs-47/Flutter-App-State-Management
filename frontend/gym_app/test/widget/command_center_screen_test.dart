import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_app/features/admin/presentation/screens/command_center_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

GoRouter _testRouter() => GoRouter(
  initialLocation: '/admin',
  routes: [
    GoRoute(path: '/admin', builder: (_, _) => const CommandCenterScreen()),
    GoRoute(
      path: '/sign-in',
      name: 'signIn',
      builder: (_, _) => const Scaffold(body: Text('Sign In')),
    ),
  ],
);

Widget _wrap() => MaterialApp.router(routerConfig: _testRouter());

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CommandCenterScreen Widget', () {
    testWidgets('renders command center headers', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.text('ADMIN'), findsOneWidget);
      expect(find.text('Command Center'), findsOneWidget);
    });

    testWidgets('renders refresh and exit icons', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.exit_to_app), findsOneWidget);
    });

    testWidgets('shows loading state initially', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
