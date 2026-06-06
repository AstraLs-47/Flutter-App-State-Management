// Integration test: Tab Navigation Flow
//
// Tests that an authenticated user can navigate between all bottom-nav tabs:
//   Dashboard  →  Tracking  →  Exercises  →  Product  →  Profile
//
// All HTTP calls are intercepted by a MockClient so no real backend is needed.

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
  });

  group('Tab Navigation Flow', () {
    testWidgets('signed-in user can navigate through all bottom-nav tabs', (
      tester,
    ) async {
      final mockClient = buildMockClient();
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

        // Sign in
        await goToSignIn(tester);
        await signIn(tester, 'user@example.com', 'Password123');

        // Dashboard visible
        expect(find.text('THE PULSE'), findsOneWidget);

        // Tab: Tracking
        await tester.tap(find.text('Tracking'));
        await pumpFor(tester, const Duration(seconds: 1));
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is RichText &&
                w.text.toPlainText().contains('DAILY Tracking'),
          ),
          findsOneWidget,
        );

        // Tab: Exercises
        await tester.tap(find.text('Exercises'));
        await pumpFor(tester, const Duration(seconds: 1));
        expect(find.text('WORKOUT'), findsOneWidget);

        // Tab: Product
        await tester.tap(find.text('Product'));
        await pumpFor(tester, const Duration(seconds: 1));
        expect(find.text('Arena'), findsOneWidget);

        // Tab: Profile
        await tester.tap(find.text('Profile'));
        await pumpFor(tester, const Duration(seconds: 1));
        expect(find.text('Profile'), findsOneWidget);
      }, () => mockClient);
    });
  });
}
