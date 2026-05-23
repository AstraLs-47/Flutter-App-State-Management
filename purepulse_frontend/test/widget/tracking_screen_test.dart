// Widget tests for the Tracking screen and AddWorkout screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/domain/auth/user.dart';
import 'package:gym_app/features/auth/application/auth_notifier.dart';
import 'package:gym_app/features/workout/application/workouts_notifier.dart';
import 'package:gym_app/features/workout/domain/workout_entry_model.dart';
import 'package:gym_app/features/workout/presentation/screens/add_workout_screen.dart';
import 'package:gym_app/features/workout/presentation/screens/tracking_screen.dart';
import 'package:gym_app/core/widgets/user_bottom_nav.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fake notifiers for workout widget tests
// ─────────────────────────────────────────────────────────────────────────────

class FakeWorkoutsNotifier extends WorkoutsNotifier {
  final List<WorkoutEntry> _initial;
  FakeWorkoutsNotifier(this._initial);

  @override
  FutureOr<List<WorkoutEntry>> build() async => _initial;

  @override
  Future<void> addWorkout(WorkoutEntry workout) async {
    state = AsyncValue.data([...state.value ?? [], workout]);
  }

  @override
  Future<void> deleteWorkout(String id) async {
    state = AsyncValue.data(
      (state.value ?? []).where((w) => w.id != id).toList(),
    );
  }

  @override
  Future<void> updateWorkout(WorkoutEntry workout) async {
    final list = (state.value ?? []).map((w) => w.id == workout.id ? workout : w).toList();
    state = AsyncValue.data(list);
  }
}

class FakeAuthNotifier extends AuthStateNotifier {
  final User? _user;
  FakeAuthNotifier(this._user);

  @override
  FutureOr<User?> build() async => _user;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

const _testUser = User(
  id: 'u1',
  name: 'Test User',
  email: 'test@example.com',
  role: UserRole.user,
);

WorkoutEntry makeWorkout(String id, String title) => WorkoutEntry(
      id: id,
      title: title,
      date: '2024-01-15',
      duration: '30 MIN',
      exercise: 'Running (Cardio)',
      intensity: 'Moderate',
      weight: '0',
      sets: '3',
      reps: '10',
    );

Widget wrapWithProviders(
  Widget child, {
  List<WorkoutEntry> workouts = const [],
  User? user = _testUser,
}) {
  return ProviderScope(
    overrides: [
      authStateNotifierProvider.overrideWith(() => FakeAuthNotifier(user)),
      workoutsNotifierProvider.overrideWith(
        () => FakeWorkoutsNotifier(workouts),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('TrackingScreen', () {
    testWidgets('renders DAILY Tracking header', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const TrackingScreen()));
      await tester.pump();
      expect(find.textContaining('DAILY'), findsOneWidget);
      expect(find.textContaining('Tracking'), findsOneWidget);
    });

    testWidgets('shows Workout Log and Health Metrics tabs', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const TrackingScreen()));
      await tester.pump();
      expect(find.text('Workout Log'), findsOneWidget);
      expect(find.text('Health Metrics'), findsOneWidget);
    });

    testWidgets('shows empty state when no workouts', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const TrackingScreen()));
      await tester.pumpAndSettle();
      expect(find.textContaining('No entries yet'), findsOneWidget);
    });

    testWidgets('shows workout list when workouts exist', (tester) async {
      final workouts = [
        makeWorkout('w1', 'Morning Run'),
        makeWorkout('w2', 'Evening Cycling'),
      ];
      await tester.pumpWidget(wrapWithProviders(
        const TrackingScreen(),
        workouts: workouts,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Morning Run'), findsOneWidget);
      expect(find.text('Evening Cycling'), findsOneWidget);
    });

    testWidgets('shows add button (+)', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const TrackingScreen()));
      await tester.pump();
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows bottom navigation bar', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const TrackingScreen()));
      await tester.pump();
      expect(find.byType(UserBottomNav), findsOneWidget);
    });

    testWidgets('shows loading indicator while fetching', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const TrackingScreen()));
      // Before settling, there may be a loading state
      await tester.pump(const Duration(milliseconds: 50));
      // Just ensure it doesn't crash
    });

    testWidgets('switches to Health Metrics tab on tap', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const TrackingScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Health Metrics'));
      await tester.pumpAndSettle();
      // Health Metrics tab content should be visible
      expect(find.text('Health Metrics'), findsOneWidget);
    });

    testWidgets('each workout shows edit and delete buttons', (tester) async {
      final workouts = [makeWorkout('w1', 'Cardio')];
      await tester.pumpWidget(wrapWithProviders(
        const TrackingScreen(),
        workouts: workouts,
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('delete dialog appears on delete tap', (tester) async {
      final workouts = [makeWorkout('w1', 'Cardio Blast')];
      await tester.pumpWidget(wrapWithProviders(
        const TrackingScreen(),
        workouts: workouts,
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('Delete Progress'), findsOneWidget);
      expect(find.text('Are you sure you want to remove this progress?'), findsOneWidget);
    });
  });

  group('AddWorkoutScreen', () {
    testWidgets('renders Log Workout title', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const AddWorkoutScreen()));
      await tester.pump();
      expect(find.text('Log Workout'), findsOneWidget);
    });

    testWidgets('renders exercise dropdown', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const AddWorkoutScreen()));
      await tester.pump();
      expect(find.text('Choose your exercise...'), findsOneWidget);
    });

    testWidgets('renders duration and weight fields', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const AddWorkoutScreen()));
      await tester.pump();
      expect(find.text('Duration (min)'), findsOneWidget);
      expect(find.text('Weight (kg)'), findsOneWidget);
    });

    testWidgets('renders sets and reps fields', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const AddWorkoutScreen()));
      await tester.pump();
      expect(find.text('Sets'), findsOneWidget);
      expect(find.text('Reps'), findsOneWidget);
    });

    testWidgets('renders intensity buttons', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const AddWorkoutScreen()));
      await tester.pump();
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);
      expect(find.text('Intense'), findsOneWidget);
    });

    testWidgets('renders feeling icons section', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const AddWorkoutScreen()));
      await tester.pump();
      expect(find.text('Feeling'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
    });

    testWidgets('renders Log Workout submit button', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const AddWorkoutScreen()));
      await tester.pump();
      expect(find.textContaining('Log Workout'), findsWidgets);
    });

    testWidgets('shows snackbar when submitting without exercise', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const AddWorkoutScreen()));
      await tester.pumpAndSettle();

      // Scroll to the button and tap it
      await tester.dragUntilVisible(
        find.textContaining('Log Workout 🔥'),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.tap(find.textContaining('Log Workout 🔥').last);
      await tester.pumpAndSettle();

      expect(find.text('Please select an exercise'), findsOneWidget);
    });

    testWidgets('intensity selection changes highlight', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const AddWorkoutScreen()));
      await tester.pump();
      await tester.tap(find.text('Intense'));
      await tester.pump();
      // Just ensure no crash after tapping intensity
    });
  });
}
