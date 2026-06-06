import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/data/database_helper.dart';
import 'package:gym_app/features/workout/data/progress_repository.dart';
import 'package:gym_app/features/workout/data/models/workout_entry_model.dart';
import 'package:gym_app/core/network/api_client.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  late MockApiClient mockApiClient;
  late MockDatabaseHelper mockDbHelper;
  late ProgressRepository repository;

  final testEntry = WorkoutEntry(
    id: 'w1',
    title: 'Bench Press',
    date: '2026-05-31',
    duration: '45 MIN',
    exercise: 'Bench Press',
    intensity: 'Intense',
    weight: '80.0',
    sets: '4',
    reps: '10',
    calories: '300',
    achievement: 'PR',
    notes: 'Good',
  );

  final testDbRow = {
    'id': 'w1',
    'exercise_name': 'Bench Press',
    'entry_date': '2026-05-31',
    'duration_minutes': 45,
    'sets': 4,
    'reps': 10,
    'weight': 80.0,
    'intensity': 'Intense',
    'notes': 'Good',
    'achievement': 'PR',
  };

  setUp(() {
    mockApiClient = MockApiClient();
    mockDbHelper = MockDatabaseHelper();
    repository = ProgressRepository(
      apiClient: mockApiClient,
      dbHelper: mockDbHelper,
    );
  });

  group('ProgressRepository', () {
    test('should return cached data and NOT call API on cache hit', () async {
      when(
        () => mockDbHelper.queryAll('progress_entries'),
      ).thenAnswer((_) async => [testDbRow]);

      final result = await repository.getWorkoutEntries(forceRefresh: false);

      expect(result, hasLength(1));
      expect(result.first.id, 'w1');
      verify(() => mockDbHelper.queryAll('progress_entries')).called(1);
      verifyNever(() => mockApiClient.get(any()));
    });

    test(
      'should fetch from API, clear cache, and insertAll on cache miss',
      () async {
        when(
          () => mockDbHelper.queryAll('progress_entries'),
        ).thenAnswer((_) async => []);
        when(() => mockApiClient.get(any())).thenAnswer(
          (_) async => {
            'entries': [
              {
                'id': 'w1',
                'exerciseName': 'Bench Press',
                'entryDate': '2026-05-31',
                'durationMinutes': 45,
                'sets': 4,
                'reps': 10,
                'weight': 80.0,
                'intensity': 'intense',
                'calories': 300,
                'achievement': 'PR',
                'notes': 'Good',
              },
            ],
          },
        );
        when(
          () => mockDbHelper.clearTable('progress_entries'),
        ).thenAnswer((_) async {});
        when(
          () => mockDbHelper.insertAll('progress_entries', any()),
        ).thenAnswer((_) async {});

        final result = await repository.getWorkoutEntries(forceRefresh: false);

        expect(result, hasLength(1));
        expect(result.first.id, 'w1');
        verify(() => mockDbHelper.queryAll('progress_entries')).called(1);
        verify(() => mockApiClient.get(any())).called(1);
        verify(() => mockDbHelper.clearTable('progress_entries')).called(1);
        verify(
          () => mockDbHelper.insertAll('progress_entries', any()),
        ).called(1);
      },
    );

    test(
      'should fetch from API, clear cache, and insertAll on force refresh even if cache has data',
      () async {
        when(() => mockApiClient.get(any())).thenAnswer(
          (_) async => {
            'entries': [
              {
                'id': 'w1',
                'exerciseName': 'Bench Press',
                'entryDate': '2026-05-31',
                'durationMinutes': 45,
                'sets': 4,
                'reps': 10,
                'weight': 80.0,
                'intensity': 'intense',
                'calories': 300,
                'achievement': 'PR',
                'notes': 'Good',
              },
            ],
          },
        );
        when(
          () => mockDbHelper.clearTable('progress_entries'),
        ).thenAnswer((_) async {});
        when(
          () => mockDbHelper.insertAll('progress_entries', any()),
        ).thenAnswer((_) async {});

        final result = await repository.getWorkoutEntries(forceRefresh: true);

        expect(result, hasLength(1));
        expect(result.first.id, 'w1');
        verifyNever(() => mockDbHelper.queryAll('progress_entries'));
        verify(() => mockApiClient.get(any())).called(1);
        verify(() => mockDbHelper.clearTable('progress_entries')).called(1);
        verify(
          () => mockDbHelper.insertAll('progress_entries', any()),
        ).called(1);
      },
    );

    test(
      'should return cached data on force refresh when API throws but cache exists',
      () async {
        when(
          () => mockDbHelper.queryAll('progress_entries'),
        ).thenAnswer((_) async => [testDbRow]);
        when(() => mockApiClient.get(any())).thenThrow(Exception('API error'));

        final result = await repository.getWorkoutEntries(forceRefresh: true);

        expect(result, hasLength(1));
        expect(result.first.id, 'w1');
        verify(() => mockApiClient.get(any())).called(1);
        verify(() => mockDbHelper.queryAll('progress_entries')).called(1);
      },
    );

    test('should throw exception on force refresh when API throws', () async {
      when(
        () => mockDbHelper.queryAll('progress_entries'),
      ).thenAnswer((_) async => []);
      when(() => mockApiClient.get(any())).thenThrow(Exception('API error'));

      expect(
        () => repository.getWorkoutEntries(forceRefresh: true),
        throwsException,
      );
      verify(() => mockApiClient.get(any())).called(1);
      verify(() => mockDbHelper.queryAll('progress_entries')).called(1);
    });

    test(
      'should create workout entry, insert into database, and return new entry',
      () async {
        when(
          () => mockApiClient.post(any(), body: any(named: 'body')),
        ).thenAnswer(
          (_) async => {
            'id': 'w_new',
            'exerciseName': 'Bench Press',
            'entryDate': '2026-05-31',
            'durationMinutes': 45,
            'sets': 4,
            'reps': 10,
            'weight': 80.0,
            'intensity': 'intense',
            'calories': 300,
            'achievement': 'PR',
            'notes': 'Good',
          },
        );
        when(
          () => mockDbHelper.insert('progress_entries', any()),
        ).thenAnswer((_) async {});

        final result = await repository.createWorkoutEntry(testEntry);

        expect(result.id, 'w_new');
        verify(
          () => mockApiClient.post(any(), body: any(named: 'body')),
        ).called(1);
        verify(() => mockDbHelper.insert('progress_entries', any())).called(1);
      },
    );

    test(
      'should update workout entry, update cache, and return updated entry',
      () async {
        when(
          () => mockApiClient.put(any(), body: any(named: 'body')),
        ).thenAnswer(
          (_) async => {
            'id': 'w1',
            'exerciseName': 'Bench Press Updated',
            'entryDate': '2026-05-31',
            'durationMinutes': 45,
            'sets': 4,
            'reps': 10,
            'weight': 80.0,
            'intensity': 'intense',
            'calories': 300,
            'achievement': 'PR',
            'notes': 'Good',
          },
        );
        when(
          () => mockDbHelper.insert('progress_entries', any()),
        ).thenAnswer((_) async {});

        final result = await repository.updateWorkoutEntry(testEntry);

        expect(result.exercise, 'Bench Press Updated');
        verify(
          () => mockApiClient.put(any(), body: any(named: 'body')),
        ).called(1);
        verify(() => mockDbHelper.insert('progress_entries', any())).called(1);
      },
    );

    test('should delete workout entry from cache and API', () async {
      when(
        () => mockDbHelper.delete('progress_entries', 'w1'),
      ).thenAnswer((_) async {});
      when(() => mockApiClient.delete(any())).thenAnswer((_) async => {});

      await repository.deleteWorkoutEntry('w1');

      verify(() => mockDbHelper.delete('progress_entries', 'w1')).called(1);
      verify(() => mockApiClient.delete(any())).called(1);
    });

    test('should return stats from API when successful', () async {
      final mockStats = {
        'totalEntries': 10,
        'totalMinutes': 450,
        'exercisesUsed': 3,
      };
      when(() => mockApiClient.get(any())).thenAnswer((_) async => mockStats);

      final result = await repository.getStats();

      expect(result['totalEntries'], 10);
      verify(() => mockApiClient.get(any())).called(1);
    });

    test('should calculate local stats from cache when API throws', () async {
      when(() => mockApiClient.get(any())).thenThrow(Exception('API error'));
      when(
        () => mockDbHelper.queryAll('progress_entries'),
      ).thenAnswer((_) async => [testDbRow]);

      final result = await repository.getStats();

      expect(result['totalEntries'], 1);
      expect(result['totalMinutes'], 45);
      expect(result['exercisesUsed'], 1);
      verify(() => mockDbHelper.queryAll('progress_entries')).called(1);
    });
  });
}
