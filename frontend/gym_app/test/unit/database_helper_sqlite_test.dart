import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/data/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize FFI for SQLite tests on Windows/CI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.'; // Returns current directory as mock document path
      },
    );
  });

  setUp(() async {
    final helper = DatabaseHelper();
    // Clear all tables to ensure test isolation
    await helper.clearAllCaches();
    await helper.clearTable('categories');
    await helper.clearTable('user_sessions');
  });

  tearDownAll(() async {
    // Delete database file after all tests finish
    final dbFile = File('./purepulse.db');
    if (await dbFile.exists()) {
      try {
        await dbFile.delete();
      } catch (_) {}
    }
  });

  group('DatabaseHelper SQLite', () {
    test('should initialize and create tables', () async {
      final helper = DatabaseHelper();
      final products = await helper.queryAll('products');
      expect(products, isEmpty);
      
      final product = {
        'id': 'p1',
        'name': 'Protein Powder',
        'description': 'Whey protein',
        'category': 'Supplements',
        'image_url': 'http://image',
        'is_active': 1,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      };
      await helper.insert('products', product);
      
      final queryResult = await helper.queryAll('products');
      expect(queryResult, hasLength(1));
      expect(queryResult.first['id'], 'p1');
    });

    test('should insert and query all tables', () async {
      final helper = DatabaseHelper();
      
      // 1. exercises
      await helper.insert('exercises', {
        'id': 'e1',
        'name': 'Squat',
        'description': 'Leg exercise',
        'image_url': 'http://image',
        'category_name': 'Legs',
        'duration': '10',
        'warmup': '5',
        'main_workout': '20',
        'rest': '1',
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      });

      // 2. announcements
      await helper.insert('announcements', {
        'id': 'a1',
        'title': 'New Gym Hours',
        'description': 'Open 24/7',
        'date': '2026-05-31',
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      });

      // 3. progress_entries
      await helper.insert('progress_entries', {
        'id': 'pr1',
        'exercise_name': 'Bench Press',
        'entry_date': '2026-05-31',
        'duration_minutes': 45,
        'sets': 4,
        'reps': 10,
        'weight': 80.0,
        'intensity': 'High',
        'notes': 'Felt good',
        'achievement': 'PR',
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      });

      // 4. health_metrics
      await helper.insert('health_metrics', {
        'id': 'h1',
        'blood_pressure_systolic': 120,
        'blood_pressure_diastolic': 80,
        'resting_heart_rate': 65,
        'blood_sugar': 90.0,
        'weight': 75.0,
        'height': 1.8,
        'bmi': 23.1,
        'date': '2026-05-31',
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      });

      // 5. categories
      await helper.insert('categories', {
        'id': 'c1',
        'name': 'Strength',
        'type': 'Exercise',
      });

      // 6. user_sessions
      await helper.insert('user_sessions', {
        'id': 1,
        'user_id': 'u1',
        'token': 'my-token',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

      // Verify all tables have the records
      expect(await helper.queryAll('exercises'), hasLength(1));
      expect(await helper.queryAll('announcements'), hasLength(1));
      expect(await helper.queryAll('progress_entries'), hasLength(1));
      expect(await helper.queryAll('health_metrics'), hasLength(1));
      expect(await helper.queryAll('categories'), hasLength(1));
      expect(await helper.queryAll('user_sessions'), hasLength(1));
    });

    test('should batch insert using insertAll', () async {
      final helper = DatabaseHelper();
      final rows = [
        {
          'id': 'p1',
          'name': 'Protein 1',
          'is_active': 1,
        },
        {
          'id': 'p2',
          'name': 'Protein 2',
          'is_active': 1,
        }
      ];

      await helper.insertAll('products', rows);
      final result = await helper.queryAll('products');
      expect(result, hasLength(2));
    });

    test('should delete and clear tables correctly', () async {
      final helper = DatabaseHelper();
      await helper.insert('products', {'id': 'p1', 'name': 'P1'});
      await helper.insert('products', {'id': 'p2', 'name': 'P2'});

      await helper.delete('products', 'p1');
      var result = await helper.queryAll('products');
      expect(result, hasLength(1));
      expect(result.first['id'], 'p2');

      await helper.clearTable('products');
      result = await helper.queryAll('products');
      expect(result, isEmpty);
    });

    test('should clear all caches', () async {
      final helper = DatabaseHelper();
      await helper.insert('products', {'id': 'p1', 'name': 'P1'});
      await helper.insert('exercises', {'id': 'e1', 'name': 'E1'});
      await helper.insert('announcements', {'id': 'a1', 'title': 'A1'});
      await helper.insert('progress_entries', {'id': 'pr1', 'exercise_name': 'PR1'});
      await helper.insert('health_metrics', {'id': 'h1', 'date': '2026-05-31'});

      await helper.clearAllCaches();

      expect(await helper.queryAll('products'), isEmpty);
      expect(await helper.queryAll('exercises'), isEmpty);
      expect(await helper.queryAll('announcements'), isEmpty);
      expect(await helper.queryAll('progress_entries'), isEmpty);
      expect(await helper.queryAll('health_metrics'), isEmpty);
    });
  });
}
