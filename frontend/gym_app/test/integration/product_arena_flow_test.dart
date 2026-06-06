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

  group('Product Arena & Contact Us Flow', () {
    testWidgets(
      'user can view the product listing and navigate to Contact Us',
      (tester) async {
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

          // Pre-populate products cache so listing renders deterministically
          await DatabaseHelper().insert('products', {
            'id': 'p1',
            'name': 'Protein Powder',
            'description': 'Whey Protein',
            'category': 'Supplements',
            'image_url': 'protein.png',
            'is_active': 1,
            'cached_at': DateTime.now().millisecondsSinceEpoch,
          });

          // Product tab → verify listing
          await tester.tap(find.text('Product'));
          await safePump(tester);
          expect(find.text('Protein Powder'), findsOneWidget);

          // Tap the Contact button on the product card → Contact Us screen
          await tester.tap(find.text('Contact').first);
          await safePump(tester);
        }, () => mockClient);
      },
    );
  });
}
