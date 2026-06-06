import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_app/features/workout/presentation/screens/add_workout_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
//
// AddWorkoutScreen uses ExerciseRepository and WorkoutStore singletons
// internally.  Both make async calls but the widget handles errors gracefully.
// We just need the screen to render — the exercise dropdown will be empty
// (loading from a failing repo) which is fine for UI-assertion tests.
// ---------------------------------------------------------------------------
GoRouter _router() => GoRouter(
  initialLocation: '/tracking/add',
  routes: [
    GoRoute(
      path: '/tracking',
      name: 'tracking',
      builder: (_, _) => const Scaffold(body: Text('Tracking')),
      routes: [
        GoRoute(
          path: 'add',
          name: 'trackingAdd',
          builder: (_, _) => const AddWorkoutScreen(),
        ),
      ],
    ),
  ],
);

Widget _buildApp() =>
    ProviderScope(child: MaterialApp.router(routerConfig: _router()));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  group('AddWorkoutScreen widget tests', () {
    testWidgets('renders the Log Workout title', (tester) async {
      await tester.pumpWidget(_buildApp());
      // Pump a couple of frames to let initState / _loadExercises settle.
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Log Workout'), findsOneWidget);
    });

    testWidgets('exercise dropdown (EXERCISE label) is present', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // The label "EXERCISE *" is rendered above the dropdown.
      expect(find.textContaining('EXERCISE'), findsOneWidget);
    });

    testWidgets('duration field label is present', (tester) async {
      await tester.pumpWidget(_buildApp());
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.textContaining('Duration'), findsOneWidget);
    });

    testWidgets('Log Workout save button is present', (tester) async {
      await tester.pumpWidget(_buildApp());
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // The ElevatedButton contains "Log Workout 🔥"
      expect(find.textContaining('Log Workout'), findsWidgets);
    });

    testWidgets('intensity buttons (Light / Moderate / Intense) are present', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);
      expect(find.text('Intense'), findsOneWidget);
    });

    testWidgets('back button is present', (tester) async {
      await tester.pumpWidget(_buildApp());
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}
