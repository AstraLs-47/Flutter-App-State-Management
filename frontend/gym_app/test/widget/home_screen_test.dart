import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_app/features/dashboard/presentation/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

GoRouter _testRouter() => GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: '/announcements',
      name: 'announcements',
      builder: (_, _) => const Scaffold(body: Text('Announcements')),
    ),
  ],
);

Widget _wrap() =>
    ProviderScope(child: MaterialApp.router(routerConfig: _testRouter()));

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HomeScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('renders THE PULSE branding text', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('THE PULSE'), findsOneWidget);
    });

    testWidgets('renders notifications icon', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.notifications_none_outlined), findsOneWidget);
    });
  });
}
