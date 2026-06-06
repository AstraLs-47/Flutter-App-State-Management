import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/data/database_helper.dart';
import 'package:gym_app/core/models/activity_model.dart';
import 'package:gym_app/core/network/api_client.dart';
import 'package:gym_app/features/products/data/exercise_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  late MockApiClient mockApiClient;
  late MockDatabaseHelper mockDbHelper;
  late ExerciseRepository repository;

  final testActivity = Activity(
    id: 'e1',
    title: 'Push Up',
    description: 'Chest workout',
    category: 'Chest',
    image: 'pushup.png',
  );

  final testDbRow = {
    'id': 'e1',
    'name': 'Push Up',
    'description': 'Chest workout',
    'category_name': 'Chest',
    'image_url': 'pushup.png',
    'duration': '',
    'warmup': '',
    'main_workout': '',
    'rest': '',
  };

  setUp(() {
    mockApiClient = MockApiClient();
    mockDbHelper = MockDatabaseHelper();
    repository = ExerciseRepository(apiClient: mockApiClient, dbHelper: mockDbHelper);
  });

  group('ExerciseRepository', () {
    test('should return cached data and NOT call API on cache hit', () async {
      when(() => mockDbHelper.queryAll('exercises')).thenAnswer((_) async => [testDbRow]);

      final result = await repository.getExercises(forceRefresh: false);

      expect(result, hasLength(1));
      expect(result.first.id, 'e1');
      verify(() => mockDbHelper.queryAll('exercises')).called(1);
      verifyNever(() => mockApiClient.get(any()));
    });

    test('should fetch from API, clear cache, and insertAll on cache miss', () async {
      when(() => mockDbHelper.queryAll('exercises')).thenAnswer((_) async => []);
      when(() => mockApiClient.get(any())).thenAnswer((_) async => [
        {
          'id': 'e1',
          'title': 'Push Up',
          'description': 'Chest workout',
          'category': 'Chest',
          'image': 'pushup.png'
        }
      ]);
      when(() => mockDbHelper.clearTable('exercises')).thenAnswer((_) async {});
      when(() => mockDbHelper.insertAll('exercises', any())).thenAnswer((_) async {});

      final result = await repository.getExercises(forceRefresh: false);

      expect(result, hasLength(1));
      expect(result.first.id, 'e1');
      verify(() => mockDbHelper.queryAll('exercises')).called(1);
      verify(() => mockApiClient.get(any())).called(1);
      verify(() => mockDbHelper.clearTable('exercises')).called(1);
      verify(() => mockDbHelper.insertAll('exercises', any())).called(1);
    });

    test('should fetch from API, clear cache, and insertAll on force refresh even if cache has data', () async {
      when(() => mockApiClient.get(any())).thenAnswer((_) async => [
        {
          'id': 'e1',
          'title': 'Push Up',
          'description': 'Chest workout',
          'category': 'Chest',
          'image': 'pushup.png'
        }
      ]);
      when(() => mockDbHelper.clearTable('exercises')).thenAnswer((_) async {});
      when(() => mockDbHelper.insertAll('exercises', any())).thenAnswer((_) async {});

      final result = await repository.getExercises(forceRefresh: true);

      expect(result, hasLength(1));
      expect(result.first.id, 'e1');
      verifyNever(() => mockDbHelper.queryAll('exercises'));
      verify(() => mockApiClient.get(any())).called(1);
      verify(() => mockDbHelper.clearTable('exercises')).called(1);
      verify(() => mockDbHelper.insertAll('exercises', any())).called(1);
    });

    test('should throw exception on force refresh when API throws', () async {
      when(() => mockApiClient.get(any())).thenThrow(Exception('API error'));

      expect(() => repository.getExercises(forceRefresh: true), throwsException);
      verifyNever(() => mockDbHelper.queryAll('exercises'));
    });

    test('should create exercise, insert into database, and return new exercise', () async {
      when(() => mockApiClient.post(any(), body: any(named: 'body'))).thenAnswer((_) async => {
        'id': 'e_new',
        'title': 'Push Up',
        'description': 'Chest workout',
        'category': 'Chest',
        'image': 'pushup.png'
      });
      when(() => mockDbHelper.insert('exercises', any())).thenAnswer((_) async {});

      final result = await repository.createExercise(testActivity);

      expect(result.id, 'e_new');
      verify(() => mockApiClient.post(any(), body: any(named: 'body'))).called(1);
      verify(() => mockDbHelper.insert('exercises', any())).called(1);
    });

    test('should update exercise, update cache, and return updated exercise', () async {
      when(() => mockApiClient.put(any(), body: any(named: 'body'))).thenAnswer((_) async => {
        'id': 'e1',
        'title': 'Push Up Updated',
        'description': 'Chest workout',
        'category': 'Chest',
        'image': 'pushup.png'
      });
      when(() => mockDbHelper.insert('exercises', any())).thenAnswer((_) async {});

      final result = await repository.updateExercise(testActivity);

      expect(result.title, 'Push Up Updated');
      verify(() => mockApiClient.put(any(), body: any(named: 'body'))).called(1);
      verify(() => mockDbHelper.insert('exercises', any())).called(1);
    });

    test('should delete exercise from cache and API', () async {
      when(() => mockDbHelper.delete('exercises', 'e1')).thenAnswer((_) async {});
      when(() => mockApiClient.delete(any())).thenAnswer((_) async => {});

      await repository.deleteExercise('e1');

      verify(() => mockDbHelper.delete('exercises', 'e1')).called(1);
      verify(() => mockApiClient.delete(any())).called(1);
    });
  });
}
