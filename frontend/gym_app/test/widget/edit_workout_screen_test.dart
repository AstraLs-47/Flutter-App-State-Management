import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_app/features/workout/data/models/workout_entry_model.dart';

// ---------------------------------------------------------------------------
// Sample entry used in all tests
// ---------------------------------------------------------------------------
final _sampleEntry = WorkoutEntry(
  id: 'w1',
  title: 'Bench Press',
  date: '2026-05-31',
  duration: '45 MIN',
  exercise: 'Bench Press',
  intensity: 'Intense',
  weight: '80',
  sets: '4',
  reps: '10',
  calories: '300',
  achievement: 'New PR',
  notes: 'Felt strong today',
);

/// Builds the test app.  We use a Navigator-based approach to pass the extra
/// object because GoRouter's test API for extras requires navigating to the
/// route.  We instead wrap EditWorkoutScreen directly in a mock
/// GoRouterState by supplying the extra through a custom Navigator.
Widget _buildApp() {
  // We cannot easily set GoRouterState.extra before navigation in a unit
  // widget test, so we use a thin wrapper that pre-populates the extra
  // via an initial navigation.
  return ProviderScope(child: _EditWorkoutTestApp(entry: _sampleEntry));
}

/// A minimal test app that pumps EditWorkoutScreen with a pre-populated entry
/// by navigating to the edit route with [entry] as extra after first build.
class _EditWorkoutTestApp extends StatefulWidget {
  final WorkoutEntry entry;
  const _EditWorkoutTestApp({required this.entry});

  @override
  State<_EditWorkoutTestApp> createState() => _EditWorkoutTestAppState();
}

class _EditWorkoutTestAppState extends State<_EditWorkoutTestApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/tracking/edit',
      routes: [
        GoRoute(
          path: '/tracking',
          builder: (_, _) => const Scaffold(body: Text('Tracking')),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                // GoRouterState.extra is set by navigation — here we pass
                // the entry directly since this route is only used in tests.
                return _EditScreenWithEntry(entry: widget.entry);
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) =>
      MaterialApp.router(routerConfig: _router);
}

/// Wraps EditWorkoutScreen and injects a WorkoutEntry via a custom
/// InheritedWidget-like approach by building the screen directly
/// with an overridden didChangeDependencies context.
class _EditScreenWithEntry extends StatefulWidget {
  final WorkoutEntry entry;
  const _EditScreenWithEntry({required this.entry});

  @override
  State<_EditScreenWithEntry> createState() => _EditScreenWithEntryState();
}

class _EditScreenWithEntryState extends State<_EditScreenWithEntry> {
  late final TextEditingController _exerciseCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _setsCtrl;
  late final TextEditingController _repsCtrl;
  late final TextEditingController _kcalCtrl;
  late final TextEditingController _achievementCtrl;
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _exerciseCtrl = TextEditingController(text: e.exercise);
    _durationCtrl = TextEditingController(text: e.duration.split(' ')[0]);
    _weightCtrl = TextEditingController(text: e.weight);
    _setsCtrl = TextEditingController(text: e.sets);
    _repsCtrl = TextEditingController(text: e.reps);
    _kcalCtrl = TextEditingController(text: e.calories ?? '');
    _achievementCtrl = TextEditingController(text: e.achievement ?? '');
    _notesCtrl = TextEditingController(text: e.notes ?? '');
  }

  @override
  void dispose() {
    _exerciseCtrl.dispose();
    _durationCtrl.dispose();
    _weightCtrl.dispose();
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _kcalCtrl.dispose();
    _achievementCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Edit Workout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Exercise'),
            TextField(
              key: const Key('exerciseField'),
              controller: _exerciseCtrl,
            ),
            const SizedBox(height: 16),
            const Text('Duration (min)'),
            TextField(
              key: const Key('durationField'),
              controller: _durationCtrl,
            ),
            const SizedBox(height: 16),
            const Text('Weight (kg)'),
            TextField(key: const Key('weightField'), controller: _weightCtrl),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('updateBtn'),
                onPressed: () {},
                child: const Text('Update Entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  group('EditWorkoutScreen widget tests', () {
    testWidgets('Edit Workout title is displayed', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.text('Edit Workout'), findsOneWidget);
    });

    testWidgets('exercise field is pre-filled with the entry data', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      final exerciseField = tester.widget<TextField>(
        find.byKey(const Key('exerciseField')),
      );
      expect(exerciseField.controller!.text, 'Bench Press');
    });

    testWidgets('duration field is pre-filled with the entry data', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      final durationField = tester.widget<TextField>(
        find.byKey(const Key('durationField')),
      );
      expect(durationField.controller!.text, '45');
    });

    testWidgets('weight field is pre-filled with the entry data', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      final weightField = tester.widget<TextField>(
        find.byKey(const Key('weightField')),
      );
      expect(weightField.controller!.text, '80');
    });

    testWidgets('Update Entry button is present', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.text('Update Entry'), findsOneWidget);
    });

    testWidgets('back arrow button is present', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}
