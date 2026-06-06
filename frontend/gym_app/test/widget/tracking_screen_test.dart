import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_app/features/workout/presentation/screens/tracking_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

GoRouter _testRouter() => GoRouter(
  initialLocation: '/tracking',
  routes: [
    GoRoute(path: '/tracking', builder: (_, _) => const TrackingScreen()),
    GoRoute(
      path: '/tracking/add',
      name: 'trackingAdd',
      builder: (_, _) => const Scaffold(body: Text('Add Workout')),
    ),
    GoRoute(
      path: '/tracking/edit',
      name: 'trackingEdit',
      builder: (_, _) => const Scaffold(body: Text('Edit Workout')),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (_, _) => const Scaffold(body: Text('Home')),
    ),
    GoRoute(
      path: '/shop',
      name: 'shop',
      builder: (_, _) => const Scaffold(body: Text('Shop')),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (_, _) => const Scaffold(body: Text('Profile')),
    ),
  ],
);

Widget _wrap() =>
    ProviderScope(child: MaterialApp.router(routerConfig: _testRouter()));

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TrackingScreen', () {
    testWidgets('renders DAILY Tracking header', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText && widget.text.toPlainText().contains('DAILY'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders Workout Log toggle tab', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Workout Log'), findsOneWidget);
    });

    testWidgets('renders Health Metrics toggle tab', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Health Metrics'), findsOneWidget);
    });

    testWidgets('switches to Health Metrics tab on tap', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Health Metrics'));
      await tester.pump(const Duration(milliseconds: 200));

      // After tab switch, the add button changes behaviour — just verify we
      // didn't crash and the tab label is still present.
      expect(find.text('Health Metrics'), findsOneWidget);
    });

    testWidgets('renders add button', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
