import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/api_client.dart';
import 'package:gym_app/features/admin/data/admin_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------
class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  // -------------------------------------------------------------------------
  // Bootstrap: same pattern as database_helper_sqlite_test.dart so that the
  // real DatabaseHelper singleton (used by AdminRepository) can initialise
  // sqflite via FFI and find a valid document path.
  // -------------------------------------------------------------------------
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.'; // current directory as mock document path
      },
    );
  });

  tearDownAll(() async {
    final dbFile = File('./purepulse.db');
    if (await dbFile.exists()) {
      try {
        await dbFile.delete();
      } catch (_) {}
    }
  });

  late MockApiClient mockApi;

  setUp(() {
    mockApi = MockApiClient();
    // Reset the AdminRepository singleton so each test starts clean.
    AdminRepository().resetClient();
    AdminRepository().setApiClientForTest(mockApi);
  });

  // -------------------------------------------------------------------------
  // fetchCategories — cache-hit path
  // -------------------------------------------------------------------------
  group('AdminRepository - fetchCategories cache-hit', () {
    test(
        'in-memory lists are pre-populated from SQLite before any API call',
        () async {
      // Seed the real SQLite database with exercises and products.
      final repo = AdminRepository();

      // Since fetchCategories always makes an API call for categories too,
      // stub the API to return empty so that the test focuses on the cache path.
      when(() => mockApi.get(any(), includeAuth: any(named: 'includeAuth')))
          .thenAnswer((_) async => []);

      // Pre-seed the exercises table via the dbForTest getter.
      await repo.dbForTest.insert('exercises', {
        'id': 'e1',
        'name': 'Push Up',
        'description': 'Chest exercise',
        'image_url': 'pushup.png',
        'category_name': 'Chest',
        'duration': '15 min',
        'warmup': 'Arm circles',
        'main_workout': '3 sets of 15',
        'rest': '60s',
        'cached_at': 1000,
      });

      await repo.fetchCategories();

      // The cache-hit path should have loaded exercises from SQLite.
      expect(repo.activities, hasLength(greaterThanOrEqualTo(1)));
      expect(repo.activities.first['title'], 'Push Up');

      // Clean up
      await repo.dbForTest.clearTable('exercises');
    });

    test('announcements list is pre-populated from SQLite cache', () async {
      final repo = AdminRepository();

      when(() => mockApi.get(any(), includeAuth: any(named: 'includeAuth')))
          .thenAnswer((_) async => []);

      await repo.dbForTest.insert('announcements', {
        'id': 'a1',
        'title': 'Gym Closed',
        'description': 'Closed on Monday',
        'date': '2026-05-31',
        'cached_at': 1000,
      });

      await repo.fetchCategories();

      expect(repo.announcements, hasLength(greaterThanOrEqualTo(1)));

      await repo.dbForTest.clearTable('announcements');
    });
  });

  // -------------------------------------------------------------------------
  // fetchCategories — cache-miss path
  // -------------------------------------------------------------------------
  group('AdminRepository - fetchCategories cache-miss', () {
    test('calls the API when the cache is empty', () async {
      when(() => mockApi.get(any(), includeAuth: any(named: 'includeAuth')))
          .thenAnswer((_) async => [
                {'id': 'c1', 'name': 'Chest', 'type': 'exercise'},
              ]);

      await AdminRepository().fetchCategories();

      verify(
        () => mockApi.get(any(), includeAuth: any(named: 'includeAuth')),
      ).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // Product mutations
  // -------------------------------------------------------------------------
  group('AdminRepository - product mutations', () {
    test('addProduct() calls API post and persists to SQLite', () async {
      when(() => mockApi.post(any(), body: any(named: 'body')))
          .thenAnswer((_) async => {'id': 'p_new'});

      await AdminRepository().addProduct({
        'id': '',
        'name': 'Creatine',
        'category': 'Supplements',
        'image': '',
      });

      verify(() => mockApi.post(any(), body: any(named: 'body'))).called(1);

      // Confirm DB was written
      final rows = await AdminRepository().dbForTest.queryAll('products');
      expect(rows.any((r) => r['name'] == 'Creatine'), isTrue);

      await AdminRepository().dbForTest.clearTable('products');
    });

    test('removeProduct() deletes from SQLite and removes from in-memory list',
        () async {
      when(() => mockApi.delete(any())).thenAnswer((_) async => {});

      final repo = AdminRepository();
      // Pre-seed the product into the in-memory list.
      repo.products = [
        {'id': 'p1', 'name': 'Protein', 'category': 'Supplements', 'image': ''}
      ];
      // Also write to DB so delete has something to remove.
      await repo.dbForTest.insert('products', {
        'id': 'p1',
        'name': 'Protein',
        'category': 'Supplements',
        'image_url': '',
      });

      await repo.removeProduct({
        'id': 'p1',
        'name': 'Protein',
        'category': 'Supplements',
        'image': '',
      });

      expect(repo.products.any((p) => p['id'] == 'p1'), isFalse);

      final rows = await repo.dbForTest.queryAll('products');
      expect(rows.any((r) => r['id'] == 'p1'), isFalse);
    });

    test('updateProduct() persists the updated product to SQLite', () async {
      when(() => mockApi.put(any(), body: any(named: 'body')))
          .thenAnswer((_) async => {'id': 'p1'});

      final repo = AdminRepository();
      repo.products = [
        {'id': 'p1', 'name': 'Protein', 'category': 'Supplements', 'image': ''}
      ];

      await repo.updateProduct(0, {
        'id': 'p1',
        'name': 'Protein Updated',
        'category': 'Supplements',
        'image': '',
      });

      expect(repo.products.first['name'], 'Protein Updated');

      final rows = await repo.dbForTest.queryAll('products');
      expect(rows.any((r) => r['name'] == 'Protein Updated'), isTrue);

      await repo.dbForTest.clearTable('products');
    });
  });

  // -------------------------------------------------------------------------
  // Announcement mutations
  // -------------------------------------------------------------------------
  group('AdminRepository - announcement mutations', () {
    test('addAnnouncement() adds to in-memory list and persists to SQLite',
        () async {
      final repo = AdminRepository();

      repo.addAnnouncement({
        'id': 'a1',
        'title': 'Gym Closed',
        'description': 'Monday',
        'date': '2026-06-01',
      });

      // In-memory list updated immediately.
      expect(repo.announcements, hasLength(1));
      expect(repo.announcements.first['title'], 'Gym Closed');

      // Give the fire-and-forget DB insert time to complete.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final rows = await repo.dbForTest.queryAll('announcements');
      expect(rows.any((r) => r['id'] == 'a1'), isTrue);

      await repo.dbForTest.clearTable('announcements');
    });

    test(
        'updateAnnouncement() updates in-memory list and persists to SQLite',
        () async {
      final repo = AdminRepository();
      repo.announcements = [
        {
          'id': 'a1',
          'title': 'Old Title',
          'description': 'Old',
          'date': '2026-05-01',
        }
      ];

      repo.updateAnnouncement(0, {
        'id': 'a1',
        'title': 'New Title',
        'description': 'New',
        'date': '2026-06-01',
      });

      expect(repo.announcements.first['title'], 'New Title');

      await Future<void>.delayed(const Duration(milliseconds: 200));

      final rows = await repo.dbForTest.queryAll('announcements');
      expect(rows.any((r) => r['title'] == 'New Title'), isTrue);

      await repo.dbForTest.clearTable('announcements');
    });

    test(
        'removeAnnouncement() removes from in-memory list and deletes from SQLite',
        () async {
      final repo = AdminRepository();
      const ann = <String, String>{
        'id': 'a1',
        'title': 'Gym Closed',
        'description': 'Monday',
        'date': '2026-05-31',
      };
      repo.announcements = [ann];

      // Pre-seed into DB so delete has a row to remove.
      await repo.dbForTest.insert('announcements', {
        'id': 'a1',
        'title': 'Gym Closed',
        'description': 'Monday',
        'date': '2026-05-31',
        'cached_at': 1000,
      });

      repo.removeAnnouncement(ann);

      expect(repo.announcements, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 200));

      final rows = await repo.dbForTest.queryAll('announcements');
      expect(rows.any((r) => r['id'] == 'a1'), isFalse);
    });
  });
}
