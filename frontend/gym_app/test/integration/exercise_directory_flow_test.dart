// Integration test: Exercise Directory & Detail Flow
//
// Tests browsing exercises by category and opening the detail screen:
//   Login → Exercises tab → Filter by Chest → Tap exercise → Detail screen
//
// The local SQLite database is pre-seeded with a category and an exercise.
// All HTTP calls are intercepted by a MockClient so no real backend is needed.

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

  setUp(() async {
    await resetMockDb();
  });

  tearDown(() async {
    await DatabaseHelper().clearAllCaches();
    await DatabaseHelper().close();
  });

  group('Exercise Directory & Detail Flow', () {
    testWidgets(
      'user can browse exercises by category and view the detail screen',
      (tester) async {
        final mockClient = buildMockClient();

        // Pre-seed local DB with a category and an exercise
        final db = DatabaseHelper();
        await db.insert('categories', {
          'id': 'c1',
          'name': 'Chest',
          'type': 'exercise',
        });
        await db.insert('exercises', {
          'id': 'e1',
          'name': 'Push Up',
          'description': 'Chest exercise',
          'category_name': 'Chest',
          'image_url': 'pushup.png',
          'duration': '15 min',
          'warmup': 'Arm circles',
          'main_workout': '3 sets of 15 pushups',
          'rest': '60 seconds',
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

          // Navigate to Exercises tab
          await tester.tap(find.text('Exercises'));
          await safePump(tester);

          // Filter by Chest category chip
          expect(find.text('Chest'), findsOneWidget);
          await tester.tap(find.text('Chest').first);
          await safePump(tester);

          // Exercise card is visible
          expect(find.text('Push Up'), findsOneWidget);

          // Tap to open detail screen
          await tester.tap(find.text('Push Up'));
          await safePump(tester);

          // Verify detail content
          expect(find.text('Warm-up Details'), findsOneWidget);
          expect(find.text('Arm circles'), findsOneWidget);
          expect(find.text('Main Exercise'), findsOneWidget);
          expect(find.text('3 sets of 15 pushups'), findsOneWidget);
        }, () => mockClient);
      },
    );
  });
}
