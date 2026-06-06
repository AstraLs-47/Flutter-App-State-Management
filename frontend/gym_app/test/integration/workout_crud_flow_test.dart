// Integration test: Workout Log CRUD Flow
//
// Tests creating, editing, and deleting a workout entry:
//   Login → Tracking tab → Add workout → Edit workout → Delete workout
//
// The local SQLite database is pre-seeded with an exercise so the dropdown
// is populated without a live backend. All HTTP calls are mocked.
// Note: add_workout_screen and edit_workout_screen use plain TextField
// (not TextFormField) inside their _buildTextField helper.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:gym_app/core/network/api_client.dart';
import 'package:gym_app/core/providers/core_providers.dart';
import 'package:gym_app/main.dart' as app;
import 'package:gym_app/core/data/database_helper.dart';

import 'test_helpers.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => '.',
        );
  });

  tearDown(() async {
    await DatabaseHelper().clearAllCaches();
    await DatabaseHelper().close();
    await resetMockDb();
  });

  group('Workout Log CRUD Flow', () {
    testWidgets('user can add, edit, and delete a workout entry', (
      tester,
    ) async {
      final mockClient = buildMockClient();
      setLargeDisplay(tester);
      await resetMockDb();

      // Pre-seed the local DB so the exercise dropdown has data
      final db = DatabaseHelper();
      await db.insert('exercises', {
        'id': 'e1',
        'name': 'Bench Press',
        'description': 'Chest exercise',
        'category_name': 'Chest',
        'image_url': 'pushup.png',
        'duration': '',
        'warmup': '',
        'main_workout': '',
        'rest': '',
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              apiClientProvider.overrideWithValue(
                ApiClient(client: mockClient),
              ),
            ],
            child: const app.MyApp(),
          ),
        );
        await safePump(tester);

        // Login
        await goToSignIn(tester);
        await signIn(tester, 'user@example.com', 'Password123');

        // Navigate to Tracking
        await tester.tap(find.text('Tracking'));
        await safePump(tester);

        // Tap Add Workout button
        await tester.tap(find.byIcon(Icons.add));
        await safePump(tester);

        // Select exercise from dropdown
        await tester.tap(find.text('Choose your exercise...'));
        await safePump(tester);
        await tester.tap(find.text('Bench Press').last);
        await safePump(tester);

        // Fill workout form
        final formFields = find.byType(TextField);
        await tester.enterText(formFields.at(0), '45'); // duration
        await tester.enterText(formFields.at(1), '80'); // weight
        await tester.enterText(formFields.at(2), '4'); // sets
        await tester.enterText(formFields.at(3), '10'); // reps
        await tester.enterText(formFields.at(4), '300'); // calories
        await tester.enterText(formFields.at(5), 'Felt strong'); // notes
        await tester.enterText(formFields.at(6), 'PR'); // achievement

        // Submit
        await tester.tap(find.text('Log Workout 🔥'));
        await pumpFor(tester, const Duration(seconds: 1));

        // Workout appears in the list
        expect(find.text('Bench Press'), findsOneWidget);

        // Edit workout
        await tester.tap(find.byIcon(Icons.edit_outlined));
        await safePump(tester);
        final editFields = find.byType(TextField);
        await tester.enterText(editFields.at(0), '50');
        await tester.tap(find.text('Update Entry'));
        await pumpFor(tester, const Duration(seconds: 1));

        // Delete workout
        await tester.tap(find.byIcon(Icons.delete_outline));
        await safePump(tester);
        await tester.tap(find.text('Yes'));
        await pumpFor(tester, const Duration(seconds: 1));

        // Entry is removed
        expect(find.text('Bench Press'), findsNothing);
      }, () => mockClient);
    });
  });
}
