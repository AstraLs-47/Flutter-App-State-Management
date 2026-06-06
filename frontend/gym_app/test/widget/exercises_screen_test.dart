import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_app/features/exercises/presentation/screens/exercises_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

GoRouter _testRouter() => GoRouter(
  initialLocation: '/exercises',
  routes: [
    GoRoute(path: '/exercises', builder: (_, _) => const ExercisesScreen()),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (_, _) => const Scaffold(body: Text('Home')),
    ),
    GoRoute(
      path: '/tracking',
      name: 'tracking',
      builder: (_, _) => const Scaffold(body: Text('Tracking')),
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

Widget _wrap() => MaterialApp.router(routerConfig: _testRouter());

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ExercisesScreen Widget', () {
    testWidgets('renders title headers', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.text('WORKOUT'), findsOneWidget);
      // Header has "Exercises" with fontSize 28
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data == 'Exercises' &&
              widget.style?.fontSize == 28,
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders category chips and shows loading state', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('All'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
