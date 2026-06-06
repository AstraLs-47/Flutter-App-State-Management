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

  group('Admin Announcement Management Flow', () {
    testWidgets('admin can create and verify a new announcement', (
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

        // Login as admin
        await goToSignIn(tester);
        await signIn(tester, 'admin@example.com', 'adminpassword');
        await safePump(tester);

        // Navigate to Announcements management (Announce tab)
        await tester.tap(find.text('Announce'));
        await safePump(tester);

        expect(find.text('Announcements'), findsAtLeastNWidgets(1));

        // Open Create Dialog
        await tester.tap(find.byIcon(Icons.add));
        await safePump(tester);

        final fields = find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextFormField),
        );

        await tester.enterText(fields.at(0), 'Integration Test Alert');
        await tester.enterText(fields.at(1), 'This is a test announcement');

        await tester.tap(find.text('Post'));
        await safePump(tester);

        // Verify it appears in the list
        expect(find.text('Integration Test Alert'), findsOneWidget);
      }, () => mockClient);
    });
  });
}
